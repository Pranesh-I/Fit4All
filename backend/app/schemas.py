"""
SAI Sports Talent Assessment - Pydantic Schemas
Request/Response validation models
"""
from datetime import date, datetime
from typing import Optional, List
from uuid import UUID
from pydantic import BaseModel, Field, validator, field_validator
import re


# ─────────────────────────────────────────────────────────────────────────────
# SHARED VALIDATORS
# ─────────────────────────────────────────────────────────────────────────────

MOBILE_REGEX = re.compile(r"^\+91[6-9]\d{9}$")  # Indian mobile: +91XXXXXXXXXX


def validate_mobile(v: str) -> str:
    if not MOBILE_REGEX.match(v):
        raise ValueError("Mobile number must be a valid Indian number in format +91XXXXXXXXXX")
    return v


# ─────────────────────────────────────────────────────────────────────────────
# OTP SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────

class SendOTPRequest(BaseModel):
    mobile_number: str = Field(..., description="Indian mobile number: +91XXXXXXXXXX")
    purpose: str = Field(default="register", description="register | login")

    @field_validator("mobile_number")
    @classmethod
    def validate_mobile_number(cls, v):
        return validate_mobile(v)

    @field_validator("purpose")
    @classmethod
    def validate_purpose(cls, v):
        if v not in ("register", "login"):
            raise ValueError("purpose must be 'register' or 'login'")
        return v


class SendOTPResponse(BaseModel):
    otp_session_id: UUID
    message: str = "OTP sent successfully via Firebase"


class VerifyOTPRequest(BaseModel):
    mobile_number: str
    firebase_id_token: str = Field(..., description="Firebase ID token from phone auth")
    otp_session_id: UUID

    @field_validator("mobile_number")
    @classmethod
    def validate_mobile_number(cls, v):
        return validate_mobile(v)


class VerifyOTPResponse(BaseModel):
    verification_status: bool
    otp_session_id: UUID
    message: str


# ─────────────────────────────────────────────────────────────────────────────
# REGISTRATION SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────

VALID_GENDERS = {"male", "female", "other"}
VALID_STATES = {
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi", "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
}
VALID_SPORTS = {
    "Athletics", "Badminton", "Basketball", "Boxing", "Cricket",
    "Cycling", "Football", "Golf", "Gymnastics", "Hockey",
    "Judo", "Kabaddi", "Kho Kho", "Rowing", "Shooting",
    "Swimming", "Table Tennis", "Tennis", "Volleyball", "Weightlifting",
    "Wrestling", "Archery", "Aquatics"
}


class RegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=255)
    date_of_birth: date
    gender: str
    mobile_number: str
    password: str = Field(..., min_length=8, max_length=128)
    state: str
    district: str = Field(..., min_length=2, max_length=100)
    sport_interest: str
    height_cm: float = Field(..., ge=50.0, le=300.0)
    weight_kg: float = Field(..., ge=10.0, le=500.0)
    face_embedding: List[float] = Field(..., min_length=512, max_length=512)
    otp_session_id: UUID

    @field_validator("mobile_number")
    @classmethod
    def validate_mobile_number(cls, v):
        return validate_mobile(v)

    @field_validator("gender")
    @classmethod
    def validate_gender(cls, v):
        if v.lower() not in VALID_GENDERS:
            raise ValueError(f"gender must be one of: {', '.join(VALID_GENDERS)}")
        return v.lower()

    @field_validator("state")
    @classmethod
    def validate_state(cls, v):
        if v not in VALID_STATES:
            raise ValueError(f"Invalid Indian state/UT: {v}")
        return v

    @field_validator("sport_interest")
    @classmethod
    def validate_sport(cls, v):
        if v not in VALID_SPORTS:
            raise ValueError(f"Invalid sport: {v}. Must be one of SAI recognized sports.")
        return v

    @field_validator("date_of_birth")
    @classmethod
    def validate_dob(cls, v):
        from datetime import date as date_type
        today = date_type.today()
        age = (today - v).days // 365
        if age < 10 or age > 50:
            raise ValueError("Athlete must be between 10 and 50 years old")
        return v

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v):
        if not re.search(r"[A-Z]", v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not re.search(r"[a-z]", v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not re.search(r"\d", v):
            raise ValueError("Password must contain at least one digit")
        if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", v):
            raise ValueError("Password must contain at least one special character")
        return v


class RegisterResponse(BaseModel):
    status: str = "success"
    access_token: Optional[str] = None
    token_type: str = "bearer"
    user_id: UUID
    full_name: str
    message: str = "Registration successful"


# ─────────────────────────────────────────────────────────────────────────────
# LOGIN SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────

class PasswordCheckRequest(BaseModel):
    mobile_number: str
    password: str

    @field_validator("mobile_number")
    @classmethod
    def validate_mobile_number(cls, v):
        return validate_mobile(v)


class PasswordCheckResponse(BaseModel):
    status: str = "success"
    temporary_login_token: str
    message: str = "Password verified. Proceed to OTP and face verification."


class FaceVerifyRequest(BaseModel):
    temporary_login_token: str
    face_embedding: List[float] = Field(..., min_length=512, max_length=512)
    device_id: str = Field(..., min_length=1, max_length=255)


class FaceVerifyResponse(BaseModel):
    status: str = "success"
    access_token: str
    token_type: str = "bearer"
    user_id: UUID
    full_name: str
    message: str = "Authentication successful"


# ─────────────────────────────────────────────────────────────────────────────
# PROFILE SCHEMA
# ─────────────────────────────────────────────────────────────────────────────

class UserProfile(BaseModel):
    id: UUID
    full_name: str
    date_of_birth: date
    gender: str
    mobile_number: str
    state: str
    district: str
    sport_interest: str
    height_cm: float
    weight_kg: float
    is_phone_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────────────────────────────────────
# SQUAT RESULT SCHEMA
# ─────────────────────────────────────────────────────────────────────────────

class SquatResultRequest(BaseModel):
    test_id: str
    user_id: UUID
    total_reps: int
    correct_reps: int
    incorrect_reps: int
    accuracy: float
    duration_seconds: int
    pose_confidence_score: float
    recorded_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────────────────────────────────────
# SESSION SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────

class ActiveSessionResponse(BaseModel):
    session_id: UUID
    session_name: str
    test_type: str


class AttemptStatusResponse(BaseModel):
    already_attempted: bool


class SessionSquatResultRequest(BaseModel):
    session_id: UUID
    test_id: str
    user_id: UUID
    total_reps: int
    correct_reps: int
    incorrect_reps: int
    accuracy: float
    duration_seconds: int
    pose_confidence_score: float
    recorded_at: datetime


# ─────────────────────────────────────────────────────────────────────────────
# ERROR SCHEMA
# ─────────────────────────────────────────────────────────────────────────────

class ErrorResponse(BaseModel):
    detail: str
    error_code: Optional[str] = None
