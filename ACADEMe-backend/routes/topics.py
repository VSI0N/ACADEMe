import uuid
from datetime import datetime
from utils.auth import get_current_user
from services.topic_service import TopicService
from services.material_service import MaterialService
from utils.cloudinary_service import CloudinaryService
from models.topic_model import TopicCreate, SubtopicCreate
from models.material_model import MaterialCreate, MaterialResponse
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Query

router = APIRouter(prefix="/courses", tags=["Courses & Topics"])

### 📌 TOPIC ROUTES ###

@router.post("/{course_id}/topics/", response_model=dict)
async def add_topic(course_id: str, topic: TopicCreate, user: dict = Depends(get_current_user)):
    """Add a new topic to a course (Admin-only) with multilingual support."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    topic_id = str(uuid.uuid4())
    return await TopicService.create_topic(course_id, topic_id, topic)

@router.get("/{course_id}/topics/", response_model=list)
async def fetch_topics(course_id: str, target_language: str = Query("en"), user: dict = Depends(get_current_user)):
    """Fetches all topics under a specific course in the requested language."""
    topics = await TopicService.get_all_topics(course_id, target_language)
    # Sort topics by created_at in ascending order (oldest first)
    return sorted(topics, key=lambda x: x['created_at'])

### 📌 SUBTOPIC ROUTES ###

@router.post("/{course_id}/topics/{topic_id}/subtopics/", response_model=dict)
async def add_subtopic(course_id: str, topic_id: str, subtopic: SubtopicCreate, user: dict = Depends(get_current_user)):
    """Add a new subtopic with multilingual support (Admin-only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    subtopic_id = str(uuid.uuid4())
    return await TopicService.create_subtopic(course_id, topic_id, subtopic_id, subtopic)

@router.get("/{course_id}/topics/{topic_id}/subtopics/", response_model=list)
async def fetch_subtopics(
    course_id: str, 
    topic_id: str, 
    target_language: str = Query("en"), 
    user: dict = Depends(get_current_user)
):
    """Fetches all subtopics under a topic in the requested language."""
    subtopics = await TopicService.get_subtopics_by_topic(course_id, topic_id, target_language)
    # Sort subtopics by created_at in ascending order (oldest first)
    return sorted(subtopics, key=lambda x: x['created_at'])

### 📌 STUDY MATERIAL ROUTES (FOR TOPICS & SUBTOPICS) ###

@router.post("/{course_id}/topics/{topic_id}/materials/", response_model=MaterialResponse)
async def add_material_to_topic(
    course_id: str,
    topic_id: str,
    type: str = Form(...),
    category: str = Form(...),
    optional_text: str = Form(None),
    text_content: str = Form(None),
    file: UploadFile = File(None),
    user: dict = Depends(get_current_user)
):
    """Add material to a topic (Admin-only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    material_data = await handle_material_upload(course_id, topic_id, None, type, category, optional_text, text_content, file)

    if not material_data:
        raise HTTPException(status_code=500, detail="Material data processing failed.")

    return await MaterialService.add_material(course_id, topic_id, material_data)

@router.get("/{course_id}/topics/{topic_id}/materials/", response_model=list[MaterialResponse])
async def fetch_materials_from_topic(
    course_id: str, 
    topic_id: str, 
    target_language: str = Query("en"), 
    user: dict = Depends(get_current_user)
):
    """Fetches all study materials under a topic in the requested language."""
    materials = await MaterialService.get_materials(course_id, topic_id, target_language=target_language)
    # Sort materials by created_at in ascending order (oldest first)
    return sorted(materials, key=lambda x: x.created_at)

@router.post("/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/materials/", response_model=MaterialResponse)
async def add_material_to_subtopic(
    course_id: str,
    topic_id: str,
    subtopic_id: str,
    type: str = Form(...),
    category: str = Form(...),
    optional_text: str = Form(None),
    text_content: str = Form(None),
    file: UploadFile = File(None),
    user: dict = Depends(get_current_user)
):
    """Add material to a subtopic (Admin-only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    material_data = await handle_material_upload(course_id, topic_id, subtopic_id, type, category, optional_text, text_content, file)

    if not material_data:
        raise HTTPException(status_code=500, detail="Material data processing failed.")

    return await MaterialService.add_material(course_id, topic_id, material_data, is_subtopic=True, subtopic_id=subtopic_id)

@router.get("/{course_id}/topics/{topic_id}/subtopics/{subtopic_id}/materials/", response_model=list[MaterialResponse])
async def fetch_materials_from_subtopic(
    course_id: str, 
    topic_id: str, 
    subtopic_id: str, 
    target_language: str = Query("en"), 
    user: dict = Depends(get_current_user)
):
    """Fetches all study materials under a subtopic in the requested language."""
    materials = await MaterialService.get_materials(course_id, topic_id, target_language=target_language, subtopic_id=subtopic_id, is_subtopic=True)
    # Sort materials by created_at in ascending order (oldest first)
    return sorted(materials, key=lambda x: x.created_at)

### 📌 Utility Function to Handle File Uploads ###
async def handle_material_upload(
    course_id: str, topic_id: str, subtopic_id: str, type: str, category: str, optional_text: str, content: str, file: UploadFile = None
):
    """Handles file uploads and prepares material data."""
    
    type = type.lower()
    category = category.lower()
    
    file_url = None

    if type == "text":
        if not content:
            raise HTTPException(status_code=422, detail="Text content is required for 'text' type materials.")
        file_url = content

    elif type in ["image", "video", "audio", "document"]:  
        if not file:
            raise HTTPException(status_code=422, detail=f"File is required for '{type}' type materials.")

        allowed_types = {
            "image": ["image/jpeg", "image/png", "image/webp"],
            "video": ["video/mp4", "video/mkv", "video/avi"],
            "audio": ["audio/mpeg", "audio/wav", "audio/ogg"],
            "document": ["application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
        }
        if file.content_type not in allowed_types.get(type, []):
            raise HTTPException(status_code=415, detail=f"Invalid file type '{file.content_type}' for {type} materials.")

        try:
            file_url = await CloudinaryService.upload_file(file, "materials")
            if not file_url:
                raise HTTPException(status_code=500, detail="File upload failed. No URL returned.")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"File upload error: {str(e)}")
    
    else:
        raise HTTPException(status_code=400, detail="Invalid request: Provide a valid type (text, image, video, audio, document).")

    if not file_url:
        raise HTTPException(status_code=500, detail="Failed to process material content.")

    material_response = MaterialResponse(
        id=str(uuid.uuid4()),
        course_id=course_id,
        topic_id=topic_id,
        subtopic_id=subtopic_id,
        type=type,
        category=category,
        content=file_url,
        optional_text=optional_text,
        created_at=datetime.utcnow().isoformat(),
        updated_at=datetime.utcnow().isoformat(),
    )

    return material_response.model_dump()
