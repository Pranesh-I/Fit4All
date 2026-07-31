from pydantic import BaseModel
from uuid import UUID
from datetime import datetime, date
from typing import Optional, List

class AdminLogin(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class SessionCreate(BaseModel):
    session_name: str
    test_type: str = "squat"
    start_date: date
    end_date: date

class SessionOut(BaseModel):
    id: UUID
    session_name: str
    test_type: str
    start_date: date
    end_date: date
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class SubmissionOut(BaseModel):
    id: int
    test_id: str
    user_id: UUID
    athlete_name: str
    district: str
    state: str
    total_reps: int
    correct_reps: int
    incorrect_reps: int
    accuracy: float
    pose_confidence_score: float
    recorded_at: datetime

    class Config:
        from_attributes = True

class SubmissionDetailOut(SubmissionOut):
    height_cm: float
    weight_kg: float
    session_name: str
    mobile_number: Optional[str] = None

class DashboardStats(BaseModel):
    total_submissions: int
    highest_accuracy: float
    average_accuracy: float
    total_tests: int
