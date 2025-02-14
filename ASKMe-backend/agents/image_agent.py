import io
import os
import tempfile
import requests
from config import LIBRETRANSLATE_URL
from services.gemini_service import get_gemini_response

# Supported image formats (MIME types)
SUPPORTED_IMAGE_FORMATS = ["image/jpeg", "image/png", "image/gif"]

# Function to fetch all supported languages from LibreTranslate
def get_supported_languages():
    try:
        response = requests.get(f"{LIBRETRANSLATE_URL}/languages")
        response.raise_for_status()
        return [lang["code"] for lang in response.json()]
    except requests.exceptions.RequestException:
        return ["en", "es", "fr", "de", "hi", "bn", "zh", "ar", "ru", "pt"]  # Fallback list

SUPPORTED_LANGUAGES = get_supported_languages()

def detect_language(text: str) -> str:
    """
    Detects the language of a given text using LibreTranslate.
    """
    data = {"q": text}
    headers = {"Content-Type": "application/json"}

    try:
        response = requests.post(f"{LIBRETRANSLATE_URL}/detect", json=data, headers=headers)
        response.raise_for_status()
        detected_lang = response.json()[0]["language"]
        return detected_lang
    except requests.exceptions.RequestException:
        return "en"  # Default to English if detection fails

def translate_text(text: str, source_lang: str, target_lang: str) -> str:
    """
    Translates text using LibreTranslate.

    Args:
        text (str): The text to translate.
        source_lang (str): The source language code.
        target_lang (str): The target language code.

    Returns:
        str: Translated text or error message.
    """
    if source_lang not in SUPPORTED_LANGUAGES and source_lang != "auto":
        return f"Error: Unsupported source language '{source_lang}'."
    if target_lang not in SUPPORTED_LANGUAGES:
        return f"Error: Unsupported target language '{target_lang}'."

    data = {"q": text, "source": source_lang, "target": target_lang, "format": "text"}
    headers = {"Content-Type": "application/json"}

    try:
        response = requests.post(f"{LIBRETRANSLATE_URL}/translate", json=data, headers=headers)
        response.raise_for_status()
        return response.json().get("translatedText", text)
    except requests.exceptions.RequestException as e:
        return f"Translation service error: {e}"

def detect_image_format(image_data: bytes) -> str:
    """
    Detects the format of an image from its bytes.

    Args:
        image_data (bytes): Raw image data.

    Returns:
        str: Detected MIME type or "unsupported".
    """
    header = image_data[:8]

    if header[:3] == b"\xff\xd8\xff":
        return "image/jpeg"
    elif header[:8] == b"\x89PNG\r\n\x1a\n":
        return "image/png"
    elif header[:6] in [b"GIF87a", b"GIF89a"]:
        return "image/gif"
    else:
        return "unsupported"

async def process_image(image_data: bytes, prompt: str, source_lang: str = "auto", target_lang: str = "en") -> dict:
    try:
        # Validate image format
        image_format = detect_image_format(image_data)
        if image_format == "unsupported":
            return {"error": f"Unsupported image format. Please use: {', '.join(SUPPORTED_IMAGE_FORMATS)}"}

        # Check if the source language is valid
        if source_lang != "auto" and source_lang not in SUPPORTED_LANGUAGES:
            return {"error": f"Unsupported source language '{source_lang}'. Supported: {', '.join(SUPPORTED_LANGUAGES)}"}

        # Detect language if source_lang is "auto"
        if source_lang == "auto":
            source_lang = detect_language(prompt)  # Detect language

        # Translate prompt if needed
        translated_prompt = prompt
        if source_lang != target_lang:
            translated_prompt = translate_text(prompt, source_lang, target_lang)

        # Save image to a temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as temp_image:
            temp_image.write(image_data)
            temp_image_path = temp_image.name

        # Send image to Gemini
        response = get_gemini_response(prompt=translated_prompt, image_path=temp_image_path)

        print(f"🔹 Gemini RAW Response: {response}")

        # Clean up temporary image file
        os.remove(temp_image_path)

        # Translate Gemini's response if needed
        if target_lang != "en":
            detected_lang = "hi"  # Default assumption (since Gemini responded in Hindi)
            
            # Try detecting the response language dynamically
            if source_lang == "auto":
                detected_lang = detect_language(response)  # You need a function for this!

            translated_response = translate_text(response, detected_lang, target_lang)  # Use detected language
            if "Error" not in translated_response:
                response = translated_response
            else:
                print(f"🔸 Translation Error: {translated_response}")  # Debugging Log

        return {"response": response}

    except Exception as e:
        return {"error": str(e)}
