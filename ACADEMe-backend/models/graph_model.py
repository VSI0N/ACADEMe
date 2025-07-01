from pydantic import BaseModel
from typing import Dict, List, Union

class HeroGraphData(BaseModel):
    quizzes: int
    materials_read: int
    avg_score: Union[float, None] = None

class ScoreTimelineEntry(BaseModel):
    timestamp: str
    score: float

class TopicProgress(BaseModel):
    quizzes: int
    materials_read: int
    avg_score: float
    max_quiz_score: float  # ✅ Added max_quiz_score field
    quiz_scores: List[float]
    score_timeline: List[ScoreTimelineEntry]  # ✅ Use a proper schema for timestamps
    time_spent: int

class ProgressVisualResponse(BaseModel):
    visual_data: Dict[str, TopicProgress]