from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel
from core.promptgetter import *
from core.memory import *
from google import genai
from google.genai import types
import os
from dotenv import load_dotenv
from uuid import UUID
from pathlib import Path
import json

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
def load_gemini_api_key():
    config_path = Path.home() / ".allears_config.json"
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
            return config.get("gemini_api_key")
    except Exception as e:
        raise RuntimeError(f"Failed to load Gemini API key: {e}")

api_key = load_gemini_api_key()

client = genai.Client(api_key=api_key)

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
You are an intent classification model for an AI Listener system. Your task is to **classify the user's input into one of the following four categories**, based on their underlying intention. Respond **only with the category name**, and **do not include explanations or extra text**.

The intent categories are defined as follows:

- **listener**: The user is seeking someone to listen empathetically, without advice or judgment. This often includes emotional venting, sharing feelings, or expressing distress.
- **self_reflection**: The user is thinking out loud or analyzing their thoughts, behavior, or emotions. They are not directly asking for information or comfort.
- **mental_info**: The user is asking for psychological knowledge, definitions, coping techniques, mental health facts, or mental wellness resources.
- **qa**: The user is asking a question unrelated to mental health or reflection—typically fact-based, casual, or practical.

Now classify the intent of the following user input:

"{0}"

Respond only with: listener, self_reflection, mental_info, or qa.
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
    # 🔎 Load all past memory blocks
    memory_blocks = read_memories(prompt_data.id)

    # 🔁 Retrieve semantically relevant memories (RAG-style)
    relevant_memories = retrieve_memories(prompt_data.prompt, memory_blocks)
    memory_text = "\n\n".join(relevant_memories)

    # 📚 Summarize entire memory (optional global summary)
    memory_summary = summarize_memories(prompt_data.id)

    # 🔖 Trigger keyword-based memory recall
    triggered_summaries = trigger_memory_check(prompt_data.prompt, prompt_data.id)

    # 🧩 Combine all triggered tag summaries
    tag_summary_text = ""
    if triggered_summaries:
        tag_summary_text = "\n\n".join(
            f"## Summary related to '{tag}':\n{summary}" for tag, summary in triggered_summaries.items()
        )
    else:
        tag_summary_text = "No keyword-based memory summaries triggered."

    # 🎯 Format your final AI prompt
    prompt_base = prompt_getter(mode).format(prompt_data.prompt)

    formatted_prompt = f"""
You remember previous conversations. Reflect on those when responding.

# Global Summary:
{memory_summary}

# Keyword-Triggered Summaries:
{tag_summary_text}

# Relevant Semantic Memories:
{memory_text}

---
{prompt_base}
""".strip()

    print(formatted_prompt)

    ai_response = call_gemini(formatted_prompt)

    # 🧠 Store new memory with tagging
    append_memory(prompt_data.prompt, ai_response, user_id=prompt_data.id)

    return {"ai_response": ai_response}


@router.post("/clear_memory")
def clear_user_memory(payload: MemoryDeletion):
    try:
        clear_memory(payload.id)
        return {"message": f"Memory for user {payload.id} cleared successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to clear memory: {str(e)}")