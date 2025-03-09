import uuid
from datetime import datetime
from firebase_admin import firestore
from models.discussion_model import DiscussionCreate, MessageCreate

db = firestore.client()
discussions_collection = db.collection("discussions")

def create_discussion(discussion: DiscussionCreate):
    discussion_id = str(uuid.uuid4())
    new_discussion = {
        "id": discussion_id,
        "topic_id": discussion.topic_id,
        "title": discussion.title,
        "created_by": discussion.created_by,
        "created_at": datetime.utcnow()
    }
    discussions_collection.document(discussion_id).set(new_discussion)
    return new_discussion

def get_discussions_by_topic(topic_id: str):
    discussions = discussions_collection.where("topic_id", "==", topic_id).stream()
    return [discussion.to_dict() for discussion in discussions]

def create_message(message: MessageCreate):
    discussion_ref = discussions_collection.document(message.discussion_id)

    if not discussion_ref.get().exists:
        raise ValueError("Discussion not found")

    message_id = str(uuid.uuid4())
    message_data = {
        "id": message_id,
        "discussion_id": message.discussion_id,
        "user_id": message.user_id,
        "content": message.content,
        "created_at": datetime.utcnow()
    }
    discussion_ref.collection("messages").document(message_id).set(message_data)
    return message_data

def get_messages_by_discussion(discussion_id: str):
    discussion_ref = discussions_collection.document(discussion_id)
    
    if not discussion_ref.get().exists:
        raise ValueError("Discussion not found")

    messages = discussion_ref.collection("messages").stream()
    return [message.to_dict() for message in messages]
