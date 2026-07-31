"""
SAI Sports Talent Assessment - SQLAlchemy Models
PostgreSQL schema definitions
"""
import uuid
from datetime import datetime, date
from sqlalchemy import (
    Column, String, Float, Boolean, DateTime, Date,
    ForeignKey, Text, Integer, ARRAY
)
from sqlalchemy.dialects.postgresql import UUID, FLOAT
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class User(Base):
    """
    Athlete registration record.
    Face images are NEVER stored — only 512-d embeddings.
    """
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    full_name = Column(String(255), nullable=False)
    date_of_birth = Column(Date, nullable=False)
    gender = Column(String(20), nullable=False)  # male/female/other
    mobile_number = Column(String(15), unique=True, nullable=False, index=True)
    password_hash = Column(Text, nullable=False)
    state = Column(String(100), nullable=False)
    district = Column(String(100), nullable=False)
    sport_interest = Column(String(100), nullable=False)
    height_cm = Column(Float, nullable=False)
    weight_kg = Column(Float, nullable=False)
    face_embedding = Column(ARRAY(Float), nullable=False)  # 512-d FaceNet vector
    is_phone_verified = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    sessions = relationship("LoginSession", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User id={self.id} mobile={self.mobile_number}>"


class OTPVerification(Base):
    """
    Tracks OTP verification attempts.
    Firebase manages actual OTP delivery; we track session state here.
    """
    __tablename__ = "otp_verifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    mobile_number = Column(String(15), nullable=False, index=True)
    otp_token = Column(Text, nullable=False)  # Firebase ID token / session
    verified = Column(Boolean, default=False, nullable=False)
    purpose = Column(String(20), nullable=False, default="register")  # register | login
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    def __repr__(self):
        return f"<OTPVerification id={self.id} mobile={self.mobile_number} verified={self.verified}>"


class LoginSession(Base):
    """
    Tracks active login sessions per device.
    """
    __tablename__ = "login_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    device_id = Column(String(255), nullable=False)
    jwt_token = Column(Text, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)

    # Relationship
    user = relationship("User", back_populates="sessions")

    def __repr__(self):
        return f"<LoginSession id={self.id} user_id={self.user_id}>"


class TestSession(Base):
    """
    Assessment sessions created by admin.
    """
    __tablename__ = "test_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    session_name = Column(String(255), nullable=False)
    test_type = Column(String(50), default="squat")
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)


class SquatTestResult(Base):
    """
    Stores squat exercise assessment results (Practice Mode).
    """
    __tablename__ = "squat_test_results"

    id = Column(Integer, primary_key=True, autoincrement=True)
    test_id = Column(String(36), unique=True, nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    total_reps = Column(Integer, default=0, nullable=False)
    correct_reps = Column(Integer, default=0, nullable=False)
    incorrect_reps = Column(Integer, default=0, nullable=False)
    accuracy = Column(Float)
    duration_seconds = Column(Integer, default=0)
    pose_confidence_score = Column(Float, default=0)
    recorded_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class SessionSquatResult(Base):
    """
    Stores assessment results for specific sessions (Session Mode).
    """
    __tablename__ = "session_squat_results"

    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(UUID(as_uuid=True), ForeignKey("test_sessions.id", ondelete="CASCADE"), nullable=False)
    test_id = Column(String(36), unique=True, nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    total_reps = Column(Integer, default=0, nullable=False)
    correct_reps = Column(Integer, default=0, nullable=False)
    incorrect_reps = Column(Integer, default=0, nullable=False)
    accuracy = Column(Float, nullable=False)
    duration_seconds = Column(Integer, default=0, nullable=False)
    pose_confidence_score = Column(Float, default=0)
    recorded_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
