import asyncio
from typing import List
import firebase_admin
from firebase_admin import firestore
from utils.auth import get_current_user
from services.auth_service import fetch_admin_ids
from fastapi import APIRouter, Depends, HTTPException
from services.progress_service import delete_user_progress
from services.auth_service import register_user, login_user
from models.user_model import UserCreate, UserLogin, TokenResponse, UserUpdateClass

router = APIRouter(prefix="/users", tags=["Users & Authentication"])

db = firestore.client()

@router.post("/signup", response_model=TokenResponse)
async def signup(user: UserCreate):
    """Registers a new user and returns an authentication token."""
    created_user = await register_user(user)  # Await the async function
    if not created_user:
        raise HTTPException(status_code=400, detail="User registration failed")
    return created_user

@router.post("/login", response_model=TokenResponse)
async def login(user: UserLogin):
    """Logs in an existing user and returns an authentication token."""
    logged_in_user = await login_user(user)  # Await the async function
    if not logged_in_user:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return logged_in_user

@router.get("/me")
async def get_current_user_details(user: dict = Depends(get_current_user)):
    """Fetches the currently authenticated user's details."""
    if not user:  # Ensure user is not None or an empty dict
        raise HTTPException(status_code=401, detail="User not authenticated")

    return {
        "id": user.get("id"),  # Use .get() to avoid KeyError
        "name": user.get("name"),
        "email": user.get("email"),
        "student_class": user.get("student_class"),
        "photo_url": user.get("photo_url", None)  # Handle missing photo_url gracefully
    }

@router.patch("/update_class/")
async def update_user_class(update_data: UserUpdateClass, user: dict = Depends(get_current_user)):
    """Deletes user progress and updates their class."""
    user_id = user["id"]  # Get the logged-in user's ID
    user_ref = db.collection("users").document(user_id)

    # Check if user exists
    user_doc = user_ref.get()
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User not found")

    # 🔄 Delete user's progress before updating class
    await delete_user_progress(user_id)

    # ✅ Update class field asynchronously
    loop = asyncio.get_running_loop()
    await loop.run_in_executor(None, lambda: user_ref.update({"student_class": update_data.new_class}))

    return {"message": "Class updated successfully after progress reset", "new_class": update_data.new_class}

@router.get("/admins", response_model=List[str])
async def get_admin_ids():
    """Fetch all document IDs from the 'admins' collection."""
    try:
        admin_ids = await fetch_admin_ids()
        return admin_ids
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    