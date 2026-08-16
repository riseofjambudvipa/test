# -*- coding: utf-8 -*-
"""
CapStudio Emoji Category Accuracy Verifier
==========================================
Reads emoji_base.json (ground truth), then scans every file that was
physically moved into category subdirectories. Reports:
  - Files in the WRONG category folder
  - Files that exist on disk but are MISSING from the database
  - Categories in each pack with their file counts
"""

import os
import json
import sys

BASE_DIR  = r"A:\Projects\Local AI Caption Studio\CapStudio\assets\emojis"
BASE_JSON = os.path.join(BASE_DIR, "emoji_base.json")

CATEGORIES = {
    "Smileys & Emotion",
    "People & Body",
    "Animals & Nature",
    "Food & Drink",
    "Travel & Places",
    "Activities",
    "Objects",
    "Symbols",
    "Flags",
}

PACKS = {
    "googleAnimated":       os.path.join(BASE_DIR, "google_noto_emojis_animated_pack",          "512x512"),
    "googleNonAnimated":    os.path.join(BASE_DIR, "google_noto_emojis_non_animated_pack",       "512x512"),
    "microsoftAnimated":    os.path.join(BASE_DIR, "microsoft_fluentui_emoji_animated_pack",     "256x256"),
    "microsoftNonAnimated": os.path.join(BASE_DIR, "microsoft_fluentui_emoji_non_animated_pack", "256x256"),
    "openmoji":             os.path.join(BASE_DIR, "openmoji_non_animated_pack",                 "618x618"),
}


# ── Build ground-truth map: lowercase_filename -> correct_category ────────────
def build_ground_truth():
    with open(BASE_JSON, "r", encoding="utf-8") as f:
        emojis = json.load(f)

    truth = {}   # filename_lower -> correct_cat

    for e in emojis:
        cat     = e.get("cat", "Objects")
        unicode = e.get("u", "")

        # Unicode-derived filename variants
        for ext in (".png", ".gif", ".webp"):
            truth[f"{unicode}{ext}"] = cat
            # Strip variation selectors to also match bare-unicode filenames
            stripped = unicode
            for suffix in ("-fe0f-20e3", "-fe0f", "-20e3"):
                stripped = stripped.replace(suffix, "")
            if stripped != unicode:
                truth[f"{stripped}{ext}"] = cat

        # Explicit pack filename overrides
        for _pk, fname in e.get("pk", {}).items():
            if fname:
                truth[os.path.basename(fname).lower()] = cat

    return truth


# ── Scan a pack dir and build { category -> [filename, ...] } -----------------
def scan_pack(pack_dir):
    result = {}   # cat_name -> list of basenames
    if not os.path.isdir(pack_dir):
        return result

    for entry in os.scandir(pack_dir):
        if entry.is_dir() and entry.name in CATEGORIES:
            files = [
                f.name for f in os.scandir(entry.path)
                if f.is_file()
            ]
            result[entry.name] = files
    return result


# ── Main verification logic ---------------------------------------------------
def verify():
    truth = build_ground_truth()
    print(f"Ground-truth loaded: {len(truth)} filename->category mappings\n")

    grand_mismatches = 0
    grand_unknown    = 0
    grand_total      = 0

    for pack_id, pack_dir in PACKS.items():
        print("=" * 60)
        print(f"  PACK: {pack_id}")
        print(f"  DIR : {pack_dir}")
        print("=" * 60)

        if not os.path.isdir(pack_dir):
            print("  [SKIP] Directory not found.\n")
            continue

        pack_data = scan_pack(pack_dir)

        if not pack_data:
            print("  [EMPTY] No category subdirectories found.\n")
            continue

        # Stats per category
        pack_total      = 0
        pack_mismatches = 0
        pack_unknown    = 0
        mismatch_list   = []
        unknown_list    = []

        for actual_cat, files in sorted(pack_data.items()):
            cat_wrong   = 0
            cat_unknown = 0

            for fname in files:
                key = fname.lower()
                pack_total += 1

                expected_cat = truth.get(key)

                if expected_cat is None:
                    # Try stripping variation selectors: -fe0f (visual), -20e3 (keycap combiner)
                    stem, ext = os.path.splitext(key)
                    for suffix in ("-fe0f-20e3", "-fe0f", "-20e3"):
                        alt = stem.replace(suffix, "") + ext
                        expected_cat = truth.get(alt)
                        if expected_cat:
                            break

                if expected_cat is None:
                    cat_unknown += 1
                    pack_unknown += 1
                    unknown_list.append(f"    {actual_cat}/{fname}  [NOT IN DB]")
                elif expected_cat.lower() != actual_cat.lower():
                    cat_wrong += 1
                    pack_mismatches += 1
                    mismatch_list.append(
                        f"    {actual_cat}/{fname}"
                        f"  ->  SHOULD BE: [{expected_cat}]"
                    )

            status = "OK" if cat_wrong == 0 and cat_unknown == 0 else "ISSUES"
            print(f"  [{status}] {actual_cat:<25}  {len(files):>4} files"
                  f"  |  wrong: {cat_wrong}  unknown: {cat_unknown}")

        print()

        if mismatch_list:
            print(f"  MISMATCHES ({pack_mismatches}):")
            for line in mismatch_list[:50]:   # cap output at 50 per pack
                print(line)
            if len(mismatch_list) > 50:
                print(f"  ... and {len(mismatch_list)-50} more")
            print()

        if unknown_list:
            print(f"  UNKNOWN / NOT IN DB ({pack_unknown}):")
            for line in unknown_list[:20]:
                print(line)
            if len(unknown_list) > 20:
                print(f"  ... and {len(unknown_list)-20} more")
            print()

        grand_total      += pack_total
        grand_mismatches += pack_mismatches
        grand_unknown    += pack_unknown

        print(f"  PACK SUMMARY  total={pack_total}  "
              f"mismatches={pack_mismatches}  unknown={pack_unknown}\n")

    print("=" * 60)
    print("GRAND TOTAL")
    print(f"  Files checked : {grand_total}")
    print(f"  Mismatches    : {grand_mismatches}")
    print(f"  Unknown (not in DB) : {grand_unknown}")
    accuracy = ((grand_total - grand_mismatches - grand_unknown) / grand_total * 100) if grand_total else 0
    print(f"  Accuracy      : {accuracy:.2f}%")
    print("=" * 60)

    return grand_mismatches, grand_unknown


if __name__ == "__main__":
    mismatches, unknown = verify()
    sys.exit(0 if (mismatches + unknown) == 0 else 1)
