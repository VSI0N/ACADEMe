from firebase_admin import firestore
from models.course_model import CourseCreate, CourseResponse
from fastapi import HTTPException
import uuid
from datetime import datetime  # ✅ Import datetime

db = firestore.client()

class CourseService:
    @staticmethod
    def create_course(course: CourseCreate):
        """Creates a new course in Firestore."""
        course_id = str(uuid.uuid4())  # ✅ Generate UUID here
        course_ref = db.collection("courses").document(course_id)

        if course_ref.get().exists:
            raise HTTPException(status_code=400, detail="Course already exists")

        now = datetime.utcnow()  # ✅ Get current timestamp
        course_data = course.dict()
        course_data["id"] = course_id  # ✅ Assign generated ID
        course_data["created_at"] = now  # ✅ Store timestamps
        course_data["updated_at"] = now  # ✅ Store timestamps

        course_ref.set(course_data)
        return CourseResponse(**course_data)

    @staticmethod
    def get_courses():
        """Fetches all courses from Firestore and adds missing fields if necessary."""
        courses_ref = db.collection("courses").stream()
        
        courses = []
        for doc in courses_ref:
            course_data = doc.to_dict()

            # 🔍 Ensure all required fields exist before creating CourseResponse
            required_fields = ["id", "title", "class_name", "description", "created_at", "updated_at"]
            for field in required_fields:
                if field not in course_data:
                    raise HTTPException(
                        status_code=500, 
                        detail=f"Missing required field '{field}' in course document {doc.id}"
                    )

            courses.append(CourseResponse(**course_data))  # ✅ Now safe to convert

        return courses
