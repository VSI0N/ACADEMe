import whisper
import tempfile
import os

# Load the Whisper model once to optimize performance
model = whisper.load_model("base")


def transcribe_audio(audio_bytes: bytes) -> dict:
    """
    Transcribes an audio file using OpenAI Whisper.

    Args:
        audio_bytes (bytes): Raw audio data.

    Returns:
        dict: {
            "text": Transcribed text,
            "language": Detected language,
            "segments": List of timestamped segments
        }
    """

    # Save the audio to a temporary file
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_audio:
        temp_audio.write(audio_bytes)
        temp_audio_path = temp_audio.name

    try:
        # Transcribe the audio
        result = model.transcribe(temp_audio_path)
        return {
            "text": result.get("text", ""),
            "language": result.get("language", ""),
            "segments": result.get("segments", []),
        }
    except Exception as e:
        return {"error": f"Transcription failed: {str(e)}"}
    finally:
        # Remove the temporary file after processing
        os.remove(temp_audio_path)
