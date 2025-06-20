import os
from sentence_transformers import SentenceTransformer, util

model = SentenceTransformer('all-MiniLM-L6-v2')  # Good for RAG

MEMORY_DIR = "memory"

def get_memory_path(user_id: int) -> str:
    return os.path.join(MEMORY_DIR, f"{user_id}.txt")

def ensure_memory_file_exists(filepath):
    """Creates the memory file if it does not exist."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    if not os.path.exists(filepath):
        with open(filepath, "w", encoding="utf-8") as f:
            f.write("")  # Create an empty file

def read_memories(user_id: int):
    filepath = get_memory_path(user_id)
    ensure_memory_file_exists(filepath)

    with open(filepath, "r", encoding="utf-8") as f:
        blocks = f.read().split("\n---\n")
        return [block.strip() for block in blocks if block.strip()]

def retrieve_memories(query, memory_blocks, top_k=4, include_last=True):
    if not memory_blocks:
        return []

    corpus_embeddings = model.encode(memory_blocks, convert_to_tensor=True)
    query_embedding = model.encode([query], convert_to_tensor=True)

    hits = util.semantic_search(query_embedding, corpus_embeddings, top_k=top_k)
    top_blocks = [memory_blocks[hit['corpus_id']] for hit in hits[0]]

    if include_last:
        last_block = memory_blocks[-1]
        if last_block not in top_blocks:
            top_blocks.append(last_block)

    return top_blocks

def get_latest_memories(n=3, user_id: int = None):
    filepath = get_memory_path(user_id)
    ensure_memory_file_exists(filepath)

    with open(filepath, "r", encoding="utf-8") as f:
        blocks = f.read().split("\n---\n")
        cleaned_blocks = [block.strip() for block in blocks if block.strip()]
        return cleaned_blocks[-n:] if n <= len(cleaned_blocks) else cleaned_blocks

def append_memory(user_prompt, ai_response, user_id: int):
    filepath = get_memory_path(user_id)
    ensure_memory_file_exists(filepath)

    with open(filepath, "a", encoding="utf-8") as f:
        f.write(f"User: {user_prompt}\nAssistant: {ai_response}\n\n---\n\n")

def clear_memory(user_id: int):
    """Clears all stored memories for a given user."""
    filepath = get_memory_path(user_id)
    ensure_memory_file_exists(filepath)  # Make sure file exists
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("")  # Empty the file content
