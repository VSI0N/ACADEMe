import os
import json
import uuid
import httpx
from datetime import datetime
from fastapi import HTTPException
from firebase_admin import firestore
from services.course_service import CourseService
from models.quiz_model import QuizResponse, QuestionResponse
from models.quiz_model import QuizCreate, QuizResponse, QuestionCreate, QuestionResponse

db = firestore.client()

QUIZZES_JSON_PATH = "assets/quizzes.json"

class QuizService:
    @staticmethod
    async def add_quiz(
        course_id: str, 
        topic_id: str, 
        quiz_data: QuizCreate,  
        is_subtopic: bool = False, 
        subtopic_id: str = None
    ) -> QuizResponse:
        """Adds a quiz under a topic or subtopic in Firestore with multilingual support."""
        try:
            quiz_id = str(uuid.uuid4())
            quiz_dict = quiz_data.model_dump()
            quiz_dict["id"] = quiz_id
            quiz_dict["created_at"] = datetime.utcnow().isoformat()
            quiz_dict["updated_at"] = datetime.utcnow().isoformat()

            # ✅ Detect language
            detected_language = await CourseService.detect_language([quiz_data.title, quiz_data.description])

            # ✅ Define target languages
            target_languages = ["fr", "es", "de", "zh", "ar", "hi", "en"]
            if detected_language not in target_languages:
                detected_language = "en"  # Default to English if unsupported

            quiz_dict["languages"] = {detected_language: {"title": quiz_data.title, "description": quiz_data.description}}

            # ✅ Translate title & description
            for lang in target_languages:
                if lang != detected_language:
                    quiz_dict["languages"][lang] = {
                        "title": await CourseService.translate_text(quiz_data.title, lang),
                        "description": await CourseService.translate_text(quiz_data.description, lang)
                    }

            # ✅ Store quiz in Firestore
            if is_subtopic and subtopic_id:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("subtopics")
                    .document(subtopic_id)
                    .collection("quizzes")
                    .document(quiz_id)
                )
            else:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("quizzes")
                    .document(quiz_id)
                )

            ref.set(quiz_dict, merge=True)

            # ✅ Update quizzes.json
            quizzes = {}
            if os.path.exists(QUIZZES_JSON_PATH):
                with open(QUIZZES_JSON_PATH, "r", encoding="utf-8") as f:
                    quizzes = json.load(f)

            quizzes[quiz_id] = quiz_data.title  # Store quiz ID and title

            with open(QUIZZES_JSON_PATH, "w", encoding="utf-8") as f:
                json.dump(quizzes, f, indent=4, ensure_ascii=False)

            return QuizResponse(**quiz_dict)

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error adding quiz: {str(e)}")
            
    @staticmethod
    async def get_quizzes(
        course_id: str, 
        topic_id: str, 
        target_language: str = "en",  # Allow specifying language
        is_subtopic: bool = False, 
        subtopic_id: str = None
    ) -> list[QuizResponse]:
        """Fetches quizzes either under a topic or subtopic from Firestore, supporting multilingual responses."""
        try:
            if is_subtopic and subtopic_id:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("subtopics")
                    .document(subtopic_id)
                    .collection("quizzes")
                )
            else:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("quizzes")
                )

            quizzes = ref.stream()
            quiz_list = [quiz.to_dict() for quiz in quizzes]

            if not quiz_list:
                return []

            for quiz in quiz_list:
                if isinstance(quiz.get("created_at"), datetime):
                    quiz["created_at"] = quiz["created_at"].isoformat()
                if isinstance(quiz.get("updated_at"), datetime):
                    quiz["updated_at"] = quiz["updated_at"].isoformat()
                
                # ✅ Fetch translation if available
                languages = quiz.get("languages", {})
                if target_language in languages:
                    quiz["title"] = languages[target_language].get("title", quiz["title"])
                    quiz["description"] = languages[target_language].get("description", quiz["description"])
                else:
                    quiz["title"] = languages.get("en", {}).get("title", quiz["title"])
                    quiz["description"] = languages.get("en", {}).get("description", quiz["description"])

            return [QuizResponse(**quiz) for quiz in quiz_list]

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching quizzes: {str(e)}")

    @staticmethod
    async def add_question(
        course_id: str,
        topic_id: str,
        quiz_id: str,
        question_data: QuestionCreate,  
        is_subtopic: bool = False,
        subtopic_id: str = None
    ) -> QuestionResponse:
        """Adds a question to a quiz in Firestore with multilingual support."""
        try:
            question_id = str(uuid.uuid4())
            question_dict = question_data.model_dump()
            question_dict["id"] = question_id
            question_dict["quiz_id"] = quiz_id
            question_dict["created_at"] = datetime.utcnow().isoformat()
            question_dict["updated_at"] = datetime.utcnow().isoformat()

            # ✅ Detect language
            detected_language = await CourseService.detect_language([question_data.question_text] + question_data.options)

            # ✅ Define target languages (modify as needed)
            target_languages = ["fr", "es", "de", "zh", "ar", "hi", "en"]
            if detected_language not in target_languages:
                detected_language = "en"  # Default to English if the detected language is not supported

            question_dict["languages"] = {
                detected_language: {
                    "question_text": question_data.question_text,
                    "options": question_data.options
                }
            }

            # ✅ Translate question_text & options
            for lang in target_languages:
                if lang != detected_language:
                    question_dict["languages"][lang] = {
                        "question_text": await CourseService.translate_text(question_data.question_text, lang),
                        "options": [await CourseService.translate_text(opt, lang) for opt in question_data.options]
                    }

            # ✅ Store question in Firestore
            if is_subtopic and subtopic_id:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("subtopics")
                    .document(subtopic_id)
                    .collection("quizzes")
                    .document(quiz_id)
                    .collection("questions")
                    .document(question_id)
                )
            else:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("quizzes")
                    .document(quiz_id)
                    .collection("questions")
                    .document(question_id)
                )

            ref.set(question_dict, merge=True)
            return QuestionResponse(**question_dict)

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error adding question: {str(e)}")

    @staticmethod
    async def get_questions(
        course_id: str,
        topic_id: str,
        quiz_id: str,
        target_language: str = "en",  # Allow specifying language
        is_subtopic: bool = False,
        subtopic_id: str = None
    ) -> list[QuestionResponse]:
        """Fetches all questions under a quiz from Firestore, supporting multilingual responses."""
        try:
            if is_subtopic and subtopic_id:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("subtopics")
                    .document(subtopic_id)
                    .collection("quizzes")
                    .document(quiz_id)
                    .collection("questions")
                )
            else:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("quizzes")
                    .document(quiz_id)
                    .collection("questions")
                )

            questions = ref.stream()
            question_list = []

            for question in questions:
                question_data = question.to_dict()

                question_data["id"] = question.id
                question_data["quiz_id"] = quiz_id
                question_data["updated_at"] = question_data.get("updated_at", datetime.utcnow().isoformat())
                question_data["created_at"] = question_data.get("created_at", datetime.utcnow().isoformat())

                # ✅ Fetch translation if available
                languages = question_data.get("languages", {})
                if target_language in languages:
                    question_data["question_text"] = languages[target_language].get("question_text", question_data["question_text"])
                    question_data["options"] = languages[target_language].get("options", question_data["options"])
                else:
                    question_data["question_text"] = languages.get("en", {}).get("question_text", question_data["question_text"])
                    question_data["options"] = languages.get("en", {}).get("options", question_data["options"])

                question_list.append(QuestionResponse(**question_data))

            return question_list

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching questions: {str(e)}")

    @staticmethod
    def get_all_quizzes() -> dict:
        """Fetch all quizzes across courses and return a mapping {quiz_id: quiz_title}."""
        try:
            quiz_mapping = {}

            # Fetch all courses
            courses = db.collection("courses").stream()
            for course in courses:
                course_id = course.id

                # Fetch all topics in this course
                topics = db.collection("courses").document(course_id).collection("topics").stream()
                for topic in topics:
                    topic_id = topic.id

                    # Fetch quizzes under the topic
                    quizzes = db.collection("courses").document(course_id).collection("topics").document(topic_id).collection("quizzes").stream()
                    for quiz in quizzes:
                        quiz_data = quiz.to_dict()
                        quiz_mapping[quiz.id] = quiz_data.get("title", "Unknown Quiz")

                    # Fetch subtopics in the topic
                    subtopics = db.collection("courses").document(course_id).collection("topics").document(topic_id).collection("subtopics").stream()
                    for subtopic in subtopics:
                        subtopic_id = subtopic.id

                        # Fetch quizzes under subtopics
                        subtopic_quizzes = db.collection("courses").document(course_id).collection("topics").document(topic_id).collection("subtopics").document(subtopic_id).collection("quizzes").stream()
                        for quiz in subtopic_quizzes:
                            quiz_data = quiz.to_dict()
                            quiz_mapping[quiz.id] = quiz_data.get("title", "Unknown Quiz")

            return quiz_mapping
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching all quizzes: {str(e)}")
