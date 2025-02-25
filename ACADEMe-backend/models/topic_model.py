from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class TopicBase(BaseModel):
    title: str
    description: Optional[str] = None

class TopicCreate(TopicBase):
    pass  # ✅ No need to repeat fields from TopicBase

class TopicResponse(TopicBase):
    id: str
    created_at: datetime  # ✅ Ensure created_at is included in responses

    class Config:
        from_attributes = True

class SubtopicBase(BaseModel):
    title: str
    description: Optional[str] = None

class SubtopicCreate(SubtopicBase):
    pass  # ✅ No need to pass `topic_id` in request body since it's in the URL

class SubtopicResponse(SubtopicBase):
    id: str
    created_at: datetime  # ✅ Ensure created_at is included in responses

    class Config:
        from_attributes = True
