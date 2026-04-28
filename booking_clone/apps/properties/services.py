import os
import json
from google import genai
from google.genai import types

class AIDescriptionGenerator:
    """
    A Service Layer class that encapsulates the interaction with the Gemini API.
    This separates the AI logic from the Django views and models.
    """
    
    @staticmethod
    def generate_description(rooms: int, features: str, location: str) -> str:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            # Fallback or stub for development if no key is provided
            return "Beautiful apartment available for rent. Features: " + features + ". Located in " + location + "."

        try:
            client = genai.Client(api_key=api_key)
            
            prompt = f"""
            You are an expert real estate copywriter. Write an attractive, engaging, and professional 
            description for an apartment available for rent.
            
            Details:
            - Rooms: {rooms}
            - Features: {features}
            - Location: {location}
            
            Requirements:
            - Write in Russian.
            - Keep it concise but appealing (max 3-4 short paragraphs).
            - Highlight the benefits of the location and features.
            - Do not include any fake prices or contacts.
            """

            response = client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.7,
                )
            )
            
            return response.text.strip()
        except Exception as e:
            # Fallback in case of API error (timeouts, limits, etc.)
            return f"Error generating description: {str(e)}"
