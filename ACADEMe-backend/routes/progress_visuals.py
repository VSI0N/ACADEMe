from fastapi import APIRouter, Depends, HTTPException
from services.progress_service import get_progress_visuals, fetch_progress_from_firestore
from models.graph_model import ProgressVisualResponse
from utils.auth import get_current_user
import json

router = APIRouter(prefix="/progress-visuals", tags=["Progress Visualization"])

@router.get("/", response_model=ProgressVisualResponse)
async def progress_visuals(user: dict = Depends(get_current_user)):
    try:
        # Fetch progress data from Firestore
        progress_data = fetch_progress_from_firestore(user["id"])

        # Debugging: Print progress_data type and content
        print(f"Progress Data Type: {type(progress_data)}")
        print(f"Progress Data: {progress_data}")

        # Ensure progress_data is in valid format
        if isinstance(progress_data, str):
            progress_data = json.loads(progress_data)

        if not isinstance(progress_data, list):
            raise HTTPException(status_code=400, detail="Invalid progress data format")

        # Generate visual data (progress analytics)
        visual_data = get_progress_visuals(progress_data)

        if not isinstance(visual_data, dict):  # Ensure the correct format is returned
            raise HTTPException(status_code=500, detail="Invalid visual data format")

        return {"visual_data": visual_data}  # ✅ Correct response format

    except Exception as e:
        print(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
