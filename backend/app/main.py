# main.py
import threading
from app import app, keyboard_exit_listener
import uvicorn
import sys

if __name__ == "__main__":
    if sys.stdin.isatty():
        listener_thread = threading.Thread(target=keyboard_exit_listener, daemon=True)
        listener_thread.start()

    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
