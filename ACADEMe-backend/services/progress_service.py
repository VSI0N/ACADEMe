from firebase_admin import firestore
from models.progress_model import ProgressCreate
from datetime import datetime
import uuid

db = firestore.client()
progress_collection = db.collection("student_progress")

def add_student_progress(progress: ProgressCreate):
    progress_id = str(uuid.uuid4())
    new_progress = {
        "id": progress_id,
        "student_id": progress.student_id,
        "subject_id": progress.subject_id,
        "chapter_id": progress.chapter_id,
        "marks": progress.marks,
        "total_marks": progress.total_marks,
        "completion_status": progress.completion_status,
        "created_at": datetime.utcnow()
    }
    progress_collection.document(progress_id).set(new_progress)
    return new_progress

def get_student_progress(student_id: str):
    progress_records = progress_collection.where("student_id", "==", student_id).stream()
    return [record.to_dict() for record in progress_records]

def update_progress_status(progress_id: str, status: str):
    progress_ref = progress_collection.document(progress_id)
    if not progress_ref.get().exists:
        raise ValueError("Progress record not found")

    progress_ref.update({"completion_status": status})
    return {"id": progress_id, "completion_status": status}
