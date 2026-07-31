# 🔐 Backend Code Explanation - Explained Like You're a Baby!

Welcome! This document explains **EVERY SINGLE LINE** of your backend code in super simple terms. Think of it like learning to walk - we'll take it one tiny step at a time! 👶

---

## 📁 What is the Backend?

The backend is like a **restaurant kitchen**. When you order food (make a request on your app), the kitchen (backend) prepares it and sends it back. You don't see what happens inside, but it's doing all the important work!

---

## 📂 File-by-File Breakdown

---

# 1️⃣ `requirements.txt` - The Shopping List 🛒

```
fastapi>=0.115.0
```
**What it does:** This is like ordering a pizza delivery system for your restaurant. FastAPI is the tool that helps your app receive orders (requests) from customers.

**Why we need it:** Without it, your app can't talk to the outside world!

---

```
uvicorn[standard]>=0.30.0
```
**What it does:** This is like the **engine** that runs your FastAPI car. Uvicorn makes your app actually work and respond to people.

**Why we need it:** FastAPI is the design, Uvicorn is the engine that makes it move!

---

```
sqlalchemy>=2.0.0
```
**What it does:** This is a **translator** between Python (your code) and PostgreSQL (your database where data is stored).

**Why we need it:** Python and databases speak different languages. SQLAlchemy translates between them!

---

```
asyncpg>=0.29.0
```
**What it does:** This is a **super-fast messenger** that helps Python talk to PostgreSQL database.

**Why we need it:** It makes database requests really quick, like sending a text instead of a letter!

---

```
alembic>=1.13.0
```
**What it does:** This is like a **construction worker** for your database. It helps you build and change database tables.

**Why we need it:** When you need to add new features that change how data is stored, Alembic helps!

---

```
pydantic>=2.7.0
```
**What it does:** This is a **security guard** that checks if the data coming into your app is correct.

**Why we need it:** It makes sure people send the right information (like proper phone numbers, not random text).

---

```
pydantic-settings>=2.3.0
```
**What it does:** This helps your app read **settings** from files (like passwords, database addresses).

**Why we need it:** You don't want to hardcode secrets in your code. This reads them safely from environment files!

---

```
python-jose[cryptography]>=3.3.0
```
**What it does:** This creates **secret identity cards** (JWT tokens) for users after they login.

**Why we need it:** After login, users get a token (like a VIP pass) that proves who they are without logging in again!

---

```
bcrypt>=4.1.0
```
**What it does:** This **scrambles passwords** so even if hackers steal your database, they can't read passwords.

**Why we need it:** Never store passwords as plain text! bcrypt turns "mypassword123" into gibberish like "$2b$12$KIXf..." that can't be reversed.

---

```
firebase-admin>=6.5.0
```
**What it does:** This connects to **Google Firebase** to send OTP (One-Time Password) codes to users' phones.

**Why we need it:** When someone signs up, Firebase sends them an SMS with a verification code!

---

```
slowapi>=0.1.9
```
**What it does:** This **limits how many times** someone can call your API (like "only 3 OTP requests per minute").

**Why we need it:** Prevents hackers from spamming your app or sending millions of OTPs!

---

```
python-multipart>=0.0.9
```
**What it does:** This helps your app receive **file uploads** (like images or documents).

**Why we need it:** Sometimes users need to upload files, and this makes that possible!

---

```
httpx>=0.27.0
```
**What it does:** This is like a **web browser** for your backend. It can make HTTP requests to other services.

**Why we need it:** Sometimes your backend needs to call other APIs or services!

---

# 2️⃣ `schema.sql` - The Blueprint 📐

This file is like an **architect's blueprint** for your database. It tells the database how to build tables (where data lives).

---

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
**What it does:** This installs a tool that creates **unique IDs** (UUIDs) for each user.

**Why we need it:** Every user needs a unique ID, like a social security number. UUID ensures no two users have the same ID!

---

```sql
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
```
**What it does:** This adds **super-fast search** capabilities to your database.

**Why we need it:** Makes searching through text (like names) much faster!

---

```sql
CREATE TABLE IF NOT EXISTS users (
    id                  UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
```
**What it does:** This creates the **users table** (like a spreadsheet) where athlete information is stored. The `id` column is the primary key (main identifier) that auto-generates a unique UUID.

**Why we need it:** This is where all user data lives! Every row is one athlete.

---

```sql
    full_name           VARCHAR(255)    NOT NULL,
```
**What it does:** Stores the user's name. `VARCHAR(255)` means text up to 255 characters. `NOT NULL` means it's required.

**Why we need it:** You need to know the athlete's name!

---

```sql
    date_of_birth       DATE            NOT NULL,
```
**What it does:** Stores when the athlete was born (as a date).

**Why we need it:** To check their age and make sure they're eligible (10-50 years old).

---

```sql
    gender              VARCHAR(20)     NOT NULL CHECK (gender IN ('male', 'female', 'other')),
```
**What it does:** Stores gender. The `CHECK` part makes sure it can ONLY be 'male', 'female', or 'other' - nothing else!

**Why we need it:** Prevents invalid data from being stored!

---

```sql
    mobile_number       VARCHAR(15)     NOT NULL UNIQUE,
```
**What it does:** Stores phone number. `UNIQUE` means no two users can have the same phone number.

**Why we need it:** Phone number is how users login and get OTP codes. Must be unique!

---

```sql
    password_hash       TEXT            NOT NULL,
```
**What it does:** Stores the **scrambled password** (not the real password!). `TEXT` means it can be very long.

**Why we need it:** When users login, we scramble their password and compare it to this. Never store real passwords!

---

```sql
    state               VARCHAR(100)    NOT NULL,
    district            VARCHAR(100)    NOT NULL,
```
**What it does:** Stores which Indian state and district the athlete is from.

**Why we need it:** For sports talent assessment, location matters for regional programs!

---

```sql
    sport_interest      VARCHAR(100)    NOT NULL,
```
**What it does:** Stores which sport the athlete is interested in (Cricket, Swimming, etc.).

**Why we need it:** So the app knows which sport to assess them for!

---

```sql
    height_cm           FLOAT           NOT NULL CHECK (height_cm BETWEEN 50 AND 300),
    weight_kg           FLOAT           NOT NULL CHECK (weight_kg BETWEEN 10 AND 500),
```
**What it does:** Stores height (in centimeters) and weight (in kilograms). The `CHECK` ensures realistic values only!

**Why we need it:** Physical measurements are important for sports assessment!

---

```sql
    face_embedding      FLOAT[]         NOT NULL,  -- 512-dimensional FaceNet vector
```
**What it does:** This stores a **mathematical representation of the user's face** as 512 numbers. NOT a photo!

**Why we need it:** This is for face verification during login. The app compares the stored numbers with a live face scan. PRIVACY: Raw face images are NEVER stored!

---

```sql
    is_phone_verified   BOOLEAN         NOT NULL DEFAULT FALSE,
```
**What it does:** A TRUE/FALSE flag that tracks if the user's phone number has been verified via OTP.

**Why we need it:** Only verified users should be able to use the app!

---

```sql
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
```
**What it does:** Stores when the user registered (with timezone).

**Why we need it:** For tracking and auditing purposes!

---

```sql
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile_number);
```
**What it does:** Creates a **super-fast lookup** for phone numbers in the database.

**Why we need it:** When users login with phone number, this makes the search instant!

---

```sql
ALTER TABLE users ADD CONSTRAINT chk_embedding_dimension
    CHECK (array_length(face_embedding, 1) = 512);
```
**What it does:** Makes absolutely sure the face embedding is ALWAYS exactly 512 numbers.

**Why we need it:** If it's not 512, face verification won't work!

---

```sql
CREATE TABLE IF NOT EXISTS otp_verifications (
    id              UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    mobile_number   VARCHAR(15)     NOT NULL,
    otp_token       VARCHAR(512)    NOT NULL,
    verified        BOOLEAN         NOT NULL DEFAULT FALSE,
    purpose         VARCHAR(20)     NOT NULL DEFAULT 'register' CHECK (purpose IN ('register', 'login')),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);
```
**What it does:** Creates a table to **track OTP sessions**. When someone requests an OTP, a record is created here.

**Why we need it:** To prevent OTP reuse and track verification attempts!

---

```sql
CREATE TABLE IF NOT EXISTS login_sessions (
    id          UUID            PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id   VARCHAR(255)    NOT NULL,
    jwt_token   TEXT            NOT NULL,
    is_active   BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMPTZ
);
```
**What it does:** Creates a table to **track active login sessions** (which devices the user is logged into).

**Why we need it:** For security - you can see where users are logged in and logout remotely if needed!

---

```sql
CREATE TABLE IF NOT EXISTS fitness_test_results (
    id                      SERIAL          PRIMARY KEY,
    test_id                 VARCHAR(36)     NOT NULL UNIQUE,
    user_id                 VARCHAR(36)     NOT NULL,
    test_type               VARCHAR(50)     NOT NULL DEFAULT 'sit_up',
    total_reps              INTEGER         NOT NULL DEFAULT 0,
    correct_reps            INTEGER         NOT NULL DEFAULT 0,
    incorrect_reps          INTEGER         NOT NULL DEFAULT 0,
    accuracy                FLOAT           NOT NULL CHECK (accuracy BETWEEN 0 AND 100),
    duration_seconds        INTEGER         NOT NULL DEFAULT 0,
    pose_confidence_score   FLOAT           NOT NULL DEFAULT 0,
    recorded_at             TIMESTAMPTZ     NOT NULL,
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);
```
**What it does:** Creates a table to **store fitness test results** (sit-ups, squats, etc.) from the mobile app.

