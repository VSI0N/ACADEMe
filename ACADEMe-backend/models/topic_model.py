from pydantic import BaseModel
from typing import Optional, Dict
from datetime import datetime

class TopicBase(BaseModel):
    title: str
    description: Optional[str] = None

class TopicCreate(TopicBase):
    pass  

class TopicResponse(TopicBase):
    id: str
    language: str
    translations: Dict[str, Dict[str, str]]
    created_at: datetime  

    class Config:
        from_attributes = True

class SubtopicBase(BaseModel):
    title: str
    description: Optional[str] = None

class SubtopicCreate(SubtopicBase):
    pass  

class SubtopicResponse(SubtopicBase):
    id: str
    language: str
    translations: Dict[str, Dict[str, str]]
    created_at: datetime  

    class Config:
        from_attributes = True
