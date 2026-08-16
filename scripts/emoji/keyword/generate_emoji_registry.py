import json
import os
import sys
import urllib.request
import urllib.error
import re
from collections import defaultdict

# Supported Languages (17 major languages)
LANGUAGES = [
    'en', 'es', 'fr', 'de', 'it', 'pt', 'ru', 'zh', 'ja', 'ko',
    'hi', 'ar', 'tr', 'vi', 'id', 'pl', 'nl'
]

# Conceptual synonym expansions for major categories (in English)
SYNONYMS = {
    'happy': ['smile', 'joy', 'glad', 'laugh', 'giggle', 'cheerful', 'fun', 'tada', 'celebrate', 'grinning', 'pleased', 'delighted'],
    'sad': ['cry', 'blue', 'tear', 'sobbing', 'weep', 'unhappy', 'grief', 'depressed', 'mourning', 'sorrow'],
    'angry': ['mad', 'rage', 'furious', 'pissed', 'annoyed', 'scowl', 'grumpy', 'irritated'],
    'love': ['heart', 'like', 'passion', 'valentine', 'adore', 'kiss', 'hug', 'sweetheart', 'amorous'],
    'money': ['cash', 'dollar', 'euro', 'rich', 'wealth', 'pay', 'coin', 'bank', 'credit', 'bag', 'gold'],
    'car': ['vehicle', 'drive', 'auto', 'ride', 'truck', 'motorcycle', 'cab', 'taxi', 'transportation'],
    'food': ['eat', 'hungry', 'yummy', 'meal', 'delicious', 'cook', 'baking', 'restaurant', 'feed', 'snack', 'dinner'],
    'drink': ['beverage', 'cup', 'glass', 'water', 'wine', 'beer', 'juice', 'coffee', 'tea', 'bottle', 'thirsty'],
    'animal': ['pet', 'cat', 'dog', 'monkey', 'lion', 'bear', 'bird', 'fish', 'bug', 'critter', 'beast'],
    'game': ['play', 'gaming', 'video', 'board', 'fun', 'die', 'dice', 'joker', 'cards', 'controller', 'toy'],
    'tech': ['computer', 'phone', 'laptop', 'device', 'digital', 'screen', 'keyboard', 'mobile', 'cellphone', 'tablet'],
    'nature': ['tree', 'flower', 'leaf', 'plant', 'sun', 'moon', 'star', 'cloud', 'rain', 'outdoor', 'earth', 'world', 'forest'],
    'win': ['victory', 'champion', 'success', 'trophy', 'award', 'prize', 'first', 'medal', 'gold'],
}

def clean_word(word):
    """Normalize a keyword: lowercase, remove punctuation, strip."""
    word = word.lower().strip()
    # Remove standard punctuation, keeping alphanumeric
    word = re.sub(r'[^\w\s\d]', '', word)
    return word.strip()

def download_cldr_data(lang):
    """Fetch annotations.json and annotationsDerived.json for a language from Unicode CLDR GitHub repository."""
    base_url = f"https://raw.githubusercontent.com/unicode-org/cldr-json/main/cldr-json/cldr-annotations-full/annotations/{lang}"
    
    merged_annotations = {}
    
    for file_name in ["annotations.json", "annotationsDerived.json"]:
        url = f"{base_url}/{file_name}"
        print(f"  Fetching {file_name} for '{lang}'...")
        try:
            req = urllib.request.Request(
                url, 
                headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
            )
            with urllib.request.urlopen(req, timeout=5) as response:
                content = response.read().decode('utf-8')
                parsed = json.loads(content)
                
                # Extract annotations dictionary
                # Structure: { "annotations": { "annotations": { "😀": { "default": [...], "tts": [...] } } } }
                ann_dict = parsed.get("annotations", {}).get("annotations", {})
                for glyph, info in ann_dict.items():
                    if glyph not in merged_annotations:
                        merged_annotations[glyph] = {"keywords": [], "tts": ""}
                    
                    # Merge keywords
                    keywords = info.get("default", [])
                    merged_annotations[glyph]["keywords"].extend(keywords)
                    
                    # Get localized name (tts)
                    tts = info.get("tts", [])
                    if tts:
                        # tts is usually a single-element list, or a string in older formats
                        merged_annotations[glyph]["tts"] = tts[0] if isinstance(tts, list) else tts
                        
        except Exception as e:
            print(f"    Warning: Could not fetch {file_name} for '{lang}': {e}")
            
    return merged_annotations

