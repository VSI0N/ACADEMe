from firebase_admin import firestore
from models.ai_model import AIAnalysisRequest
import google.generativeai as genai
import os

# Firestore connection
db = firestore.client()
progress_collection = db.collection("student_progress")

# Google Gemini API setup
genai.configure(api_key=os.getenv("GOOGLE_GEMINI_API_KEY"))

def analyze_student_performance(request: AIAnalysisRequest):
    # Fetch student progress data
    progress_records = progress_collection.where("student_id", "==", request.student_id).stream()
    progress_data = [record.to_dict() for record in progress_records]

    if not progress_data:
        return {"error": "No progress data found for the student"}

    # Prepare AI input
    ai_prompt = f"""
    Analyze the following student progress data and provide insights:
    {progress_data}
    
    Generate key observations, strengths, weaknesses, and study recommendations.
    """

    # Call Google Gemini AI
    model = genai.GenerativeModel("gemini-pro")
    response = model.generate_content(ai_prompt)

    if response and response.candidates:
        ai_result = response.candidates[0].content.parts[0].text
    else:
        ai_result = "Unable to generate insights at this time."

    # Extract recommendations (mocked for now)
    recommendations = ["Revise algebra basics", "Practice more physics numericals"]

    return {
        "student_id": request.student_id,
        "insights": ai_result,
        "recommendations": recommendations,
        "confidence_score": 0.9  # Placeholder confidence score
    }
