from sqlalchemy import Column, String, Boolean, DateTime, Date, Float, Integer, ForeignKey, text
from sqlalchemy.dialects.postgresql import UUID
import uuid
from datetime import datetime
from database import Base

class AdminUser(Base):
    __tablename__ = "admin_users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String(50), default="admin")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=text("NOW()"))

class TestSession(Base):
    __tablename__ = "test_sessions"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_name = Column(String(255), nullable=False)
    test_type = Column(String(50), default="squat")
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=text("NOW()"))

class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True)
    full_name = Column(String(255), nullable=False)
    state = Column(String(100), nullable=False)
    district = Column(String(100), nullable=False)
    height_cm = Column(Float, nullable=False)
    weight_kg = Column(Float, nullable=False)
    mobile_number = Column(String(15), nullable=False)

class SquatTestResult(Base):
    __tablename__ = "squat_test_results"
    id = Column(Integer, primary_key=True, autoincrement=True)
    test_id = Column(String(36), unique=True, nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    total_reps = Column(Integer)
    correct_reps = Column(Integer)
    incorrect_reps = Column(Integer)
    accuracy = Column(Float)
    duration_seconds = Column(Integer)
    pose_confidence_score = Column(Float)
    recorded_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=text("NOW()"))

class SessionSquatResult(Base):
    __tablename__ = "session_squat_results"
    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(UUID(as_uuid=True), ForeignKey("test_sessions.id"))
    test_id = Column(String(36), unique=True, nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    total_reps = Column(Integer)
    correct_reps = Column(Integer)
    incorrect_reps = Column(Integer)
    accuracy = Column(Float)
    duration_seconds = Column(Integer)
    pose_confidence_score = Column(Float)
    recorded_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=text("NOW()"))
