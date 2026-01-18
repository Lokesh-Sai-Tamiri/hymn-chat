import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("GOOGLE_API_KEY")
if API_KEY:
    genai.configure(api_key=API_KEY)

class LLMService:
    def __init__(self):
        # System instruction for Inara Persona
        self.system_instruction = """
You are Inara, an advanced AI Clinical Assistant designed to help doctors and healthcare professionals. 
Your goal is to assist with research, diagnosis support, and administrative tasks.
- You are professional, precise, and empathetic.
- You should always clarify that you are an AI and your suggestions should be verified by a medical professional.
- When analyzing images (like scans), provide observations but do not make a definitive diagnosis.
- Keep responses concise unless asked for a detailed explanation.
"""
        # Configure model with system instruction
        self.model = genai.GenerativeModel(
            model_name='gemini-2.5-pro',
            system_instruction=self.system_instruction
        )

    async def generate_response(self, message: str, history: list = [], image_data: bytes = None, mime_type: str = None) -> str:
        try:
            # Start chat with provided history
            chat = self.model.start_chat(history=history)
            
            content = []
            if image_data and mime_type:
                image_part = {
                    "mime_type": mime_type,
                    "data": image_data
                }
                content.append(image_part)
            
            content.append(message)

            # Send message to the chat session
            response = chat.send_message(content)
            return response.text
        except Exception as e:
            return f"Error generating response: {str(e)}"
