"""Application settings loaded from environment variables."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "Ayni SOS API"
    app_version: str = "0.1.0"
    debug: bool = True
    api_v1_prefix: str = "/api/v1"

    # Database — SQLite for local prototype; Postgres+PostGIS in Docker/prod
    database_url: str = "sqlite+aiosqlite:///./ayni_sos_local.db"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # JWT
    jwt_secret_key: str = "change-me-in-production-ayni-sos-research-proto"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30

    # MinIO / S3
    minio_endpoint: str = "localhost:9000"
    minio_access_key: str = "ayni_minio"
    minio_secret_key: str = "ayni_minio_secret"
    minio_bucket: str = "ayni-evidence"
    minio_secure: bool = False
    use_local_media: bool = True
    local_media_dir: str = "./media_store"

    # SMS gateway (prototype)
    sms_gateway_enabled: bool = True
    sms_inbound_secret: str = "ayni-sms-inbound-secret"

    # CORS
    cors_origins: list[str] = ["*"]


@lru_cache
def get_settings() -> Settings:
    return Settings()
