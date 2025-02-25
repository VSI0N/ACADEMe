from firebase import db

def get_document(collection: str, doc_id: str):
    doc_ref = db.collection(collection).document(doc_id)
    doc = doc_ref.get()
    return doc.to_dict() if doc.exists else None

def create_document(collection: str, doc_id: str, data: dict):
    db.collection(collection).document(doc_id).set(data)

def update_document(collection: str, doc_id: str, data: dict):
    db.collection(collection).document(doc_id).update(data)

def delete_document(collection: str, doc_id: str):
    db.collection(collection).document(doc_id).delete()
