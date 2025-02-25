from fastapi import APIRouter, Depends, HTTPException
from utils.auth import get_current_user
from services.quiz_service import QuizService
from models.quiz_model import QuizCreate, QuizResponse, QuestionCreate
from typing import List

router = APIRouter(prefix="/courses", tags=["Quizzes"])

### 📌 Create a Quiz Under a Topic ###
@router.post("/{course_id}/topics/{topic_id}/quizzes/")
async def create_topic_quiz(
    course_id: str,
    topic_id: str,
    quiz_data: QuizCreate,
    user: dict = Depends(get_current_user)
):
    """Add Quiz to a topic (Admin-only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    """Creates a quiz under a topic."""
    return await QuizService.add_quiz(course_id, topic_id, quiz_data, is_subtopic=False)


### 📌 Create a Quiz Under a Subtopic ###
@router.post("/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/quizzes/")
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
    
    """Creates a quiz under a subtopic."""
    return await QuizService.add_quiz(course_id, topic_id, quiz_data, is_subtopic=True, subtopic_id=subtopic_id)


### 📌 Fetch Quizzes Under a Topic ###
@router.get("/{course_id}/topics/{topic_id}/quizzes/")
async def get_topic_quizzes(
    course_id: str,
    topic_id: str,
    user: dict = Depends(get_current_user)
):
    """Fetches quizzes that are directly added under a topic."""
    return await QuizService.get_quizzes(course_id, topic_id, is_subtopic=False)


### 📌 Fetch Quizzes Under a Subtopic ###
@router.get("/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/quizzes/")
async def get_subtopic_quizzes(
    course_id: str,
    topic_id: str,
    subtopic_id: str,
    user: dict = Depends(get_current_user)
):
    """Fetches quizzes that are specifically added under a subtopic."""
    return await QuizService.get_quizzes(course_id, topic_id, is_subtopic=True, subtopic_id=subtopic_id)


### 📌 Add a Question to a Topic Quiz ###
@router.post("/{course_id}/topics/{topic_id}/quizzes/{quiz_id}/questions/")
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
    
    """Adds a question to a quiz under a topic."""
    return await QuizService.add_question(course_id, topic_id, quiz_id, question_data, is_subtopic=False)


### 📌 Add a Question to a Subtopic Quiz ###
@router.post("/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/quizzes/{quiz_id}/questions/")
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
    
    """Adds a question to a quiz under a subtopic."""
    return await QuizService.add_question(course_id, topic_id, quiz_id, question_data, is_subtopic=True, subtopic_id=subtopic_id)

### 📌 Fetch Questions for a Topic Quiz ###
@router.get("/{course_id}/topics/{topic_id}/quizzes/{quiz_id}/questions/")
async def get_questions_for_topic_quiz(
    course_id: str,
    topic_id: str,
    quiz_id: str,
    user: dict = Depends(get_current_user)
):
    """Fetches all questions under a quiz in a topic."""
    return await QuizService.get_questions(course_id, topic_id, quiz_id, is_subtopic=False)


### 📌 Fetch Questions for a Subtopic Quiz ###
@router.get("/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/quizzes/{quiz_id}/questions/")
async def get_questions_for_subtopic_quiz(
    course_id: str,
    topic_id: str,
    subtopic_id: str,
    quiz_id: str,
    user: dict = Depends(get_current_user)
):
    """Fetches all questions under a quiz in a subtopic."""
    return await QuizService.get_questions(course_id, topic_id, quiz_id, is_subtopic=True, subtopic_id=subtopic_id)
