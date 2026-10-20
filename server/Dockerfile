FROM python:3.11-slim
WORKDIR /app
COPY server/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# Course content the index is built from, and the model, are baked into the image.
COPY server/ ./
COPY assets/data/course_knowledge.json /repo/assets/data/course_knowledge.json
COPY tools/seed/seed.json /repo/tools/seed/seed.json
ENV CHROMA_DIR=/data/chroma EMBED_CACHE=/app/.models
RUN python -c "from app import rag; rag.embeddings().embed_query('warm up')"
EXPOSE 8710
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8710"]
