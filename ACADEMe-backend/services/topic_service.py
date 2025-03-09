import os
import json
import firebase_admin
from datetime import datetime
from firebase_admin import firestore
from services.course_service import CourseService
from models.topic_model import TopicCreate, SubtopicCreate

db = firestore.client()  # Firestore DB instance

TOPICS_FILE = "assets/topics.json"
SUBTOPICS_FILE = "assets/subtopics.json"

class TopicService:
    @staticmethod
    async def create_topic(course_id: str, topic_id: str, topic: TopicCreate):
        """Creates a new topic inside a course with multilingual support and updates assets/topics.json."""
        detected_lang = await CourseService.detect_language([topic.title, topic.description]) or "en"

        languages = {
            detected_lang: {"title": topic.title, "description": topic.description}
        }

        target_languages = ["fr", "es", "de", "zh", "ar", "hi", "en"]

        translation_tasks = {
            lang: {
                "title": CourseService.translate_text(topic.title, lang),
                "description": CourseService.translate_text(topic.description, lang),
            }
            for lang in target_languages
        }

        for lang in target_languages:
            languages[lang] = {
                "title": await translation_tasks[lang]["title"],
                "description": await translation_tasks[lang]["description"],
            }

        topic_data = {
            "id": topic_id,
            "created_at": datetime.utcnow(),
            "languages": languages,  # ✅ Use "languages" instead of "translations"
        }

        db.collection("courses").document(course_id).collection("topics").document(topic_id).set(topic_data)

        # 🔄 **Update `topics.json`**
        TopicService._update_json_file(TOPICS_FILE, topic_id, topic.title)

        return {"message": "Topic created successfully", "topic_id": topic_id}

    @staticmethod
    async def get_all_topics(course_id: str, target_language: str = "en"):
        """Fetches all topics for a course in the requested language."""
        topics_ref = db.collection("courses").document(course_id).collection("topics").stream()
        topics = []

        for topic in topics_ref:
            topic_data = topic.to_dict()

            if "languages" not in topic_data:
                continue  # Skip topics without language data

            # ✅ Ensure we check for `target_language` and fallback to "en"
            lang_data = topic_data["languages"].get(target_language) or topic_data["languages"].get("en", {})

            topics.append({
                "id": topic.id,
                "title": lang_data.get("title", ""),
                "description": lang_data.get("description", ""),
                "created_at": topic_data["created_at"],
            })

        return topics

    @staticmethod
    async def create_subtopic(course_id: str, topic_id: str, subtopic_id: str, subtopic: SubtopicCreate):
        """Creates a subtopic under a specific topic with multilingual support and updates assets/subtopics.json."""
        detected_lang = await CourseService.detect_language([subtopic.title, subtopic.description]) or "en"

        languages = {
            detected_lang: {"title": subtopic.title, "description": subtopic.description}
        }

        target_languages = ["fr", "es", "de", "zh", "ar", "hi", "en"]

        translation_tasks = {
            lang: {
                "title": CourseService.translate_text(subtopic.title, lang),
                "description": CourseService.translate_text(subtopic.description, lang),
            }
            for lang in target_languages
        }

        for lang in target_languages:
            languages[lang] = {
                "title": await translation_tasks[lang]["title"],
                "description": await translation_tasks[lang]["description"],
            }

        subtopic_data = {
            "id": subtopic_id,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "languages": languages,  # ✅ Store translations under "languages"
        }

        db.collection("courses").document(course_id).collection("topics").document(topic_id).collection("subtopics").document(subtopic_id).set(subtopic_data)

        # 🔄 **Update `subtopics.json`**
        TopicService._update_json_file(SUBTOPICS_FILE, subtopic_id, subtopic.title)

        return {"message": "Subtopic added successfully", "subtopic_id": subtopic_id}

    @staticmethod
    async def get_subtopics_by_topic(course_id: str, topic_id: str, target_language: str = "en"):
        """Fetches all subtopics under a topic in the requested language."""
        subtopics_ref = db.collection("courses").document(course_id).collection("topics").document(topic_id).collection("subtopics").stream()
        subtopics = []

        for subtopic in subtopics_ref:
            subtopic_data = subtopic.to_dict()

            if "languages" not in subtopic_data:
                continue  # Skip subtopics without language data

            # ✅ Ensure we check for `target_language` and fallback to "en"
            lang_data = subtopic_data["languages"].get(target_language) or subtopic_data["languages"].get("en", {})

            subtopics.append({
                "id": subtopic.id,
                "title": lang_data.get("title", ""),
                "description": lang_data.get("description", ""),
                "created_at": subtopic_data["created_at"],
            })

        return subtopics
    
    @staticmethod
    def _update_json_file(file_path: str, entry_id: str, entry_title: str):
        """Helper method to update JSON files (`topics.json` or `subtopics.json`)."""
        os.makedirs(os.path.dirname(file_path), exist_ok=True)  # ✅ Ensure `assets/` exists

        data = {}
        if os.path.exists(file_path):
            try:
                with open(file_path, "r", encoding="utf-8") as file:
                    data = json.load(file)  # ✅ Load existing data
            except json.JSONDecodeError:
                print(f"⚠️ Detected empty or invalid JSON file: {file_path}. Resetting...")
                data = {}  # ✅ Reset to empty dictionary

        data[entry_id] = entry_title  # ✅ Add new entry

        with open(file_path, "w", encoding="utf-8") as file:
            json.dump(data, file, indent=4, ensure_ascii=False)  # ✅ Save updated data

        print(f"📌 Updated {file_path}: {entry_id} → {entry_title}")
