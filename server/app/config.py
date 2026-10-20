"""Settings, read from environment variables so nothing secret is in the code."""
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # repository root
SERVER = Path(__file__).resolve().parents[1]

CHROMA_DIR = os.getenv("CHROMA_DIR", str(SERVER / "chroma"))
EMBED_MODEL = os.getenv("EMBED_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
EMBED_CACHE = os.getenv("EMBED_CACHE", str(SERVER / ".models"))

# Optional: with a key the chain writes its answer with Claude; without one it
# answers with the best-matching passages from the course material.
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")
ANTHROPIC_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-sonnet-5-5")

# Relevance (0 to 1, cosine) a passage needs before it is used as context.
MIN_RELEVANCE = float(os.getenv("MIN_RELEVANCE", "0.30"))

ALLOWED_ORIGINS = [
    o.strip()
    for o in os.getenv(
        "ALLOWED_ORIGINS",
        "http://localhost:8080,http://127.0.0.1:8080,https://ajaynagarajan2005.github.io",
    ).split(",")
    if o.strip()
]


def firebase_api_key() -> str:
    """The web API key identifies the Firebase project; it is not a secret.
    Taken from the environment, else from the Flutter app's own config file."""
    key = os.getenv("FIREBASE_API_KEY")
    if key:
        return key
    options = ROOT / "lib" / "firebase_options.dart"
    if options.exists():
        text = options.read_text(encoding="utf-8")
        web = text[text.find("FirebaseOptions web"):]
        m = re.search(r"apiKey: '([^']+)'", web)
        if m:
            return m.group(1)
    return ""
