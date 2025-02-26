from fastapi import APIRouter, Depends, HTTPException
from fastapi.encoders import jsonable_encoder
from services.progress_service import log_progress, get_student_progress, update_progress_status
from models.progress_model import ProgressCreate, ProgressUpdate
from utils.auth import get_current_user

router = APIRouter(prefix="/progress", tags=["Student Progress"])

@router.post("/")
def track_progress(progress_data: ProgressCreate, user: dict = Depends(get_current_user)):
    """Logs student progress in Firestore."""
    progress_dict = jsonable_encoder(progress_data.dict())  # Ensure serialization
    response = log_progress(user["id"], progress_dict)
    return {"message": "Progress logged successfully", "progress": response}

@router.get("/")
def fetch_student_progress(user: dict = Depends(get_current_user)):
    """Fetches all progress records for a student."""
    progress = get_student_progress(user["id"])
    if not progress:
        raise HTTPException(status_code=404, detail="No progress records found")
    return {"message": "Progress records fetched successfully", "progress": progress}

@router.put("/{progress_id}")
def update_progress(progress_id: str, progress_update: ProgressUpdate, user: dict = Depends(get_current_user)):
    """Updates a student's progress record in Firestore."""
    update_data = jsonable_encoder(progress_update.dict(exclude_unset=True))  # Ensure proper serialization
    updated_progress = update_progress_status(user["id"], progress_id, update_data)
    return {"message": "Progress updated successfully", "progress": updated_progress}
