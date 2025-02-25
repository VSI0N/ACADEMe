from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_create_topic():
    response = client.post("/topics/", json={"title": "Mathematics", "description": "Basic math concepts"})
    assert response.status_code == 200
    assert response.json()["title"] == "Mathematics"

def test_get_all_topics():
    response = client.get("/topics/")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_create_subtopic():
    topic_response = client.post("/topics/", json={"title": "Science", "description": "Physics"})
    topic_id = topic_response.json()["id"]

    response = client.post("/subtopics/", json={"title": "Newton’s Laws", "description": "Physics topic", "topic_id": topic_id})
    assert response.status_code == 200
    assert response.json()["title"] == "Newton’s Laws"

def test_get_subtopics():
    topic_response = client.post("/topics/", json={"title": "History", "description": "World history"})
    topic_id = topic_response.json()["id"]

    client.post("/subtopics/", json={"title": "WW2", "description": "Second World War", "topic_id": topic_id})
    response = client.get(f"/topics/{topic_id}/subtopics")
    
    assert response.status_code == 200
    assert isinstance(response.json(), list)
