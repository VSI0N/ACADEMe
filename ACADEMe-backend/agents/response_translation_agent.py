from services.libretranslate_service import translate_text
from utils.language_detection import detect_language

def translate_response(response_text: str, target_language: str) -> str:
    return translate_text(response_text, "en", target_language)

def translate_response_all(response_text: str, target_language: str) -> str:
    """For responses where source language is unknown"""
    # Detect source language
    source_lang = detect_language(response_text)
    
    # First translate to English if not already
    if source_lang != "en":
        response_text = translate_text(response_text, source_lang, "en")
    
    # Then translate to target language if needed
    if target_language.lower() != "en":
        response_text = translate_text(response_text, "en", target_language)
    
    return response_text