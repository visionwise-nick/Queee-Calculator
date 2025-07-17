#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os

# 全球前30种语言列表
LANGUAGES = {
    "en": "English",
    "zh": "中文",
    "es": "Español",
    "fr": "Français", 
    "de": "Deutsch",
    "ja": "日本語",
    "ko": "한국어",
    "pt": "Português",
    "it": "Italiano",
    "ru": "Русский",
    "ar": "العربية",
    "hi": "हिन्दी",
    "tr": "Türkçe",
    "th": "ไทย",
    "vi": "Tiếng Việt",
    "pl": "Polski",
    "nl": "Nederlands",
    "sv": "Svenska",
    "da": "Dansk",
    "no": "Norsk",
    "fi": "Suomi",
    "cs": "Čeština",
    "hu": "Magyar",
    "ro": "Română",
    "bg": "Български",
    "hr": "Hrvatski",
    "sk": "Slovenčina",
    "sl": "Slovenščina",
    "et": "Eesti",
    "lv": "Latviešu"
}

def load_template():
    """加载英文模板"""
    with open('i18n/en.json', 'r', encoding='utf-8') as f:
        return json.load(f)

def create_placeholder_translation(template, lang_code):
    """创建占位翻译文件"""
    translation = {}
    
    def translate_value(value, path=""):
        if isinstance(value, dict):
            result = {}
            for k, v in value.items():
                new_path = f"{path}.{k}" if path else k
                result[k] = translate_value(v, new_path)
            return result
        elif isinstance(value, str):
            # 为占位符添加语言标识
            return f"[{lang_code.upper()}] {value}"
        else:
            return value
    
    return translate_value(template)

def main():
    """生成所有语言的本地化文件"""
    print("🌍 开始生成多语言文件...")
    
    # 加载英文模板
    template = load_template()
    
    # 确保i18n目录存在
    os.makedirs('i18n', exist_ok=True)
    
    # 生成每种语言的翻译文件
    for lang_code, lang_name in LANGUAGES.items():
        if lang_code == 'en':
            continue  # 跳过英文，因为已经有模板
            
        filename = f'i18n/{lang_code}.json'
        
        if lang_code == 'zh':
            # 中文已经有翻译，跳过
            print(f"✅ {lang_name} ({lang_code}) - 已存在")
            continue
            
        # 创建占位翻译
        translation = create_placeholder_translation(template, lang_code)
        
        # 保存文件
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(translation, f, ensure_ascii=False, indent=2)
        
        print(f"📝 {lang_name} ({lang_code}) - 已生成")
    
    print(f"✅ 已生成 {len(LANGUAGES)-2} 种语言的本地化文件")
    print("📁 文件保存在 backend/i18n/ 目录中")
    print("💡 请手动翻译这些文件中的占位符文本")

if __name__ == "__main__":
    main() 