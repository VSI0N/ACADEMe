from services.libretranslate_service import translate_text

def translate_response(response_text: str, target_language: str) -> str:
    return translate_text(response_text, "en", target_language)
