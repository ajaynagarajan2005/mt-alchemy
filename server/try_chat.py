"""Manual check against a running service: python try_chat.py
Signs in as the demo learner over REST and asks a few questions."""
import json
import re
import sys
from pathlib import Path

import httpx

URL = "http://localhost:8710"
root = Path(__file__).resolve().parents[1]
opts = (root / "lib/firebase_options.dart").read_text(encoding="utf-8")
web = opts[opts.index("FirebaseOptions web"):]
key = re.search(r"apiKey: '([^']+)'", web).group(1)
pw = json.loads((root / "tools/seed/seed.json").read_text(encoding="utf-8"))["password"]

r = httpx.post(f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={key}",
               json={"email": "amara@example.com", "password": pw, "returnSecureToken": True}, timeout=20)
token = r.json()["idToken"]

snapshot = {
    "user": {"name": "Amara Osei", "careerStage": "professional", "interests": ["emotional-intelligence"]},
    "enrolments": [{"courseId": "ei-foundations", "courseTitle": "Emotional Intelligence Foundations", "done": 3, "total": 12,
                    "progress": 0.25, "next": "Mapping your triggers", "accessType": "purchase", "amountPaid": 149}],
    "orders": [{"number": "MTA-10001", "date": "2 Oct 2026", "total": 149, "items": "Emotional Intelligence Foundations"}],
    "certificates": [],
    "assigned": [],
}

questions = [
    ("guest", "What should I do in the ninety second pause?"),
    ("guest", "How do I give feedback without people getting defensive?"),
    ("guest", "what is the capital of Peru"),
    ("amara", "How far through my emotional intelligence course am I?"),
    ("amara", "How much did I pay for my course?"),
]
for who, q in questions:
    headers = {"Authorization": f"Bearer {token}"} if who == "amara" else {}
    body = {"question": q, "snapshot": snapshot if who == "amara" else snapshot}  # guests send it too: it must be ignored
    out = httpx.post(f"{URL}/chat", json=body, headers=headers, timeout=60).json()
    print(f"\n[{who}] {q}\n  mode={out['mode']} personalised={out['personalised']}")
    print("  answer:", out["answer"][:260].replace("\n", " "))
    for s in out["sources"]:
        print(f"   - {s['kind']:6} {s['score']:.2f}  {s['title']}")
