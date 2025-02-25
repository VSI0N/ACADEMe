from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_user_signup():
    response = client.post("/auth/signup", json={"email": "testuser@example.com", "password": "password123"})
    assert response.status_code == 200
    assert "message" in response.json()

def test_user_login():
    response = client.post("/auth/login", json={"email": "testuser@example.com", "password": "password123"})
    assert response.status_code == 200
    assert "token" in response.json()
