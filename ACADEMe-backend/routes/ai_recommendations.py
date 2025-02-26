from fastapi import APIRouter, Depends, HTTPException
from services.ai_service import get_recommendations
from models.recommendation_model import AIRecommendationResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/recommendations", tags=["AI Recommendations"])

@router.get("/", response_model=AIRecommendationResponse)
async def fetch_recommendations(user: dict = Depends(get_current_user)):
    """
    Analyze student progress and provide AI-driven learning recommendations.
    """
    try:
        recommendations = await get_recommendations(user["id"])
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
