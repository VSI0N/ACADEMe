from typing import List
from utils.auth import get_current_user
from services.quiz_service import QuizService
from fastapi import APIRouter, Depends, HTTPException
from models.quiz_model import QuizCreate, QuizResponse, QuestionCreate

router = APIRouter(prefix="/courses", tags=["Quizzes"])

### 📌 Create a Quiz Under a Topic ###
@router.post("/{course_id}/topics/{topic_id}/quizzes/", response_model=QuizResponse)
async def create_topic_quiz(
    course_id: str,
    topic_id: str,
    quiz_data: QuizCreate,
    user: dict = Depends(get_current_user)
):
    """Add Quiz to a topic (Admin-only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    return await QuizService.add_quiz(course_id, topic_id, quiz_data, is_subtopic=False)

### 📌 Create a Quiz Under a Subtopic ###
@router.post("/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/quizzes/", response_model=QuizResponse)
async def create_subtopic_quiz(
    course_id: str,
    topic_id: str,
    subtopic_id: str,
    quiz_data: QuizCreate,
    user: dict = Depends(get_current_user)
):
    """Add Quiz to a Subtopic (Admin-only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    return await QuizService.add_quiz(course_id, topic_id, quiz_data, is_subtopic=True, subtopic_id=subtopic_id)

### 📌 Fetch Quizzes Under a Topic ###
@router.get("/{course_id}/topics/{topic_id}/quizzes/", response_model=List[QuizResponse])
async def get_topic_quizzes(
    course_id: str,
    topic_id: str,
    target_language: str = "en",
    user: dict = Depends(get_current_user)
):
    """Fetches quizzes that are directly added under a topic."""
    quizzes = await QuizService.get_quizzes(course_id, topic_id, target_language, is_subtopic=False)
    # Sort quizzes by created_at in ascending order (oldest first)
    return sorted(quizzes, key=lambda x: x.created_at)

### 📌 Fetch Quizzes Under a Subtopic ###
@router.get("/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/quizzes/", response_model=List[QuizResponse])
async def get_subtopic_quizzes(
    course_id: str,
    topic_id: str,
    subtopic_id: str,
    target_language: str = "en",
    user: dict = Depends(get_current_user)
):
    """Fetches quizzes that are specifically added under a subtopic."""
    quizzes = await QuizService.get_quizzes(course_id, topic_id, target_language, is_subtopic=True, subtopic_id=subtopic_id)
    # Sort quizzes by created_at in ascending order (oldest first)
    return sorted(quizzes, key=lambda x: x.created_at)

### 📌 Add a Question to a Topic Quiz ###
@router.post("/{course_id}/topics/{topic_id}/quizzes/{quiz_id}/questions/", response_model=QuestionCreate)
async def add_question_to_topic_quiz(
    course_id: str,
    topic_id: str,
    quiz_id: str,
    question_data: QuestionCreate,
    user: dict = Depends(get_current_user)
):
    """Add question to a quiz of a topic (Admin-only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    return await QuizService.add_question(course_id, topic_id, quiz_id, question_data, is_subtopic=False)

### 📌 Add a Question to a Subtopic Quiz ###
@router.post("/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/quizzes/{quiz_id}/questions/", response_model=QuestionCreate)
async def add_question_to_subtopic_quiz(
    course_id: str,
    topic_id: str,
    subtopic_id: str,
    quiz_id: str,
    question_data: QuestionCreate,
    user: dict = Depends(get_current_user)
):
    """Add question to a quiz of a Subtopic (Admin-only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    return await QuizService.add_question(course_id, topic_id, quiz_id, question_data, is_subtopic=True, subtopic_id=subtopic_id)

### 📌 Fetch Questions for a Topic Quiz ###
@router.get("/{course_id}/topics/{topic_id}/quizzes/{quiz_id}/questions/", response_model=List[QuestionCreate])
async def get_questions_for_topic_quiz(
    course_id: str,
    topic_id: str,
    quiz_id: str,
    target_language: str = "en",
    user: dict = Depends(get_current_user)
):
    """Fetches all questions under a quiz in a topic."""
    questions = await QuizService.get_questions(course_id, topic_id, quiz_id, target_language, is_subtopic=False)
    # Sort questions by created_at in ascending order (oldest first)
    return sorted(questions, key=lambda x: x.created_at)

### 📌 Fetch Questions for a Subtopic Quiz ###
@router.get("/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/quizzes/{quiz_id}/questions/", response_model=List[QuestionCreate])
async def get_questions_for_subtopic_quiz(
    course_id: str,
    topic_id: str,
    subtopic_id: str,
    quiz_id: str,
    target_language: str = "en",
    user: dict = Depends(get_current_user)
):
    """Fetches all questions under a quiz in a subtopic."""
    questions = await QuizService.get_questions(course_id, topic_id, quiz_id, target_language, is_subtopic=True, subtopic_id=subtopic_id)
    # Sort questions by created_at in ascending order (oldest first)
    return sorted(questions, key=lambda x: x.created_at)
