import json
import os
import re

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, "..", "..", ".."))
    output_dir = os.path.join(project_root, "assets", "emojis")
    metadata_path = os.path.join(output_dir, "metadata.json")
    data_dir = os.path.join(output_dir, "data")

    # Ensure output directories exist
    os.makedirs(data_dir, exist_ok=True)

    if not os.path.exists(metadata_path):
        print(f"Error: {metadata_path} not found.")
        return

    print(f"Loading {metadata_path}...")
    with open(metadata_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    emojis = data.get('emojis', [])
    print(f"Loaded {len(emojis)} emojis. Splitting...")

    # 1. index.json
    index_emojis = []
    for e in emojis:
        index_emojis.append({
            'unicode': e['unicode'],
            'glyph': e['glyph'],
            'name': e['name'],
            'group': e['group']
        })

    index_data = {
        'version': data.get('version', '2.0'),
        'emojis': index_emojis
    }

    index_path = os.path.join(output_dir, "index.json")
    with open(index_path, "w", encoding="utf-8") as f:
        json.dump(index_data, f, separators=(',', ':'))
    print(f"Generated {index_path} ({os.path.getsize(index_path) / 1024:.2f} KB)")

    # 2. search_index.json
    # Map keyword -> list of unicodes
    search_index = {}
    for e in emojis:
        unicode_val = e['unicode']
        for kw in e.get('keywords', []):
            kw_clean = kw.lower().strip()
            if kw_clean:
                search_index.setdefault(kw_clean, []).append(unicode_val)
        
        # Split name words too
        name_words = re.split(r'[\s\-,\(\)\:\/]+', e['name'].lower())
        for word in name_words:
            word_clean = word.strip()
            if len(word_clean) > 1:
                search_index.setdefault(word_clean, []).append(unicode_val)

    # Deduplicate lists
    for kw in search_index:
        search_index[kw] = list(set(search_index[kw]))

    search_index_path = os.path.join(output_dir, "search_index.json")
    with open(search_index_path, "w", encoding="utf-8") as f:
        json.dump(search_index, f, separators=(',', ':'))
    print(f"Generated {search_index_path} ({os.path.getsize(search_index_path) / 1024:.2f} KB)")

    # 3. Individual files in data/{unicode}.json
    print("Writing individual emoji detail JSONs...")
    for e in emojis:
        unicode_val = e['unicode']
        detail_path = os.path.join(data_dir, f"{unicode_val}.json")
        with open(detail_path, "w", encoding="utf-8") as f:
            json.dump(e, f, separators=(',', ':'))
            
    print("Redesign files generated successfully.")

if __name__ == "__main__":
    main()
