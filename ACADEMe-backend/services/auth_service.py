import os
import datetime
import random
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from fastapi import HTTPException
from firebase_admin import auth, firestore
from models.user_model import UserCreate, UserLogin, TokenResponse
from utils.auth import create_jwt_token, verify_password, hash_password

db = firestore.client()

TOKEN_EXPIRY = 10**9  # 30+ years in seconds (practically never expires)

# Email configuration - replace with your SMTP settings
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
EMAIL_ADDRESS = os.getenv("EMAIL_ADDRESS")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD")

# Validate email configuration on startup
if not EMAIL_ADDRESS:
    raise ValueError("EMAIL_ADDRESS environment variable is not set")
if not EMAIL_PASSWORD:
    raise ValueError("EMAIL_PASSWORD environment variable is not set")

# In-memory OTP storage (use Redis in production)
otp_storage = {}

def generate_otp():
    """Generate a 6-digit OTP."""
    return str(random.randint(100000, 999999))

def send_otp_email(email: str, otp: str):
    """Send OTP via email."""
    try:
        # Validate email credentials
        if not EMAIL_ADDRESS or not EMAIL_PASSWORD:
            print("Email credentials not configured properly")
            return False
            
        msg = MIMEMultipart()
        msg['From'] = EMAIL_ADDRESS
        msg['To'] = email
        msg['Subject'] = "Your OTP for Registration"
        
        body = f"""
        Your OTP for account registration is: {otp}
        
        This OTP will expire in 10 minutes.
        
        Please enter this OTP to complete your registration.
        """
        
        msg.attach(MIMEText(body, 'plain'))
        
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        text = msg.as_string()
        server.sendmail(EMAIL_ADDRESS, email, text)
        server.quit()
        
        print(f"OTP sent successfully to {email}")
        return True
    except smtplib.SMTPAuthenticationError as e:
        print(f"SMTP Authentication failed: {e}")
        return False
    except smtplib.SMTPException as e:
        print(f"SMTP error occurred: {e}")
        return False
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False

async def send_otp(email: str):
    """Generate and send OTP to email."""
    try:
        # Validate email credentials first
        if not EMAIL_ADDRESS or not EMAIL_PASSWORD:
            raise HTTPException(
                status_code=500, 
                detail="Email service not configured. Please contact administrator."
            )
        
        # Check if email already exists in Firebase Auth
        try:
            auth.get_user_by_email(email)
            raise HTTPException(status_code=400, detail="Email already exists")
        except auth.UserNotFoundError:
            pass  # Email doesn't exist, continue
        
        # Generate OTP
        otp = generate_otp()
        
        # Store OTP with expiry (10 minutes)
        otp_storage[email] = {
            "otp": otp,
            "expires_at": datetime.datetime.utcnow() + datetime.timedelta(minutes=10)
        }
        
        # Send OTP via email
        if send_otp_email(email, otp):
            return {"message": "OTP sent successfully", "email": email}
        else:
            # Clean up OTP if email sending failed
            if email in otp_storage:
                del otp_storage[email]
            raise HTTPException(
                status_code=500, 
                detail="Failed to send OTP. Please check your email address and try again."
            )
            
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in send_otp: {e}")
        raise HTTPException(status_code=500, detail=str(e))

async def register_user(user: UserCreate, otp: str):
    """Registers a user after OTP verification."""
    try:
        # Verify OTP
        if user.email not in otp_storage:
            raise HTTPException(status_code=400, detail="OTP not found. Please request a new OTP.")
        
        stored_otp_data = otp_storage[user.email]
        
        # Check if OTP has expired
        if datetime.datetime.utcnow() > stored_otp_data["expires_at"]:
            del otp_storage[user.email]  # Clean up expired OTP
            raise HTTPException(status_code=400, detail="OTP has expired. Please request a new OTP.")
        
        # Verify OTP
        if otp != stored_otp_data["otp"]:
            raise HTTPException(status_code=400, detail="Invalid OTP")
        
        # OTP verified, proceed with registration
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

        # Clean up OTP after successful registration
        del otp_storage[user.email]

        # Generate JWT token
        token = create_jwt_token(
            {
                "id": user_record.uid,
                "email": user.email,
                "student_class": user.student_class,
                "name": user.name,
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
    except HTTPException:
        raise
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

async def fetch_admin_ids():
    """Fetch all document IDs from the 'admins' collection in Firestore."""
    try:
        admins_ref = db.collection("admins")
        docs = admins_ref.stream()  # Ensure this is correct

        admin_ids = [doc.id for doc in docs]
        return admin_ids

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))