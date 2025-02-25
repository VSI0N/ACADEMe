from fastapi import APIRouter, HTTPException
from services.progress_service import add_student_progress, get_student_progress, update_progress_status
from models.progress_model import ProgressCreate

router = APIRouter()

@router.post("/progress/", response_model=dict)
async def add_progress(progress: ProgressCreate):
    return add_student_progress(progress)

@router.get("/progress/{student_id}", response_model=list)
async def fetch_progress(student_id: str):
    return get_student_progress(student_id)

@router.put("/progress/{progress_id}/status", response_model=dict)
async def update_status(progress_id: str, status: str):
    try:
        return update_progress_status(progress_id, status)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
