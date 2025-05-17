import os
import requests

def detect_language(text: str) -> str:
    # Check for empty input
    if not text.strip():
        raise ValueError("Input text cannot be empty.")
    
    # Get LibreTranslate URL from environment variables
    libretranslate_url = os.getenv("LIBRETRANSLATE_URL")
    if not libretranslate_url:
        raise RuntimeError("LIBRETRANSLATE_URL is not set in environment variables.")
    
    # Prepare API endpoint and request data
    endpoint = f"{libretranslate_url}/detect"
    payload = {"q": text}
    
    try:
        # Send request to LibreTranslate
        response = requests.post(endpoint, data=payload)
        response.raise_for_status()  # Raise HTTP errors
        
        # Parse response
        detections = response.json()
        if not detections:
            raise ValueError("No languages detected.")
        
        # Return highest confidence language code
        return detections[0]["language"]
    
    except requests.exceptions.RequestException as e:
        raise RuntimeError(f"Language detection request failed: {str(e)}")