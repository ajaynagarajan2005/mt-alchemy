"""HTTP service for the assistant. Run: uvicorn app.main:app --port 8710"""
from __future__ import annotations

import time
from collections import defaultdict, deque
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from . import config, rag
from .auth import verify_token

_state: dict[str, Any] = {}
_hits: dict[str, deque] = defaultdict(deque)
LIMIT, WINDOW = 30, 60  # questions per minute per caller


@asynccontextmanager
async def lifespan(_: FastAPI):
    _state["rag"] = rag.Rag()
    store = rag.course_store()
    if not store.get()["ids"]:  # first start: build the course index
        rag.ingest_courses()
    yield


app = FastAPI(title="MT Alchemy assistant", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.ALLOWED_ORIGINS,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)


class ChatRequest(BaseModel):
    question: str = Field(min_length=1, max_length=500)
    # The learner's own records, sent by the app and used only for their answer.
    snapshot: dict[str, Any] | None = None


@app.get("/health")
def health() -> dict:
    r: rag.Rag = _state["rag"]
    return {
        "ok": True,
        "mode": r.mode,
        "embedding_model": config.EMBED_MODEL,
        "course_passages": len(rag.course_store().get()["ids"]),
    }


@app.post("/chat")
async def chat(req: ChatRequest, authorization: str | None = Header(default=None)) -> dict:
    token = authorization.split(" ", 1)[1] if authorization and authorization.lower().startswith("bearer ") else None
    uid = await verify_token(token)
    caller = uid or "guest"
    now = time.time()
    q = _hits[caller]
    while q and q[0] < now - WINDOW:
        q.popleft()
    if len(q) >= LIMIT:
        raise HTTPException(429, "Too many questions. Please wait a minute.")
    q.append(now)
    # Guests get course answers only: their snapshot is ignored.
    snapshot = req.snapshot if uid else None
    result = _state["rag"].ask(req.question, uid=uid, snapshot=snapshot)
    used_records = any(src["kind"] == "record" for src in result["sources"])
    return {**result, "personalised": bool(uid and snapshot and used_records)}
