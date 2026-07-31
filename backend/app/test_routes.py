"""
SAI Sports Talent Assessment - Fitness Test Routes
POST /tests/squat-result — Upload squat test results
"""
import logging
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from .database import get_db
from .schemas import SquatResultRequest

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/tests", tags=["Fitness Tests"])


# ── Schema ────────────────────────────────────────────────────────


class SquatResultResponse(BaseModel):
    status: str
    message: str
    test_id: Optional[str] = None


# ── Endpoint ──────────────────────────────────────────────────────


@router.post(
    "/squat-result",
    response_model=SquatResultResponse,
    summary="Upload squat test result",
)
async def upload_squat_result(
    body: SquatResultRequest,
    db: AsyncSession = Depends(get_db),
) -> SquatResultResponse:
    """
    Receives squat test results from the Flutter app.
    Stores them in the squat_test_results table.
    """
    try:
        logger.info(
            f"Squat result received | user={body.user_id} | "
            f"total={body.total_reps} | correct={body.correct_reps} | "
            f"accuracy={body.accuracy:.1f}%"
        )

        query = """
            INSERT INTO squat_test_results (
                test_id, user_id, 
                total_reps, correct_reps, incorrect_reps,
                accuracy, duration_seconds,
                pose_confidence_score, recorded_at
            ) VALUES (
                :test_id, :user_id,
                :total_reps, :correct_reps, :incorrect_reps,
                :accuracy, :duration_seconds,
                :pose_confidence_score, :recorded_at
            )
            ON CONFLICT (test_id) DO NOTHING
        """

        await db.execute(text(query), body.model_dump())
        await db.commit()

        logger.info(f"Squat result stored | test_id={body.test_id}")

        # SECTION 14 — VERIFY INSERT SUCCESS RESPONSE
        return SquatResultResponse(
            status="success",
            message="Squat result stored",
            test_id=body.test_id,
        )

    except Exception as e:
        await db.rollback()
        logger.error(f"Squat result upload failed: {e}")
        return SquatResultResponse(
            status="error",
            message=f"Upload failed: {str(e)}",
        )
