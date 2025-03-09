import os
import json
import google.generativeai as genai
from services.quiz_service import QuizService
from services.course_service import CourseService
from config.settings import GOOGLE_GEMINI_API_KEY
from services.progress_service import fetch_student_performance

genai.configure(api_key=GOOGLE_GEMINI_API_KEY)

# ✅ Define paths to JSON files
JSON_FILES = {
    "courses": "assets/courses.json",
    "topics": "assets/topics.json",
    "subtopics": "assets/subtopics.json",
    "quizzes": "assets/quizzes.json",
    "materials": "assets/materials.json",
}

# ✅ Function to load JSON data safely
def load_json_data(file_path):
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}

async def get_recommendations(user_id: str, target_language: str = "en"):
    """
    Fetch student progress, analyze it using Gemini AI, and return personalized recommendations.
    Automatically translates the response into the specified target language.
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

    # ✅ Load all JSON files
    data_mappings = {key: load_json_data(path) for key, path in JSON_FILES.items()}

    for record in progress_data:
        if isinstance(record, dict):
            # ✅ Replace IDs with actual titles/content
            if "quiz_id" in record and record["quiz_id"] in data_mappings["quizzes"]:
                record["quiz_title"] = data_mappings["quizzes"][record["quiz_id"]]
            if "course_id" in record and record["course_id"] in data_mappings["courses"]:
                record["course_title"] = data_mappings["courses"][record["course_id"]]
            if "topic_id" in record and record["topic_id"] in data_mappings["topics"]:
                record["topic_title"] = data_mappings["topics"][record["topic_id"]]
            if "subtopic_id" in record and record["subtopic_id"] in data_mappings["subtopics"]:
                record["subtopic_title"] = data_mappings["subtopics"][record["subtopic_id"]]
            if "material_id" in record and record["material_id"] in data_mappings["materials"]:
                record["material_content"] = data_mappings["materials"][record["material_id"]]
        else:
            raise ValueError(f"Unexpected progress data format: {record}")

    # ✅ Construct a detailed prompt for Gemini AI
    prompt = f"""
    You are an advanced AI tutor analyzing student learning progress.
    You have access to the following data mappings:

    - Courses: {json.dumps(data_mappings["courses"], indent=2, ensure_ascii=False)}
    - Topics: {json.dumps(data_mappings["topics"], indent=2, ensure_ascii=False)}
    - Subtopics: {json.dumps(data_mappings["subtopics"], indent=2, ensure_ascii=False)}
    - Quizzes: {json.dumps(data_mappings["quizzes"], indent=2, ensure_ascii=False)}
    - Materials: {json.dumps(data_mappings["materials"], indent=2, ensure_ascii=False)}

    The student's progress data is as follows:
    {json.dumps(progress_data, indent=2, ensure_ascii=False)}

    Based on the student's performance and learning history, provide personalized recommendations.
    Include:
    - Areas where the student is struggling.
    - A learning roadmap tailored to their progress.
    - Suggested topics, subtopics, and quizzes they should focus on.
    - Any extra study materials they should review.

    Make your recommendations concise, structured, and easy to follow. 
    Always use actual course, topic, subtopic, quiz, and material names instead of IDs.
    Each quiz is worth 100 points.
    """

    model = genai.GenerativeModel("gemini-2.0-flash")
    response = model.generate_content(prompt)

    # ✅ Translate the recommendations into the target language
    translated_text = await CourseService.translate_text(response.text, target_language)

    return {"recommendations": translated_text}
