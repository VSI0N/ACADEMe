import firebase_admin
from firebase_admin import credentials, firestore
import dotenv
import os

# Load environment variables
dotenv.load_dotenv()

# Get Firebase credentials path from .env
FIREBASE_CRED_PATH = os.getenv("FIREBASE_CRED_PATH")

# Ensure the environment variable is set
if not FIREBASE_CRED_PATH:
    raise ValueError("FIREBASE_CRED_PATH is not set in .env file!")

# Check if Firebase is already initialized
if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_CRED_PATH)
    firebase_admin.initialize_app(cred)

# Initialize Firestore client
db = firestore.client()

print("Firebase initialized successfully!")
