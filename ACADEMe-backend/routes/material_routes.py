from fastapi import APIRouter, File, UploadFile, Form, Depends, HTTPException
import cloudinary.uploader
from utils.auth import get_current_user
from services.material_service import MaterialService
from models.material_model import MaterialCreate
import mimetypes

router = APIRouter(prefix="/courses", tags=["Courses & Topics"])

@router.post("/{course_id}/topics/{topic_id}/materials/upload/")
async def upload_file(
    course_id: str,
    topic_id: str,
    file: UploadFile = File(...),
    type: str = Form(...),
    category: str = Form(...),
    optional_text: str = Form(None),
    is_subtopic: bool = Form(False),
    subtopic_id: str = Form(None),
    user: dict = Depends(get_current_user)
):
    """Uploads a file to Cloudinary and stores the URL in Firestore."""

    try:
        # ✅ Check file validity
        if not file:
            raise HTTPException(status_code=400, detail="File is required.")

        # ✅ Upload file to Cloudinary
        upload_result = cloudinary.uploader.upload(file.file)
        file_url = upload_result.get("secure_url")

        if not file_url:
            raise HTTPException(status_code=500, detail="Failed to upload file to Cloudinary.")

        # ✅ Determine file type
        file_type = file.content_type.split('/')[0] if file.content_type else None
        if not file_type:
            guessed_type, _ = mimetypes.guess_type(file.filename)
            file_type = guessed_type.split('/')[0] if guessed_type else "unknown"

        # ✅ Prepare material data
        material_data = MaterialCreate(
            type=type if type else file_type,
            category=category,
            content=file_url,
            optional_text=optional_text or f"File '{file.filename}' uploaded successfully!"
        ).model_dump()

        # ✅ Save to Firestore
        return MaterialService.add_material(course_id, topic_id, material_data, is_subtopic, subtopic_id)

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"File upload failed: {str(e)}")
