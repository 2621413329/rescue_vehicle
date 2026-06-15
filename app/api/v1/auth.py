from datetime import timedelta

from fastapi import APIRouter, Depends, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.api.deps import get_client_ip
from app.core.config import get_settings
from app.core.database import get_db
from app.core.security import create_access_token
from app.schemas.common import TokenResponse
from app.services.user_service import UserService

router = APIRouter(prefix="/auth", tags=["认证"])
settings = get_settings()


@router.post("/login", response_model=TokenResponse)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    user = UserService(db).authenticate(form_data.username, form_data.password)
    if not user:
        from fastapi import HTTPException

        raise HTTPException(status_code=401, detail="用户名或密码错误")
    token = create_access_token(
        {"sub": str(user.id), "role": user.role.value if hasattr(user.role, "value") else user.role},
        expires_delta=timedelta(minutes=settings.jwt_access_token_expire_minutes),
    )
    return TokenResponse(access_token=token)
