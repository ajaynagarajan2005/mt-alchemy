"""Rebuilds the course vector index. Run after the course content changes:
    python ingest.py
"""
from app import rag

if __name__ == "__main__":
    n = rag.ingest_courses()
    print(f"Indexed {n} course passages into Chroma.")
