from firebase_admin import auth, firestore
from models.user_model import UserCreate, UserLogin, TokenResponse
from utils.auth import create_jwt_token, verify_password, hash_password
from fastapi import HTTPException
import datetime

db = firestore.client()

TOKEN_EXPIRY = 10**9  # 30+ years in seconds (practically never expires)

async def register_user(user: UserCreate):
    """Registers a user in Firebase Auth & Firestore."""
    try:
        hashed_password = hash_password(user.password)

        # Create user in Firebase Auth
        user_record = auth.create_user(email=user.email, password=user.password)

        # Prepare user data
        user_data = {
            "id": user_record.uid,
            "name": user.name,
            "email": user.email,
            "student_class": user.student_class,
            "password": hashed_password,
            "photo_url": user.photo_url
        }

        # Store user in Firestore
        db.collection("users").document(user_record.uid).set(user_data)

        # ✅ Generate JWT token
        token = create_jwt_token(
            {
                "id": user_record.uid,
                "email": user.email,
                "student_class": user.student_class,
                "name": user.name,  # ✅ Fixed
                "photo_url": user.photo_url,
            }
        )

        return TokenResponse(
            access_token=token,
            token_type="bearer",
            expires_in=TOKEN_EXPIRY,
            created_at=datetime.datetime.utcnow().isoformat(),
            email=user.email,
            student_class=user.student_class,
            name=user.name,
            photo_url=user.photo_url
        )

    except auth.EmailAlreadyExistsError:
        raise HTTPException(status_code=400, detail="Email already exists")
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


async def login_user(user: UserLogin):
    """Verifies user login credentials and returns a JWT token."""
    try:
        user_docs = list(db.collection("users").where("email", "==", user.email).limit(1).stream())

        if not user_docs:
            raise HTTPException(status_code=401, detail="Invalid credentials")

        user_data = user_docs[0].to_dict()

        # ✅ Verify password correctly
        if not verify_password(user.password, user_data["password"]):
            raise HTTPException(status_code=401, detail="Invalid credentials")

        # ✅ Generate JWT token (Include photo_url)
        token = create_jwt_token(
            {
                "id": user_data["id"],
                "email": user.email,
                "student_class": user_data["student_class"],
                "name": user_data.get("name", ""),
                "photo_url": user_data.get("photo_url", None),
            }
        )

        return TokenResponse(
            access_token=token,
            token_type="bearer",
            expires_in=TOKEN_EXPIRY,
            created_at=datetime.datetime.utcnow().isoformat(),
            email=user.email,
            student_class=user_data["student_class"],
            name=user_data["name"],
            photo_url=user_data.get("photo_url", None),
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
