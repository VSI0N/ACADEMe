from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class CourseCreate(BaseModel):
    title: str
    class_name: str
    description: str

class CourseResponse(BaseModel):
    id: str
    title: str
    class_name: str
    description: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True  # ✅ Ensures conversion from Firestore docs
