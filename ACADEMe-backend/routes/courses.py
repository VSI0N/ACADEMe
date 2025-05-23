from utils.auth import get_current_user
from services.course_service import CourseService
from fastapi import APIRouter, Depends, HTTPException
from utils.class_filter import filter_courses_by_class
from models.course_model import CourseCreate, CourseResponse

router = APIRouter(prefix="/courses", tags=["Courses"])

@router.post("/", response_model=CourseResponse)
async def create_course(course: CourseCreate, user: dict = Depends(get_current_user)):
    """Creates a new course (Admin-only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")

    created_course = await CourseService.create_course(course)

    if not created_course:
        raise HTTPException(status_code=400, detail="Course creation failed")
    
    return created_course

@router.get("/", response_model=list[CourseResponse])
async def get_courses(target_language: str = "en", user: dict = Depends(get_current_user)):
    """Fetches all courses in the specified language."""
    all_courses = CourseService.get_courses(target_language)
    filtered_courses = filter_courses_by_class(all_courses, user["student_class"])
    
    # Convert Pydantic models to dictionaries if needed
    if filtered_courses and hasattr(filtered_courses[0], 'dict'):
        filtered_courses = [course.dict() for course in filtered_courses]
    
    # Sort courses by created_at in ascending order (oldest first)
    return sorted(filtered_courses, key=lambda x: x['created_at'])