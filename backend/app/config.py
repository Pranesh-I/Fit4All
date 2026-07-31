"""
SAI Sports Talent Assessment - Configuration Module
Government of India / Sports Authority of India
"""
import os
from functools import lru_cache
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "SAI Sports Talent Assessment"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://sai_user:sai_password@localhost:5432/sai_sports_db"
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 30

    # JWT Configuration
    JWT_SECRET_KEY: str = "your-super-secret-jwt-key-change-in-production-min-256-bits"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_HOURS: int = 24
    JWT_TEMP_TOKEN_EXPIRE_MINUTES: int = 10  # Short-lived token for login step 2

    # bcrypt
    BCRYPT_ROUNDS: int = 12

    # Face Verification
    FACE_SIMILARITY_THRESHOLD: float = 0.5  # cosine distance must be < 0.5
    FACE_EMBEDDING_DIMENSION: int = 512

    # OTP Configuration (Firebase)
    FIREBASE_PROJECT_ID: Optional[str] = None
    FIREBASE_SERVICE_ACCOUNT_PATH: Optional[str] = None

    # Rate Limiting
    OTP_RATE_LIMIT_PER_MINUTE: int = 3
    LOGIN_RATE_LIMIT_PER_MINUTE: int = 10

    # CORS
    ALLOWED_ORIGINS: list[str] = ["*"]

    # Security
    HTTPS_ONLY: bool = False  # Set True in production

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
