from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
from app.exercises.squat.logic import SquatAnalyzer

router = APIRouter(prefix="/local", tags=["Local Edge Processing"])

# Simple memory storage for analyzer instances
# In production, you would probably tie this to a specific session_id in a DB or cache
# For local embedded runtime, an in-memory dictionary works well
_analyzers = {}

class FrameData(BaseModel):
    session_id: str
    hip_x: float
    hip_y: float
    knee_x: float
    knee_y: float
    ankle_x: float
    ankle_y: float
    heel_y: float
    toe_x: float
    shoulder_x: float
    shoulder_y: float
    knee_visibility: float
    hip_visibility: float
    ankle_visibility: float
    timestamp: str
    is_facing_right: bool

@router.post("/squat-frame-analysis")
async def process_squat_frame(data: FrameData):
    session_id = data.session_id
    if session_id not in _analyzers:
        _analyzers[session_id] = SquatAnalyzer()
        
    analyzer = _analyzers[session_id]
    
    result = analyzer.process_frame(data.model_dump())
    return result

@router.delete("/squat-session/{session_id}")
async def end_squat_session(session_id: str):
    if session_id in _analyzers:
        del _analyzers[session_id]
    return {"success": True}
