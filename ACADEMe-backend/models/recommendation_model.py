from pydantic import BaseModel

class AIRecommendationResponse(BaseModel):
    recommendations: str
