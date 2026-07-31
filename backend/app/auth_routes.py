"""
SAI Sports Talent Assessment - Authentication Routes
All auth endpoints with security middleware.
"""
import uuid
import logging
from datetime import datetime, timezone
from typing import Annotated

import bcrypt
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import User, OTPVerification, LoginSession
from app.schemas import (
    SendOTPRequest, SendOTPResponse,
    VerifyOTPRequest, VerifyOTPResponse,
    RegisterRequest, RegisterResponse,
    PasswordCheckRequest, PasswordCheckResponse,
    FaceVerifyRequest, FaceVerifyResponse,
    UserProfile,
)
from app.jwt_handler import (
    create_access_token,
    create_temp_login_token,
    verify_access_token,
    verify_temp_login_token,
)
from app.face_verification import verify_face, validate_embedding
from app.otp_service import (
    create_otp_session,
    verify_firebase_otp,
    get_verified_otp_session,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])
security = HTTPBearer()
limiter = Limiter(key_func=get_remote_address)


# ─────────────────────────────────────────────────────────────────────────────
# DEPENDENCY: Get Current User from JWT
# ─────────────────────────────────────────────────────────────────────────────

async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
    db: AsyncSession = Depends(get_db),
) -> User:
    """Extract and validate the current user from the Bearer token."""
    payload = verify_access_token(credentials.credentials)
    user_id = payload.get("sub")

    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account not found or has been deactivated.",
        )
    return user


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT: Send OTP
# ─────────────────────────────────────────────────────────────────────────────

@router.post(
    "/send-otp",
    response_model=SendOTPResponse,
    summary="Initiate Firebase OTP for phone number verification",
    responses={
        429: {"description": "Rate limit exceeded"},
        400: {"description": "Invalid mobile number"},
    },
)
@limiter.limit("3/minute")
async def send_otp(
    request: Request,
    body: SendOTPRequest,
    db: AsyncSession = Depends(get_db),
) -> SendOTPResponse:
    """
    Initiates OTP flow via Firebase Phone Authentication.

    - For registration: verifies phone is not already registered
    - Creates a session record in otp_verifications table
    - Firebase handles actual SMS delivery

    Rate limited: 3 requests per minute per IP
    """
    # For registration: block if mobile already registered
    if body.purpose == "register":
        result = await db.execute(
            select(User).where(User.mobile_number == body.mobile_number)
        )
        existing = result.scalar_one_or_none()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="This mobile number is already registered. Please login instead.",
            )

    # For login: verify the user exists
    if body.purpose == "login":
        result = await db.execute(
            select(User).where(User.mobile_number == body.mobile_number)
        )
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No account found with this mobile number.",
            )

    # Create OTP session in DB
    session = await create_otp_session(db, body.mobile_number, body.purpose)

    logger.info(
        f"OTP session created for {body.mobile_number} "
        f"(purpose={body.purpose}, session_id={session.id})"
    )

    return SendOTPResponse(
        otp_session_id=session.id,
        message=(
            "OTP has been sent to your mobile via Firebase. "
            "Please complete the Firebase phone auth flow in the app."
        ),
    )


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT: Verify OTP
# ─────────────────────────────────────────────────────────────────────────────

@router.post(
    "/verify-otp",
    response_model=VerifyOTPResponse,
    summary="Verify Firebase ID token from phone auth",
)
@limiter.limit("5/minute")
async def verify_otp(
    request: Request,
    body: VerifyOTPRequest,
    db: AsyncSession = Depends(get_db),
) -> VerifyOTPResponse:
    """
    Verifies the Firebase ID token returned after successful phone OTP.

    The Flutter app completes Firebase phone auth and sends the resulting
    ID token here. We verify it server-side using Firebase Admin SDK.
    """
    is_verified = await verify_firebase_otp(
        db,
        body.mobile_number,
        body.firebase_id_token,
        body.otp_session_id,
    )

    return VerifyOTPResponse(
        verification_status=is_verified,
        otp_session_id=body.otp_session_id,
        message="Phone number verified successfully." if is_verified else "Verification failed.",
    )


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT: Register
# ─────────────────────────────────────────────────────────────────────────────

