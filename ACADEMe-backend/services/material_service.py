import os
import json
import uuid
from datetime import datetime
from fastapi import HTTPException
from firebase_admin import firestore
from services.course_service import CourseService
from models.material_model import MaterialResponse

db = firestore.client()

MATERIALS_JSON_PATH = "assets/materials.json"

class MaterialService:
    @staticmethod
    async def add_material(
        course_id: str, 
        topic_id: str, 
        material: dict,  
        is_subtopic: bool = False, 
        subtopic_id: str = None
    ) -> MaterialResponse:
        """Adds a material under a topic or subtopic in Firestore with multilingual support."""
        try:
            material_id = str(uuid.uuid4())
            material["id"] = material_id
            material["created_at"] = datetime.utcnow().isoformat()
            material["updated_at"] = datetime.utcnow().isoformat()

            # 🔹 Detect language only if `text_content` or `optional_text` exist
            detected_lang = "en"
            text_fields = [material.get("text_content", ""), material.get("optional_text", "")]
            if any(text_fields):
                detected_lang = await CourseService.detect_language(text_fields) or "en"

            # 🔹 Organize translations under "languages" key
            languages = {
                detected_lang: {
                    "content": material.get("content", ""),
                    "optional_text": material.get("optional_text", ""),
                }
            }

            # 🔹 Translate only `content` if type == "text", and always translate `optional_text`
            target_languages = ["fr", "es", "de", "zh", "ar", "hi", "en"]

            translation_tasks = {
                lang: {
                    "content": CourseService.translate_text(material["content"], lang) if material["type"] == "text" else None,
                    "optional_text": CourseService.translate_text(material["optional_text"], lang) if material.get("optional_text") else None,
                }
                for lang in target_languages
            }

            for lang in target_languages:
                languages[lang] = {
                    "content": await translation_tasks[lang]["content"] if translation_tasks[lang]["content"] else material["content"],  # ✅ Keeps original content if not text
                    "optional_text": await translation_tasks[lang]["optional_text"] if translation_tasks[lang]["optional_text"] else "",
                }
            
            material["languages"] = languages  # ✅ Store translations properly

            # 🔹 Determine Firestore reference
            if is_subtopic and subtopic_id:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("subtopics")
                    .document(subtopic_id)
                    .collection("materials")
                    .document(material_id)
                )
            else:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("materials")
                    .document(material_id)
                )

            ref.set(material, merge=True)

            # ✅ Update materials.json
            materials = {}
            if os.path.exists(MATERIALS_JSON_PATH):
                with open(MATERIALS_JSON_PATH, "r", encoding="utf-8") as f:
                    materials = json.load(f)

            materials[material_id] = material["content"]  # Store material ID and content

            with open(MATERIALS_JSON_PATH, "w", encoding="utf-8") as f:
                json.dump(materials, f, indent=4, ensure_ascii=False)

            return MaterialResponse(**material)

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error adding material: {str(e)}")

    @staticmethod
    async def get_materials(
        course_id: str, 
        topic_id: str, 
        target_language: str = "en",
        is_subtopic: bool = False, 
        subtopic_id: str = None
    ) -> list[MaterialResponse]:
        """Fetches all materials under a topic or subtopic in the requested language."""
        try:
            # 🔹 Determine Firestore reference
            if is_subtopic and subtopic_id:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("subtopics")
                    .document(subtopic_id)
                    .collection("materials")
                )
            else:
                ref = (
                    db.collection("courses")
                    .document(course_id)
                    .collection("topics")
                    .document(topic_id)
                    .collection("materials")
                )

            materials = ref.stream()
            material_list = []

            for material in materials:
                material_data = material.to_dict()

                # 🔹 Ensure "languages" key exists
                if "languages" not in material_data:
                    continue  

                lang_data = material_data["languages"].get(target_language, material_data["languages"].get("en", {}))

                # 🔹 Construct material response
                material_list.append({
                    "id": material.id,
                    "type": material_data.get("type", ""),
                    "category": material_data.get("category", ""),
                    "content": lang_data.get("content", material_data["content"]),  # ✅ Use translated content if available
                    "optional_text": lang_data.get("optional_text", ""),
                    "created_at": material_data["created_at"],
                    "updated_at": material_data["updated_at"],
                })

            return [MaterialResponse(**material) for material in material_list]

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching materials: {str(e)}")