**Why we need it:** Athletes do physical tests offline, and results sync to the database when internet is available!

---

# 3️⃣ `config.py` - The Settings Panel ⚙️

This file stores all the **configuration settings** for your app, like a control panel.

---

```python
import os
```
**What it does:** Imports the `os` module to interact with the operating system (like reading environment variables).

**Why we need it:** To read secret settings from `.env` files securely!

---

```python
from functools import lru_cache
```
**What it does:** Imports a tool that **caches** (remembers) function results so they don't need to be recalculated.

**Why we need it:** Settings are loaded once and remembered, making the app faster!

---

```python
from pydantic_settings import BaseSettings
```
**What it does:** Imports a class that makes it easy to load settings from environment variables and `.env` files.

**Why we need it:** Pydantic validates that settings are correct and loads them automatically!

---

```python
class Settings(BaseSettings):
```
**What it does:** Creates a class called `Settings` that will hold all configuration values.

**Why we need it:** Groups all settings in one place, making them easy to manage!

---

```python
    APP_NAME: str = "SAI Sports Talent Assessment"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"
```
**What it does:** Sets basic app info: name, version, whether debug mode is on, and environment (development vs production).

**Why we need it:** Debug mode shows detailed errors (good for testing, bad for production). Environment tells the app where it's running!

---

```python
    DATABASE_URL: str = "postgresql+asyncpg://sai_user:sai_password@localhost:5432/sai_sports_db"
```
**What it does:** The **address** of your database. It says:
- Type: PostgreSQL
- Driver: asyncpg (async version)
- Username: sai_user
- Password: sai_password
- Location: localhost (your computer)
- Port: 5432
- Database name: sai_sports_db

**Why we need it:** Without this, the app doesn't know where to find the database!

---

```python
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 30
```
**What it does:** Sets how many **simultaneous database connections** the app can have (20 normal + 30 extra during busy times).

**Why we need it:** Like having multiple cashiers at a store - more connections = faster service for many users!

---

```python
    JWT_SECRET_KEY: str = "your-super-secret-jwt-key-change-in-production-min-256-bits"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_HOURS: int = 24
    JWT_TEMP_TOKEN_EXPIRE_MINUTES: int = 10
```
**What it does:** 
- `JWT_SECRET_KEY`: The **master password** used to sign JWT tokens (MUST be kept secret!)
- `JWT_ALGORITHM`: The math formula used to create tokens (HS256)
- `JWT_ACCESS_TOKEN_EXPIRE_HOURS`: How long login tokens last (24 hours)
- `JWT_TEMP_TOKEN_EXPIRE_MINUTES`: How long temporary login tokens last (10 minutes)

**Why we need it:** JWT tokens prove who users are. The secret key prevents fake tokens!

---

```python
    BCRYPT_ROUNDS: int = 12
```
**What it does:** Sets how many times bcrypt **scrambles** the password. Higher = more secure but slower.

**Why we need it:** 12 rounds is a good balance between security and speed!

---

```python
    FACE_SIMILARITY_THRESHOLD: float = 0.5
    FACE_EMBEDDING_DIMENSION: int = 512
```
**What it does:**
- `FACE_SIMILARITY_THRESHOLD`: The maximum "distance" allowed between two face scans to consider them the same person (lower = stricter)
- `FACE_EMBEDDING_DIMENSION`: How many numbers make up a face embedding (512)

**Why we need it:** Controls how strict face verification is. 0.5 means faces must be reasonably similar!

---

```python
    FIREBASE_PROJECT_ID: Optional[str] = None
    FIREBASE_SERVICE_ACCOUNT_PATH: Optional[str] = None
```
**What it does:** Stores Firebase configuration for sending OTP codes via SMS.

**Why we need it:** Firebase handles the actual OTP SMS delivery!

---

```python
    OTP_RATE_LIMIT_PER_MINUTE: int = 3
    LOGIN_RATE_LIMIT_PER_MINUTE: int = 10
```
**What it does:** Limits how many OTP requests (3) and login attempts (10) someone can make per minute.

**Why we need it:** Prevents hackers from spamming your system!

---

```python
    ALLOWED_ORIGINS: list[str] = ["*"]
```
**What it does:** Controls which websites/apps can talk to your backend. `["*"]` means "allow everyone" (okay for testing, bad for production).

**Why we need it:** Security feature called CORS - prevents unauthorized apps from accessing your API!

---

```python
    HTTPS_ONLY: bool = False
```
**What it does:** If True, only allows secure (HTTPS) connections.

**Why we need it:** In production, always set this to True to encrypt all data in transit!

---

```python
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
```
**What it does:** Tells Pydantic to read settings from the `.env` file with UTF-8 encoding.

**Why we need it:** This is how secret values get loaded without being hardcoded!

---

```python
@lru_cache()
def get_settings() -> Settings:
    return Settings()
```
**What it does:** Creates a function that returns Settings, but **only loads them once** (thanks to `@lru_cache()`).

**Why we need it:** Makes the app faster by not reloading settings every time!

---

```python
settings = get_settings()
```
**What it does:** Actually calls the function and stores the settings in a variable called `settings`.

**Why we need it:** Now other files can just `from app.config import settings` to access all configuration!

---

# 4️⃣ `database.py` - The Database Connection 🔌

This file sets up the **connection** to your PostgreSQL database.

---

```python
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    create_async_engine,
    async_sessionmaker,
)
```
**What it does:** Imports tools for **async** (non-blocking) database connections.

**Why we need it:** Async means the app can handle other requests while waiting for the database - much faster!

---

```python
from sqlalchemy.orm import DeclarativeBase
```
**What it does:** Imports the base class that all your database models (tables) will inherit from.

**Why we need it:** This is the foundation for defining database tables in Python!

---

