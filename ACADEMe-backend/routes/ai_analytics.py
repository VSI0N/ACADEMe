from fastapi import APIRouter, HTTPException
from services.ai_service import analyze_student_performance
from models.ai_model import AIAnalysisRequest, AIAnalysisResponse

router = APIRouter()

@router.post("/ai/analyze", response_model=AIAnalysisResponse)
async def get_ai_analysis(request: AIAnalysisRequest):
    result = analyze_student_performance(request)
    
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])

    return result
