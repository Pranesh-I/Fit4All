"""
SAI Sports Talent Assessment - Face Verification Module
Cosine distance comparison of FaceNet 512-d embeddings.

PRIVACY GUARANTEE: Raw face images are NEVER stored.
Only the 512-dimensional floating-point embedding vector is persisted.
"""
import math
from typing import List

from app.config import settings


def _dot_product(a: List[float], b: List[float]) -> float:
    """Compute dot product of two vectors."""
    return sum(x * y for x, y in zip(a, b))


def _magnitude(v: List[float]) -> float:
    """Compute L2 norm of a vector."""
    return math.sqrt(sum(x * x for x in v))


def cosine_similarity(embedding_a: List[float], embedding_b: List[float]) -> float:
    """
    Compute cosine similarity between two 512-d FaceNet embeddings.
    Returns a value in [-1, 1]; higher means more similar.
    """
    if len(embedding_a) != len(embedding_b):
        raise ValueError(
            f"Embedding dimension mismatch: {len(embedding_a)} vs {len(embedding_b)}"
        )

    dot = _dot_product(embedding_a, embedding_b)
    mag_a = _magnitude(embedding_a)
    mag_b = _magnitude(embedding_b)

    if mag_a == 0 or mag_b == 0:
        raise ValueError("Zero-magnitude embedding detected. Face capture may have failed.")

    return dot / (mag_a * mag_b)


def cosine_distance(embedding_a: List[float], embedding_b: List[float]) -> float:
    """
    Compute cosine distance: 1 - cosine_similarity.
    Range: [0, 2]; lower means more similar.

    Threshold: distance < 0.5 → same person (accept)
               distance >= 0.5 → different person (reject)
    """
    return 1.0 - cosine_similarity(embedding_a, embedding_b)


def verify_face(
    stored_embedding: List[float],
    live_embedding: List[float],
    threshold: float = None,
) -> tuple[bool, float]:
    """
    Compare stored and live FaceNet embeddings using cosine distance.

    Args:
        stored_embedding: 512-d embedding from registration
        live_embedding: 512-d embedding from live capture
        threshold: distance threshold (default: settings.FACE_SIMILARITY_THRESHOLD)

    Returns:
        (is_match: bool, distance: float)

    Security:
        - Validates embedding dimensions
        - Rejects zero-vector embeddings
        - Uses configurable threshold (default 0.5)
    """
    if threshold is None:
        threshold = settings.FACE_SIMILARITY_THRESHOLD

    if len(stored_embedding) != settings.FACE_EMBEDDING_DIMENSION:
        raise ValueError(
            f"Stored embedding has invalid dimension: {len(stored_embedding)}. "
            f"Expected {settings.FACE_EMBEDDING_DIMENSION}."
        )

    if len(live_embedding) != settings.FACE_EMBEDDING_DIMENSION:
        raise ValueError(
            f"Live embedding has invalid dimension: {len(live_embedding)}. "
            f"Expected {settings.FACE_EMBEDDING_DIMENSION}."
        )

    distance = cosine_distance(stored_embedding, live_embedding)
    is_match = distance < threshold

    return is_match, distance


def validate_embedding(embedding: List[float]) -> bool:
    """
    Validate that an embedding is:
    - Exactly 512 dimensions
    - Not a zero vector
    - Contains finite values (no NaN / Inf)
    """
    if len(embedding) != settings.FACE_EMBEDDING_DIMENSION:
        return False
    if all(v == 0.0 for v in embedding):
        return False
    if not all(math.isfinite(v) for v in embedding):
        return False
    return True
