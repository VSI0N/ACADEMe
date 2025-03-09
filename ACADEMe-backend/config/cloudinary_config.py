import os
import cloudinary
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Debugging: Print environment variables inside Python
print("CLOUDINARY_CLOUD_NAME:", os.getenv("CLOUDINARY_CLOUD_NAME"))
print("CLOUDINARY_API_KEY:", os.getenv("CLOUDINARY_API_KEY"))
print("CLOUDINARY_API_SECRET:", os.getenv("CLOUDINARY_API_SECRET"))

# Configure Cloudinary
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True,
)
