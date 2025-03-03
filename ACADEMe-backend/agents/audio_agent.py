from services.whisper_service import transcribe_audio
from services.gemini_service import process_text_with_gemini
from utils.language_detection import detect_language
from services.libretranslate_service import translate_text
import mimetypes

SUPPORTED_AUDIO_FORMATS = {
    "audio/mpeg",
    "audio/wav",
    "audio/x-wav",
    "audio/flac",
    "audio/ogg",
    "audio/webm"
}

async def process_audio(file, prompt: str = None):
    """
    Processes an uploaded audio file:
    - Reads the file
    - Transcribes the audio
    - Detects language & translates if needed
    - Sends transcription (and optional user prompt) to Gemini
    """
    
    print(f"🔍 Received prompt: '{prompt}'")  # Debugging

    if not prompt:
        print("⚠️ Warning: No prompt received!")  # Debugging

    try:
        filename = file.filename  # Get filename
        mime_type, _ = mimetypes.guess_type(filename)  # Get MIME type

        if mime_type not in SUPPORTED_AUDIO_FORMATS:
            return {"error": f"Unsupported file format: {mime_type or 'unknown'}. Supported formats: MP3, WAV, FLAC, OGG, WEBM."}

        print(f"✅ File format detected: {mime_type}")  # Debugging Log
        
        # 🔹 Step 1: Read the audio file as bytes
        audio_content = await file.read()

        # 🔹 Step 2: Transcribe the audio
        transcription_result = transcribe_audio(audio_content)

        # Debugging: Print transcription result
        print("DEBUG: Transcription Result =", transcription_result)

        if "error" in transcription_result or not transcription_result["text"]:
            return {"error": "Transcription failed or returned empty text."}

        transcribed_text = transcription_result["text"]
        print(f"✅ Transcription received: {transcribed_text[:100]}...")  # Debugging Log

        # 🔹 Step 3: Detect language of transcription
        detected_lang = detect_language(transcribed_text)
        print(f"🌍 Detected Transcription Language: {detected_lang}")  # Debugging Log

        # 🔹 Step 4: Translate transcription if needed
        if detected_lang.lower() != "en":
            print("🔄 Translating transcription to English...")  # Debugging Log
            transcribed_text = translate_text(transcribed_text, detected_lang, "en")

        # 🔹 Step 5: Translate prompt (if given)
        if prompt and prompt.strip():
            prompt_lang = detect_language(prompt)
            print(f"🌍 Detected Prompt Language: {prompt_lang}")  # Debugging Log
            
            if prompt_lang.lower() != "en":
                print("🔄 Translating prompt to English...")  # Debugging Log
                prompt = translate_text(prompt, prompt_lang, "en")

        # 🔹 Step 6: Create Final Prompt for Gemini
        if prompt and prompt.strip():
            final_prompt = f"""
            You are analyzing a transcribed audio file.

            **Task:**
            - Follow the user’s request **strictly**.
            - Do **NOT** add any extra information.
            - Keep responses **concise and relevant**.

            **User Request:** {prompt}

            **Transcription (translated to English):**
            {transcribed_text}

            Respond **only** based on the transcription and user request.
            """
        else:
            final_prompt = f"""
            The following is a transcription of an audio file. Extract and summarize the most relevant details.

            **Transcription (translated to English):**
            {transcribed_text}

            Keep your response concise.
            """

        print(f"✅ Final Prompt Sent to Gemini:\n{final_prompt[:200]}...\n")  # Debugging Log

        # 🔹 Step 7: Send to Gemini
        response = await process_text_with_gemini(final_prompt)  # ✅ Await for async call

        return {"response": response}

    except Exception as e:
        error_message = f"❌ Error processing audio: {str(e)}"
        print(error_message)
        return {"error": str(e)}
