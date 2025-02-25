from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_create_question():
    quiz_response = client.post("/quizzes/", json={"title": "Science Quiz", "description": "Physics basics", "subject": "Science"})
    quiz_id = quiz_response.json()["id"]

    response = client.post("/questions/", json={
        "quiz_id": quiz_id,
        "question_text": "What is gravity?",
        "options": ["Force", "Speed", "Light", "Sound"],
        "correct_answer": "Force"
    })
    assert response.status_code == 200
    assert response.json()["question_text"] == "What is gravity?"

def test_get_questions():
    quiz_response = client.post("/quizzes/", json={"title": "History Quiz", "description": "World War 2", "subject": "History"})
    quiz_id = quiz_response.json()["id"]

    client.post("/questions/", json={
        "quiz_id": quiz_id,
        "question_text": "When did WW2 start?",
        "options": ["1935", "1939", "1945", "1950"],
        "correct_answer": "1939"
    })
    response = client.get(f"/quizzes/{quiz_id}/questions")
    
    assert response.status_code == 200
    assert isinstance(response.json(), list)
