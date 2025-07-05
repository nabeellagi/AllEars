from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.routing import APIRouter
from routers import askai

import os
import json
import socket
import qrcode
import nltk
from sentence_transformers import SentenceTransformer

from rich.console import Console
from rich.prompt import Prompt
from rich.panel import Panel
from rich.text import Text

from contextlib import asynccontextmanager

import threading
import sys
import time
import signal
from pathlib import Path

# === Setup Rich Console ===
console = Console()

# === Global NLP Variables ===
transformer_model = None

# === FastAPI App Initialization with Lifespan ===
@asynccontextmanager
async def lifespan(app: FastAPI):
    port = 8000
    ip = get_local_ip()
    display_qr_code(ip, port)
    get_or_create_gemini_key()
    preload_models()
    yield

app = FastAPI(lifespan=lifespan)

# === Enable CORS ===
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return True

app.include_router(askai.router)

# === Get Local IP Utility ===
def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

# === QR Code Display Utility ===
def display_qr_code(ip: str, port: int):
    url = f"http://{ip}:{port}"
    qr = qrcode.QRCode(border=1, box_size=1)
    qr.add_data(url)
    qr.make(fit=True)
    matrix = qr.get_matrix()
    console.print(Panel(Text(url, style="bold green"), title="🔗 Access Link"))
    for row in matrix:
        line = "".join("  " if not bit else "██" for bit in row)
        console.print(line, style="white")

# === Gemini API Key Loader ===
def get_or_create_gemini_key(config_path: str = ".allears_config.json") -> str:
    if os.path.exists(config_path):
        with open(config_path, "r") as f:
            config = json.load(f)
            if "GEMINI_API_KEY" in config:
                console.log("[green]Gemini API key loaded from config.")
                return config["GEMINI_API_KEY"]

    key = Prompt.ask("[bold yellow]Enter your Gemini API Key")
    console.log("[cyan]After input, press enter multiple times.")
    with open(config_path, "w") as f:
        json.dump({"GEMINI_API_KEY": key}, f)
    console.log("[cyan]Gemini API key saved to config.")
    return key

# === NLP Preloading ===
def preload_models():
    global transformer_model
    with console.status("[bold green]Loading NLP models...", spinner="dots"):
        if getattr(sys, 'frozen', False):
            nltk_data_path = Path(sys._MEIPASS) / "nltk_data"
            nltk.data.path.append(str(nltk_data_path))
        nltk.download("punkt")
        console.log("[blue]Downloaded NLTK punkt tokenizer.")
        
        transformer_model = SentenceTransformer('all-MiniLM-L6-v2')
        console.log("[blue]Loaded SentenceTransformer.")

# === Keyboard Exit Listener ===
def keyboard_exit_listener():
    try:
        while True:
            user_input = input("[Press 'q' then ENTER to quit]: ").strip().lower()
            if user_input == 'q':
                console.print("\n[bold red]Exit signal received. Shutting down...[/bold red]")
                time.sleep(0.5)
                os.kill(os.getpid(), signal.SIGINT)
                sys.exit()
    except (EOFError, KeyboardInterrupt):
        console.print("\n[bold red]Shutdown interrupted. Forcing exit.[/bold red]")
        os.kill(os.getpid(), signal.SIGINT)

listener_thread = threading.Thread(target=keyboard_exit_listener, daemon=True)
listener_thread.start()
