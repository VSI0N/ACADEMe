from services.libretranslate_service import translate_text
from services.gemini_service import get_gemini_response
from utils.language_detection import detect_language

async def process_text(text: str, target_language: str) -> str:
    source_lang = detect_language(text)
    english_text = translate_text(text, source_lang, target_language)
    response = get_gemini_response(english_text)
    # final_response = translate_text(response, "en", target_language)
    return response
