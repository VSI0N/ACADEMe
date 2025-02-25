from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class ProgressBase(BaseModel):
    student_id: str  # The student whose progress is tracked
    subject_id: str  # The subject this progress belongs to
    chapter_id: str  # The chapter being tracked
    marks: float  # Marks obtained in the chapter
    total_marks: float  # Total possible marks
    completion_status: Optional[str] = "in_progress"  # Status: in_progress, completed

class ProgressCreate(ProgressBase):
    pass

class ProgressResponse(ProgressBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True
