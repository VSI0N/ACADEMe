from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_create_discussion():
    response = client.post("/discussions/", json={"topic_id": "123", "title": "Physics Concepts", "created_by": "user_1"})
    assert response.status_code == 200
    assert response.json()["title"] == "Physics Concepts"

def test_get_discussions():
    response = client.get("/topics/123/discussions")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_create_message():
    discussion_response = client.post("/discussions/", json={"topic_id": "456", "title": "Mathematics Doubts", "created_by": "user_2"})
    discussion_id = discussion_response.json()["id"]

    response = client.post("/messages/", json={
        "discussion_id": discussion_id,
        "user_id": "user_3",
        "content": "Can someone explain calculus?"
    })
    assert response.status_code == 200
    assert response.json()["content"] == "Can someone explain calculus?"

def test_get_messages():
    discussion_response = client.post("/discussions/", json={"topic_id": "789", "title": "History Questions", "created_by": "user_4"})
    discussion_id = discussion_response.json()["id"]

    client.post("/messages/", json={
        "discussion_id": discussion_id,
        "user_id": "user_5",
        "content": "When did World War 2 start?"
    })
    response = client.get(f"/discussions/{discussion_id}/messages")
    
    assert response.status_code == 200
    assert isinstance(response.json(), list)
