from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_signup():
    response = client.post("/auth/signup", json={
        "name": "Test User",
        "email": "test@example.com",
        "password": "password123",
        "student_class": "5"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_login():
    response = client.post("/auth/login", json={
        "email": "test@example.com",
        "password": "password123"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()
