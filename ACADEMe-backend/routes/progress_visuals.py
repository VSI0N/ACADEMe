from fastapi import APIRouter, Depends, HTTPException
from services.progress_service import get_progress_visuals
from models.progress_model import ProgressVisualResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/progress-visuals", tags=["Progress Visualization"])

@router.get("/", response_model=ProgressVisualResponse)
async def fetch_progress_visuals(user: dict = Depends(get_current_user)):
    """
    Fetch graphical data on student progress (marks, time spent, performance trends).
    """
    try:
        progress_data = await get_progress_visuals(user["id"])
        return progress_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
