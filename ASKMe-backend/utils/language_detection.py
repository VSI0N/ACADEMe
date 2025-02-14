from langdetect import detect

def detect_language(text: str) -> str:
    return detect(text)
