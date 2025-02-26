import os
from dotenv import load_dotenv

load_dotenv()

FIREBASE_CRED_PATH = os.getenv("FIREBASE_CRED_PATH")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
