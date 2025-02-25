from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_ai_analysis():
    response = client.post("/ai/analyze", json={"student_id": "student_1"})
    assert response.status_code == 200
    assert "insights" in response.json()
    assert "recommendations" in response.json()
