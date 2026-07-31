"""
SAI Sports Talent Assessment - JWT Handler
HS256 tokens with 24-hour expiry for access tokens.
Short-lived 10-minute tokens for intermediate login step.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional
import uuid

from jose import JWTError, jwt
from fastapi import HTTPException, status

from app.config import settings


# ─────────────────────────────────────────────────────────────────────────────
# TOKEN CREATION
# ─────────────────────────────────────────────────────────────────────────────

def create_access_token(user_id: str, mobile_number: str) -> str:
    """
    Creates a 24-hour JWT access token for authenticated sessions.
    """
    now = datetime.now(timezone.utc)
    expire = now + timedelta(hours=settings.JWT_ACCESS_TOKEN_EXPIRE_HOURS)
    payload = {
        "sub": str(user_id),
        "mobile": mobile_number,
        "type": "access",
        "jti": str(uuid.uuid4()),  # JWT ID — enables token revocation
        "iat": now,
        "exp": expire,
        "iss": "SAI-SportsTalent",
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_temp_login_token(user_id: str, mobile_number: str) -> str:
    """
    Creates a short-lived 10-minute token after password verification.
    Used to authorize the face verification step — prevents replay attacks.
    """
    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=settings.JWT_TEMP_TOKEN_EXPIRE_MINUTES)
    payload = {
        "sub": str(user_id),
        "mobile": mobile_number,
        "type": "temp_login",   # Scope-limited — cannot access protected routes
        "jti": str(uuid.uuid4()),
        "iat": now,
        "exp": expire,
        "iss": "SAI-SportsTalent",
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


# ─────────────────────────────────────────────────────────────────────────────
# TOKEN VERIFICATION
# ─────────────────────────────────────────────────────────────────────────────

def verify_access_token(token: str) -> dict:
    """
    Verifies a JWT access token. Raises HTTP 401 on failure.
    Returns the decoded payload dict.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials. Token may be expired or invalid.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
            options={"verify_exp": True},
        )
        token_type: str = payload.get("type")
        if token_type != "access":
            raise credentials_exception
        user_id: str = payload.get("sub")
        if not user_id:
            raise credentials_exception
        return payload
    except JWTError:
        raise credentials_exception


def verify_temp_login_token(token: str) -> dict:
    """
    Verifies a temporary login token from step 1.
    Returns payload if valid; raises HTTP 401 otherwise.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Temporary login token is invalid or expired. Please restart login.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
            options={"verify_exp": True},
        )
        token_type: str = payload.get("type")
        if token_type != "temp_login":
            raise credentials_exception
        user_id: str = payload.get("sub")
        if not user_id:
            raise credentials_exception
        return payload
    except JWTError:
        raise credentials_exception


def decode_token_unsafe(token: str) -> Optional[dict]:
    """
    Decode without verification (for debugging only — never use in auth paths).
    """
    try:
        return jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
            options={"verify_exp": False, "verify_signature": False},
        )
    except JWTError:
        return None
