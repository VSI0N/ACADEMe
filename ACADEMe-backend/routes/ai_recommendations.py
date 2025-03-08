from fastapi import APIRouter, Depends, HTTPException, Query
from services.ai_service import get_recommendations
from models.recommendation_model import AIRecommendationResponse
from utils.auth import get_current_user

router = APIRouter(prefix="/recommendations", tags=["AI Recommendations"])

@router.get("/", response_model=AIRecommendationResponse)
async def fetch_recommendations(
    user: dict = Depends(get_current_user),
    target_language: str = Query("en", description="Target language for recommendations")
):
    """
    Analyze student progress and provide AI-driven learning recommendations in the specified target language.
    Defaults to English if no language is specified.
    """
    try:
        recommendations = await get_recommendations(user["id"], target_language)
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
