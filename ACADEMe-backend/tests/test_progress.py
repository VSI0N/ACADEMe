from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_add_progress():
    response = client.post("/progress/", json={
        "student_id": "student_1",
        "subject_id": "math_101",
        "chapter_id": "algebra",
        "marks": 80,
        "total_marks": 100,
        "completion_status": "in_progress"
    })
    assert response.status_code == 200
    assert response.json()["marks"] == 80

def test_get_progress():
    response = client.get("/progress/student_1")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_update_progress_status():
    progress_response = client.post("/progress/", json={
        "student_id": "student_2",
        "subject_id": "science_101",
        "chapter_id": "physics",
        "marks": 90,
        "total_marks": 100,
        "completion_status": "in_progress"
    })
    progress_id = progress_response.json()["id"]

    response = client.put(f"/progress/{progress_id}/status?status=completed")
    assert response.status_code == 200
    assert response.json()["completion_status"] == "completed"
