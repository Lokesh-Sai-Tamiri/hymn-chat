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
        self.db = self.client.get_database("hymn-chat")
        self.collection = self.db.get_collection("sessions")

    async def create_session(self, user_id: str = None, title: str = None) -> str:
        session_id = str(uuid.uuid4())
        # Create empty session document
        await self.collection.insert_one({
            "session_id": session_id,
            "user_id": user_id,
            "title": title or "New Chat",
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
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
        cursor = self.collection.find({"user_id": user_id}).sort("updated_at", -1)
        sessions = await cursor.to_list(length=100)
        return sessions

    async def update_session_title(self, session_id: str, title: str):
        """Update the session title."""
        await self.collection.update_one(
            {"session_id": session_id},
            {"$set": {"title": title, "updated_at": datetime.utcnow()}}
        )

    async def delete_session(self, session_id: str) -> bool:
        """Delete a session by its ID."""
        result = await self.collection.delete_one({"session_id": session_id})
        return result.deleted_count > 0

    async def add_message(self, session_id: str, role: str, content: Any, image_data: bytes = None, mime_type: str = None):
        """
        Adds a message to the history. 
        Content can be string literal or we can pass image_data to be stored as a structure.
        Uses a format compatible with OpenAI's message structure.
        """
        # Map to standard roles (user/model for consistency)
        stored_role = "user" if role == "user" else "model"
        
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
            "role": stored_role,
            "parts": parts,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        await self.collection.update_one(
            {"session_id": session_id},
            {
                "$push": {"history": new_turn},
                "$set": {"updated_at": datetime.utcnow()}
            },
            upsert=True
        )
    
    async def should_generate_title(self, session_id: str) -> bool:
        """Check if we should generate a title (after first exchange)."""
        session = await self.get_session(session_id)
        if session:
            # Generate title if it's still "New Chat" and we have at least 2 messages (user + model)
            history = session.get("history", [])
            return session.get("title") == "New Chat" and len(history) >= 2
        return False
