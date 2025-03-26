import os
import jwt
import firebase_admin
from passlib.context import CryptContext
from datetime import datetime, timedelta
from firebase_admin import auth, firestore
from fastapi import HTTPException, Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# ✅ Initialize Firebase Admin (Only if not initialized)
if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()  # ✅ Move this below Firebase initialization

# ✅ Environment Variables
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your_secret_key_here")
JWT_ALGORITHM = "HS256"
DEFAULT_EXPIRY_SECONDS = 10**9  # 30+ hours

# ✅ Password Hashing Setup
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

security = HTTPBearer()

# ✅ Firebase Token Verification
def verify_firebase_token(token: str):
    """Verifies Firebase ID token."""
    try:
        decoded_token = auth.verify_id_token(token, check_revoked=True)
        return decoded_token
    except auth.RevokedIdTokenError:
        raise HTTPException(status_code=401, detail="Firebase token has been revoked")
    except auth.ExpiredIdTokenError:
        raise HTTPException(status_code=401, detail="Expired Firebase token")
    except auth.InvalidIdTokenError:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Firebase token error: {str(e)}")

# ✅ JWT Token Generation
def create_jwt_token(data: dict, expiry_seconds: int = DEFAULT_EXPIRY_SECONDS):
    """Creates a JWT token with an optional expiry."""
    payload = data.copy()
    payload["exp"] = datetime.utcnow() + timedelta(seconds=expiry_seconds)

    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

# ✅ JWT Token Verification
def verify_jwt_token(token: str):
    """Verifies and decodes a JWT token."""
    try:
        decoded_token = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return decoded_token
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# ✅ Get Current User (Supports Firebase, JWT & Admin Check)
def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security)):
    """Extracts the current user from either Firebase token or JWT token & checks admin status."""
    token = credentials.credentials

    try:
        # 🔹 Try verifying as a Firebase token
        user = verify_firebase_token(token)
    except HTTPException:
        try:
            # 🔹 If Firebase fails, try verifying as a JWT token
            user = verify_jwt_token(token)
        except HTTPException:
            raise HTTPException(status_code=401, detail="Invalid authentication token")

    email = user.get("email")
    if not email:
        raise HTTPException(status_code=401, detail="Email not found in token")

    # 🔹 Check if the user is an admin in Firestore
    admin_ref = db.collection("admins").document(email).get()
    user["role"] = "admin" if admin_ref.exists else "student"

    return user

# ✅ Password Hashing
def hash_password(password: str):
    """Hashes the password using bcrypt."""
    return pwd_context.hash(password)

# ✅ Password Verification
def verify_password(plain_password: str, hashed_password: str):
    """Verifies the password against the hashed version."""
    return pwd_context.verify(plain_password, hashed_password)
