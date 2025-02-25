import cloudinary.uploader
import uuid

class CloudinaryService:
    @staticmethod
    async def upload_file(file, folder: str):
        """Uploads file to Cloudinary and returns the URL."""
        public_id = f"{folder}/{uuid.uuid4()}"  # Generate a unique filename

        result = cloudinary.uploader.upload(
            file.file,  # ✅ Pass as stream
            folder=folder,
            public_id=public_id,
            resource_type="auto"  # ✅ Ensures Cloudinary detects the correct type
        )

        return result["secure_url"]  # Return the Cloudinary URL
