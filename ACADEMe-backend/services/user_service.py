from firebase_admin import auth
from models.user_model import UserCreate, UserLogin
from utils.auth import create_jwt_token, hash_password, verify_password
from fastapi import HTTPException

def create_user(user: UserCreate):
    try:
        firebase_user = auth.create_user(email=user.email, password=user.password)
        return {"message": "User created successfully", "uid": firebase_user.uid}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

def login_user(user: UserLogin):
    try:
        firebase_user = auth.get_user_by_email(user.email)
        
        # Simulated password verification (Firebase handles authentication separately)
        if not firebase_user:
            raise HTTPException(status_code=401, detail="Invalid credentials")

        # Generate JWT token
        token = create_jwt_token({"sub": firebase_user.uid, "email": user.email})
        return {"email": user.email, "token": token}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
