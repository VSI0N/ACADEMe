from firebase_admin import firestore
from models.material_model import MaterialResponse
from datetime import datetime
import uuid
from fastapi import HTTPException

db = firestore.client()

class MaterialService:
    @staticmethod
    async def add_material(
        course_id: str, 
        topic_id: str, 
        material: dict,  # ✅ Accept dictionary
        is_subtopic: bool = False, 
        subtopic_id: str = None
    ) -> MaterialResponse:
        """Adds a material under a topic or subtopic in Firestore."""
        try:
            # ✅ Generate unique ID
            material_id = str(uuid.uuid4())

            # ✅ Convert datetime to ISO string
            material["id"] = material_id
            material["created_at"] = datetime.utcnow().isoformat()  # ✅ Fix here
            material["updated_at"] = datetime.utcnow().isoformat()  # ✅ Fix here

            # ✅ Determine Firestore reference
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

            # ✅ Save to Firestore
            ref.set(material, merge=True)

            return MaterialResponse(**material)  # ✅ Convert back to Pydantic model
        
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error adding material: {str(e)}")
            
    @staticmethod
    async def get_materials(
        course_id: str, 
        topic_id: str, 
        is_subtopic: bool = False, 
        subtopic_id: str = None
    ) -> list[MaterialResponse]:
        """Fetches all materials under a topic or subtopic from Firestore."""
        try:
            # ✅ Determine Firestore reference
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

            # ✅ Fetch documents from Firestore
            materials = ref.stream()
            material_list = [material.to_dict() for material in materials]

            # ✅ Convert Firestore Timestamp to datetime
            for material in material_list:
                if isinstance(material.get("created_at"), datetime):
                    material["created_at"] = material["created_at"].isoformat()
                if isinstance(material.get("updated_at"), datetime):
                    material["updated_at"] = material["updated_at"].isoformat()

            # ✅ Return empty list instead of raising HTTPException
            return [MaterialResponse(**material) for material in material_list]
        
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching materials: {str(e)}")
