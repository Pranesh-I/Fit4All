from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession
from .database import get_db
from .schemas import ActiveSessionResponse, AttemptStatusResponse, SessionSquatResultRequest
from uuid import UUID
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/sessions", tags=["Sessions"])

@router.get("/active", response_model=ActiveSessionResponse)
async def get_active_session(db: AsyncSession = Depends(get_db)):
    """
    Logic:
    SELECT * FROM test_sessions 
    WHERE is_active = TRUE 
    AND CURRENT_DATE BETWEEN start_date AND end_date 
    LIMIT 1;
    """
    query = text("""
        SELECT id as session_id, session_name, test_type 
        FROM test_sessions 
        WHERE is_active = TRUE 
        AND CURRENT_DATE BETWEEN start_date AND end_date 
        LIMIT 1
    """)
    result = await db.execute(query)
    session = result.mappings().first()
    
    if not session:
        raise HTTPException(status_code=404, detail="No active session available")
    
    return session

@router.get("/{session_id}/attempt-status/{user_id}", response_model=AttemptStatusResponse)
async def check_attempt_status(session_id: UUID, user_id: UUID, db: AsyncSession = Depends(get_db)):
    """
    Logic:
    SELECT EXISTS(
        SELECT 1 FROM session_squat_results 
        WHERE session_id = :session_id AND user_id = :user_id
    );
    """
    query = text("""
        SELECT EXISTS(
            SELECT 1 FROM session_squat_results 
            WHERE session_id = :session_id AND user_id = :user_id
        )
    """)
    result = await db.execute(query, {"session_id": session_id, "user_id": user_id})
    exists = result.scalar()
    return {"already_attempted": exists}

@router.post("/squat-result")
async def save_session_squat_result(body: SessionSquatResultRequest, db: AsyncSession = Depends(get_db)):
    """
    Insert into session_squat_results
    """
    try:
        query = text("""
            INSERT INTO session_squat_results (
                session_id, test_id, user_id, 
                total_reps, correct_reps, incorrect_reps,
                accuracy, duration_seconds,
                pose_confidence_score, recorded_at
            ) VALUES (
                :session_id, :test_id, :user_id,
                :total_reps, :correct_reps, :incorrect_reps,
                :accuracy, :duration_seconds,
                :pose_confidence_score, :recorded_at
            )
        """)
        await db.execute(query, body.model_dump())
        await db.commit()
        return {"status": "success", "message": "Session result stored"}
    except Exception as e:
        await db.rollback()
        logger.error(f"Failed to save session result: {e}")
        raise HTTPException(status_code=400, detail=f"Failed to save result: {str(e)}")
