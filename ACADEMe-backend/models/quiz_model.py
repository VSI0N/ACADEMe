from pydantic import BaseModel
from typing import List, Optional

# ✅ Model for creating a new quiz
class QuizCreate(BaseModel):
    title: str
    description: Optional[str] = None

# ✅ Response model for fetching quizzes
class QuizResponse(QuizCreate):
    id: str
    created_at: str
    updated_at: str
    subtopic_id: Optional[str] = None  # ✅ Include for subtopic-based quizzes

    class Config:
        from_attributes = True

# ✅ Model for creating a new question
class QuestionCreate(BaseModel):
    question_text: str
    options: List[str]  # Example: ["Option1", "Option2", "Option3", "Option4"]
    correct_option: int  # Index of the correct answer (0-3)

# ✅ Response model for fetching questions
class QuestionResponse(QuestionCreate):
    id: str
    created_at: str
    updated_at: str  # ✅ Added for consistency
    quiz_id: str  # ✅ Added to track which quiz the question belongs to
    subtopic_id: Optional[str] = None  # ✅ Include for subtopic-based questions

    class Config:
        from_attributes = True
