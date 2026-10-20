"""Identifies the caller from their Firebase ID token."""
import time

import httpx

from .config import firebase_api_key

_cache: dict[str, tuple[float, str]] = {}
_TTL = 300  # seconds


async def verify_token(token: str | None) -> str | None:
    """Returns the Firebase uid for a valid ID token, or None.

    Uses Firebase's own lookup endpoint, so no service-account key is needed.
    A missing or bad token simply means the caller is treated as a guest: they
    can ask about course content but never see anyone's personal records."""
    if not token:
        return None
    hit = _cache.get(token)
    if hit and hit[0] > time.time():
        return hit[1]
    key = firebase_api_key()
    if not key:
        return None
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            r = await client.post(
                f"https://identitytoolkit.googleapis.com/v1/accounts:lookup?key={key}",
                json={"idToken": token},
            )
        if r.status_code != 200:
            return None
        uid = r.json()["users"][0]["localId"]
    except Exception:
        return None
    _cache[token] = (time.time() + _TTL, uid)
    return uid
