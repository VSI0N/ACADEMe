import asyncio
from typing import List
import firebase_admin
from firebase_admin import firestore
from utils.auth import get_current_user
from services.auth_service import fetch_admin_ids, send_otp, send_reset_otp, reset_password
from fastapi import APIRouter, Depends, HTTPException
from services.progress_service import delete_user_progress
from services.auth_service import register_user, login_user
from models.user_model import UserCreate, UserLogin, TokenResponse, UserUpdateClass
from pydantic import BaseModel, EmailStr

router = APIRouter(prefix="/users", tags=["Users & Authentication"])

db = firestore.client()

# Model for OTP request
class OTPRequest(BaseModel):
    email: EmailStr

# Model for user registration with OTP
class UserCreateWithOTP(UserCreate):
    otp: str

# Model for forgot password OTP request
class ForgotPasswordRequest(BaseModel):
    email: EmailStr

# Model for password reset with OTP
class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: str

@router.post("/send-otp")
async def send_otp_endpoint(request: OTPRequest):
    """Send OTP to email for registration verification."""
    try:
        result = await send_otp(request.email)
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/forgot-password")
async def forgot_password_endpoint(request: ForgotPasswordRequest):
    """Send OTP to email for password reset."""
    try:
        result = await send_reset_otp(request.email)
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/reset-password")
async def reset_password_endpoint(request: ResetPasswordRequest):
    """Reset password after OTP verification."""
    try:
        result = await reset_password(request.email, request.otp, request.new_password)
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/signup", response_model=TokenResponse)
async def signup(user: UserCreateWithOTP):
    """Registers a new user with OTP verification and returns an authentication token."""
    try:
        # Extract OTP from the request
        otp = user.otp
        
        # Create UserCreate object without OTP
        user_data = UserCreate(
            name=user.name,
            email=user.email,
            password=user.password,
            student_class=user.student_class,
            photo_url=user.photo_url
        )
        
        # Register user with OTP verification
        created_user = await register_user(user_data, otp)
        if not created_user:
            raise HTTPException(status_code=400, detail="User registration failed")
        return created_user
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

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

    return {"message": "Class updated successfully after progress reset.", "new_class": update_data.new_class}

@router.get("/admins", response_model=List[str])
async def get_admin_ids():
    """Fetch all document IDs from the 'admins' collection."""
    try:
        admin_ids = await fetch_admin_ids()
        return admin_ids
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
