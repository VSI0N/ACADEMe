from firebase_admin import firestore
from fastapi import HTTPException
from google.cloud.firestore import DocumentReference
from datetime import datetime
from fastapi.encoders import jsonable_encoder

db = firestore.client()

def log_progress(user_id: str, progress_data: dict):
    """Logs a new progress entry inside the user's progress subcollection in Firestore."""
    try:
        progress_ref: DocumentReference = db.collection("users").document(user_id).collection("progress").document()
        progress_data["timestamp"] = firestore.SERVER_TIMESTAMP  # Firestore will set timestamp
        progress_ref.set(progress_data)

        # Fetch document to get Firestore-populated timestamp
        saved_progress = progress_ref.get().to_dict()
        saved_progress["id"] = progress_ref.id

        # Ensure FastAPI serialization by removing Firestore Sentinels
        return jsonable_encoder(saved_progress)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error logging progress: {str(e)}")

def get_student_progress(user_id: str):
    """Fetches all progress entries for a student from Firestore."""
    try:
        progress_ref = db.collection("users").document(user_id).collection("progress")
        progress_docs = progress_ref.stream()
        return [{**doc.to_dict(), "id": doc.id} for doc in progress_docs if doc.exists]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching progress: {str(e)}")

def update_progress_status(user_id: str, progress_id: str, progress_update: dict):
    """Updates an existing progress entry in Firestore."""
    try:
        progress_ref = db.collection("users").document(user_id).collection("progress").document(progress_id)
        doc = progress_ref.get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Progress entry not found")

        # Add Firestore's server timestamp for tracking updates
        progress_update["updated_at"] = firestore.SERVER_TIMESTAMP

        # Update Firestore document
        progress_ref.update(progress_update)

        # Fetch updated document after Firestore processing
        updated_doc = progress_ref.get().to_dict()
        updated_doc["id"] = progress_id

        # Ensure FastAPI serialization by removing Firestore Sentinels
        return jsonable_encoder(updated_doc)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating progress: {str(e)}")
