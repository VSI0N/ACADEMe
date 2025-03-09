import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    """Schema for user registration."""
    email: EmailStr
    password: str
    student_class: str  # ✅ Added to store the class of the student
    name: str
    photo_url: Optional[str]

class UserLogin(BaseModel):
    """Schema for user login."""
    email: EmailStr
    password: str

class UserUpdateClass(BaseModel):
    new_class: str

class TokenResponse(BaseModel):
    """Schema for JWT token response."""
    access_token: str
    token_type: str = "bearer"
    expires_in: int  # Token expiry duration in seconds
    created_at: datetime.datetime  # Timestamp of when the token was created
    email: EmailStr  # Include email in response
    student_class: str  # Include class in response
    name: str  # ✅ Fix missing name field
    photo_url: Optional[str]

    class Config:
        arbitrary_types_allowed = True
        from_attributes = True
