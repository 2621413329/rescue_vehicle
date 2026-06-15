from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Request
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import get_db

router = APIRouter(tags=["健康检查"])


def _client_ip(request: Request) -> str | None:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return None


def build_health_payload(request: Request, db: Session) -> dict:
    settings = get_settings()
    db_ok = False
    db_error: str | None = None
    try:
        db.execute(text("SELECT 1"))
        db_ok = True
    except Exception as exc:
        db_error = str(exc)

    status = "ok" if db_ok else "degraded"
    return {
        "status": status,
        "reachable": True,
        "app": settings.app_name,
        "env": settings.app_env,
        "version": "1.0.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "database": "ok" if db_ok else "error",
        "database_error": db_error,
        "client_ip": _client_ip(request),
        "host": settings.app_host,
        "port": settings.app_port,
        "api_prefix": settings.api_v1_prefix,
    }


@router.get("/health")
def api_health_check(request: Request, db: Session = Depends(get_db)):
    """供手机端检测是否能访问当前后端环境（无需登录）。"""
    return build_health_payload(request, db)
