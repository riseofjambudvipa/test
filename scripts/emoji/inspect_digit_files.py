# -*- coding: utf-8 -*-
"""
Inspect what the 10 unknown digit files (0030-0039) are
and find what category they should belong to.
"""
import json, os, shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", "..", ".."))
BASE_DIR = os.path.join(PROJECT_ROOT, "assets", "emojis")
BASE_JSON = os.path.join(BASE_DIR, "emoji_base.json")
OBJECTS_DIR = os.path.join(BASE_DIR, "google_noto_emojis_non_animated_pack", "512x512", "Objects")
SYMBOLS_DIR = os.path.join(BASE_DIR, "google_noto_emojis_non_animated_pack", "512x512", "Symbols")

with open(BASE_JSON, "r", encoding="utf-8") as f:
    emojis = json.load(f)

print("=== DB entries whose unicode starts with 003x (digits 0-9) ===")
for e in emojis:
    u = e.get("u", "")
    if u.startswith("003"):
        print(f"  unicode={u}  cat={e.get('cat')}  name={e.get('n','')}")

print()
print("=== Unicode explanation of 0030-0039 ===")
for code in range(0x0030, 0x003A):
    char = chr(code)
    print(f"  U+{code:04X}  ->  '{char}'  (plain ASCII digit {char})")

print()
print("=== Keycap emoji in DB that use these digits ===")
for e in emojis:
    u = e.get("u", "")
    # Keycap emojis look like: 0030-fe0f-20e3
    if "-fe0f-20e3" in u or "-20e3" in u:
        print(f"  unicode={u}  cat={e.get('cat')}  name={e.get('n','')}")

print()
print("=== Files currently in Objects/ that are the unknowns ===")
if os.path.isdir(OBJECTS_DIR):
    for f in sorted(os.listdir(OBJECTS_DIR)):
        if f.startswith("003"):
            print(f"  {f}")
