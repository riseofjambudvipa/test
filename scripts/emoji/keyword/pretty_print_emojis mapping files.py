import os
import json

base_dir = "A:/Projects/Local AI Caption Studio/CapStudio/assets/emojis"
emoji_base_path = os.path.join(base_dir, "emoji_base.json")
langs_dir = os.path.join(base_dir, "langs")

print("=== Starting Pretty Printing of Emoji JSON Files ===")

# 1. Pretty print emoji_base.json
if os.path.exists(emoji_base_path):
    print(f"Pretty printing {emoji_base_path}...")
    try:
        with open(emoji_base_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        with open(emoji_base_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print("Successfully pretty printed emoji_base.json")
    except Exception as e:
        print(f"Error pretty printing emoji_base.json: {e}")
else:
    print(f"File not found: {emoji_base_path}")

# 2. Pretty print files in langs/
if os.path.exists(langs_dir):
    print(f"Walking through {langs_dir}...")
    files = [f for f in os.listdir(langs_dir) if f.endswith(".json")]
    print(f"Found {len(files)} JSON files in langs/ directory.")
    
    for i, file_name in enumerate(files):
        file_path = os.path.join(langs_dir, file_name)
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            with open(file_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            if (i + 1) % 10 == 0 or i + 1 == len(files):
                print(f"[{i+1}/{len(files)}] Pretty printed {file_name}")
        except Exception as e:
            print(f"Error pretty printing {file_name}: {e}")
            
    print("Successfully completed pretty printing langs/ folder!")
else:
    print(f"Directory not found: {langs_dir}")

print("=== Done ===")
