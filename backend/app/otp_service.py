"""
SAI Sports Talent Assessment - OTP Service
Firebase Phone Authentication integration.

Firebase handles:
  - Sending OTP SMS via Firebase Auth
  - Rate limiting at the Firebase level
  - Phone number format validation

We handle:
  - Tracking OTP sessions in PostgreSQL
  - Verifying Firebase ID tokens server-side
  - Purpose scoping (register vs login)
"""
import uuid
from datetime import datetime, timezone
from typing import Optional

from firebase_admin import auth as firebase_auth, credentials, initialize_app, get_app
import firebase_admin
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models import OTPVerification
from app.config import settings
import logging

logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────────────────────────────────────
# FIREBASE INITIALIZATION
# ─────────────────────────────────────────────────────────────────────────────

def init_firebase():
    """Initialize Firebase Admin SDK (called once on startup)."""
    try:
        get_app()
        logger.info("Firebase already initialized.")
    except ValueError:
        if settings.FIREBASE_SERVICE_ACCOUNT_PATH:
            cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
            initialize_app(cred)
            logger.info("Firebase initialized with service account.")
        else:
            # Development mode: Firebase operations will be mocked
            logger.warning(
                "Firebase service account not configured. "
                "OTP verification will use mock mode (DEV ONLY)."
            )


# ─────────────────────────────────────────────────────────────────────────────
# OTP SESSION MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────

async def create_otp_session(
    db: AsyncSession,
    mobile_number: str,
    purpose: str = "register",
) -> OTPVerification:
    """
    Create an OTP verification session in the database.
    
    Firebase sends the actual OTP SMS to the user's phone.
    The session tracks whether verification completed successfully.
    
    Note: Firebase enforces rate limits at the platform level.
    We additionally track sessions for audit purposes.
    """
    # Invalidate any existing unverified sessions for this mobile/purpose
    existing = await db.execute(
        select(OTPVerification)
        .where(
            OTPVerification.mobile_number == mobile_number,
            OTPVerification.verified == False,
            OTPVerification.purpose == purpose,
        )
    )
    for old_session in existing.scalars().all():
        old_session.verified = True  # Expire old sessions

    # Create a placeholder token — Firebase ID token will be set during verify
    otp_record = OTPVerification(
        id=uuid.uuid4(),
        mobile_number=mobile_number,
        otp_token="PENDING",  # Will be replaced with Firebase ID token on verify
        verified=False,
        purpose=purpose,
        created_at=datetime.now(timezone.utc),
    )
    db.add(otp_record)
    await db.flush()
    return otp_record


async def verify_firebase_otp(
    db: AsyncSession,
    mobile_number: str,
    firebase_id_token: str,
    otp_session_id: uuid.UUID,
) -> bool:
    """
    Verify Firebase ID token from client-side phone auth.
    
    Flow:
    1. Client completes Firebase phone auth flow
    2. Firebase SDK returns an ID token on success
    3. We verify that ID token server-side using Firebase Admin SDK
    4. Confirm the phone number in the token matches the requested number
    5. Mark session as verified in DB
    """
    # Load session
    result = await db.execute(
        select(OTPVerification).where(OTPVerification.id == otp_session_id)
    )
    session = result.scalar_one_or_none()

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="OTP session not found. Please request a new OTP.",
        )

    if session.verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OTP session already used. Please request a new OTP.",
        )

    if session.mobile_number != mobile_number:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number mismatch.",
        )

    try:
        # Verify Firebase ID token
        decoded_token = firebase_auth.verify_id_token(firebase_id_token)
        firebase_phone = decoded_token.get("phone_number")

        if not firebase_phone:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Firebase token does not contain a phone number.",
            )

        # Normalize comparison
        if firebase_phone.replace(" ", "") != mobile_number.replace(" ", ""):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Firebase verified phone number does not match the requested number.",
            )

        # Mark session as verified and store token
        session.verified = True
        session.otp_token = firebase_id_token
        await db.flush()
        return True

    except firebase_admin.exceptions.FirebaseError as e:
        logger.error(f"Firebase token verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Firebase OTP verification failed: {str(e)}",
        )


async def get_verified_otp_session(
    db: AsyncSession,
    mobile_number: str,
    otp_session_id: uuid.UUID,
    purpose: str = "register",
) -> Optional[OTPVerification]:
    """
    Retrieve a verified OTP session for use in registration/login.
    Returns None if not found, not verified, or expired (> 10 mins).
    """
    from datetime import timedelta

    # 10 minute TTL for verified sessions to be used
    expiration_limit = datetime.now(timezone.utc) - timedelta(minutes=10)

    result = await db.execute(
        select(OTPVerification).where(
            OTPVerification.id == otp_session_id,
            OTPVerification.mobile_number == mobile_number,
            OTPVerification.verified == True,
            OTPVerification.purpose == purpose,
            OTPVerification.created_at >= expiration_limit,
        )
    )
    return result.scalar_one_or_none()