@router.post(
    "/register",
    response_model=RegisterResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register new athlete with face embedding",
)
async def register(
    body: RegisterRequest,
    db: AsyncSession = Depends(get_db),
) -> RegisterResponse:
    """
    Registers a new athlete. All validations must pass before storage.
    """
    # STEP 2 & 9 — Normalize fields and add debug logging
    body.gender = body.gender.lower().strip()
    body.state = body.state.strip()
    body.sport_interest = body.sport_interest.strip()
    body.mobile_number = body.mobile_number.strip()

    print("Incoming registration request:")
    print("Name:", body.full_name)
    print("Gender:", body.gender)
    print("State:", body.state)
    print("Sport:", body.sport_interest)
    print("Mobile:", body.mobile_number)
    print("Embedding length:", len(body.face_embedding))

    # STEP 3 — Validate embedding length
    if len(body.face_embedding) != 512:
        raise HTTPException(status_code=422, detail="Embedding must be length 512")

    try:
        # STEP 4 — Validate OTP session exists
        # Using the existing helper which also checks verification and expiration
        otp_session = await get_verified_otp_session(
            db, body.mobile_number, body.otp_session_id, purpose="register"
        )
        if not otp_session:
            raise HTTPException(status_code=422, detail="Invalid or expired OTP session")

        # Check duplicate mobile
        result = await db.execute(
            select(User).where(User.mobile_number == body.mobile_number)
        )
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Mobile number already registered.",
            )

        if not validate_embedding(body.face_embedding):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Invalid face embedding content.",
            )

        # Hash password with bcrypt
        password_bytes = body.password.encode("utf-8")
        salt = bcrypt.gensalt(rounds=12)
        password_hash = bcrypt.hashpw(password_bytes, salt).decode("utf-8")

        # Create user record
        new_user = User(
            id=uuid.uuid4(),
            full_name=body.full_name.strip(),
            date_of_birth=body.date_of_birth,
            gender=body.gender,
            mobile_number=body.mobile_number,
            password_hash=password_hash,
            state=body.state,
            district=body.district.strip(),
            sport_interest=body.sport_interest,
            height_cm=body.height_cm,
            weight_kg=body.weight_kg,
            face_embedding=body.face_embedding,
            is_phone_verified=True,
            created_at=datetime.now(timezone.utc),
        )
        db.add(new_user)

        # Cleanup the used OTP session
        await db.delete(otp_session)
        await db.flush()

        # Issue JWT access token - REMOVED AS PER REQUIREMENT
        # access_token = create_access_token(str(new_user.id), new_user.mobile_number)

        logger.info(f"New athlete registered: {new_user.id} ({new_user.mobile_number})")

        return RegisterResponse(
            user_id=new_user.id,
            full_name=new_user.full_name,
            message="Registration successful. Please login with your mobile number and password.",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Registration error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Registration failed: {str(e)}"
        )


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT: Login Step 1 — Password Check
# ─────────────────────────────────────────────────────────────────────────────

@router.post(
    "/login-password-check",
    response_model=PasswordCheckResponse,
    summary="Step 1: Verify mobile + password, returns temp token",
)
@limiter.limit("10/minute")
async def login_password_check(
    request: Request,
    body: PasswordCheckRequest,
    db: AsyncSession = Depends(get_db),
) -> PasswordCheckResponse:
    """
    Login step 1: Verifies phone number and password.

    Returns a short-lived (10-min) temporary token if valid.
    This token is required for the face verification step.

    Security:
    - Constant-time password comparison via bcrypt
    - Generic error messages to prevent user enumeration
    """
    # Fetch user
    result = await db.execute(
        select(User).where(User.mobile_number == body.mobile_number)
    )
    user = result.scalar_one_or_none()

    # Constant-time comparison: always run bcrypt even if user not found
    dummy_hash = "$2b$12$KIXfKh0cFn1R3Jl5o9bxqO5P3VYQj3Rf2PGbxeO9vVkCl2Hx6oqpi"
    stored_hash = user.password_hash if user else dummy_hash

    password_match = bcrypt.checkpw(
        body.password.encode("utf-8"),
        stored_hash.encode("utf-8"),
    )

    if not user or not password_match:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials. Please check your mobile number and password.",
        )

    # Issue short-lived temp token
    temp_token = create_temp_login_token(str(user.id), user.mobile_number)

    logger.info(f"Password verified for user {user.id}. Proceeding to OTP+face step.")

    return PasswordCheckResponse(
        temporary_login_token=temp_token,
        message="Password verified. Complete OTP and face verification to login.",
    )


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT: Login Step 2 — Face Verification
# ─────────────────────────────────────────────────────────────────────────────

@router.post(
    "/login-face-verify",
    response_model=FaceVerifyResponse,
    summary="Step 2: Face embedding comparison, returns JWT on success",
)
@limiter.limit("5/minute")
async def login_face_verify(
    request: Request,
    body: FaceVerifyRequest,
    db: AsyncSession = Depends(get_db),
) -> FaceVerifyResponse:
    """
    Login step 2: Compares live face embedding against stored embedding.

    Security:
    - Validates temporary login token (must not be expired)
    - Cosine distance must be < 0.5
    - Creates login session record for audit trail
    - Issues 24-hour JWT access token on success
    """
    # Validate temp token
    payload = verify_temp_login_token(body.temporary_login_token)
    user_id = payload["sub"]

    # Fetch user
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account not found.",
        )

    # Validate live embedding
    if not validate_embedding(body.face_embedding):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid face embedding. Ensure your face is clearly visible.",
        )

    # Compare embeddings
    is_match, distance = verify_face(user.face_embedding, body.face_embedding)

    if not is_match:
        logger.warning(
            f"Face verification FAILED for user {user_id}. "
            f"Distance={distance:.4f}, Threshold={0.5}"
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=(
                f"Face verification failed (distance={distance:.3f}). "
                "Please ensure adequate lighting and face the camera directly."
            ),
        )

    logger.info(
        f"Face verification PASSED for user {user_id}. Distance={distance:.4f}"
    )

    # Issue full access token
    access_token = create_access_token(str(user.id), user.mobile_number)

    # Record login session
    session = LoginSession(
        id=uuid.uuid4(),
        user_id=user.id,
        device_id=body.device_id,
        jwt_token=access_token,
        is_active=True,
        created_at=datetime.now(timezone.utc),
    )
    db.add(session)
    await db.flush()

    return FaceVerifyResponse(
        access_token=access_token,
        user_id=user.id,
        full_name=user.full_name,
        message="Authentication successful. Welcome back!",
    )


# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT: Get Profile
# ─────────────────────────────────────────────────────────────────────────────

@router.get(
    "/profile",
    response_model=UserProfile,
    summary="Get authenticated athlete's profile",
)
async def get_profile(
    current_user: User = Depends(get_current_user),
) -> UserProfile:
    """
    Returns the authenticated athlete's profile.
    Requires valid Bearer JWT token.
    
    Note: face_embedding is deliberately excluded from response.
    """
    return UserProfile.model_validate(current_user)
