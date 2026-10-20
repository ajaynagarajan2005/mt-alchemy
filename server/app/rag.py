"""Retrieval-augmented generation with LangChain and Chroma.

Two vector collections:
  courses      shared: lecture notes, glossary, exercises and lesson text
  user_<hash>  one per learner: their progress, payments and certificates

A question is embedded, the nearest passages are fetched from both, and a
LangChain chain writes a grounded answer. With ANTHROPIC_API_KEY set the
answer is written by Claude from those passages; without it the answer is
the best-matching sentences, so the service still works with no model.
"""
from __future__ import annotations

import hashlib
import json
import re
from functools import lru_cache
from typing import Any

from langchain_chroma import Chroma
from langchain_community.embeddings.fastembed import FastEmbedEmbeddings
from langchain_core.documents import Document
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnableLambda

from . import config

RECORD_BOOST = 1.25  # multiplier for the learner's own records
COLLECTION_META = {"hnsw:space": "cosine"}  # so scores read as 0..1 similarity


@lru_cache(maxsize=1)
def embeddings() -> FastEmbedEmbeddings:
    return FastEmbedEmbeddings(model_name=config.EMBED_MODEL, cache_dir=config.EMBED_CACHE)


def _store(name: str, emb=None) -> Chroma:
    return Chroma(
        collection_name=name,
        embedding_function=emb or embeddings(),
        persist_directory=config.CHROMA_DIR,
        collection_metadata=COLLECTION_META,
    )


def course_store(emb=None) -> Chroma:
    return _store("courses", emb)


def user_collection(uid: str) -> str:
    return "user_" + hashlib.sha1(uid.encode()).hexdigest()[:24]


# --------------------------------------------------------------- ingestion


def course_documents(knowledge: dict[str, list[dict]], courses: dict[str, dict]) -> list[Document]:
    """Passages from the lecture notes plus each course's own summary and lessons."""
    docs: list[Document] = []
    for cid, passages in knowledge.items():
        title = courses.get(cid, {}).get("title", cid)
        for p in passages:
            docs.append(
                Document(
                    page_content=f"{p['title']}. {p['text']}",
                    metadata={"id": p["id"], "course_id": cid, "course_title": title, "title": p["title"], "kind": "course"},
                )
            )
    for cid, c in courses.items():
        docs.append(
            Document(
                page_content=f"About {c['title']}. {c.get('summary', '')} You will learn to: "
                + "; ".join(c.get("outcomes", []))
                + f". Led by {c.get('trainer', '')}. Level: {c.get('level', '')}. Price: £{c.get('price', 0):.0f}.",
                metadata={"id": f"{cid}-about", "course_id": cid, "course_title": c["title"], "title": f"About {c['title']}", "kind": "course"},
            )
        )
        for m in c.get("modules", []):
            body = (m.get("body") or "").strip()
            if m.get("type") == "quiz" or len(body) < 40:
                continue
            docs.append(
                Document(
                    page_content=f"Lesson: {m['title']}. {body}",
                    metadata={"id": f"{cid}-{m['id']}", "course_id": cid, "course_title": c["title"], "title": f"Lesson: {m['title']}", "kind": "course"},
                )
            )
    return docs


def ingest_courses(knowledge_path=None, seed_path=None, emb=None) -> int:
    """Rebuilds the shared course collection from the files in the repository."""
    knowledge_path = knowledge_path or config.ROOT / "assets" / "data" / "course_knowledge.json"
    seed_path = seed_path or config.ROOT / "tools" / "seed" / "seed.json"
    knowledge = json.loads(open(knowledge_path, encoding="utf-8").read())
    courses = json.loads(open(seed_path, encoding="utf-8").read())["courses"]
    docs = course_documents(knowledge, courses)
    vs = course_store(emb)
    existing = vs.get()["ids"]
    if existing:
        vs.delete(ids=existing)
    vs.add_documents(docs, ids=[d.metadata["id"] for d in docs])
    return len(docs)


