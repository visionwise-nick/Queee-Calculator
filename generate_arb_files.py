import os
import json

# List of top 30 languages with their ISO 639-1 codes and English names
languages = {
    "en": "English",
    "zh": "Chinese",
    "hi": "Hindi",
    "es": "Spanish",
    "fr": "French",
    "ar": "Arabic",
    "bn": "Bengali",
    "ru": "Russian",
    "pt": "Portuguese",
    "ur": "Urdu",
    "id": "Indonesian",
    "de": "German",
    "ja": "Japanese",
    "pa": "Punjabi",
    "tr": "Turkish",
    "ko": "Korean",
    "vi": "Vietnamese",
    "it": "Italian",
    "fa": "Persian",
    "pl": "Polish",
    "uk": "Ukrainian",
    "ro": "Romanian",
    "nl": "Dutch",
    "el": "Greek",
    "hu": "Hungarian",
    "sv": "Swedish",
    "cs": "Czech",
    "fi": "Finnish",
    "th": "Thai",
    "ha": "Hausa",
}

# The directory where the .arb files will be stored
l10n_dir = "lib/l10n"

# The base content for the .arb files
base_content = {
  "history": "History",
  "multiParamHelp": "Multi-parameter Function Help",
  "aiDesigner": "AI Designer",
  "imageWorkshop": "Image Generation Workshop"
}

# Create the directory if it doesn't exist
os.makedirs(l10n_dir, exist_ok=True)

# Generate the .arb files
for code, name in languages.items():
    file_path = os.path.join(l10n_dir, f"app_{code}.arb")
    content = base_content.copy()
    content["appTitle"] = f"Queee Calculator ({name})" # Placeholder translation
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(content, f, ensure_ascii=False, indent=2)

    print(f"Created {file_path}")

print("\nSuccessfully generated .arb files for 30 languages.") 