def main():
    print("=== Starting Professional Emoji Registry Generation ===")
    
    # 1. Load local metadata.json as the master mapping list (for glyphs, unicodes, groups, styles)
    meta_path = "assets/emojis/metadata.json"
    if not os.path.exists(meta_path):
        print(f"Error: {meta_path} not found. Make sure you are running this in the CapStudio root directory.")
        sys.exit(1)
        
    with open(meta_path, "r", encoding="utf-8") as f:
        metadata_data = json.load(f)
        
    emojis = metadata_data.get("emojis", [])
    print(f"Loaded {len(emojis)} emoji mappings from {meta_path}")
    
    # 2. Download CLDR annotations for all 17 languages (with offline fallback)
    cldr_by_lang = {}
    is_offline = False
    
    print("\n--- Downloading Official Unicode CLDR Data ---")
    for lang in LANGUAGES:
        try:
            lang_data = download_cldr_data(lang)
            if lang_data:
                cldr_by_lang[lang] = lang_data
                print(f"  Successfully loaded {len(lang_data)} emojis for language '{lang}'")
            else:
                print(f"  Warning: No data returned for language '{lang}' (falling back)")
        except Exception as e:
            print(f"  Warning: Failed to fetch CLDR data for '{lang}' (offline mode): {e}")
            is_offline = True
            
    if len(cldr_by_lang) == 0:
        print("\n[!] RUNNING IN COMPLETE OFFLINE MODE [!]")
        print("    No internet connection or CLDR servers are down. Falling back to local metadata.json.")
        is_offline = True
    else:
        print(f"\nSuccessfully loaded CLDR data for {len(cldr_by_lang)}/{len(LANGUAGES)} languages.")
        
    # 3. Process emojis and build the global search index
    # kEmojiSearchIndex: Map<String, List<int>>
    search_index = defaultdict(set)
    
    # We will build a clean, official list of EmojiModels
    final_emojis = []
    
    print("\n--- Merging Data & Building Multilingual Inverted Index ---")
    for idx, e in enumerate(emojis):
        glyph = e.get("glyph", "")
        unicode_val = e.get("unicode", "")
        group = e.get("group", "Other")
        shortcodes = e.get("shortcodes", [])
        styles = e.get("styles", {})
        
        # Determine the name and base keywords
        # First, try official CLDR English
        cldr_en = cldr_by_lang.get("en", {}).get(glyph)
        
        if cldr_en:
            # Use official Unicode English name
            official_name = cldr_en["tts"].lower()
            # Use official Unicode English keywords
            base_keywords = [clean_word(k) for k in cldr_en["keywords"]]
        else:
            # Fallback to metadata.json
            official_name = e.get("name", "").lower()
            base_keywords = [clean_word(k) for k in e.get("keywords", [])]
            
        # Clean and deduplicate keywords
        base_keywords = list(filter(None, sorted(list(set(base_keywords)))))
        
        # Create the EmojiModel entry
        model = {
            "unicode": unicode_val,
            "glyph": glyph,
            "name": official_name,
            "group": group,
            "keywords": base_keywords,
            "shortcodes": shortcodes,
            "styles": styles
        }
        final_emojis.append(model)
        
        # --- Indexing Mappings ---
        # A. Index English keywords
        for kw in base_keywords:
            search_index[kw].add(idx)
            
        # B. Index English name words
        name_words = re.split(r'[\s\-,\(\)\:\/]+', official_name)
        for word in name_words:
            cleaned = clean_word(word)
            if len(cleaned) > 1:
                search_index[cleaned].add(idx)
                
        # C. Index synonyms (English)
        for category, syn_list in SYNONYMS.items():
            # If the category keyword or any of its synonyms is already in this emoji's keywords or name
            has_category = category in base_keywords or category in official_name
            if not has_category:
                for syn in syn_list:
                    if syn in base_keywords or syn in official_name:
                        has_category = True
                        break
            
            # If it belongs to this category, add all synonyms to the search index for this emoji!
            if has_category:
                for syn in syn_list:
                    search_index[syn].add(idx)
                    
        # D. Index Multilingual CLDR keywords (for all other languages)
        for lang, lang_data in cldr_by_lang.items():
            # We already handled English above, but merging it again is harmless.
            # Find the emoji in this language
            lang_entry = lang_data.get(glyph)
            if lang_entry:
                # Localized keywords
                for kw in lang_entry["keywords"]:
                    cleaned = clean_word(kw)
                    if cleaned:
                        search_index[cleaned].add(idx)
                        
                # Localized name words
                localized_name = lang_entry["tts"].lower()
                for word in re.split(r'[\s\-,\(\)\:\/]+', localized_name):
                    cleaned = clean_word(word)
                    if len(cleaned) > 1:
                        search_index[cleaned].add(idx)
                        
    # Convert search index sets to sorted lists of integers
    final_search_index = {}
    for kw, indices in sorted(search_index.items()):
        # Exclude empty or single-character words (unless they are digits like 0-9)
        if len(kw) > 1 or kw.isdigit():
            final_search_index[kw] = sorted(list(indices))
            
    print(f"Generated {len(final_emojis)} refined emojis.")
    print(f"Built multilingual index with {len(final_search_index)} unique keywords.")
    
    # 4. Generate the Dart Registry Files
    output_dir = "lib/core/emoji/data"
    os.makedirs(output_dir, exist_ok=True)
    
    # A. Write emoji_data_registry.dart
    registry_path = os.path.join(output_dir, "emoji_data_registry.dart")
    print(f"\nWriting {registry_path}...")
    
    with open(registry_path, "w", encoding="utf-8") as f_reg:
        f_reg.write("""// ignore_for_file: unnecessary_const
import '../emoji_model.dart';

/// Auto-generated compiled emoji data registry. DO NOT EDIT.
/// Total unique emojis: {count}
/// Generated directly from official Unicode CLDR data and disk files.
const List<EmojiModel> kEmojiRegistry = [
""".format(count=len(final_emojis)))
        
        for e in final_emojis:
            # Escape single quotes in strings
            name_esc = e["name"].replace("'", "\\'")
            group_esc = e["group"].replace("'", "\\'")
            
            # Styles map
            styles_str = ", ".join(f"'{k}': '{v}'" for k, v in e["styles"].items())
            
            # Keywords list (escaped and clean)
            keywords_cleaned = [k.replace("'", "\\'") for k in e["keywords"]]
            keywords_str = ", ".join(f"'{k}'" for k in keywords_cleaned)
            
            # Shortcodes list (escaped and clean)
            shortcodes_cleaned = [s.replace("'", "\\'") for s in e["shortcodes"]]
            shortcodes_str = ", ".join(f"'{s}'" for s in shortcodes_cleaned)
            
            f_reg.write("  EmojiModel(\n")
            f_reg.write("    unicode: '{0}',\n".format(e["unicode"]))
            f_reg.write("    glyph: '{0}',\n".format(e["glyph"]))
            f_reg.write("    name: '{0}',\n".format(name_esc))
            f_reg.write("    group: '{0}',\n".format(group_esc))
            f_reg.write("    keywords: const [{0}],\n".format(keywords_str))
            f_reg.write("    shortcodes: const [{0}],\n".format(shortcodes_str))
            f_reg.write("    styles: const {{{0}}},\n".format(styles_str))
            f_reg.write("  ),\n")
            
        f_reg.write("];\n")
        
    # B. Write emoji_search_index.dart
    search_index_path = os.path.join(output_dir, "emoji_search_index.dart")
    print(f"Writing {search_index_path}...")
    
    with open(search_index_path, "w", encoding="utf-8") as f_idx:
        f_idx.write("""// ignore_for_file: unnecessary_const
/// Auto-generated inverted multilingual emoji search index. DO NOT EDIT.
/// Maps lowercased keyword in 17 languages -> List of indices into kEmojiRegistry.
/// Total unique search keywords: {count}
const Map<String, List<int>> kEmojiSearchIndex = {{
""".format(count=len(final_search_index)))
        
        for kw, indices in sorted(final_search_index.items()):
            # Escape single quotes in keyword
            kw_esc = kw.replace("'", "\\'")
            f_idx.write("  '{0}': const {1},\n".format(kw_esc, indices))
            
        f_idx.write("};\n")
        
    print("\n=== Success! Emoji registry and search index successfully generated. ===")

if __name__ == '__main__':
    main()