```python
from sqlalchemy.pool import NullPool
```
**What it does:** Imports a connection pool manager (though it's not actually used in this code).

**Why we need it:** Would be used if you wanted to disable connection pooling (not needed here).

---

```python
from typing import AsyncGenerator
```
**What it does:** Imports a type hint for async generators (functions that yield values over time).

**Why we need it:** Used for the database session dependency that yields a session and cleans it up!

---

```python
from app.config import settings
```
**What it does:** Imports the settings we just discussed (database URL, pool size, etc.).

**Why we need it:** To configure the database connection with the right settings!

---

```python
class Base(DeclarativeBase):
    pass
```
**What it does:** Creates the **base class** that all your database models will inherit from.

**Why we need it:** Every model (User, OTPVerification, etc.) extends this Base class!

---

```python
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_MAX_OVERFLOW,
    pool_pre_ping=True,
    pool_recycle=3600,
)
```
**What it does:** Creates the **database engine** - the main connection to PostgreSQL.
- `settings.DATABASE_URL`: Where the database is
- `echo=settings.DEBUG`: If True, prints all SQL queries (good for debugging)
- `pool_size`: How many connections to keep open
- `max_overflow`: Extra connections during busy times
- `pool_pre_ping=True`: Tests connections before using them (prevents errors)
- `pool_recycle=3600`: Recycles connections every hour (prevents stale connections)

**Why we need it:** This is the main pipeline to your database!

---

```python
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)
```
**What it does:** Creates a **factory** that makes database sessions (individual connections).
- `expire_on_commit=False`: Keeps data accessible after saving
- `autocommit=False`: You must manually commit changes (safer)
- `autoflush=False`: You control when changes are sent to database

**Why we need it:** Each request gets its own session for safety and isolation!

---

```python
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency: yields database session and ensures cleanup."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```
**What it does:** This is a **dependency** that FastAPI uses to give each request a database session.
1. Opens a new session
2. `yield session`: Gives the session to the request handler
3. If successful: commits (saves) changes
4. If error: rolls back (undoes) changes
5. Always: closes the session

**Why we need it:** Ensures every request gets a clean database session that's properly cleaned up!

---

```python
async def init_db():
    """Initialize database tables (run on startup)."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
```
**What it does:** Creates all database tables when the app starts (if they don't exist).

**Why we need it:** So your app can create its own tables instead of manually running SQL!

---

```python
async def close_db():
    """Dispose engine on shutdown."""
    await engine.dispose()
```
**What it does:** Closes all database connections when the app shuts down.

**Why we need it:** Prevents resource leaks and database connection issues!

---

# 5️⃣ `models.py` - The Database Tables 📊

This file defines your database tables as **Python classes** (using SQLAlchemy).

---

```python
import uuid
```
**What it does:** Imports the UUID module to generate unique IDs.

**Why we need it:** Every user needs a unique identifier!

---

```python
from datetime import datetime, date
```
**What it does:** Imports tools to work with dates and times.

**Why we need it:** To store when users registered, their birthdate, etc.!

---

```python
from sqlalchemy import (
    Column, String, Float, Boolean, DateTime, Date,
    ForeignKey, Text, Integer, ARRAY
)
```
**What it does:** Imports all the **column types** you can use in database tables.

**Why we need it:** These are the building blocks for defining table structure!

---

```python
from sqlalchemy.dialects.postgresql import UUID, FLOAT
```
**What it does:** Imports PostgreSQL-specific column types.

**Why we need it:** UUID and FLOAT work better with PostgreSQL's native types!

---

```python
from sqlalchemy.orm import relationship
```
**What it does:** Imports the tool to create **relationships** between tables (like linking users to their login sessions).

**Why we need it:** So you can easily access related data (like `user.sessions` to get all login sessions)!

---

```python
from app.database import Base
```
**What it does:** Imports the Base class we created in database.py.

**Why we need it:** All models must inherit from Base!

---

```python
class User(Base):
    """
    Athlete registration record.
    Face images are NEVER stored — only 512-d embeddings.
    """
    __tablename__ = "users"
```
**What it does:** Creates the **User model** that maps to the "users" table in the database.

**Why we need it:** This is how Python interacts with the users table!

---

```python
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
```
**What it does:** Creates the `id` column as a UUID primary key that auto-generates.

**Why we need it:** Every user needs a unique ID!

---

```python
    full_name = Column(String(255), nullable=False)
```
**What it does:** Creates a column for the user's full name (max 255 characters, required).

**Why we need it:** To store the athlete's name!

---

```python
    date_of_birth = Column(Date, nullable=False)
```
**What it does:** Creates a column for birthdate.

**Why we need it:** To verify age eligibility!

---

```python
    gender = Column(String(20), nullable=False)
```
**What it does:** Creates a column for gender (male/female/other).

**Why we need it:** For sports categorization!

---

```python
    mobile_number = Column(String(15), unique=True, nullable=False, index=True)
```
**What it does:** Creates a column for phone number (unique, required, indexed for fast lookup).

**Why we need it:** This is how users login!

---

```python
    password_hash = Column(Text, nullable=False)
```
**What it does:** Creates a column for the **scrambled password**.

**Why we need it:** To verify passwords during login without storing the real password!

---

```python
    state = Column(String(100), nullable=False)
    district = Column(String(100), nullable=False)
    sport_interest = Column(String(100), nullable=False)
```
**What it does:** Creates columns for location and sport preferences.

**Why we need it:** For regional sports programs!

---

```python
    height_cm = Column(Float, nullable=False)
    weight_kg = Column(Float, nullable=False)
```
**What it does:** Creates columns for physical measurements.

**Why we need it:** Important for sports assessment!

---

```python
    face_embedding = Column(ARRAY(Float), nullable=False)
```
**What it does:** Creates a column to store the **512-number face embedding** as an array.

**Why we need it:** For face verification without storing actual photos!

---

```python
    is_phone_verified = Column(Boolean, default=False, nullable=False)
```
**What it does:** Creates a TRUE/FALSE column for phone verification status.

**Why we need it:** Only verified users can access the app!

---

```python
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
```
**What it does:** Creates a timestamp column that auto-fills with the current time when a user is created.

**Why we need it:** For tracking when users registered!

---

```python
    sessions = relationship("LoginSession", back_populates="user", cascade="all, delete-orphan")
```
**What it does:** Creates a **relationship** to the LoginSession table. `cascade="all, delete-orphan"` means if a user is deleted, all their sessions are deleted too.

**Why we need it:** So you can do `user.sessions` to get all login sessions for that user!

---

```python
class OTPVerification(Base):
    __tablename__ = "otp_verifications"
```
**What it does:** Creates the OTP tracking table.

**Why we need it:** To track OTP sessions and prevent reuse!

---

```python
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    mobile_number = Column(String(15), nullable=False, index=True)
    otp_token = Column(String(512), nullable=False)
    verified = Column(Boolean, default=False, nullable=False)
    purpose = Column(String(20), nullable=False, default="register")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
```
**What it does:** Creates all the columns for OTP tracking:
- `id`: Unique ID
- `mobile_number`: Which phone number requested OTP
- `otp_token`: Firebase token after verification
- `verified`: Whether OTP was successfully verified
- `purpose`: Was this for registration or login?
- `created_at`: When was this OTP requested?

**Why we need it:** To manage OTP lifecycle and prevent abuse!

---

```python
class LoginSession(Base):
    __tablename__ = "login_sessions"
```
**What it does:** Creates the login session tracking table.

**Why we need it:** To track which devices users are logged in from!

---

```python
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    device_id = Column(String(255), nullable=False)
    jwt_token = Column(Text, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)
```
**What it does:** Creates columns for session tracking:
- `user_id`: Links to the users table (foreign key)
- `device_id`: Which device is logged in
- `jwt_token`: The actual token string
- `is_active`: Is this session still valid?
- `created_at`: When did they login?
- `expires_at`: When does the session expire?

**Why we need it:** For security and session management!

---

```python
    user = relationship("User", back_populates="sessions")
```
**What it does:** Creates the other side of the relationship (from session back to user).

**Why we need it:** So you can do `session.user` to get the user who owns this session!

---

# 6️⃣ `schemas.py` - The Data Validators 📝

This file defines **what data is allowed** to come in and go out of your API. Think of it as a bouncer at a club!

---

```python
from datetime import date, datetime
from typing import Optional, List
from uuid import UUID
from pydantic import BaseModel, Field, validator, field_validator
import re
```
**What it does:** Imports tools for data validation:
- `date, datetime`: For date/time validation
- `Optional, List`: For type hints
- `UUID`: For UUID validation
- `BaseModel, Field, validator`: Pydantic validation tools
- `re`: For regular expressions (pattern matching)

**Why we need it:** To validate incoming data before it hits your database!

---

```python
MOBILE_REGEX = re.compile(r"^\+91[6-9]\d{9}$")
```
**What it does:** Creates a **pattern** that matches valid Indian phone numbers:
- `^\+91`: Must start with +91 (India country code)
- `[6-9]`: Next digit must be 6, 7, 8, or 9
- `\d{9}`: Followed by exactly 9 more digits

**Why we need it:** To ensure only valid Indian phone numbers are accepted!

---

```python
def validate_mobile(v: str) -> str:
    if not MOBILE_REGEX.match(v):
        raise ValueError("Mobile number must be a valid Indian number in format +91XXXXXXXXXX")
    return v
```
**What it does:** A function that checks if a phone number matches the Indian format. If not, it raises an error.

**Why we need it:** Reusable validation function used by multiple schemas!

---

```python
class SendOTPRequest(BaseModel):
    mobile_number: str = Field(..., description="Indian mobile number: +91XXXXXXXXXX")
    purpose: str = Field(default="register", description="register | login")
```
**What it does:** Defines what data is needed to **request an OTP**:
- `mobile_number`: Required (the `...` means required)
- `purpose`: Optional, defaults to "register", can be "register" or "login"

**Why we need it:** Ensures the OTP request has valid data!

---

```python
    @field_validator("mobile_number")
    @classmethod
    def validate_mobile_number(cls, v):
        return validate_mobile(v)
```
**What it does:** Runs the `validate_mobile` function on the mobile_number field before accepting the data.

**Why we need it:** Automatic validation! If the number is invalid, Pydantic rejects it before your code even runs!

---

```python
    @field_validator("purpose")
    @classmethod
    def validate_purpose(cls, v):
        if v not in ("register", "login"):
            raise ValueError("purpose must be 'register' or 'login'")
        return v
```
**What it does:** Makes sure purpose is either "register" or "login", nothing else.

**Why we need it:** Prevents invalid purpose values!

---

```python
class SendOTPResponse(BaseModel):
    otp_session_id: UUID
    message: str = "OTP sent successfully via Firebase"
```
**What it does:** Defines what the **response** looks like after sending OTP:
- `otp_session_id`: The unique ID for this OTP session
- `message`: A success message

**Why we need it:** Ensures consistent response format!

---

```python
class VerifyOTPRequest(BaseModel):
    mobile_number: str
    firebase_id_token: str = Field(..., description="Firebase ID token from phone auth")
    otp_session_id: UUID
```
**What it does:** Defines what data is needed to **verify an OTP**:
- `mobile_number`: The phone number
- `firebase_id_token`: The token Firebase gives after successful OTP
- `otp_session_id`: The session ID from the send-otp step

**Why we need it:** To verify the OTP was completed successfully!

---

```python
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
```
**What it does:** Defines ALL the data needed to register a new user:
- `full_name`: 2-255 characters
- `date_of_birth`: A valid date
- `gender`: male/female/other
- `mobile_number`: Valid Indian number
- `password`: 8-128 characters
- `state`: Indian state
- `district`: 2-100 characters
- `sport_interest`: The sport they want
- `height_cm`: 50-300 cm
- `weight_kg`: 10-500 kg
- `face_embedding`: Exactly 512 numbers
- `otp_session_id`: Proof they verified their phone

**Why we need it:** Complete validation for registration data!

---

```python
VALID_GENDERS = {"male", "female", "other"}
VALID_STATES = { ... }  # All Indian states
VALID_SPORTS = { ... }  # All SAI-recognized sports
```
**What it does:** Creates sets of **allowed values** for gender, states, and sports.

**Why we need it:** To validate that users only select valid options!

---

```python
    @field_validator("gender")
    @classmethod
    def validate_gender(cls, v):
        if v.lower() not in VALID_GENDERS:
            raise ValueError(f"gender must be one of: {', '.join(VALID_GENDERS)}")
        return v.lower()
```
**What it does:** Checks gender is valid and converts to lowercase.

**Why we need it:** Prevents "Male", "MALE", "male" from being treated as different values!

---

```python
    @field_validator("state")
    @classmethod
    def validate_state(cls, v):
        if v not in VALID_STATES:
            raise ValueError(f"Invalid Indian state/UT: {v}")
        return v
```
**What it does:** Makes sure the state is one of the valid Indian states.

**Why we need it:** Prevents typos or fake state names!

---

```python
    @field_validator("sport_interest")
    @classmethod
    def validate_sport(cls, v):
        if v not in VALID_SPORTS:
            raise ValueError(f"Invalid sport: {v}. Must be one of SAI recognized sports.")
        return v
```
**What it does:** Makes sure the sport is officially recognized by SAI.

**Why we need it:** Keeps data consistent and valid!

---

```python
    @field_validator("date_of_birth")
    @classmethod
    def validate_dob(cls, v):
        from datetime import date as date_type
        today = date_type.today()
        age = (today - v).days // 365
        if age < 10 or age > 50:
            raise ValueError("Athlete must be between 10 and 50 years old")
        return v
```
**What it does:** Calculates age from birthdate and ensures it's between 10-50 years.

**Why we need it:** Only athletes in this age range are eligible!

---

```python
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
```
**What it does:** Checks password strength:
- Must have uppercase letter (A-Z)
- Must have lowercase letter (a-z)
- Must have digit (0-9)
- Must have special character (!@#$%^&*...)

**Why we need it:** Strong passwords prevent hackers from guessing them!

---

```python
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
```
**What it does:** Defines what a user's profile looks like when returned by the API. **Notice: NO password_hash or face_embedding!**

**Why we need it:** Never expose sensitive data like passwords or face embeddings in responses!

---

# 7️⃣ `face_verification.py` - The Face Matcher 🤖

This file contains the **math** to compare two face embeddings and decide if they're the same person.

---

```python
import math
from typing import List
from app.config import settings
```
**What it does:** Imports math functions, type hints, and app settings.

**Why we need it:** For the cosine similarity calculations!

---

```python
def _dot_product(a: List[float], b: List[float]) -> float:
    """Compute dot product of two vectors."""
    return sum(x * y for x, y in zip(a, b))
```
**What it does:** Calculates the **dot product** of two vectors (multiply corresponding numbers and add them up).

**Why we need it:** This is step 1 in calculating how similar two faces are!

**Baby Example:** If vector A = [1, 2, 3] and vector B = [4, 5, 6], dot product = (1×4) + (2×5) + (3×6) = 32

---

```python
def _magnitude(v: List[float]) -> float:
    """Compute L2 norm of a vector."""
    return math.sqrt(sum(x * x for x in v))
```
**What it does:** Calculates the **length** (magnitude) of a vector using Pythagorean theorem.

**Why we need it:** Step 2 in face comparison - we need to know how "long" each face vector is!

**Baby Example:** If vector = [3, 4], magnitude = √(9 + 16) = √25 = 5

---

```python
def cosine_similarity(embedding_a: List[float], embedding_b: List[float]) -> float:
    """
    Compute cosine similarity between two 512-d FaceNet embeddings.
    Returns a value in [-1, 1]; higher means more similar.
    """
```
**What it does:** This function calculates **how similar two faces are** on a scale of -1 to 1.

**Why we need it:** This is the core algorithm for face verification!

---

```python
    if len(embedding_a) != len(embedding_b):
        raise ValueError(f"Embedding dimension mismatch: {len(embedding_a)} vs {len(embedding_b)}")
```
**What it does:** Makes sure both embeddings have the same number of elements.

**Why we need it:** Can't compare apples to oranges! Both must be 512 numbers.

---

```python
    dot = _dot_product(embedding_a, embedding_b)
    mag_a = _magnitude(embedding_a)
    mag_b = _magnitude(embedding_b)
```
**What it does:** Calculates the dot product and magnitudes of both vectors.

**Why we need it:** These are the ingredients for the cosine similarity formula!

---

```python
    if mag_a == 0 or mag_b == 0:
        raise ValueError("Zero-magnitude embedding detected. Face capture may have failed.")
```
**What it does:** Checks if either vector is all zeros (which means face detection failed).

**Why we need it:** Can't divide by zero! A zero vector means the face wasn't captured properly.

---

```python
    return dot / (mag_a * mag_b)
```
**What it does:** The actual cosine similarity formula!

**Baby Example:** 
- If two faces are IDENTICAL: similarity = 1.0
- If two faces are COMPLETELY DIFFERENT: similarity = 0.0
- If similarity = 0.8, they're pretty similar!

---

```python
def cosine_distance(embedding_a: List[float], embedding_b: List[float]) -> float:
    """
    Compute cosine distance: 1 - cosine_similarity.
    Range: [0, 2]; lower means more similar.
    
    Threshold: distance < 0.5 → same person (accept)
               distance >= 0.5 → different person (reject)
    """
    return 1.0 - cosine_similarity(embedding_a, embedding_b)
```
**What it does:** Converts similarity to **distance** (opposite). Lower distance = more similar.

**Why we need it:** Distance is easier to understand - we want it to be LOW for a match!

**Baby Example:**
- Same person: distance ≈ 0.1 (very close)
- Different people: distance ≈ 0.8 (far apart)
- Threshold is 0.5 - if distance < 0.5, it's a match!

---

```python
def verify_face(stored_embedding, live_embedding, threshold=None):
    """
    Compare stored and live FaceNet embeddings using cosine distance.
    Returns: (is_match: bool, distance: float)
    """
```
**What it does:** The main function that decides if two face scans are the same person!

**Why we need it:** This is what runs during login to verify your identity!

---

```python
    if threshold is None:
        threshold = settings.FACE_SIMILARITY_THRESHOLD
```
**What it does:** Uses the default threshold (0.5) from settings if not provided.

**Why we need it:** Allows flexibility but has a sensible default!

---

```python
    if len(stored_embedding) != settings.FACE_EMBEDDING_DIMENSION:
        raise ValueError(f"Stored embedding has invalid dimension...")
    if len(live_embedding) != settings.FACE_EMBEDDING_DIMENSION:
        raise ValueError(f"Live embedding has invalid dimension...")
```
**What it does:** Validates both embeddings are exactly 512 numbers.

**Why we need it:** Garbage in, garbage out! Must be valid embeddings.

---

```python
    distance = cosine_distance(stored_embedding, live_embedding)
    is_match = distance < threshold
    return is_match, distance
```
**What it does:** 
1. Calculates the distance between the two face embeddings
2. Checks if distance is below the threshold (0.5)
3. Returns TRUE/FALSE and the actual distance

**Baby Example:** If distance = 0.3 and threshold = 0.5, then 0.3 < 0.5 = TRUE → Same person!

---

```python
def validate_embedding(embedding: List[float]) -> bool:
    """
    Validate that an embedding is:
    - Exactly 512 dimensions
    - Not a zero vector
    - Contains finite values (no NaN / Inf)
    """
```
**What it does:** Checks if a face embedding is valid before using it.

**Why we need it:** Prevents bad data from breaking the system!

---

```python
    if len(embedding) != settings.FACE_EMBEDDING_DIMENSION:
        return False
    if all(v == 0.0 for v in embedding):
        return False
    if not all(math.isfinite(v) for v in embedding):
        return False
    return True
```
**What it does:** 
1. Checks length is 512
2. Checks it's not all zeros
3. Checks all numbers are valid (not NaN or infinity)
4. Returns True if all checks pass

**Why we need it:** Ensures only valid embeddings are stored or compared!

---

# 8️⃣ `jwt_handler.py` - The Token Maker 🎫

This file creates and verifies **JWT tokens** (the digital VIP passes that prove who you are).

---

```python
from datetime import datetime, timedelta, timezone
from typing import Optional
import uuid
from jose import JWTError, jwt
from fastapi import HTTPException, status
from app.config import settings
```
**What it does:** Imports tools for:
- Working with dates/times
- Generating UUIDs
- Creating/verifying JWT tokens
- Handling errors

**Why we need it:** All the ingredients for JWT token management!

---

```python
def create_access_token(user_id: str, mobile_number: str) -> str:
    """Creates a 24-hour JWT access token for authenticated sessions."""
```
**What it does:** Creates the **main login token** that lasts 24 hours.

**Why we need it:** After successful login, users get this token to access protected features!

---

```python
    now = datetime.now(timezone.utc)
    expire = now + timedelta(hours=settings.JWT_ACCESS_TOKEN_EXPIRE_HOURS)
```
**What it does:** 
- Gets the current time
- Calculates when the token expires (24 hours from now)

**Why we need it:** Tokens must have an expiration for security!

---

```python
    payload = {
        "sub": str(user_id),
        "mobile": mobile_number,
        "type": "access",
        "jti": str(uuid.uuid4()),
        "iat": now,
        "exp": expire,
        "iss": "SAI-SportsTalent",
    }
```
**What it does:** Creates the **payload** (the data inside the token):
- `sub`: User ID (subject)
- `mobile`: Phone number
- `type`: "access" (this is a full access token)
- `jti`: Unique token ID (for revocation if needed)
- `iat`: Issued at (when token was created)
- `exp`: Expiration time
- `iss`: Issuer (who created this token)

**Why we need it:** This data travels inside the token and proves who the user is!

---

```python
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
```
**What it does:** **Signs** the payload with the secret key, creating the actual JWT token string.

**Why we need it:** The signature prevents tampering. If someone changes the token, the signature won't match!

---

```python
def create_temp_login_token(user_id: str, mobile_number: str) -> str:
    """Creates a short-lived 10-minute token after password verification."""
```
**What it does:** Creates a **temporary token** that only lasts 10 minutes, used between login step 1 and step 2.

**Why we need it:** Prevents replay attacks! Even if someone steals this token, it expires quickly.

---

```python
    payload = {
        "sub": str(user_id),
        "mobile": mobile_number,
        "type": "temp_login",  # Scope-limited — cannot access protected routes
        "jti": str(uuid.uuid4()),
        "iat": now,
        "exp": expire,
        "iss": "SAI-SportsTalent",
    }
```
**What it does:** Similar to access token, but `type` is "temp_login" instead of "access".

**Why we need it:** The type tells the system this token can ONLY be used for face verification, not for accessing other features!

---

```python
def verify_access_token(token: str) -> dict:
    """Verifies a JWT access token. Raises HTTP 401 on failure."""
```
**What it does:** Checks if a token is valid and returns the data inside it.

**Why we need it:** Every time a user makes a request, we verify their token to make sure they're authenticated!

---

```python
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials. Token may be expired or invalid.",
        headers={"WWW-Authenticate": "Bearer"},
    )
```
**What it does:** Creates an error to raise if the token is invalid.

**Why we need it:** Consistent error messages for authentication failures!

---

```python
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
            options={"verify_exp": True},
        )
```
**What it does:** Attempts to decode and verify the token:
- Checks the signature (makes sure it wasn't tampered with)
- Checks expiration (if `verify_exp: True`)

**Why we need it:** This is where the magic happens - JWT library does all the verification!

---

```python
        token_type: str = payload.get("type")
        if token_type != "access":
            raise credentials_exception
```
**What it does:** Makes sure this is an "access" token, not a "temp_login" token.

**Why we need it:** Prevents using temporary tokens to access protected routes!

---

```python
        user_id: str = payload.get("sub")
        if not user_id:
            raise credentials_exception
        return payload
    except JWTError:
        raise credentials_exception
```
**What it does:** 
- Extracts user ID from token
- If no user ID, raises error
- If everything is good, returns the payload
- If JWT library throws an error (expired, invalid signature), catches it and raises authentication error

**Why we need it:** Complete token validation with proper error handling!

---

```python
def verify_temp_login_token(token: str) -> dict:
    """Verifies a temporary login token from step 1."""
```
**What it does:** Same as `verify_access_token` but checks for `type == "temp_login"` instead.

**Why we need it:** Used during the 2-step login process!

---

```python
def decode_token_unsafe(token: str) -> Optional[dict]:
    """Decode without verification (for debugging only — never use in auth paths)."""
```
**What it does:** Decodes a token WITHOUT checking if it's valid or expired.

**Why we need it:** ONLY for debugging! Never use this for actual authentication because it skips all security checks!

---

# 9️⃣ `otp_service.py` - The OTP Manager 📱

This file handles **OTP (One-Time Password) verification** using Firebase.

---

```python
from firebase_admin import auth as firebase_auth, credentials, initialize_app, get_app
import firebase_admin
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models import OTPVerification
from app.config import settings
import logging
```
**What it does:** Imports:
- Firebase Admin SDK (for verifying OTP tokens)
- FastAPI exceptions
- SQLAlchemy for database queries
- OTPVerification model
- Settings
- Logging

**Why we need it:** All tools needed for OTP verification!

---

```python
def init_firebase():
    """Initialize Firebase Admin SDK (called once on startup)."""
```
**What it does:** Sets up the connection to Firebase when the app starts.

**Why we need it:** Firebase handles sending OTP codes to users' phones!

---

```python
    try:
        get_app()
        logger.info("Firebase already initialized.")
    except ValueError:
```
**What it does:** Checks if Firebase is already initialized (to avoid initializing twice).

**Why we need it:** Firebase can only be initialized once!

---

```python
        if settings.FIREBASE_SERVICE_ACCOUNT_PATH:
            cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
            initialize_app(cred)
            logger.info("Firebase initialized with service account.")
```
**What it does:** If a Firebase service account file exists, it loads the credentials and initializes Firebase.

**Why we need it:** This connects your backend to Firebase so you can verify OTP tokens!

---

```python
        else:
            logger.warning("Firebase service account not configured. OTP verification will use mock mode (DEV ONLY).")
```
**What it does:** If no Firebase credentials are found, logs a warning (development mode).

**Why we need it:** Lets developers test the app without Firebase setup, but warns them it's not for production!

---

```python
async def create_otp_session(db, mobile_number, purpose="register"):
    """Create an OTP verification session in the database."""
```
**What it does:** Creates a new OTP session record when someone requests an OTP.

**Why we need it:** To track OTP requests and prevent reuse!

---

```python
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
```
**What it does:** 
1. Finds any unverified OTP sessions for this phone number and purpose
2. Marks them as verified (effectively expiring them)

**Why we need it:** Prevents multiple active OTP sessions for the same number!

---

```python
    otp_record = OTPVerification(
        id=uuid.uuid4(),
        mobile_number=mobile_number,
        otp_token="PENDING",
        verified=False,
        purpose=purpose,
        created_at=datetime.now(timezone.utc),
    )
    db.add(otp_record)
    await db.flush()
    return otp_record
```
**What it does:** 
1. Creates a new OTP record with status "PENDING"
2. Adds it to the database
3. Returns the record (which includes the generated ID)

**Why we need it:** This session ID is sent to the Flutter app so it can complete the OTP verification!

---

```python
async def verify_firebase_otp(db, mobile_number, firebase_id_token, otp_session_id):
    """Verify Firebase ID token from client-side phone auth."""
```
**What it does:** Verifies the Firebase token after the user completes OTP on their phone.

**Why we need it:** This is where we confirm the user actually received and entered the correct OTP!

---

```python
    result = await db.execute(
        select(OTPVerification).where(OTPVerification.id == otp_session_id)
    )
    session = result.scalar_one_or_none()
```
**What it does:** Loads the OTP session from the database.

**Why we need it:** We need to check if this session exists and hasn't been used already!

---

```python
    if not session:
        raise HTTPException(status_code=404, detail="OTP session not found...")
    if session.verified:
        raise HTTPException(status_code=400, detail="OTP session already used...")
    if session.mobile_number != mobile_number:
        raise HTTPException(status_code=400, detail="Mobile number mismatch.")
```
**What it does:** Validates the session:
- Exists?
- Not already used?
- Phone number matches?

**Why we need it:** Security checks to prevent OTP replay attacks!

---

```python
    try:
        decoded_token = firebase_auth.verify_id_token(firebase_id_token)
        firebase_phone = decoded_token.get("phone_number")
```
**What it does:** Uses Firebase Admin SDK to verify the token and extract the phone number from it.

**Why we need it:** Firebase does the actual verification - we just need to check the result!

---

```python
        if not firebase_phone:
            raise HTTPException(status_code=400, detail="Firebase token does not contain a phone number.")
        if firebase_phone.replace(" ", "") != mobile_number.replace(" ", ""):
            raise HTTPException(status_code=400, detail="Firebase verified phone number does not match...")
```
**What it does:** 
1. Checks the token contains a phone number
2. Makes sure it matches the requested number (removing spaces for comparison)

**Why we need it:** Prevents someone from verifying a different number than they requested!

---

```python
        session.verified = True
        session.otp_token = firebase_id_token
        await db.flush()
        return True
```
**What it does:** 
1. Marks the session as verified
2. Stores the Firebase token
3. Saves to database
4. Returns True (success)

**Why we need it:** Now the user can proceed to registration or login!

---

```python
    except firebase_admin.exceptions.FirebaseError as e:
        logger.error(f"Firebase token verification failed: {e}")
        raise HTTPException(status_code=401, detail=f"Firebase OTP verification failed: {str(e)}")
```
**What it does:** If Firebase verification fails (wrong token, expired, etc.), logs the error and raises an HTTP error.

**Why we need it:** Proper error handling so the user knows what went wrong!

---

```python
async def get_verified_otp_session(db, mobile_number, otp_session_id, purpose="register"):
    """Retrieve a verified OTP session for use in registration/login."""
```
**What it does:** Gets a verified OTP session that's still valid (not expired).

**Why we need it:** Used during registration/login to confirm the user completed OTP verification!

---

```python
    expiration_limit = datetime.now(timezone.utc) - timedelta(minutes=10)
```
**What it does:** Calculates the time 10 minutes ago.

**Why we need it:** OTP sessions expire after 10 minutes for security!

---

```python
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
```
**What it does:** Searches for an OTP session that:
- Has the correct ID
- Has the correct phone number
- Is verified
- Has the correct purpose (register/login)
- Was created within the last 10 minutes

**Why we need it:** Complete validation - all conditions must be met!

---

# 🔟 `auth_routes.py` - The API Endpoints 🚪

This file defines all the **API endpoints** (URLs) for authentication. This is what the Flutter app actually calls!

---

```python
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
```
**What it does:** Imports all the tools needed for authentication routes:
- `uuid`: For generating unique IDs
- `logging`: For recording events
- `datetime`: For timestamps
- `bcrypt`: For password hashing
- `FastAPI` components: For building routes
- `HTTPBearer`: For JWT token authentication
- `slowapi`: For rate limiting
- `sqlalchemy`: For database queries

**Why we need it:** The complete toolkit for building secure authentication endpoints!

---

```python
from app.database import get_db
from app.models import User, OTPVerification, LoginSession
from app.schemas import (SendOTPRequest, SendOTPResponse, VerifyOTPRequest, VerifyOTPResponse, ...)
from app.jwt_handler import create_access_token, create_temp_login_token, verify_access_token, verify_temp_login_token
from app.face_verification import verify_face, validate_embedding
from app.otp_service import create_otp_session, verify_firebase_otp, get_verified_otp_session
```
**What it does:** Imports all the helper functions and models we've been discussing.

**Why we need it:** Routes combine all these pieces to create complete authentication flows!

---

```python
router = APIRouter(prefix="/auth", tags=["Authentication"])
```
**What it does:** Creates a router with URL prefix "/auth".

**Why we need it:** All endpoints in this file will start with `/auth/` (like `/auth/send-otp`, `/auth/register`, etc.)

---

```python
security = HTTPBearer()
```
**What it does:** Sets up Bearer token authentication (for JWT).

**Why we need it:** This extracts the JWT token from the `Authorization: Bearer <token>` header!

---

```python
limiter = Limiter(key_func=get_remote_address)
```
**What it does:** Creates a rate limiter that tracks requests by IP address.

**Why we need it:** Prevents abuse by limiting how many requests one IP can make!

---

```python
async def get_current_user(credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)], db: AsyncSession = Depends(get_db)) -> User:
    """Extract and validate the current user from the Bearer token."""
```
**What it does:** This is a **dependency** that extracts the user from the JWT token. It's used by protected endpoints.

**Why we need it:** So endpoints can easily get the authenticated user without repeating code!

---

```python
    payload = verify_access_token(credentials.credentials)
    user_id = payload.get("sub")
```
**What it does:** 
1. Verifies the JWT token
2. Extracts the user ID from it

**Why we need it:** This is how we know who's making the request!

---

```python
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    user = result.scalar_one_or_none()
```
**What it does:** Looks up the user in the database by their ID.

**Why we need it:** To get the full user record (name, phone, etc.) and make sure they still exist!

---

```python
    if not user:
        raise HTTPException(status_code=401, detail="User account not found or has been deactivated.")
    return user
```
**What it does:** If user doesn't exist, raises an error. Otherwise, returns the user.

**Why we need it:** Prevents deleted/deactivated users from accessing the app!

---

## ENDPOINT 1: Send OTP

```python
@router.post("/send-otp", response_model=SendOTPResponse, summary="Initiate Firebase OTP...")
@limiter.limit("3/minute")
async def send_otp(request: Request, body: SendOTPRequest, db: AsyncSession = Depends(get_db)):
```
**What it does:** Creates the `/auth/send-otp` endpoint:
- `@router.post`: This is a POST request
- `response_model`: Defines what the response looks like
- `@limiter.limit("3/minute")`: Max 3 requests per minute per IP
- `send_otp`: The function that handles the request

**Why we need it:** This is the first step in authentication - sending an OTP to the user's phone!

---

```python
    if body.purpose == "register":
        result = await db.execute(select(User).where(User.mobile_number == body.mobile_number))
        existing = result.scalar_one_or_none()
        if existing:
            raise HTTPException(status_code=409, detail="This mobile number is already registered...")
```
**What it does:** For registration, checks if the phone number is already registered. If yes, blocks the request.

**Why we need it:** Can't register the same number twice!

---

```python
    if body.purpose == "login":
        result = await db.execute(select(User).where(User.mobile_number == body.mobile_number))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="No account found with this mobile number.")
```
**What it does:** For login, checks if the phone number exists. If not, blocks the request.

**Why we need it:** Can't login with a number that's not registered!

---

```python
    session = await create_otp_session(db, body.mobile_number, body.purpose)
```
**What it does:** Creates an OTP session in the database (we discussed this in otp_service.py).

**Why we need it:** To track this OTP request!

---

```python
    return SendOTPResponse(otp_session_id=session.id, message="OTP has been sent to your mobile via Firebase...")
```
**What it does:** Returns the OTP session ID to the Flutter app.

**Why we need it:** The app needs this ID to complete the OTP verification!

**Note:** Firebase handles the actual SMS sending. We just create the session and return the ID!

---

## ENDPOINT 2: Verify OTP

```python
@router.post("/verify-otp", response_model=VerifyOTPResponse, summary="Verify Firebase ID token...")
@limiter.limit("5/minute")
async def verify_otp(request: Request, body: VerifyOTPRequest, db: AsyncSession = Depends(get_db)):
```
**What it does:** Creates the `/auth/verify-otp` endpoint (max 5 requests/minute).

**Why we need it:** This is where the Flutter app sends the Firebase token after the user completes OTP!

---

```python
    is_verified = await verify_firebase_otp(db, body.mobile_number, body.firebase_id_token, body.otp_session_id)
```
**What it does:** Calls the OTP verification function we discussed in otp_service.py.

**Why we need it:** This actually verifies the Firebase token and marks the session as verified!

---

```python
    return VerifyOTPResponse(
        verification_status=is_verified,
        otp_session_id=body.otp_session_id,
        message="Phone number verified successfully." if is_verified else "Verification failed.",
    )
```
**What it does:** Returns whether verification succeeded or failed.

**Why we need it:** The app needs to know if the user can proceed to registration/login!

---

## ENDPOINT 3: Register

```python
@router.post("/register", response_model=RegisterResponse, status_code=201, summary="Register new athlete...")
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
```
**What it does:** Creates the `/auth/register` endpoint for new user registration.

**Why we need it:** This is where new athletes sign up!

---

```python
    body.gender = body.gender.lower().strip()
    body.state = body.state.strip()
    body.sport_interest = body.sport_interest.strip()
    body.mobile_number = body.mobile_number.strip()
```
**What it does:** Cleans up the input data (removes extra spaces, converts gender to lowercase).

**Why we need it:** Prevents "Male " and "male" from being treated differently!

---

```python
    print("Incoming registration request:")
    print("Name:", body.full_name)
    print("Gender:", body.gender)
    ...
```
**What it does:** Prints debug information to the console.

**Why we need it:** Helpful for developers to see what data is coming in during testing!

---

```python
    if len(body.face_embedding) != 512:
        raise HTTPException(status_code=422, detail="Embedding must be length 512")
```
**What it does:** Validates the face embedding is exactly 512 numbers.

**Why we need it:** Face verification won't work otherwise!

---

```python
    otp_session = await get_verified_otp_session(db, body.mobile_number, body.otp_session_id, purpose="register")
    if not otp_session:
        raise HTTPException(status_code=422, detail="Invalid or expired OTP session")
```
**What it does:** Checks that the user completed OTP verification recently.

**Why we need it:** Can't register without verifying your phone number first!

---

```python
    result = await db.execute(select(User).where(User.mobile_number == body.mobile_number))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Mobile number already registered.")
```
**What it does:** Double-checks the phone number isn't already registered.

**Why we need it:** Extra safety check!

---

```python
    if not validate_embedding(body.face_embedding):
        raise HTTPException(status_code=422, detail="Invalid face embedding content.")
```
**What it does:** Validates the face embedding is not all zeros, doesn't contain NaN, etc.

**Why we need it:** Prevents bad face data from being stored!

---

```python
    password_bytes = body.password.encode("utf-8")
    salt = bcrypt.gensalt(rounds=12)
    password_hash = bcrypt.hashpw(password_bytes, salt).decode("utf-8")
```
**What it does:** 
1. Converts password to bytes
2. Generates a random "salt" (extra security)
3. Hashes the password with bcrypt (12 rounds)
4. Converts back to string

**Why we need it:** Never store passwords as plain text! This makes them irreversible!

---

```python
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
```
**What it does:** Creates a new User object with all the registration data and adds it to the database.

**Why we need it:** This is the actual registration - saving the user to the database!

---

```python
    await db.delete(otp_session)
    await db.flush()
```
**What it does:** Deletes the used OTP session from the database.

**Why we need it:** OTP sessions can only be used once!

---

```python
    access_token = create_access_token(str(new_user.id), new_user.mobile_number)
```
**What it does:** Creates a JWT access token for the newly registered user.

**Why we need it:** So the user is automatically logged in after registration!

---

```python
    return RegisterResponse(
        access_token=access_token,
        user_id=new_user.id,
        full_name=new_user.full_name,
        message="Registration successful.",
    )
```
**What it does:** Returns the token and user info to the app.

**Why we need it:** The app needs the token to make authenticated requests!

---

## ENDPOINT 4: Login Step 1 - Password Check

```python
@router.post("/login-password-check", response_model=PasswordCheckResponse, summary="Step 1: Verify mobile + password...")
@limiter.limit("10/minute")
async def login_password_check(request: Request, body: PasswordCheckRequest, db: AsyncSession = Depends(get_db)):
```
**What it does:** Creates the first step of login - verifying phone number and password.

**Why we need it:** Login is 2-step: password first, then face verification!

---

```python
    result = await db.execute(select(User).where(User.mobile_number == body.mobile_number))
    user = result.scalar_one_or_none()
```
**What it does:** Looks up the user by phone number.

**Why we need it:** To get their stored password hash!

---

```python
    dummy_hash = "$2b$12$KIXfKh0cFn1R3Jl5o9bxqO5P3VYQj3Rf2PGbxeO9vVkCl2Hx6oqpi"
    stored_hash = user.password_hash if user else dummy_hash
```
**What it does:** If user doesn't exist, uses a fake hash instead.

**Why we need it:** **Security trick!** Makes the response time the same whether the user exists or not, preventing hackers from discovering valid phone numbers!

---

```python
    password_match = bcrypt.checkpw(body.password.encode("utf-8"), stored_hash.encode("utf-8"))
```
**What it does:** Compares the entered password with the stored hash.

**Why we need it:** bcrypt does a constant-time comparison (another security feature)!

---

```python
    if not user or not password_match:
        raise HTTPException(status_code=401, detail="Invalid credentials...")
```
**What it does:** If user doesn't exist OR password is wrong, returns generic error.

**Why we need it:** Doesn't tell hackers whether the phone number exists or the password was wrong!

---

```python
    temp_token = create_temp_login_token(str(user.id), user.mobile_number)
```
**What it does:** Creates a temporary token (valid for 10 minutes).

**Why we need it:** This token is needed for step 2 (face verification)!

---

```python
    return PasswordCheckResponse(temporary_login_token=temp_token, message="Password verified...")
```
**What it does:** Returns the temporary token to the app.

**Why we need it:** The app will use this token in the next step!

---

## ENDPOINT 5: Login Step 2 - Face Verification

```python
@router.post("/login-face-verify", response_model=FaceVerifyResponse, summary="Step 2: Face embedding comparison...")
@limiter.limit("5/minute")
async def login_face_verify(request: Request, body: FaceVerifyRequest, db: AsyncSession = Depends(get_db)):
```
**What it does:** Creates the second step of login - verifying the user's face.

**Why we need it:** This is the biometric security layer!

---

```python
    payload = verify_temp_login_token(body.temporary_login_token)
    user_id = payload["sub"]
```
**What it does:** Verifies the temporary token from step 1 and extracts the user ID.

**Why we need it:** Makes sure the user completed step 1 and the token hasn't expired!

---

```python
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="User account not found.")
```
**What it does:** Loads the user from the database.

**Why we need it:** To get their stored face embedding for comparison!

---

```python
    if not validate_embedding(body.face_embedding):
        raise HTTPException(status_code=422, detail="Invalid face embedding...")
```
**What it does:** Validates the live face capture is valid.

**Why we need it:** Prevents bad face data!

---

```python
    is_match, distance = verify_face(user.face_embedding, body.face_embedding)
```
**What it does:** Compares the stored face embedding with the live capture.

**Why we need it:** This is the actual face verification!

---

```python
    if not is_match:
        logger.warning(f"Face verification FAILED for user {user_id}. Distance={distance:.4f}...")
        raise HTTPException(status_code=401, detail=f"Face verification failed (distance={distance:.3f})...")
```
**What it does:** If faces don't match, logs a warning and returns an error with the distance.

**Why we need it:** Tells the user why verification failed and helps developers debug!

---

```python
    logger.info(f"Face verification PASSED for user {user_id}. Distance={distance:.4f}")
```
**What it does:** Logs successful verification.

**Why we need it:** For security auditing!

---

```python
    access_token = create_access_token(str(user.id), user.mobile_number)
```
**What it does:** Creates a full access token (valid for 24 hours).

**Why we need it:** Now the user is fully authenticated!

---

```python
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
```
**What it does:** Creates a login session record to track this device.

**Why we need it:** For security auditing and session management!

---

```python
    return FaceVerifyResponse(
        access_token=access_token,
        user_id=user.id,
        full_name=user.full_name,
        message="Authentication successful. Welcome back!",
    )
```
**What it does:** Returns the access token and user info.

**Why we need it:** The user is now logged in!

---

## ENDPOINT 6: Get Profile

```python
@router.get("/profile", response_model=UserProfile, summary="Get authenticated athlete's profile")
async def get_profile(current_user: User = Depends(get_current_user)):
```
**What it does:** Creates the `/auth/profile` endpoint that returns the user's profile.

**Why we need it:** So users can view their own information!

---

```python
    return UserProfile.model_validate(current_user)
```
**What it does:** Converts the User object to a UserProfile response (which excludes password_hash and face_embedding).

**Why we need it:** Never expose sensitive data!

---

# 1️⃣1️⃣ `main.py` - The App Entry Point 🚀

This is the **main file** that starts your entire backend application!

---

```python
import logging
import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from app.config import settings
from app.database import init_db, close_db
from app.auth_routes import router as auth_router
from app.test_routes import router as test_router
from app.otp_service import init_firebase
```
**What it does:** Imports everything needed to run the app:
- Logging and timing
- FastAPI and its components
- CORS middleware (for cross-origin requests)
- Trusted host middleware (security)
- Rate limiting
- Database functions
- Route routers
- Firebase initialization

**Why we need it:** All the pieces to build and run the complete application!

---

```python
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger(__name__)
```
**What it does:** Configures logging:
- If DEBUG is False: only log INFO and above
- If DEBUG is True: log everything including DEBUG
- Format: timestamp | level | name | message

**Why we need it:** So you can see what's happening in your app!

---

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
```
**What it does:** Creates a function that runs code on **startup** and **shutdown**.

**Why we need it:** To initialize things when the app starts and clean up when it stops!

---

```python
    logger.info("═" * 60)
    logger.info(f"🏋️  {settings.APP_NAME} v{settings.APP_VERSION}")
    logger.info(f"🌍  Environment: {settings.ENVIRONMENT}")
    logger.info("═" * 60)
```
**What it does:** Logs a nice startup message with app name and version.

**Why we need it:** So you know the app started successfully!

---

```python
    logger.info("Initializing Firebase Admin SDK...")
    init_firebase()
```
**What it does:** Initializes Firebase for OTP functionality.

**Why we need it:** Firebase must be ready before the app can handle OTP requests!

---

```python
    logger.info("Initializing PostgreSQL database...")
    await init_db()
    logger.info("✅ Database ready.")
```
**What it does:** Creates database tables if they don't exist.

**Why we need it:** The app needs its database tables to function!

---

```python
    yield  # Application runs here
```
**What it does:** This is where the app actually runs. Everything before is startup, everything after is shutdown.

**Why we need it:** The lifespan pattern separates startup, running, and shutdown phases!

---

```python
    logger.info("Shutting down gracefully...")
    await close_db()
    logger.info("✅ Database connections closed.")
```
**What it does:** When the app stops, this closes database connections properly.

**Why we need it:** Prevents resource leaks and database issues!

---

```python
limiter = Limiter(key_func=get_remote_address)
```
**What it does:** Creates the global rate limiter.

**Why we need it:** To prevent API abuse!

---

```python
app = FastAPI(
    title=settings.APP_NAME,
    description="Production-grade authentication system...",
    version=settings.APP_VERSION,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    openapi_url="/openapi.json" if settings.DEBUG else None,
    lifespan=lifespan,
)
```
**What it does:** Creates the FastAPI application with:
- Title, description, version
- API documentation URLs (only in DEBUG mode for security)
- Lifespan handler for startup/shutdown

**Why we need it:** This IS your backend application!

---

```python
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
```
**What it does:** Attaches the rate limiter to the app and sets up error handling.

**Why we need it:** So rate limiting actually works!

---

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type", "X-Device-ID"],
    max_age=86400,
)
```
**What it does:** Adds CORS middleware with settings:
- Which origins can access the API
- Allow cookies/credentials
- Allowed HTTP methods
- Allowed headers
- Cache preflight requests for 24 hours

**Why we need it:** So your Flutter app can communicate with the backend!

---

```python
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"] if settings.DEBUG else ["api.sai-sports.gov.in", "localhost"],
)
```
**What it does:** Adds security middleware that only allows requests with valid Host headers.

**Why we need it:** Prevents host header injection attacks!

---

```python
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all requests with timing information."""
```
**What it does:** Creates custom middleware that logs every request.

**Why we need it:** So you can see what requests are coming in and how long they take!

---

```python
    start_time = time.perf_counter()
    response = await call_next(request)
    process_time_ms = (time.perf_counter() - start_time) * 1000
```
**What it does:** 
1. Records the start time
2. Processes the request
3. Calculates how long it took (in milliseconds)

**Why we need it:** For performance monitoring!

---

```python
    logger.info(f"{request.method} {request.url.path} → {response.status_code} [{process_time_ms:.1f}ms] IP={request.client.host}")
```
**What it does:** Logs the request method, path, response status, processing time, and IP address.

**Why we need it:** So you can monitor app activity and performance!

---

```python
    response.headers["X-Process-Time-Ms"] = f"{process_time_ms:.1f}"
    response.headers["X-API-Version"] = settings.APP_VERSION
```
**What it does:** Adds custom headers to the response:
- Processing time
- API version

**Why we need it:** Helpful for debugging and monitoring!

---

```python
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
```
**What it does:** Creates a custom error handler for validation errors.

**Why we need it:** So validation errors are returned in a consistent, useful format!

---

```python
    print("VALIDATION ERROR:", exc.errors())
    errors = []
    for error in exc.errors():
        errors.append({
            "field": " → ".join(str(loc) for loc in error["loc"]),
            "message": error["msg"],
            "type": error["type"],
        })
```
**What it does:** 
1. Prints the raw validation error
2. Formats it into a cleaner structure with field name, message, and error type

**Why we need it:** Makes error messages easier to understand!

---

```python
    return JSONResponse(
        status_code=422,
        content={"detail": "Input validation failed", "errors": errors},
    )
```
**What it does:** Returns a 422 (Unprocessable Entity) response with the formatted errors.

**Why we need it:** Standard HTTP status code for validation errors!

---

```python
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch-all handler — never expose stack traces in production."""
```
**What it does:** Creates a catch-all error handler for ANY unhandled exception.

**Why we need it:** So users never see scary stack traces or internal details!

---

```python
    logger.exception(f"Unhandled exception for {request.method} {request.url.path}: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "An internal server error occurred. Please try again later.", "error_code": "INTERNAL_SERVER_ERROR"},
    )
```
**What it does:** 
1. Logs the full error (with stack trace) for developers
2. Returns a generic error message to users

**Why we need it:** Security! Never expose internal errors to users!

---

```python
app.include_router(auth_router)
app.include_router(test_router)
```
**What it does:** Adds the authentication routes and test routes to the app.

**Why we need it:** So the endpoints are actually accessible!

---

```python
@app.get("/health", tags=["Health"], include_in_schema=False)
async def health_check():
    """Kubernetes / load balancer health check endpoint."""
    return {"status": "healthy", "service": settings.APP_NAME, "version": settings.APP_VERSION, "environment": settings.ENVIRONMENT}
```
**What it does:** Creates a `/health` endpoint that returns the app's status.

**Why we need it:** Load balancers and Kubernetes use this to check if the app is running properly!

---

```python
@app.get("/", tags=["Root"], include_in_schema=False)
async def root():
    return {"service": settings.APP_NAME, "version": settings.APP_VERSION, "docs": "/docs" if settings.DEBUG else "Disabled in production"}
```
**What it does:** Creates the root endpoint `/` that returns basic app info.

**Why we need it:** So people visiting the base URL get useful information!

---

# 1️⃣2️⃣ `test_routes.py` - Fitness Test Endpoints 💪

This file handles uploading **fitness test results** (sit-ups, squats) from the mobile app.

---

```python
class SitUpResultRequest(BaseModel):
    test_id: Optional[str] = None
    user_id: str
    total_reps: int = Field(..., ge=0, le=10000)
    correct_reps: int = Field(..., ge=0)
    incorrect_reps: int = Field(..., ge=0)
    accuracy: float = Field(..., ge=0.0, le=100.0)
    duration: int = Field(..., ge=0, description="Duration in seconds")
    pose_confidence: float = Field(..., ge=0.0, le=1.0)
    timestamp: str
```
**What it does:** Defines the data structure for sit-up test results:
- `test_id`: Optional unique ID (for offline sync)
- `user_id`: Who did the test
- `total_reps`: Total sit-ups done (0-10000)
- `correct_reps`: How many were done correctly
- `incorrect_reps`: How many were done incorrectly
- `accuracy`: Percentage accuracy (0-100)
- `duration`: How long the test took (in seconds)
- `pose_confidence`: AI confidence in pose detection (0-1)
- `timestamp`: When the test was done

**Why we need it:** Validates all sit-up data before storing it!

---

```python
class SquatResultRequest(BaseModel):
    test_id: Optional[str] = None
    user_id: str
    total_reps: int = Field(..., ge=0, le=10000)
    correct_reps: int = Field(..., ge=0)
    incorrect_reps: int = Field(..., ge=0)
    accuracy_percentage: float = Field(..., ge=0.0, le=100.0)
    duration_seconds: int = Field(..., ge=0, description="Duration in seconds")
    pose_confidence_score: float = Field(..., ge=0.0, le=1.0)
    timestamp: str
```
**What it does:** Same as SitUpResultRequest but for squats (slightly different field names).

**Why we need it:** Validates squat test data!

---

```python
@router.post("/situp-result", response_model=SitUpResultResponse, summary="Upload sit-up test result")
async def upload_situp_result(body: SitUpResultRequest, request: Request, db: AsyncSession = Depends(get_db)):
```
**What it does:** Creates the `/tests/situp-result` endpoint.

**Why we need it:** So the Flutter app can upload sit-up results!

---

```python
    try:
        logger.info(f"SitUp result received | user={body.user_id} | total={body.total_reps} | correct={body.correct_reps} | accuracy={body.accuracy:.1f}%")
```
**What it does:** Logs the incoming test result.

**Why we need it:** For monitoring and debugging!

---

```python
        try:
            recorded_at = datetime.fromisoformat(body.timestamp)
        except ValueError:
            recorded_at = datetime.now(timezone.utc)
```
**What it does:** Tries to parse the timestamp. If it fails, uses current time.

**Why we need it:** Handles offline tests that might have old timestamps!

---

```python
        test_id = body.test_id or str(__import__('uuid').uuid4())
```
**What it does:** Uses the provided test_id or generates a new one.

**Why we need it:** Each test needs a unique ID!

---

```python
        await db.execute(
            text("""
                INSERT INTO fitness_test_results (
                    test_id, user_id, test_type,
                    total_reps, correct_reps, incorrect_reps,
                    accuracy, duration_seconds,
                    pose_confidence_score, recorded_at, created_at
                ) VALUES (
                    :test_id, :user_id, 'sit_up',
                    :total_reps, :correct_reps, :incorrect_reps,
                    :accuracy, :duration,
                    :pose_confidence, :recorded_at, NOW()
                )
                ON CONFLICT (test_id) DO NOTHING
            """),
            {...parameters...}
        )
```
**What it does:** Inserts the sit-up result into the database using raw SQL.
- `ON CONFLICT (test_id) DO NOTHING`: If this test_id already exists, skip it (prevents duplicates from offline sync).

**Why we need it:** Stores the test result safely with duplicate protection!

---

```python
        await db.commit()
        logger.info(f"SitUp result stored | test_id={test_id}")
        return SitUpResultResponse(success=True, message="Sit-up result uploaded successfully.", test_id=test_id)
```
**What it does:** 
1. Commits (saves) to database
2. Logs success
3. Returns success response

**Why we need it:** Completes the upload process!

---

```python
    except Exception as e:
        await db.rollback()
        logger.error(f"SitUp result upload failed: {e}")
        return SitUpResultResponse(success=False, message=f"Upload failed: {str(e)}")
```
**What it does:** If anything fails:
1. Rolls back (undoes) database changes
2. Logs the error
3. Returns error response

**Why we need it:** Proper error handling prevents data corruption!

---

The squat endpoint works exactly the same way, just with squat-specific field names!

---

# 1️⃣3️⃣ `__init__.py` - The Package Marker 📦

```python
# SAI Sports Talent Assessment - Backend Package
```
**What it does:** This empty file (with just a comment) tells Python that the `app` directory is a **package**.

**Why we need it:** Without this file, Python won't recognize the directory as importable!

---

# 🎓 Summary: How Everything Works Together

## The Complete Flow:

### 📝 Registration Flow:
1. **User enters details** in Flutter app → calls `/auth/send-otp`
2. **Backend checks** if phone is already registered → creates OTP session
3. **Firebase sends SMS** with OTP code to user's phone
4. **User enters OTP** in app → Flutter completes Firebase auth → calls `/auth/verify-otp`
5. **Backend verifies** Firebase token → marks session as verified
6. **App captures face** → creates face embedding (512 numbers)
7. **App calls** `/auth/register` with all data + face embedding + OTP session ID
8. **Backend validates everything** → hashes password → saves user → returns JWT token
9. **User is now registered and logged in!** ✅

### 🔐 Login Flow (2-Step Security):
**Step 1 - Password:**
1. User enters phone + password → calls `/auth/login-password-check`
2. Backend verifies password with bcrypt
3. Returns temporary token (valid 10 minutes)

**Step 2 - Face Verification:**
1. App captures live face → creates embedding
2. Calls `/auth/login-face-verify` with temp token + face embedding
3. Backend compares embeddings using cosine distance
4. If distance < 0.5 → Same person! → Returns full JWT token
5. **User is now logged in!** ✅

### 🏋️ Fitness Test Flow:
1. User does sit-ups/squats offline in the app
2. AI counts reps and calculates accuracy
3. When internet is available, app calls `/tests/situp-result` or `/tests/squat-result`
4. Backend stores results in database
5. Results are synced and ready for analysis!

---

## 🔒 Security Features:

1. **Password Hashing**: bcrypt scrambles passwords irreversibly
2. **Face Biometrics**: 512-d embeddings instead of storing photos (privacy!)
3. **JWT Tokens**: Signed tokens prevent tampering
4. **2-Step Login**: Password + Face verification
5. **Rate Limiting**: Prevents spam and brute force attacks
6. **OTP Verification**: Firebase handles secure SMS delivery
7. **Temporary Tokens**: Short-lived tokens for intermediate steps
8. **Input Validation**: Pydantic validates all incoming data
9. **SQL Injection Protection**: SQLAlchemy parameterized queries
10. **CORS Protection**: Only allowed apps can access the API
11. **Constant-Time Comparison**: Prevents timing attacks on passwords
12. **Error Handling**: Never expose internal errors to users

---

## 📊 Database Tables:

1. **users**: Athlete profiles (with face embeddings, not photos!)
2. **otp_verifications**: Track OTP sessions
3. **login_sessions**: Track active login sessions per device
4. **fitness_test_results**: Store sit-up/squat test results

---

## 🚀 How to Run:

```bash
# Navigate to backend folder
cd backend

# Install dependencies
pip install -r requirements.txt

# Create .env file with your settings
# (Use .env.example as template)

# Run the app
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Your API will be available at: `http://localhost:8000`

API Documentation (in DEBUG mode): `http://localhost:8000/docs`

---

# 🎉 Congratulations!

You now understand **EVERY LINE** of your backend code! It's a production-grade authentication system with:
- ✅ Phone OTP verification
- ✅ Password hashing
- ✅ Face biometric verification
- ✅ JWT token management
- ✅ Fitness test result tracking
- ✅ Comprehensive security
- ✅ Error handling
- ✅ Rate limiting
- ✅ Database management

You're now ready to build, modify, and debug this backend like a pro! 💪🚀
