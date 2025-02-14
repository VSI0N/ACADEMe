from fastapi import FastAPI, File, UploadFile, Form
from agents.text_agent import process_text
from agents.response_translation_agent import translate_response
from agents.document_agent import process_document
from agents.image_agent import process_image
from agents.audio_agent import process_audio
from agents.video_agent import process_video
from agents.stt_agent import process_stt

app = FastAPI()

def process_and_translate(response, target_language):
    # Ensure that errors are not processed further
    if isinstance(response, dict) and "error" in response:
        return response  # Return the error directly
    """
    If target_language is not English, translate the response.
    Otherwise, return the original response.
    """
    if target_language.lower() != "en":
        response = translate_response(response, target_language)
    return response

@app.post("/api/process_text")
async def process_text_api(
        text: str = Form(...),
        target_language: str = Form("en")
):
    response = await process_text(text, "en")
    return {"response": process_and_translate(response, target_language)}

@app.post("/api/process_stt")
async def process_stt_api(file: UploadFile = File(...)):
    response = await process_stt(file)

    # ✅ Ensure errors are returned properly
    if isinstance(response, dict) and "error" in response:
        return {"error": response["error"]}

    return response

@app.post("/api/translate_response")
async def translate_response_api(text: str, target_language: str):
    response = translate_response(text, target_language)
    return {"response": response}

@app.post("/api/process_document")
async def process_document_api(
        file: UploadFile = File(...),
        prompt: str = Form(None),
        target_language: str = Form("en")
):
    response = await process_document(file, prompt)

    print(f"🔍 Debug: Response from process_document -> {response}")  # Debugging Log

    # ✅ If response contains an error, return it directly
    if isinstance(response, dict) and "error" in response:
        return {"error": response["error"]}

    if "response" not in response:
        return {"error": "Unexpected response format from document processor."}

    translated_response = process_and_translate(response["response"], target_language)

    return {"response": translated_response}

@app.post("/api/process_image")
async def process_image_endpoint(
        image: UploadFile = File(...),
        prompt: str = Form("Describe this image"),
        source_lang: str = Form("auto"),
        target_lang: str = Form("en")
):
    """
    API endpoint to process images with optional multilingual prompts.
    """
    image_data = await image.read()
    response = await process_image(image_data, prompt, source_lang, target_lang)
    return response

@app.post("/api/process_audio")
async def process_audio_api(
        file: UploadFile = File(...),
        prompt: str = Form(None),
        target_language: str = Form("en")
):
    response = await process_audio(file, prompt)

    # ✅ Ensure errors are returned properly
    if isinstance(response, dict) and "error" in response:
        return {"error": response["error"]}

    if "response" not in response:
        return {"error": "Unexpected response format from AI."}

    return {"response": process_and_translate(response["response"], target_language)}

@app.post("/api/process_video")
async def process_video_api(
        file: UploadFile = File(...),
        prompt: str = Form(None),
        target_language: str = Form("en")
):
    allowed_video_types = {"video/mp4", "video/mkv", "video/webm", "video/avi"}
    if file.content_type not in allowed_video_types:
        return {"error": f"Invalid file type: {file.content_type}. Please upload a video file."}

    response = await process_video(file, prompt)

    # ✅ Ensure errors are returned properly
    if isinstance(response, dict) and "error" in response:
        return {"error": response["error"]}

    if "response" not in response:
        return {"error": "Unexpected response format from AI."}

    return {"response": process_and_translate(response["response"], target_language)}
