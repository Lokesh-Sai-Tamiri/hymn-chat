from typing import List, Dict, Optional, Any
import uuid
import os
import base64
from datetime import datetime
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")

class SessionService:
    def __init__(self):
        self.client = AsyncIOMotorClient(MONGO_URI)
        # CHANGED: DB Name to hymn-chat
        self.db = self.client.get_database("hymn-chat")
        self.collection = self.db.get_collection("sessions")

    async def create_session(self, user_id: str = None) -> str:
        session_id = str(uuid.uuid4())
        # Create empty session document
        await self.collection.insert_one({
            "session_id": session_id,
            "user_id": user_id,
            "created_at": datetime.utcnow(),
            "history": []
        })
        return session_id

    async def get_history(self, session_id: str) -> List[Dict]:
        doc = await self.collection.find_one({"session_id": session_id})
        if doc and "history" in doc:
            return doc["history"]
        return []
    
    async def get_session(self, session_id: str) -> Optional[Dict]:
        return await self.collection.find_one({"session_id": session_id})

    async def get_user_sessions(self, user_id: str) -> List[Dict]:
        cursor = self.collection.find({"user_id": user_id}).sort("created_at", -1)
        sessions = await cursor.to_list(length=100)
        return sessions

    async def add_message(self, session_id: str, role: str, content: Any, image_data: bytes = None, mime_type: str = None):
        """
        Adds a message to the history. 
        Content can be string literal or we can pass image_data to be stored as a structure.
        """
        # Mapping generic roles to Gemini roles
        gemini_role = "user" if role == "user" else "model"
        
        parts = []
        
        # If there is image data, we persist it (Base64) so it can be restored contextually
        if image_data and mime_type:
            # Encode bytes to base64 string
            b64_data = base64.b64encode(image_data).decode('utf-8')
            parts.append({
                "inline_data": {
                    "mime_type": mime_type,
                    "data": b64_data
                }
            })
        
        # Add text content if present
        if content:
             parts.append({"text": str(content)})
        
        new_turn = {
            "role": gemini_role,
            "parts": parts
        }
        
        await self.collection.update_one(
            {"session_id": session_id},
            {"$push": {"history": new_turn}},
            upsert=True
        )
