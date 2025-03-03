import google.generativeai as genai
import json
from config.settings import GOOGLE_GEMINI_API_KEY
from services.progress_service import fetch_student_performance
from services.quiz_service import QuizService

genai.configure(api_key=GOOGLE_GEMINI_API_KEY)

async def get_recommendations(user_id: str):
    """
    Fetch student progress, analyze it using Gemini AI, and return personalized recommendations.
    """

    progress_data = await fetch_student_performance(user_id)

    if isinstance(progress_data, str):
        try:
            progress_data = json.loads(progress_data)
        except json.JSONDecodeError:
            raise ValueError(f"Invalid JSON format in progress data: {progress_data}")

    if isinstance(progress_data, dict):
        progress_data = [progress_data]

    if not isinstance(progress_data, list):
        raise ValueError(f"Expected a list, but got: {type(progress_data)}")

    quiz_mapping = QuizService.get_all_quizzes()  # ✅ No `await` needed

    for record in progress_data:
        if isinstance(record, dict):
            quiz_id = record.get("quiz_id")
            if quiz_id and quiz_id in quiz_mapping:
                record["quiz_title"] = quiz_mapping[quiz_id]
        else:
            raise ValueError(f"Unexpected progress data format: {record}")

    prompt = f"""
    Analyze the student's quiz performance and progress data: {progress_data}.
    Suggest areas of improvement, a learning roadmap, and personalized strategies. Also make all your suggestions concise and to the point.
    Also Remember each quiz is worth 100 points.
    """

    model = genai.GenerativeModel("gemini-2.0-flash")
    response = model.generate_content(prompt)

    response_text = response.text
    for quiz_id, quiz_title in quiz_mapping.items():
        response_text = response_text.replace(quiz_id, f'"{quiz_title}"')

    return {"recommendations": response_text}  # ✅ Fixed incorrect `await`
