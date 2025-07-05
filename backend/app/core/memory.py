import os
import json
import nltk
from sentence_transformers import SentenceTransformer, util
from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.lex_rank import LexRankSummarizer
from nltk.corpus import stopwords
import string
from rake_nltk import Rake
from difflib import get_close_matches

# Download required models and resources
nltk.download('punkt')
nltk.download('stopwords')

stop_words = set(stopwords.words('english'))
punct = set(string.punctuation)

model = SentenceTransformer('all-MiniLM-L6-v2')  # Good for RAG

MEMORY_DIR = "memory"

def get_memory_path(user_id: int) -> str:
    return os.path.join(MEMORY_DIR, f"{user_id}.jsonl")

def ensure_memory_file_exists(filepath):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    if not os.path.exists(filepath):
        with open(filepath, "w", encoding="utf-8") as f:
            f.write("")

def extract_tags(text: str) -> set:
    rake = Rake(stopwords=stop_words, punctuations=punct)
    rake.extract_keywords_from_text(text)
    ranked_phrases_with_scores = rake.get_ranked_phrases_with_scores()

    # Filter by minimum relevance score and remove greetings/common phrases
    MIN_SCORE = 3  # Adjust RAKE score threshold
    banned = {
        "hello", "hi", "welcome", "thanks", "goodbye", "bye", "nice to meet", "nice meeting",
        "take care", "thank you", "you're welcome", "see you", "how are you", "on your mind"
    }

    cleaned_tags = set()
    for score, phrase in ranked_phrases_with_scores:
        phrase = phrase.lower().strip()
        if score < MIN_SCORE:
            continue
        if phrase in banned:
            continue
        if any(b in phrase for b in banned):
            continue
        if phrase in cleaned_tags:
            continue
        cleaned_tags.add(phrase)

    return cleaned_tags

def append_memory(user_prompt, ai_response, user_id: int):
    filepath = get_memory_path(user_id)
    ensure_memory_file_exists(filepath)

    tags = list(extract_tags(user_prompt + " " + ai_response))
    memory_block = {
        "user": user_prompt,
        "assistant": ai_response,
        "tags": tags
    }
    with open(filepath, "a", encoding="utf-8") as f:
        f.write(json.dumps(memory_block, ensure_ascii=False) + "\n")

def read_memories(user_id: int):
    filepath = get_memory_path(user_id)
    ensure_memory_file_exists(filepath)
    memories = []
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            try:
                memories.append(json.loads(line))
            except json.JSONDecodeError:
                continue
    return memories

def get_latest_memories(n=3, user_id: int = None):
    memories = read_memories(user_id)
    return memories[-n:] if n <= len(memories) else memories

def retrieve_memories(query, memory_blocks, top_k=5):
    memory_texts = [f"User: {m['user']}\nAssistant: {m['assistant']}" for m in memory_blocks]
    query_embedding = model.encode(query, convert_to_tensor=True)
    memory_embeddings = model.encode(memory_texts, convert_to_tensor=True)
    selected_indices = util.semantic_search(query_embedding, memory_embeddings, top_k=top_k)[0]
    selected = [memory_texts[match['corpus_id']] for match in selected_indices]
    return selected

def tag_matches(query_tag: str, tags: list[str], threshold=0.4):
    matches = get_close_matches(query_tag, tags, cutoff=threshold)
    return bool(matches)

def retrieve_by_tag(query_tag: str, user_id: int):
    query_tag = query_tag.lower()
    memories = read_memories(user_id)
    return [m for m in memories if tag_matches(query_tag, m.get("tags", []))]

def summarize_memories(user_id: int):
    memory_blocks = read_memories(user_id)
    if not memory_blocks:
        print("No significant memories recorded yet.")
        return " "

    full_text = "\n\n".join(f"User: {m['user']}\nAssistant: {m['assistant']}" for m in memory_blocks)
    if len(full_text.split()) < 50:
        print("Not enough memory to summarize meaningfully.")
        return " "

    return summarize_text(full_text)

def summarize_text(text):
    parser = PlaintextParser.from_string(text, Tokenizer("english"))
    summarizer = LexRankSummarizer()
    summary_sentences = summarizer(parser.document, sentences_count=5)
    return "\n".join(str(sentence) for sentence in summary_sentences)

def clear_memory(user_id: int):
    filepath = get_memory_path(user_id)
    ensure_memory_file_exists(filepath)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("")

def trigger_memory_check(user_input: str, user_id: int):
    query_tags = extract_tags(user_input)
    triggered_memories = {}

    for tag in query_tags:
        blocks = retrieve_by_tag(tag, user_id)
        if blocks:
            triggered_memories[tag] = blocks

    return triggered_memories

def get_short_term_memory(user_id: int, n: int = 3):
    recent = read_memories(user_id)
    if not recent:
        return ""

    # Get the last n chats (from the bottom of the list)
    recent = recent[-n:]

    polished = []
    for entry in recent:
        user_text = entry.get("user", "").strip().replace("\n", " ")
        assistant_text = entry.get("assistant", "").strip().replace("\n", " ")
        if user_text and assistant_text:
            polished.append(f"User: {user_text}\nAssistant: {assistant_text}")

    return "\n\n".join(polished)