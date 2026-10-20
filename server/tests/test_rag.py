"""Pipeline tests that need no model download: a deterministic fake embedder
stands in for FastEmbed, so only the LangChain and Chroma plumbing is tested."""
import json

import pytest
from langchain_core.embeddings import DeterministicFakeEmbedding

from app import config, rag


@pytest.fixture()
def emb(tmp_path, monkeypatch):
    monkeypatch.setattr(config, "CHROMA_DIR", str(tmp_path / "chroma"))
    monkeypatch.setattr(config, "MIN_RELEVANCE", -1.0)  # fake vectors are not semantic
    rag._indexed.clear()
    return DeterministicFakeEmbedding(size=64)


KNOWLEDGE = {
    "c1": [{"id": "c1-s0", "title": "Lecture: The pause", "text": "Breathe, name the feeling, decide the next step. It is a short routine."}]
}
COURSES = {"c1": {"title": "Course One", "summary": "Learn to pause.", "outcomes": ["Pause"], "trainer": "Maya", "level": "foundation", "price": 149,
                  "modules": [{"id": "m1", "title": "Triggers", "type": "text", "body": "Most reactive moments follow a pattern worth mapping."}]}}


def test_course_documents_cover_notes_summary_and_lessons():
    docs = rag.course_documents(KNOWLEDGE, COURSES)
    ids = {d.metadata["id"] for d in docs}
    assert ids == {"c1-s0", "c1-about", "c1-m1"}
    assert all(d.metadata["course_title"] == "Course One" for d in docs)


def test_ingest_is_repeatable_and_searchable(emb, tmp_path):
    k, s = tmp_path / "k.json", tmp_path / "s.json"
    k.write_text(json.dumps(KNOWLEDGE))
    s.write_text(json.dumps({"courses": COURSES}))
    assert rag.ingest_courses(k, s, emb) == 3
    assert rag.ingest_courses(k, s, emb) == 3  # no duplicates on a second run
    assert len(rag.course_store(emb).get()["ids"]) == 3


def test_snapshot_becomes_personal_passages():
    snap = {"user": {"name": "Amara Osei", "careerStage": "professional", "interests": ["team-engagement"]},
            "enrolments": [{"courseId": "c1", "courseTitle": "Course One", "done": 3, "total": 11, "progress": 3 / 11, "next": "Triggers", "accessType": "purchase", "amountPaid": 149}],
            "orders": [{"number": "MTA-1", "date": "1 Oct 2026", "total": 149, "items": "Course One"}],
            "certificates": [{"code": "MTA-C1-AAA", "courseTitle": "Course One", "issuedAt": "2 Oct 2026", "review": "Well done."}]}
    docs = rag.snapshot_documents(snap)
    text = " ".join(d.page_content for d in docs)
    assert "completed 3 of 11 lessons (27%)" in text and "£149.00" in text and "Well done." in text
    assert {d.metadata["record"] for d in docs} == {"progress", "payment", "certificate", "profile"}


def test_each_user_has_a_separate_collection(emb):
    assert rag.user_collection("alice") != rag.user_collection("bob")
    rag.index_user("alice", {"orders": [{"number": "A1", "total": 5, "items": "x"}]}, emb)
    rag.index_user("bob", {"orders": [{"number": "B1", "total": 9, "items": "y"}]}, emb)
    a = rag._store(rag.user_collection("alice"), emb).get()["ids"]
    b = rag._store(rag.user_collection("bob"), emb).get()["ids"]
    assert a == ["payment-A1"] and b == ["payment-B1"]


def test_unchanged_snapshot_is_not_reindexed(emb):
    snap = {"orders": [{"number": "A1", "total": 5, "items": "x"}]}
    assert rag.index_user("alice", snap, emb) == 1
    assert rag.index_user("alice", snap, emb) == 0


def test_chain_answers_from_retrieved_passages_without_a_model(emb, tmp_path):
    k, s = tmp_path / "k.json", tmp_path / "s.json"
    k.write_text(json.dumps(KNOWLEDGE))
    s.write_text(json.dumps({"courses": COURSES}))
    rag.ingest_courses(k, s, emb)
    r = rag.Rag(emb=emb, use_env_llm=False)
    out = r.ask("breathe and name the feeling")
    assert out["mode"] == "extractive"
    assert out["sources"] and out["answer"]


def test_a_guest_never_sees_personal_records(emb, tmp_path):
    rag.index_user("alice", {"orders": [{"number": "SECRET1", "total": 5, "items": "x"}]}, emb)
    r = rag.Rag(emb=emb, use_env_llm=False)
    out = r.ask("order SECRET1 payment", uid=None)
    assert all(src["kind"] != "record" for src in out["sources"])
