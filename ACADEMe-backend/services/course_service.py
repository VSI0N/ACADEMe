from firebase_admin import firestore
from models.course_model import CourseCreate, CourseResponse
from fastapi import HTTPException
import uuid
from datetime import datetime
import httpx
from langdetect import detect, DetectorFactory

db = firestore.client()
DetectorFactory.seed = 0

class CourseService:
    @staticmethod
    async def translate_text(text: str, target_lang: str) -> str:
        """Translates text using the `/api/translate_response` endpoint."""
        if not text:
            return text  # ✅ Return original text if empty

        url = "http://127.0.0.1:8000/api/translate_response"
        payload = {"text": text, "target_language": target_lang}

        print(f"🔍 Sending translation request: {payload}")  # ✅ Debug log

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, params=payload)  # ✅ Use `params=`
                response.raise_for_status()
                return response.json().get("response", text)
        except httpx.HTTPStatusError as e:
            print(f"🔥 Translation API error: {e.response.status_code} - {e.response.text}")
        except httpx.RequestError as e:
            print(f"⚠️ Connection error: {e}")
        except Exception as e:
            print(f"❌ Unexpected error: {e}")

        return text  # ✅ Return original text on failure

    @staticmethod
    async def detect_language(texts: list[str]) -> str:
        """Detects language from a list of text fields, defaults to English on failure."""
        for text in texts:
            if text:  # Ensure we have text to analyze
                try:
                    return detect(text)  # Detect language from the first non-empty text
                except Exception:
                    continue  # If detection fails, try the next text
        return "en"

    @staticmethod
    async def create_course(course: CourseCreate):
        """Creates a new course with multilingual support."""
        course_id = str(uuid.uuid4())
        course_ref = db.collection("courses").document(course_id)

        if course_ref.get().exists:
            raise HTTPException(status_code=400, detail="Course already exists")

        now = datetime.utcnow()

        # 🔍 Detect language dynamically
        detected_lang = await CourseService.detect_language([course.title, course.description])
        translations = {
            detected_lang: {
                "title": course.title,
                "description": course.description,
            }
        }

        # 🌎 Translate into other languages (excluding detected language)
        target_languages = ["fr", "es", "de", "zh", "ar", "hi", "en"]
        target_languages.remove(detected_lang)

        # 🚀 Run all translation tasks in parallel
        translation_tasks = {
            lang: {
                "title": CourseService.translate_text(course.title, lang),
                "description": CourseService.translate_text(course.description, lang),
            }
            for lang in target_languages
        }

        # 🔄 Wait for all translations to complete (parallel execution)
        for lang in target_languages:
            translations[lang] = {
                "title": await translation_tasks[lang]["title"],  # ✅ Fix: No double await
                "description": await translation_tasks[lang]["description"],
            }

        course_data = {
            "id": course_id,
            "class_name": course.class_name,
            "created_at": now,
            "updated_at": now,
            "languages": translations,
        }

        course_ref.set(course_data)
        return CourseResponse(
            **course_data,
            title=translations[detected_lang]["title"],
            description=translations[detected_lang]["description"]
        )

    @staticmethod
    def get_courses(target_language: str = "en"):
        """Fetches courses and returns them in the requested language."""
        courses_ref = db.collection("courses").stream()
        
        courses = []
        for doc in courses_ref:
            course_data = doc.to_dict()

            if "languages" not in course_data:
                raise HTTPException(status_code=500, detail=f"Missing 'languages' field in course {doc.id}")

            # 🏷️ Fetch content in requested language, fallback to English
            lang_data = course_data["languages"].get(target_language, course_data["languages"].get("en", {}))

            courses.append(CourseResponse(
                id=course_data["id"],
                title=lang_data.get("title", ""),
                class_name=course_data["class_name"],
                description=lang_data.get("description", ""),
                created_at=course_data["created_at"].isoformat(),  # ✅ Convert Firestore timestamp
                updated_at=course_data["updated_at"].isoformat(),  # ✅ Convert Firestore timestamp
            ))

        return courses
