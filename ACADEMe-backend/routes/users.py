from fastapi import APIRouter, Depends, HTTPException
from models.user_model import UserCreate, UserLogin, TokenResponse, UserUpdateClass
from services.auth_service import register_user, login_user
from utils.auth import get_current_user
from firebase_admin import firestore

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
    return {
        "id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "student_class": user["student_class"],
        "photo_url": user.get("photo_url", None)  # Handle missing photo_url gracefully
    }

@router.patch("/update-class/")
async def update_user_class(update_data: UserUpdateClass, user: dict = Depends(get_current_user)):
    """Updates the class of the logged-in user."""
    user_id = user["id"]  # Get the logged-in user's ID
    user_ref = db.collection("users").document(user_id)

    # Check if user exists
    user_doc = user_ref.get()
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User not found")

    # Update class field
    user_ref.update({"student_class": update_data.new_class})

    return {"message": "Class updated successfully", "new_class": update_data.new_class}