def snapshot_documents(snapshot: dict[str, Any]) -> list[Document]:
    """Turns a learner's own records into passages that can be searched."""
    who = (snapshot.get("user") or {}).get("name", "The learner")
    docs: list[Document] = []

    def add(kind: str, key: str, text: str, title: str, course_id: str = "", display: str = "") -> None:
        # `text` is what gets embedded and searched; `display` is the clean
        # sentence shown when the answer is taken straight from the record.
        docs.append(
            Document(
                page_content=text,
                metadata={"id": f"{kind}-{key}", "kind": "record", "record": kind, "title": title, "course_id": course_id, "course_title": title, "display": display or text},
            )
        )

    for e in snapshot.get("enrolments", []):
        pct = round(e.get("progress", 0) * 100)
        access = {"purchase": "bought this course", "assignment": "were given it by your employer", "granted": "were given free access by the team"}.get(e.get("accessType"), "are enrolled on it")
        paid = f" You paid £{e['amountPaid']:.0f}." if e.get("amountPaid") else ""
        nxt = f" Your next lesson is {e['next']}." if e.get("next") else " Every lesson is done."
        add(
            "progress", e["courseId"],
            f"Your progress, how far you are through {e['courseTitle']}: you have completed {e.get('done', 0)} of {e.get('total', 0)} lessons ({pct}%). You {access}.{paid}{nxt}",
            f"Your progress in {e['courseTitle']}", e["courseId"],
            display=f"In {e['courseTitle']} you have completed {e.get('done', 0)} of {e.get('total', 0)} lessons ({pct}%). You {access}.{paid}{nxt}",
        )
    for o in snapshot.get("orders", []):
        add(
            "payment", o["number"],
            f"Your payments, how much you paid or spent and what you pay for a course: order {o['number']} on {o.get('date', 'an unknown date')} for £{o.get('total', 0):.2f} covering {o.get('items', 'items')}. Payments run in test mode, so no real card was charged.",
            f"Your order {o['number']}",
            display=f"Order {o['number']} on {o.get('date', 'an unknown date')} was £{o.get('total', 0):.2f}, covering {o.get('items', 'items')}. Payments run in test mode, so no real card was charged.",
        )
    for c in snapshot.get("certificates", []):
        review = f" Review: {c['review']}" if c.get("review") else ""
        add(
            "certificate", c["code"],
            f"Your certificate for {c['courseTitle']}, code {c['code']}, was issued on {c.get('issuedAt', 'an unknown date')}.{review}",
            f"Your certificate for {c['courseTitle']}",
        )
    for a in snapshot.get("assigned", []):
        add("assigned", a["courseId"], f"Assigned course: {a['courseTitle']} was assigned by an employer and can be started from My learning.", f"Assigned: {a['courseTitle']}", a["courseId"])
    u = snapshot.get("user") or {}
    if u:
        add("profile", "pathway", f"Your learning pathway: you are at the {u.get('careerStage') or 'unspecified'} career stage with interests in {', '.join(u.get('interests', [])) or 'no chosen areas'}.", "Your learning pathway")
    return docs


_indexed: dict[str, str] = {}


def index_user(uid: str, snapshot: dict[str, Any], emb=None) -> int:
    """Replaces the learner's collection with their current records. Skips the
    work when nothing changed since the last question."""
    digest = hashlib.sha1(json.dumps(snapshot, sort_keys=True, default=str).encode()).hexdigest()
    if _indexed.get(uid) == digest:
        return 0
    vs = _store(user_collection(uid), emb)
    old = vs.get()["ids"]
    if old:
        vs.delete(ids=old)
    docs = snapshot_documents(snapshot)
    if docs:
        vs.add_documents(docs, ids=[d.metadata["id"] for d in docs])
    _indexed[uid] = digest
    return len(docs)


# --------------------------------------------------------------- the chain

PROMPT = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "You are the MT Alchemy learning assistant. Answer using ONLY the context below, which holds "
            "course material and, when present, the learner's own records. Write in plain English in at most "
            "120 words, with no headings. Say which lesson or record you used. If the context does not contain "
            "the answer, say you could not find it in the course material and suggest asking the trainer. "
            "Never invent course content, prices or payments.",
        ),
        ("human", "Question: {question}\n\nContext:\n{context}"),
    ]
)


