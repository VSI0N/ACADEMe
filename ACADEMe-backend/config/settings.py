import os
from dotenv import load_dotenv

load_dotenv()

FIREBASE_CRED_PATH = os.getenv("FIREBASE_CRED_PATH")
GOOGLE_GEMINI_API_KEY = os.getenv("GOOGLE_GEMINI_API_KEY")
