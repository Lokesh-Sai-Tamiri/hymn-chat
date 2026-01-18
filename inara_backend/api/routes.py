from fastapi import APIRouter, File, UploadFile, Form, HTTPException, Body
from typing import Optional, List
from services.llm_service import LLMService
from services.session_service import SessionService
from api.models import ChatResponse, SessionCreateRequest, SessionResponse

router = APIRouter()
llm_service = LLMService()
session_service = SessionService()

@router.post("/sessions", response_model=SessionResponse)
async def create_session(request: SessionCreateRequest = Body(...)):
    """Creates a new session, optionally linked to a user_id."""
    session_id = await session_service.create_session(request.user_id)
    # Fetch back to get created_at
    session = await session_service.get_session(session_id)
    return SessionResponse(
        session_id=session_id,
        user_id=request.user_id,
        created_at=session["created_at"],
        history=[]
    )

@router.get("/sessions/{session_id}", response_model=SessionResponse)
async def get_session(session_id: str):
    """Gets details and history of a specific session."""
    session = await session_service.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    return SessionResponse(
        session_id=session["session_id"],
        user_id=session.get("user_id"),
        created_at=session.get("created_at"),
        history=session.get("history", [])
    )

@router.get("/users/{user_id}/sessions", response_model=List[SessionResponse])
async def get_user_sessions(user_id: str):
    """Lists all sessions for a specific user."""
    sessions = await session_service.get_user_sessions(user_id)
    return [
        SessionResponse(
            session_id=s["session_id"],
            user_id=s.get("user_id"),
            created_at=s.get("created_at"),
            history=s.get("history", [])
        ) for s in sessions
    ]

@router.post("/chat", response_model=ChatResponse)
async def chat_endpoint(
    message: str = Form(...),
    session_id: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None)
):
    """
    Endpoint to chat with the AI.
    Accepts 'message', optional 'session_id', and an optional 'file'.
    Persistence: Stores conversation (including images) in underlying MongoDB.
    """
    try:
        # Create new session if not provided (Implicit creation fallback)
        if not session_id:
            session_id = await session_service.create_session()
        
        # Get history
        history = await session_service.get_history(session_id)

        image_data = None
        mime_type = None

        if file:
            if not file.content_type.startswith("image/"):
                pass 
            
            image_data = await file.read()
            mime_type = file.content_type

        # Generate response using history
        # Note: We pass the image_data to logic to generate response 
        response_text = await llm_service.generate_response(message, history, image_data, mime_type)
        
        # Update history with new turn (async)
        # Store USER message with image (if any)
        await session_service.add_message(session_id, "user", message, image_data, mime_type)
        
        # Store MODEL response
        await session_service.add_message(session_id, "model", response_text)

        return ChatResponse(response=response_text, session_id=session_id)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
