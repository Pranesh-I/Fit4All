"""
SAI Sports Talent Assessment - FastAPI Application Entry Point
Government of India / Sports Authority of India

Run with:
    uvicorn main:app --reload --host 0.0.0.0 --port 8000

Production:
    uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4 --ssl-keyfile key.pem --ssl-certfile cert.pem
"""
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
from app.session_routes import router as session_router
from app.local_engine import router as local_engine_router
from app.otp_service import init_firebase

# Configure structured logging
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────────────────────────────────────
# LIFESPAN: Startup / Shutdown
# ─────────────────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    logger.info("═" * 60)
    logger.info(f"🏋️  {settings.APP_NAME} v{settings.APP_VERSION}")
    logger.info(f"🌍  Environment: {settings.ENVIRONMENT}")
    logger.info("═" * 60)

    # Initialize Firebase
    logger.info("Initializing Firebase Admin SDK...")
    init_firebase()

    # Initialize database tables
    logger.info("Initializing PostgreSQL database...")
    await init_db()
    logger.info("✅ Database ready.")

    yield  # Application runs here

    # Shutdown
    logger.info("Shutting down gracefully...")
    await close_db()
    logger.info("✅ Database connections closed.")


# ─────────────────────────────────────────────────────────────────────────────
# RATE LIMITER
# ─────────────────────────────────────────────────────────────────────────────

limiter = Limiter(key_func=get_remote_address)


# ─────────────────────────────────────────────────────────────────────────────
# APPLICATION
# ─────────────────────────────────────────────────────────────────────────────

app = FastAPI(
    title=settings.APP_NAME,
    description=(
        "Production-grade authentication system for the Sports Authority of India "
        "AI-powered sports talent assessment platform. "
        "Includes biometric face verification, OTP phone authentication, and JWT sessions."
    ),
    version=settings.APP_VERSION,
    docs_url="/docs" if settings.DEBUG else None,   # Disable Swagger in production
    redoc_url="/redoc" if settings.DEBUG else None,
    openapi_url="/openapi.json" if settings.DEBUG else None,
    lifespan=lifespan,
)

# Attach rate limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)


# ─────────────────────────────────────────────────────────────────────────────
# MIDDLEWARE
# ─────────────────────────────────────────────────────────────────────────────

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type", "X-Device-ID"],
    max_age=86400,  # Cache preflight for 24h
)

# Trusted Host protection (prevent host header injection)
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"] if settings.DEBUG else ["api.sai-sports.gov.in", "localhost"],
)


# ─────────────────────────────────────────────────────────────────────────────
# MIDDLEWARE: Request Logging + Timing
# ─────────────────────────────────────────────────────────────────────────────

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all requests with timing information."""
    start_time = time.perf_counter()
    
    # Body logging for debugging 422
    if request.method == "POST" and "register" in str(request.url):
        body = await request.body()
        # Reset request body so it can be read again by the route handler
        async def receive():
            return {"type": "http.request", "body": body}
        request._receive = receive
        logger.info(f"DEBUG REGISTER BODY: {body.decode()[:1000]}")

    response = await call_next(request)
    process_time_ms = (time.perf_counter() - start_time) * 1000

    logger.info(
        f"{request.method} {request.url.path} → {response.status_code} "
        f"[{process_time_ms:.1f}ms] IP={request.client.host}"
    )

    # Add processing time header
    response.headers["X-Process-Time-Ms"] = f"{process_time_ms:.1f}"
    response.headers["X-API-Version"] = settings.APP_VERSION

    return response


# ─────────────────────────────────────────────────────────────────────────────
# EXCEPTION HANDLERS
# ─────────────────────────────────────────────────────────────────────────────

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Return structured validation errors."""
    print("DEBUG: Validation Error details:")
    for error in exc.errors():
        print(f"  - Field: {error.get('loc')}, Message: {error.get('msg')}, Type: {error.get('type')}")
    
    # Also print body if possible
    try:
        raw_body = await request.body()
        print(f"DEBUG: Raw body length: {len(raw_body)}")
        # print(f"DEBUG: Raw body (first 200 chars): {raw_body.decode()[:200]}")
    except Exception as e:
        print(f"DEBUG: Could not read body: {e}")

    errors = []
    for error in exc.errors():
        errors.append({
            "field": " → ".join(str(loc) for loc in error["loc"]),
            "message": error["msg"],
            "type": error["type"],
        })
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": "Input validation failed", "errors": errors},
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch-all handler — never expose stack traces in production."""
    logger.exception(f"Unhandled exception for {request.method} {request.url.path}: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "An internal server error occurred. Please try again later.",
            "error_code": "INTERNAL_SERVER_ERROR",
        },
    )


# ─────────────────────────────────────────────────────────────────────────────
# ROUTERS
# ─────────────────────────────────────────────────────────────────────────────

app.include_router(auth_router)
app.include_router(test_router)
app.include_router(session_router)
app.include_router(local_engine_router)


# ─────────────────────────────────────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/health", tags=["Health"], include_in_schema=False)
async def health_check():
    """Kubernetes / load balancer health check endpoint."""
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
    }


@app.get("/", tags=["Root"], include_in_schema=False)
async def root():
    return {
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs" if settings.DEBUG else "Disabled in production",
    }
