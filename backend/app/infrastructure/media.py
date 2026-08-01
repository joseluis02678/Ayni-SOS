"""Object storage helpers — MinIO when available, local filesystem fallback."""

from __future__ import annotations

from pathlib import Path

from app.core.config import get_settings

_local_root: Path | None = None


def _local_dir() -> Path:
    global _local_root
    if _local_root is None:
        settings = get_settings()
        _local_root = Path(settings.local_media_dir)
        _local_root.mkdir(parents=True, exist_ok=True)
    return _local_root


def ensure_bucket() -> None:
    settings = get_settings()
    if settings.use_local_media:
        _local_dir()
        return
    try:
        from minio import Minio

        client = Minio(
            settings.minio_endpoint,
            access_key=settings.minio_access_key,
            secret_key=settings.minio_secret_key,
            secure=settings.minio_secure,
        )
        if not client.bucket_exists(settings.minio_bucket):
            client.make_bucket(settings.minio_bucket)
    except Exception:  # noqa: BLE001
        # Fall back to local disk for prototype runs without MinIO
        _local_dir()


def put_object(object_key: str, data: bytes, content_type: str) -> None:
    settings = get_settings()
    if settings.use_local_media:
        path = _local_dir() / object_key.replace("/", "_")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        return
    try:
        from io import BytesIO

        from minio import Minio

        client = Minio(
            settings.minio_endpoint,
            access_key=settings.minio_access_key,
            secret_key=settings.minio_secret_key,
            secure=settings.minio_secure,
        )
        client.put_object(
            settings.minio_bucket,
            object_key,
            BytesIO(data),
            length=len(data),
            content_type=content_type,
        )
    except Exception:  # noqa: BLE001
        path = _local_dir() / object_key.replace("/", "_")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
