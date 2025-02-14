from pydantic import BaseModel

class Message(BaseModel):
    text: str
    language: str
