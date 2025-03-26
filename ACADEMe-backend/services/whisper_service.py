import os
from dotenv import load_dotenv
from huggingface_hub import InferenceClient

# Load environment variables from .env file
load_dotenv()

# Initialize the InferenceClient once
client = InferenceClient(token=os.getenv("HUGGING_FACE_TOKEN"))


def transcribe_audio(audio_bytes: bytes) -> dict:
    """
    Transcribes audio using Hugging Face's Inference API with OpenAI Whisper.

    Args:
        audio_bytes (bytes): Raw audio data in FLAC, WAV, or MP3 format.

    Returns:
        dict: {
            "text": Transcribed text,
            "language": Detected language (if supported),
            "segments": List of timestamped segments (if supported)
        }
    """
    try:
        # Send audio data to the API
        response = client.automatic_speech_recognition(
            audio=audio_bytes,
            model=os.getenv("STT_MODEL")
        )

        # Extract text from response
        text = response.text

        # Attempt to get language (may not be available in all API configurations)
        language = "en"

        # Process timestamp segments
        # segments = []
        # for chunk in response.chunks:
        #     # Handle timestamp format variation
        #     timestamps = chunk.get("timestamp", [None, None])
        #     segments.append({
        #         "start": timestamps[0],
        #         "end": timestamps[1],
        #         "text": chunk.get("text", "")
        #     })

        # return {
        #     "text": text,
        #     "language": language,
        #     "segments": segments
        # }

        return {"text": text, "language": language}

    except Exception as e:
        return {"error": f"Transcription failed: {str(e)}"}
    