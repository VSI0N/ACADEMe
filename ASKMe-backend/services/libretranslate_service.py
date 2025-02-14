import requests
from config import LIBRETRANSLATE_URL

def translate_text(text: str, source_lang: str, target_lang: str) -> str:
    data = {"q": text, "source": source_lang, "target": target_lang, "format": "text"}
    headers = {"Content-Type": "application/json"}

    try:
        response = requests.post(f"{LIBRETRANSLATE_URL}/translate", json=data, headers=headers)

        print("Response Status:", response.status_code)
        print("Response JSON:", response.json())

        if response.status_code != 200:
            raise Exception(f"Translation error: {response.text}")

        return response.json().get("translatedText", text)

    except requests.exceptions.RequestException as e:
        raise Exception(f"Translation service error: {e}")

