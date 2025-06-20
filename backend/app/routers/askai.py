from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel
from core.promptgetter import *
from core.memory import *
from google import genai
from google.genai import types
import os
from dotenv import load_dotenv
from uuid import UUID

load_dotenv()

router = APIRouter()

class PromptRequest(BaseModel):
    prompt: str
    id : UUID

class MemoryDeletion(BaseModel):
    id : UUID

class Lines(BaseModel):
    num : int

# Gemini client initialization (runs once)
client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
model = "gemini-2.5-flash"
generate_content_config = types.GenerateContentConfig(
    thinking_config=types.ThinkingConfig(thinking_budget=-1),
    response_mime_type="text/plain",
)

def call_gemini(prompt: str) -> str:
    contents = [
        types.Content(
            role="user",
            parts=[types.Part.from_text(text=prompt)],
        )
    ]
    try:
        response_text = ""
        for chunk in client.models.generate_content_stream(
            model=model,
            contents=contents,
            config=generate_content_config,
        ):
            response_text += chunk.text
        return response_text
    except Exception as e:
        return f"[ERROR] {str(e)}"

prompt_classify = """
Classify the user's intent as one of the following and do not answer with anything else:
- listener
- self_reflection
- mental_info
- qa

User input: "{0}"

Intent based on the options:
"""

@router.post("/classify")
def classify(prompt_data: PromptRequest):
    prompt = prompt_classify.format(prompt_data.prompt)
    ai_response = call_gemini(prompt)
    return {"ai_response": ai_response}

@router.post("/summarize")
def summarize(lines: Lines, user_id: int = Query(...)):
    data = get_latest_memories(n=lines.num, user_id=user_id)
    prompt = summarizer().format(data)
    ai_response = call_gemini(prompt)
    return {"ai_response": ai_response}

@router.post("/conversation")
def conversation(prompt_data: PromptRequest, mode: str = Query(...)):
    memory_blocks = read_memories(prompt_data.id)
    relevant_memories = retrieve_memories(prompt_data.prompt, memory_blocks)
    memory_text = "\n\n".join(relevant_memories)
    prompt_base = prompt_getter(mode).format(prompt_data.prompt)

    formatted_prompt = f"""
Relevant past conversations, your memories:
{memory_text}
---
{prompt_base}
"""
    print(formatted_prompt)

    ai_response = call_gemini(formatted_prompt)
    append_memory(prompt_data.prompt, ai_response, user_id=prompt_data.id)

    return {"ai_response": ai_response}

@router.post("/clear_memory")
def clear_user_memory(payload: MemoryDeletion):
    try:
        clear_memory(payload.id)
        return {"message": f"Memory for user {payload.id} cleared successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to clear memory: {str(e)}")