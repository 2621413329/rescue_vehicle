from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.api.deps import get_client_ip, get_current_user
from app.core.database import get_db
from app.core.permissions import Permission, require_permission
from app.models.user import User
from app.schemas.common import MessageResponse, PageResult
from app.schemas.user import UserCreate, UserOut, UserQuery, UserUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["用户管理"])


@router.post("", response_model=UserOut)
def create_user(
    data: UserCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.USER_MANAGE)),
):
    return UserService(db).create_user(data, current_user, get_client_ip(request))


@router.get("", response_model=PageResult[UserOut])
def list_users(
    query: UserQuery = Depends(),
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.USER_MANAGE)),
):
    return UserService(db).list_users(query)


@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return UserOut.model_validate(current_user)


@router.get("/{user_id}", response_model=UserOut)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.USER_MANAGE)),
):
    return UserService(db).get_user(user_id)


@router.put("/{user_id}", response_model=UserOut)
def update_user(
    user_id: int,
    data: UserUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.USER_MANAGE)),
):
    return UserService(db).update_user(user_id, data, current_user, get_client_ip(request))


@router.delete("/{user_id}", response_model=MessageResponse)
def delete_user(
    user_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.USER_MANAGE)),
):
    UserService(db).delete_user(user_id, current_user, get_client_ip(request))
    return MessageResponse(message="删除成功")
