import os
import json
import shutil
from collections import defaultdict

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, "..", "..", ".."))
    base_dir = os.path.join(project_root, "assets", "emojis")
    base_json_path = os.path.join(base_dir, "emoji_base.json")
    
    if not os.path.exists(base_json_path):
        print(f"Error: Could not find emoji_base.json at {base_json_path}")
        return
        
    with open(base_json_path, 'r', encoding='utf-8') as f:
        emojis = json.load(f)
        
    print(f"Loaded {len(emojis)} emojis from database.")
    
    # Map Unicode and/or styles filename to Emoji Category
    # Emojis can have styles filename mappings. For example:
    # {"u":"0023-20e3","cat":"Symbols","pk":{"googleNonAnimated":"0023-20e3.png", ...}}
    
    # We will build lookups to map file names to categories
    file_to_cat = {}
    for e in emojis:
        cat = e.get("cat", "Other")
        unicode_val = e.get("u", "")
        # Standard filenames based on unicode
        file_to_cat[f"{unicode_val}.png"] = cat
        file_to_cat[f"{unicode_val}.gif"] = cat
        file_to_cat[f"{unicode_val}.webp"] = cat
        
        # Styles-specific filenames
        for pack_id, filename in e.get("pk", {}).items():
            # basename in lowercase
            clean_fn = os.path.basename(filename).lower()
            file_to_cat[clean_fn] = cat
            
    # Packs configuration
    packs = {
        'googleAnimated': {
            'dir': os.path.join(base_dir, 'google_noto_emojis_animated_pack', '512x512'),
            'ext': '.gif'
        },
        'googleNonAnimated': {
            'dir': os.path.join(base_dir, 'google_noto_emojis_non_animated_pack', '512x512'),
            'ext': '.png'
        },
        'microsoftAnimated': {
            'dir': os.path.join(base_dir, 'microsoft_fluentui_emoji_animated_pack', '256x256'),
            'ext': '.png'
        },
        'microsoftNonAnimated': {
            'dir': os.path.join(base_dir, 'microsoft_fluentui_emoji_non_animated_pack', '256x256'),
            'ext': '.png'
        },
        'openmoji': {
            'dir': os.path.join(base_dir, 'openmoji_non_animated_pack', '618x618'),
            'ext': '.png'
        }
    }
    
    print("\n--- Simulating Categorization ---")
    
    for pack_id, info in packs.items():
        pack_dir = info['dir']
        if not os.path.exists(pack_dir):
            print(f"Directory not found for pack {pack_id}: {pack_dir}")
            continue
            
        print(f"\nProcessing Pack: {pack_id}")
        files = [f for f in os.listdir(pack_dir) if os.path.isfile(os.path.join(pack_dir, f))]
        print(f"  Found {len(files)} files in flat folder.")
        
        cat_counts = defaultdict(int)
        unmapped = []
        
        for f in files:
            if f.lower() == 'license.md' or f.lower() == 'readme.md':
                continue
                
            clean_f = f.lower()
            cat = file_to_cat.get(clean_f)
            
            # Fallback checks: try unicode strip, remove -fe0f, etc.
            if not cat:
                name_without_ext = os.path.splitext(clean_f)[0]
                cat = file_to_cat.get(f"{name_without_ext}.png") or file_to_cat.get(f"{name_without_ext}.gif")
                if not cat and name_without_ext.endswith('-fe0f'):
                    clean_name = name_without_ext.replace('-fe0f', '')
                    cat = file_to_cat.get(f"{clean_name}.png") or file_to_cat.get(f"{clean_name}.gif")
                    
            if cat:
                cat_counts[cat] += 1
            else:
                unmapped.append(f)
                
        print("  Categorization distribution:")
        for cat, count in sorted(cat_counts.items()):
            print(f"    - {cat}: {count} files")
        print(f"  Unmapped files: {len(unmapped)}")
        if unmapped[:5]:
            print(f"    Examples: {unmapped[:5]}")
            
def run_physical_reorganization(dry_run=True):
    # This is a helper function to perform actual move operations
    base_dir = r"A:\Projects\Local AI Caption Studio\CapStudio\assets\emojis"
    base_json_path = os.path.join(base_dir, "emoji_base.json")
    
    with open(base_json_path, 'r', encoding='utf-8') as f:
        emojis = json.load(f)
        
    file_to_cat = {}
    for e in emojis:
        cat = e.get("cat", "Other")
        unicode_val = e.get("u", "")
        file_to_cat[f"{unicode_val}.png"] = cat
        file_to_cat[f"{unicode_val}.gif"] = cat
        file_to_cat[f"{unicode_val}.webp"] = cat
        for pack_id, filename in e.get("pk", {}).items():
            clean_fn = os.path.basename(filename).lower()
            file_to_cat[clean_fn] = cat
            
    packs = {
        'googleAnimated': os.path.join(base_dir, 'google_noto_emojis_animated_pack', '512x512'),
        'googleNonAnimated': os.path.join(base_dir, 'google_noto_emojis_non_animated_pack', '512x512'),
        'microsoftAnimated': os.path.join(base_dir, 'microsoft_fluentui_emoji_animated_pack', '256x256'),
        'microsoftNonAnimated': os.path.join(base_dir, 'microsoft_fluentui_emoji_non_animated_pack', '256x256'),
        'openmoji': os.path.join(base_dir, 'openmoji_non_animated_pack', '618x618')
    }
    
    for pack_id, pack_dir in packs.items():
        if not os.path.exists(pack_dir):
            continue
            
        files = [f for f in os.listdir(pack_dir) if os.path.isfile(os.path.join(pack_dir, f))]
        
        for f in files:
            if f.lower() in ('license.md', 'readme.md'):
                continue
                
            clean_f = f.lower()
            cat = file_to_cat.get(clean_f)
            
            if not cat:
                name_without_ext = os.path.splitext(clean_f)[0]
                cat = file_to_cat.get(f"{name_without_ext}.png") or file_to_cat.get(f"{name_without_ext}.gif")
                if not cat and name_without_ext.endswith('-fe0f'):
                    clean_name = name_without_ext.replace('-fe0f', '')
                    cat = file_to_cat.get(f"{clean_name}.png") or file_to_cat.get(f"{clean_name}.gif")
            
            if not cat:
                cat = "Other"
                
            cat_dir = os.path.join(pack_dir, cat)
            if not dry_run:
                os.makedirs(cat_dir, exist_ok=True)
                src = os.path.join(pack_dir, f)
                dst = os.path.join(cat_dir, f)
                shutil.move(src, dst)
                
    if dry_run:
        print("\n[Dry Run] Reorganization simulation complete. No files moved.")
    else:
        print("\nReorganization complete! Files successfully moved to category subdirectories.")

if __name__ == "__main__":
    main()
