import os
import base64
from pathlib import Path

# Firebase credentials setup - Runs BEFORE any other imports
FIREBASE_CREDENTIALS_PATH = Path("firebase/firebase_service_account.json")

# Check if running in Railway production environment
if os.getenv("RAILWAY_ENVIRONMENT"):
    encoded_creds = os.getenv("FIREBASE_CREDENTIALS_BASE64")
    if not encoded_creds:
        raise ValueError("🚨 Missing FIREBASE_CREDENTIALS_BASE64 environment variable")

    # Decode and write credentials file
    decoded_creds = base64.b64decode(encoded_creds)
    FIREBASE_CREDENTIALS_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(FIREBASE_CREDENTIALS_PATH, "wb") as creds_file:
        creds_file.write(decoded_creds)
    print("✅ Firebase credentials file created successfully")

# Now import FastAPI and routes
from fastapi import FastAPI, File, UploadFile, Form
from routes import users, courses, topics, quizzes, discussions, student_progress, ai_recommendations, progress_visuals
from agents.text_agent import process_text
from agents.response_translation_agent import translate_response, translate_response_all
from agents.document_agent import process_document
from agents.image_agent import process_image
from agents.audio_agent import process_audio
from agents.video_agent import process_video
from agents.stt_agent import process_stt

app = FastAPI(title="ACADEMe API", version="1.0")

app.include_router(users.router, prefix="/api")
app.include_router(courses.router, prefix="/api")
app.include_router(topics.router, prefix="/api")
app.include_router(quizzes.router, prefix="/api")
app.include_router(discussions.router, prefix="/api")
app.include_router(student_progress.router, prefix="/api")
app.include_router(ai_recommendations.router, prefix="/api")
app.include_router(progress_visuals.router, prefix="/api")

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

def process_and_translate_all(response, target_language):
    # Handle errors first
    if isinstance(response, dict) and "error" in response:
        return response
    
    # Handle different response types
    if isinstance(response, str):
        return translate_response_all(response, target_language)
    elif isinstance(response, dict):
        return {k: translate_response_all(v, target_language) if isinstance(v, str) else v 
               for k, v in response.items()}
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
    
    # ✅ Error handling and translation
    if isinstance(response, dict) and "error" in response:
        return {"error": response["error"]}

    if "response" not in response:
        return {"error": "Unexpected response format from image processor."}

    translated_response = process_and_translate(response["response"], target_lang)
    
    return {"response": translated_response}

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

    return {"response": process_and_translate_all(response["response"], target_language)}

@app.get("/")
def home():
    return {"message": "ACADEMe API is running!"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port, reload=True)
