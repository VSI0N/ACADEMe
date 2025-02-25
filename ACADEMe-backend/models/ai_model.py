from pydantic import BaseModel
from typing import List, Dict, Optional

class AIAnalysisRequest(BaseModel):
    student_id: str  # Student for whom AI analytics is requested

class AIAnalysisResponse(BaseModel):
    student_id: str
    insights: str  # AI-generated insights
    recommendations: List[str]  # Suggested study improvements
    confidence_score: Optional[float] = None  # AI confidence score (if available)