def _llm():
    if not config.ANTHROPIC_API_KEY:
        return None
    from langchain_anthropic import ChatAnthropic

    return ChatAnthropic(model=config.ANTHROPIC_MODEL, api_key=config.ANTHROPIC_API_KEY, temperature=0.2, max_tokens=400)


def _words(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z0-9]+", text.lower()) if len(w) > 2}


def extractive_answer(question: str, hits: list[tuple[Document, float]]) -> str:
    """No model available: pick the sentences, across the best passages, that
    share the most words with the question."""
    if not hits:
        return "I could not find that in the course material. Try different words, or ask your trainer."
    q = _words(question)
    top = hits[0][1]
    cands: list[tuple[float, int, int, str]] = []  # (score, doc order, sentence order, text)
    for d_i, (doc, score) in enumerate(hits[:3]):
        if score < top * 0.8:
            continue
        body = doc.metadata.get("display") or doc.page_content
        title = doc.metadata.get("title", "")
        if title and body.startswith(title + "."):
            body = body[len(title) + 1:].strip()  # drop the heading, keep the content
        for s_i, sent in enumerate(x.strip() for x in re.split(r"(?<=[.!?])\s+", body) if x.strip()):
            overlap = len(_words(sent) & q)
            cands.append((overlap + score, d_i, s_i, sent))
    if not cands:
        return hits[0][0].page_content[:300]
    chosen: list[tuple[float, int, int, str]] = []
    for c in sorted(cands, key=lambda c: -c[0]):
        w = _words(c[3])
        # Skip a sentence that mostly repeats one already chosen.
        if any(len(w & _words(k[3])) / max(1, len(w | _words(k[3]))) > 0.5 for k in chosen):
            continue
        chosen.append(c)
        if len(chosen) == 2:
            break
    best = chosen
    return " ".join(c[3] for c in sorted(best, key=lambda c: (c[1], c[2])))


class Rag:
    """The retrieval chain. Build once, call ask() per question."""

    def __init__(self, emb=None, llm=None, use_env_llm: bool = True):
        self.emb = emb
        self.llm = llm if llm is not None else (_llm() if use_env_llm else None)
        # LangChain Expression Language: retrieve passages, then generate.
        self.chain = RunnableLambda(self._retrieve) | RunnableLambda(self._generate)

    @property
    def mode(self) -> str:
        return "llm" if self.llm else "extractive"

    def _retrieve(self, inp: dict) -> dict:
        q = inp["question"]
        hits: list[tuple[Document, float]] = []
        hits += course_store(self.emb).similarity_search_with_relevance_scores(q, k=5)
        uid = inp.get("uid")
        if uid:
            # Their own records are short and exactly about them, so a record
            # that is a reasonable match should outrank general course text.
            mine = _store(user_collection(uid), self.emb).similarity_search_with_relevance_scores(q, k=3)
            hits += [(d, min(1.0, s * RECORD_BOOST)) for d, s in mine]
        hits = sorted((h for h in hits if h[1] >= config.MIN_RELEVANCE), key=lambda h: -h[1])[:5]
        return {**inp, "hits": hits}

    def _generate(self, inp: dict) -> dict:
        hits = inp["hits"]
        if not hits:
            text = "I could not find that in the course material or your records. Try different words, or ask your trainer."
        elif self.llm:
            context = "\n\n".join(f"[{d.metadata.get('title')}] {d.page_content}" for d, _ in hits)
            text = (PROMPT | self.llm | StrOutputParser()).invoke({"question": inp["question"], "context": context})
        else:
            text = extractive_answer(inp["question"], hits)
        sources = [
            {
                "kind": d.metadata.get("kind", "course"),
                "title": d.metadata.get("title", ""),
                "course_id": d.metadata.get("course_id", ""),
                "course_title": d.metadata.get("course_title", ""),
                "score": round(float(s), 3),
                "snippet": d.page_content[:220],
            }
            for d, s in hits[:3]
        ]
        return {"answer": text.strip(), "mode": self.mode, "sources": sources}

    def ask(self, question: str, uid: str | None = None, snapshot: dict | None = None) -> dict:
        if uid and snapshot:
            index_user(uid, snapshot, self.emb)
        return self.chain.invoke({"question": question, "uid": uid})
