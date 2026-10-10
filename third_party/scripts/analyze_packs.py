import json
import os
from collections import defaultdict

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    base = os.path.join(project_root, "assets", "emojis")
    meta_path = os.path.join(base, "metadata.json")
    
    with open(meta_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    emojis = data['emojis']
    packs_info = data.get('packs', [])
    
    pack_ids = ['googleAnimated', 'googleNonAnimated', 'microsoftAnimated', 'microsoftNonAnimated', 'openmoji']
    
    # 1. Count files per pack
    pack_counts = defaultdict(int)
    total_files = 0
    for e in emojis:
        for pid in e.get('styles', {}):
            pack_counts[pid] += 1
            total_files += 1
    
    print("=== PACK COVERAGE ===")
    for pid in pack_ids:
        print(f"  {pid}: {pack_counts[pid]} emojis")
    print(f"  Total file references: {total_files}")
    print(f"  Unique emojis: {len(emojis)}")
    
    # 2. How many packs each emoji is in
    print("\n=== EMOJIS BY NUMBER OF PACKS ===")
    by_count = defaultdict(int)
    for e in emojis:
        n = len(e.get('styles', {}))
        by_count[n] += 1
    for n in sorted(by_count):
        print(f"  In {n} packs: {by_count[n]} emojis")
    
    # 3. Groups
    print("\n=== GROUPS ===")
    groups = defaultdict(int)
    for e in emojis:
        groups[e['group']] += 1
    for g, c in sorted(groups.items(), key=lambda x: -x[1]):
        print(f"  {g}: {c}")
    
    # 4. Keyword statistics
    print("\n=== KEYWORD STATS ===")
    kw_counts = [len(e.get('keywords', [])) for e in emojis]
    print(f"  Min keywords: {min(kw_counts)}")
    print(f"  Max keywords: {max(kw_counts)}")
    print(f"  Avg keywords: {sum(kw_counts)/len(kw_counts):.1f}")
    no_kw = sum(1 for c in kw_counts if c == 0)
    few_kw = sum(1 for c in kw_counts if 0 < c <= 3)
    print(f"  Emojis with 0 keywords: {no_kw}")
    print(f"  Emojis with 1-3 keywords: {few_kw}")
    
    # 5. Find emojis ONLY in specific packs (unique to one pack)
    print("\n=== PACK-EXCLUSIVE EMOJIS ===")
    for pid in pack_ids:
        exclusive = [e for e in emojis if list(e.get('styles', {}).keys()) == [pid]]
        print(f"  Only in {pid}: {len(exclusive)}")
        if exclusive[:3]:
            for ex in exclusive[:3]:
                print(f"    - {ex['glyph']} {ex['name']} ({ex['unicode']})")
    
    # 6. Scan actual pack directories for files NOT in metadata
    print("\n=== ACTUAL PACK DIRECTORY SCAN ===")
    pack_dirs = {
        'googleAnimated': os.path.join(base, 'google_noto_emojis_animated_pack'),
        'googleNonAnimated': os.path.join(base, 'google_noto_emojis_non_animated_pack'),
        'microsoftAnimated': os.path.join(base, 'microsoft_fluentui_emoji_animated_pack'),
        'microsoftNonAnimated': os.path.join(base, 'microsoft_fluentui_emoji_non_animated_pack'),
        'openmoji': os.path.join(base, 'openmoji_non_animated_pack'),
    }
    
    for pid, dir_path in pack_dirs.items():
        if os.path.exists(dir_path):
            all_files = []
            for root, dirs, files in os.walk(dir_path):
                for f in files:
                    if f.lower().endswith(('.png', '.webp', '.gif', '.jpg', '.jpeg')):
                        all_files.append(f)
            
            # Files in metadata for this pack
            meta_files = set()
            for e in emojis:
                fn = e.get('styles', {}).get(pid)
                if fn:
                    meta_files.add(fn.lower())
            
            disk_files = set(f.lower() for f in all_files)
            on_disk_only = disk_files - meta_files
            in_meta_only = meta_files - disk_files
            
            print(f"\n  {pid}:")
            print(f"    On disk: {len(disk_files)} image files")
            print(f"    In metadata: {len(meta_files)} entries")
            print(f"    On disk but NOT in metadata: {len(on_disk_only)}")
            print(f"    In metadata but NOT on disk: {len(in_meta_only)}")
            if on_disk_only and len(on_disk_only) <= 5:
                for f in sorted(on_disk_only)[:5]:
                    print(f"      MISSING from metadata: {f}")
        else:
            print(f"  {pid}: directory not found at {dir_path}")
    
    # 7. Filename pattern analysis
    print("\n=== FILENAME PATTERNS ===")
    for pid in pack_ids:
        filenames = [e['styles'][pid] for e in emojis if pid in e.get('styles', {})]
        if not filenames:
            continue
        exts = defaultdict(int)
        for f in filenames:
            ext = os.path.splitext(f)[1].lower()
            exts[ext] += 1
        naming = 'unicode' if filenames[0].startswith(('1f', '0', '2', 'e')) else 'descriptive'
        # Check for emoji_u prefix
        prefixed = sum(1 for f in filenames if f.startswith('emoji_u'))
        print(f"  {pid}: {', '.join(f'{e}={c}' for e,c in sorted(exts.items()))}, naming={naming}, emoji_u_prefix={prefixed}")

if __name__ == '__main__':
    main()
