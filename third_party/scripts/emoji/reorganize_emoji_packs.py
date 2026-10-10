"""
CapStudio Emoji Pack Physical Reorganizer
=========================================
Moves all emoji image files from the current flat directory structure into
9 Unicode-standard category subdirectories within each pack folder.

Before:
  google_noto_emojis_animated_pack/512x512/
    1f600.gif
    1f601.gif
    ...

After:
  google_noto_emojis_animated_pack/512x512/
    Smileys & Emotion/
      1f600.gif
      1f601.gif
    People & Body/
      1f466.gif
    ...

Backward compatibility:
  The file scan in EmojiService uses recursive=true, so it finds files in
  subdirectories. The getAssetPath function has been updated to check
  category-aware paths first, then fall back to the flat root path.
"""

import os
import json
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "..", ".."))
BASE_DIR = os.path.join(PROJECT_ROOT, "assets", "emojis")
BASE_JSON = os.path.join(BASE_DIR, "emoji_base.json")

# The 9 canonical Unicode categories
CATEGORIES = [
    "Smileys & Emotion",
    "People & Body",
    "Animals & Nature",
    "Food & Drink",
    "Travel & Places",
    "Activities",
    "Objects",
    "Symbols",
    "Flags",
]

PACKS = {
    "googleAnimated":       os.path.join(BASE_DIR, "google_noto_emojis_animated_pack",           "512x512"),
    "googleNonAnimated":    os.path.join(BASE_DIR, "google_noto_emojis_non_animated_pack",        "512x512"),
    "microsoftAnimated":    os.path.join(BASE_DIR, "microsoft_fluentui_emoji_animated_pack",      "256x256"),
    "microsoftNonAnimated": os.path.join(BASE_DIR, "microsoft_fluentui_emoji_non_animated_pack",  "256x256"),
    "openmoji":             os.path.join(BASE_DIR, "openmoji_non_animated_pack",                  "618x618"),
}

SKIP_FILES = {".md", ".txt", ".json", ".xml"}


def load_file_to_category_map():
    """Build a dict mapping lowercase filename -> category name."""
    with open(BASE_JSON, "r", encoding="utf-8") as f:
        emojis = json.load(f)

    mapping = {}
    for e in emojis:
        cat = e.get("cat", "Objects")
        unicode_val = e.get("u", "")

        # Map all known filename variants to this category
        for ext in (".png", ".gif", ".webp"):
            mapping[f"{unicode_val}{ext}"] = cat
            # Remove -fe0f variant (variation selector)
            cleaned = unicode_val.replace("-fe0f", "")
            if cleaned != unicode_val:
                mapping[f"{cleaned}{ext}"] = cat

        # Map explicitly declared pack filenames
        for _pack_id, filename in e.get("pk", {}).items():
            if filename:
                base = os.path.basename(filename).lower()
                mapping[base] = cat

    return mapping


def reorganize(dry_run=False):
    file_to_cat = load_file_to_category_map()

    total_moved = 0
    total_skipped = 0
    total_unmapped = 0

    for pack_id, pack_dir in PACKS.items():
        if not os.path.isdir(pack_dir):
            print(f"  [SKIP] {pack_id}: directory not found at {pack_dir}")
            continue

        # Collect only the files sitting directly in the pack_dir root (flat)
        flat_files = [
            f for f in os.listdir(pack_dir)
            if os.path.isfile(os.path.join(pack_dir, f))
        ]

        if not flat_files:
            print(f"  [DONE] {pack_id}: no flat files to move (already organised?)")
            continue

        print(f"\n  [{pack_id}]  {len(flat_files)} flat files found")

        moved = 0
        skipped = 0
        unmapped = 0

        for filename in flat_files:
            ext = os.path.splitext(filename)[1].lower()
            if ext in SKIP_FILES:
                skipped += 1
                continue

            key = filename.lower()
            cat = file_to_cat.get(key)

            # Fallback: try stripping -fe0f
            if not cat:
                name_no_ext = os.path.splitext(key)[0]
                clean = name_no_ext.replace("-fe0f", "")
                for try_ext in (".png", ".gif", ".webp"):
                    cat = file_to_cat.get(f"{clean}{try_ext}")
                    if cat:
                        break

            if not cat:
                print(f"      [UNMAPPED] {filename}")
                unmapped += 1
                # Put unmapped files into 'Objects' as safe default
                cat = "Objects"

            dest_dir = os.path.join(pack_dir, cat)
            src = os.path.join(pack_dir, filename)
            dst = os.path.join(dest_dir, filename)

            if dry_run:
                print(f"    [DRY] {filename}  ->  {cat}/")
            else:
                os.makedirs(dest_dir, exist_ok=True)
                shutil.move(src, dst)

            moved += 1

        total_moved    += moved
        total_skipped  += skipped
        total_unmapped += unmapped
        print(f"    Moved: {moved}  |  Skipped: {skipped}  |  Unmapped->Objects: {unmapped}")

    print(f"\n{'[DRY RUN] ' if dry_run else ''}Done.  Total moved: {total_moved}")


if __name__ == "__main__":
    print("=== CapStudio Emoji Pack Reorganizer ===\n")
    print("Starting physical reorganization...\n")
    reorganize(dry_run=False)
    print("\nAll packs reorganized into category subdirectories.")
