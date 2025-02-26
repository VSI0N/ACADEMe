from firebase_admin import firestore
from fastapi import HTTPException
from typing import Dict, Any, List
from services.quiz_service import QuizService
from google.cloud.firestore import DocumentReference
from datetime import datetime
from fastapi.encoders import jsonable_encoder
import asyncio

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

def get_student_progress_list(user_id: str):
    """Fetches all progress entries for a student from Firestore."""
    try:
        progress_ref = db.collection("users").document(user_id).collection("progress")
        progress_docs = progress_ref.stream()
        return [{**doc.to_dict(), "id": doc.id} for doc in progress_docs if doc.exists]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching progress: {str(e)}")

async def get_student_progress(user_id: str):
    """Fetches all progress entries for a student using Firestore's `stream()` asynchronously."""
    try:
        progress_ref = db.collection("users").document(user_id).collection("progress")

        # ✅ Run `stream()` in a separate thread to prevent blocking
        loop = asyncio.get_running_loop()
        progress_docs = await loop.run_in_executor(None, lambda: list(progress_ref.stream()))

        # ✅ Convert Firestore documents to JSON serializable format
        progress_list = [{**doc.to_dict(), "id": doc.id} for doc in progress_docs if doc.exists]

        return progress_list
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

def fetch_quiz_progress(user_id: str):
    """Fetches only quiz-related progress entries for analytics."""
    try:
        progress_ref = db.collection("users").document(user_id).collection("progress")
        progress_docs = progress_ref.where("category", "==", "quiz").stream()

        return [{**doc.to_dict(), "id": doc.id} for doc in progress_docs if doc.exists]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching quiz progress: {str(e)}")

def get_progress_visuals(user_id: str):
    """Fetches graphical data for student progress."""
    try:
        progress_data = get_student_progress(user_id)  # Fetch all progress

        chart_data = {
            "chapters": [p.get("topic_id", "Unknown") for p in progress_data],
            "marks": [p.get("score", 0) for p in progress_data],
            "time_spent": [p["metadata"].get("time_spent", "0 min") for p in progress_data if "metadata" in p]
        }

        return {"visual_data": chart_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching progress visuals: {str(e)}")

async def fetch_student_performance(user_id: str):
    """Fetches student performance for AI-driven recommendations, replacing quiz IDs with titles."""
    try:
        progress_data = await get_student_progress(user_id)

        if not isinstance(progress_data, list):
            raise ValueError(f"get_student_progress() returned {type(progress_data)}, expected list.")

        quiz_progress = [p for p in progress_data if p.get("activity_type") == "quiz"]
        if not quiz_progress:
            return {"recommendations": "No quiz progress data available for analysis."}

        # ✅ Call `get_all_quizzes()` correctly (NO await)
        quizzes = QuizService.get_all_quizzes()

        if not isinstance(quizzes, dict):
            raise ValueError(f"get_all_quizzes() returned {type(quizzes)}, expected dict.")

        for p in quiz_progress:
            quiz_id = p.get("quiz_id")
            p["quiz_title"] = quizzes.get(quiz_id, f"Unknown Quiz ({quiz_id})")

        total_score = sum(p.get("score", 0) or 0 for p in quiz_progress)
        avg_score = total_score / len(quiz_progress) if quiz_progress else 0
        completed_topics = sum(1 for p in quiz_progress if p.get("status") == "completed")

        return {
            "total_score": total_score,
            "average_score": avg_score,
            "completed_topics": completed_topics,
            "progress_details": quiz_progress
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching student performance: {str(e)}")
