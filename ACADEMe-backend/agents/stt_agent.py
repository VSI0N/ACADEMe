from fastapi import UploadFile
from services.whisper_service import transcribe_audio
import mimetypes

# Supported audio formats
SUPPORTED_AUDIO_FORMATS = {
    "audio/mpeg",
    "audio/wav",
    "audio/x-wav",
    "audio/flac",
    "audio/ogg",
    "audio/webm"
}

async def process_stt(file: UploadFile):
    """
    Processes an uploaded audio file:
    - Reads the file
    - Transcribes the audio using Whisper
    - Returns transcribed text and detected language
    """

    try:
        filename = file.filename  # Get filename
        mime_type, _ = mimetypes.guess_type(filename)  # Get MIME type

        # ✅ Validate audio format
        if mime_type not in SUPPORTED_AUDIO_FORMATS:
            return {"error": f"Unsupported file format: {mime_type or 'unknown'}. Supported formats: MP3, WAV, FLAC, OGG, WEBM."}

        print(f"✅ File format detected: {mime_type}")  # Debugging Log
        
        # 🔹 Read the audio file as bytes
        audio_content = await file.read()

        # 🔹 Transcribe the audio
        transcription_result = transcribe_audio(audio_content)

        # Debugging: Print transcription result
        print("DEBUG: Transcription Result =", transcription_result)

        # 🔹 Validate transcription output
        if "error" in transcription_result or not transcription_result["text"]:
            return {"error": "Transcription failed or returned empty text."}

        # ✅ Return transcribed text and detected language
        return {
            "text": transcription_result["text"],
            "language": transcription_result["language"]
        }

    except Exception as e:
        error_message = f"❌ Error processing audio: {str(e)}"
        print(error_message)
        return {"error": str(e)}
