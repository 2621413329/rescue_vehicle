from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    app_name: str = "医院抢救车药品与物资效期管理系统"
    app_env: str = "development"
    debug: bool = True
    api_v1_prefix: str = "/api/v1"

    app_host: str = "0.0.0.0"
    app_port: int = 7080

    database_url: str = "postgresql://postgres:postgres@127.0.0.1:5432/rescue"

    jwt_secret_key: str = "change-this-to-a-random-secret-key-in-production"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 480

    inventory_expiry_cron_hour: int = 1
    inventory_expiry_cron_minute: int = 0

    seed_admin_username: str = "admin"
    seed_admin_password: str = "Admin@123456"


@lru_cache
def get_settings() -> Settings:
    return Settings()
