from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_create_quiz():
    response = client.post("/quizzes/", json={"title": "Math Quiz", "description": "Basic math questions", "subject": "Mathematics"})
    assert response.status_code == 200
    assert response.json()["title"] == "Math Quiz"

def test_get_all_quizzes():
    response = client.get("/quizzes/")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
