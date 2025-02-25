from firebase_admin import firestore
from models.quiz_model import QuizResponse, QuestionResponse
from models.quiz_model import QuizCreate, QuizResponse, QuestionCreate, QuestionResponse
from datetime import datetime
import uuid
from fastapi import HTTPException

db = firestore.client()

class QuizService:
    @staticmethod
    async def add_quiz(
        course_id: str, 
        topic_id: str, 
        quiz_data: QuizCreate,  # ✅ This is a Pydantic model
        is_subtopic: bool = False, 
        subtopic_id: str = None
    ) -> QuizResponse:
        """Adds a quiz under a topic or subtopic in Firestore."""
        try:
            quiz_id = str(uuid.uuid4())

            # ✅ Convert Pydantic model to a dictionary
            quiz_dict = quiz_data.model_dump()

            # ✅ Now modify values in the dictionary
            quiz_dict["id"] = quiz_id
            quiz_dict["created_at"] = datetime.utcnow().isoformat()
            quiz_dict["updated_at"] = datetime.utcnow().isoformat()

            # ✅ Reference to Firestore
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

            # ✅ Store modified quiz data in Firestore
            ref.set(quiz_dict, merge=True)

            # ✅ Return response using Pydantic model
            return QuizResponse(**quiz_dict)

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error adding quiz: {str(e)}")
            
    @staticmethod
    async def get_quizzes(
        course_id: str, 
        topic_id: str, 
        is_subtopic: bool = False, 
        subtopic_id: str = None
    ) -> list[QuizResponse]:
        """Fetches quizzes either under a topic or subtopic from Firestore."""
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
                return []  # ✅ Return empty list instead of throwing error

            for quiz in quiz_list:
                if isinstance(quiz.get("created_at"), datetime):
                    quiz["created_at"] = quiz["created_at"].isoformat()
                if isinstance(quiz.get("updated_at"), datetime):
                    quiz["updated_at"] = quiz["updated_at"].isoformat()

            return [QuizResponse(**quiz) for quiz in quiz_list]

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching quizzes: {str(e)}")

    @staticmethod
    async def add_question(
        course_id: str,
        topic_id: str,
        quiz_id: str,
        question_data: QuestionCreate,  # ✅ This is a Pydantic model
        is_subtopic: bool = False,
        subtopic_id: str = None
    ) -> QuestionResponse:
        """Adds a question to a quiz in Firestore."""
        try:
            question_id = str(uuid.uuid4())

            # ✅ Convert Pydantic model to dictionary before modifying
            question_dict = question_data.dict()
            question_dict["id"] = question_id
            question_dict["quiz_id"] = quiz_id  # ✅ Add quiz_id
            question_dict["created_at"] = datetime.utcnow().isoformat()
            question_dict["updated_at"] = datetime.utcnow().isoformat()  # ✅ Add updated_at

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
            return QuestionResponse(**question_dict)  # ✅ No more missing fields!

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error adding question: {str(e)}")

    @staticmethod
    async def get_questions(
        course_id: str,
        topic_id: str,
        quiz_id: str,
        is_subtopic: bool = False,
        subtopic_id: str = None
    ) -> list[QuestionResponse]:
        """Fetches all questions under a quiz from Firestore."""
        try:
            # ✅ Determine Firestore reference based on topic or subtopic
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

            # ✅ Fetch questions
            questions = ref.stream()
            question_list = []

            for question in questions:
                question_data = question.to_dict()

                # ✅ Ensure required fields exist
                question_data["id"] = question.id  # Assign Firestore document ID
                question_data["quiz_id"] = quiz_id  # ✅ Ensure `quiz_id` exists
                question_data["updated_at"] = question_data.get("updated_at", datetime.utcnow().isoformat())
                question_data["created_at"] = question_data.get("created_at", datetime.utcnow().isoformat())

                question_list.append(QuestionResponse(**question_data))

            return question_list

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching questions: {str(e)}")