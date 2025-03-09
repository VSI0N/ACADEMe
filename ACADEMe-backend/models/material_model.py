from datetime import datetime
from pydantic import BaseModel
from typing import Literal, Optional

class MaterialCreate(BaseModel):
    type: Literal["text", "document", "image", "audio", "video"]
    category: Literal["Notes", "Reference Links", "Practice Questions", "notes", "reference links", "practice questions"]
    content: str  # URL or text content
    optional_text: Optional[str] = None  # Description of the material

class MaterialResponse(MaterialCreate):
    id: str
    created_at: str
    updated_at: str

    class Config:
        from_attributes=True