from fastapi import APIRouter, HTTPException
from models.discussion_model import DiscussionCreate, MessageCreate
from services.discussion_service import create_discussion, get_discussions_by_topic, create_message, get_messages_by_discussion

router = APIRouter()

@router.post("/discussions/", response_model=dict)
async def add_discussion(discussion: DiscussionCreate):
    return create_discussion(discussion)

@router.get("/topics/{topic_id}/discussions", response_model=list)
async def fetch_discussions(topic_id: str):
    return get_discussions_by_topic(topic_id)

@router.post("/messages/", response_model=dict)
async def add_message(message: MessageCreate):
    try:
        return create_message(message)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/discussions/{discussion_id}/messages", response_model=list)
async def fetch_messages(discussion_id: str):
    try:
        return get_messages_by_discussion(discussion_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
