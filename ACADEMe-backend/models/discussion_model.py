from datetime import datetime
from pydantic import BaseModel
from typing import List, Optional

class DiscussionBase(BaseModel):
    topic_id: str  # The topic related to this discussion
    title: str
    created_by: str  # User ID of the creator

class DiscussionCreate(DiscussionBase):
    pass

class DiscussionResponse(DiscussionBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True

class MessageBase(BaseModel):
    discussion_id: str  # The discussion to which the message belongs
    user_id: str  # User who posted the message
    content: str  # The actual message

class MessageCreate(MessageBase):
    pass

class MessageResponse(MessageBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True
