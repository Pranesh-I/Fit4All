import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "SAI Admin Dashboard"
    DATABASE_URL: str = "postgresql+asyncpg://sai_user:sai_password@localhost:5432/sai_sports_db"
    JWT_SECRET: str = "admin-secret-key-12345"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours

settings = Settings()
