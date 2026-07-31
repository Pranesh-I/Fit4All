from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, text
import models, schemas, auth, database
from database import engine, get_db, AsyncSessionLocal
from auth import get_password_hash, verify_password, create_access_token, get_current_admin
from datetime import datetime

app = FastAPI(title="SAI Admin API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    # 1. Create tables first
    async with engine.begin() as conn:
        await conn.run_sync(models.Base.metadata.create_all)
        
    # 2. Check and insert default admin in a separate session
    async with AsyncSessionLocal() as session:
        try:
            result = await session.execute(select(models.AdminUser).where(models.AdminUser.username == "admin1"))
            if not result.scalar_one_or_none():
                admin = models.AdminUser(
                    username="admin1",
                    password_hash=get_password_hash("admin123")
                )
                session.add(admin)
                await session.commit()
        except Exception as e:
            print(f"Error during admin creation: {e}")
            await session.rollback()
        finally:
            await session.close()

@app.post("/admin/login", response_model=schemas.Token)
async def login(data: schemas.AdminLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.AdminUser).where(models.AdminUser.username == data.username))
    admin = result.scalar_one_or_none()
    if not admin or not verify_password(data.password, admin.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    access_token = create_access_token(data={"sub": admin.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/admin/create-session", response_model=schemas.SessionOut)
async def create_session(data: schemas.SessionCreate, db: AsyncSession = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    # Deactivate other sessions if this is active (simplified: only one active)
    await db.execute(text("UPDATE test_sessions SET is_active = FALSE"))
    
    new_session = models.TestSession(**data.model_dump())
    db.add(new_session)
    await db.commit()
    await db.refresh(new_session)
    return new_session

@app.get("/admin/sessions", response_model=list[schemas.SessionOut])
async def get_sessions(db: AsyncSession = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    result = await db.execute(select(models.TestSession).order_by(models.TestSession.created_at.desc()))
    return result.scalars().all()

@app.get("/admin/submissions", response_model=list[schemas.SubmissionOut])
async def get_submissions(db: AsyncSession = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    # 1. Identify active session
    active_session_result = await db.execute(select(models.TestSession.id).where(models.TestSession.is_active == True))
    active_session_id = active_session_result.scalar_one_or_none()
    
    if not active_session_id:
        return []

    # 2. Query results for THAT specific session
    query = select(
        models.SessionSquatResult.id,
        models.SessionSquatResult.test_id,
        models.SessionSquatResult.user_id,
        models.User.full_name.label("athlete_name"),
        models.User.district,
        models.User.state,
        models.SessionSquatResult.total_reps,
        models.SessionSquatResult.correct_reps,
        models.SessionSquatResult.incorrect_reps,
        models.SessionSquatResult.accuracy,
        models.SessionSquatResult.pose_confidence_score,
        models.SessionSquatResult.recorded_at
    ).join(models.User, models.SessionSquatResult.user_id == models.User.id)\
     .where(models.SessionSquatResult.session_id == active_session_id)
    
    result = await db.execute(query.order_by(models.SessionSquatResult.accuracy.desc()))
    return result.mappings().all()

@app.get("/admin/submissions/{submission_id}", response_model=schemas.SubmissionDetailOut)
async def get_submission_details(submission_id: int, db: AsyncSession = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    query = select(
        models.SessionSquatResult.id,
        models.SessionSquatResult.test_id,
        models.SessionSquatResult.user_id,
        models.User.full_name.label("athlete_name"),
        models.User.district,
        models.User.state,
        models.User.height_cm,
        models.User.weight_kg,
        models.User.mobile_number,
        models.TestSession.session_name,
        models.SessionSquatResult.total_reps,
        models.SessionSquatResult.correct_reps,
        models.SessionSquatResult.incorrect_reps,
        models.SessionSquatResult.accuracy,
        models.SessionSquatResult.pose_confidence_score,
        models.SessionSquatResult.recorded_at
    ).join(models.User, models.SessionSquatResult.user_id == models.User.id)\
     .join(models.TestSession, models.SessionSquatResult.session_id == models.TestSession.id)\
     .where(models.SessionSquatResult.id == submission_id)
    
    result = await db.execute(query)
    details = result.mappings().one_or_none()
    
    if not details:
        raise HTTPException(status_code=404, detail="Submission not found")
    return details

@app.get("/admin/dashboard-stats", response_model=schemas.DashboardStats)
async def get_stats(db: AsyncSession = Depends(get_db), current_admin: str = Depends(get_current_admin)):
    # Total tests (using session_squat_results)
    total_result = await db.execute(select(func.count(models.SessionSquatResult.id)))
    total_tests = total_result.scalar() or 0
    
    # Submissions (unique user count in session_squat_results)
    submissions_result = await db.execute(select(func.count(func.distinct(models.SessionSquatResult.user_id))))
    total_submissions = submissions_result.scalar() or 0
    
    # Accuracy stats (from session_squat_results)
    accuracy_result = await db.execute(select(
        func.max(models.SessionSquatResult.accuracy),
        func.avg(models.SessionSquatResult.accuracy)
    ))
    max_acc, avg_acc = accuracy_result.one()
    
    return {
        "total_submissions": total_submissions,
        "highest_accuracy": max_acc or 0.0,
        "average_accuracy": float(avg_acc) if avg_acc else 0.0,
        "total_tests": total_tests
    }
