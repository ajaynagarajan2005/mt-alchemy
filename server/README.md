# MT Alchemy assistant service

A retrieval-augmented generation (RAG) service for the in-app chat assistant.

| Part | Choice |
|---|---|
| Framework | LangChain (LCEL chain: retrieve, then generate) |
| Vector database | Chroma, saved to `server/chroma/` |
| Embeddings | FastEmbed `sentence-transformers/all-MiniLM-L6-v2`, run locally |
| Generation | Claude through `langchain-anthropic` when `ANTHROPIC_API_KEY` is set; otherwise the best-matching sentences from the retrieved passages |
| API | FastAPI: `GET /health`, `POST /chat` |
| Identity | Firebase ID token, checked with Firebase's own lookup endpoint |

## How a question is answered

1. The app sends the question, the learner's Firebase ID token and a snapshot of their own records (progress, orders, certificates, pathway).
2. The service checks the token. No valid token means a guest: course answers only, and the snapshot is ignored.
3. The snapshot is turned into passages and stored in that learner's own Chroma collection (`user_<hash>`). It is only re-indexed when it changes.
4. The question is embedded and the nearest passages are fetched from the shared `courses` collection (lecture notes, glossary, exercises, lessons) and from the learner's collection. Passages below the relevance threshold are dropped, so an off-topic question gets "I could not find that".
5. A LangChain chain writes the answer from those passages and returns it with the sources it used. The app draws sources as chips that open the course or record.

Questions are also saved by the app to Firestore (`chatMessages`, readable only by their owner) for the "Your recent questions" list.

## Run it

```bash
cd server
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt     # Windows; use .venv/bin/python on macOS/Linux
.venv/Scripts/python ingest.py                                # builds the course index (first run downloads the model, about 90 MB)
.venv/Scripts/python -m uvicorn app.main:app --port 8710
```

Optional: `ANTHROPIC_API_KEY=...` for model-written answers (`ANTHROPIC_MODEL` to change the model).
Check it with `python try_chat.py` while the service is running, and run the pipeline tests with `python -m pytest tests`.

After changing course content, run `python -m tools.content.export_knowledge` from the repository root, then `python ingest.py` here.

## Connecting the app

The app calls `http://localhost:8710` by default (`--dart-define=RAG_URL=...` to change it, empty to turn the service off). If the service is unreachable the app falls back to its built-in keyword search, so the chat never breaks.

The GitHub Pages site cannot reach a service on your own computer. To use the assistant on the live site, host this service (the `Dockerfile` builds an image; Render, Fly.io or Cloud Run all run it), add the site's address to `ALLOWED_ORIGINS`, and publish with `RAG_URL=https://your-service bash tools/deploy_pages.sh`.

## Limits

- Without `ANTHROPIC_API_KEY` answers are extracted sentences, not written prose.
- The learner's snapshot comes from the app. A learner could send false records about themselves, but only ever affects their own answers.
- Rate limit: 30 questions a minute per person, kept in memory.
