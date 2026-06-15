from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import get_password_hash, verify_password
from app.models.enums import OperationType, UserRole, UserStatus
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.common import PageResult
from app.schemas.user import UserCreate, UserOut, UserQuery, UserUpdate
from app.services.audit_service import AuditService


class UserService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = UserRepository(db)

    def authenticate(self, username: str, password: str) -> User | None:
        user = self.repo.get_by_username(username)
        if not user or not verify_password(password, user.password_hash):
            return None
        if user.status != UserStatus.ACTIVE:
            return None
        user.last_login_time = datetime.now(timezone.utc)
        self.db.commit()
        self.db.refresh(user)
        return user

    def create_user(
        self, data: UserCreate, operator: User, ip_address: str | None = None
    ) -> UserOut:
        if self.repo.get_by_username(data.username):
            raise HTTPException(status_code=400, detail="用户名已存在")
        if data.role != UserRole.SUPER_ADMIN and not data.department_id:
            raise HTTPException(status_code=400, detail="非超级管理员必须指定科室")
        user = User(
            username=data.username,
            password_hash=get_password_hash(data.password),
            real_name=data.real_name,
            phone=data.phone,
            email=data.email,
            department_id=data.department_id,
            role=data.role,
            status=data.status,
            created_by=operator.id,
            updated_by=operator.id,
        )
        self.db.add(user)
        self.db.flush()
        AuditService.log_model_change(
            self.db,
            module="user",
            obj=user,
            operation_type=OperationType.CREATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(user)
        return UserOut.model_validate(user)

    def update_user(
        self, user_id: int, data: UserUpdate, operator: User, ip_address: str | None = None
    ) -> UserOut:
        user = self.repo.get_by_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="用户不存在")
        old_user = User(
            id=user.id,
            username=user.username,
            real_name=user.real_name,
            phone=user.phone,
            email=user.email,
            department_id=user.department_id,
            role=user.role,
            status=user.status,
            password_hash=user.password_hash,
        )
        update_data = data.model_dump(exclude_unset=True)
        password = update_data.pop("password", None)
        for key, value in update_data.items():
            setattr(user, key, value)
        if password:
            user.password_hash = get_password_hash(password)
        user.updated_by = operator.id
        AuditService.log_model_change(
            self.db,
            module="user",
            obj=user,
            operation_type=OperationType.UPDATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=old_user,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(user)
        return UserOut.model_validate(user)

    def delete_user(self, user_id: int, operator: User, ip_address: str | None = None) -> None:
        user = self.repo.get_by_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="用户不存在")
        if user.id == operator.id:
            raise HTTPException(status_code=400, detail="不能删除当前登录用户")
        AuditService.log_model_change(
            self.db,
            module="user",
            obj=user,
            operation_type=OperationType.DELETE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=user,
            ip_address=ip_address,
        )
        self.repo.soft_delete(user)
        self.db.commit()

    def get_user(self, user_id: int) -> UserOut:
        user = self.repo.get_by_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="用户不存在")
        return UserOut.model_validate(user)

    def list_users(self, query: UserQuery) -> PageResult[UserOut]:
        items, total = self.repo.list_users(
            page=query.page,
            page_size=query.page_size,
            department_id=query.department_id,
            role=query.role.value if query.role else None,
            keyword=query.keyword,
        )
        return PageResult(
            items=[UserOut.model_validate(i) for i in items],
            total=total,
            page=query.page,
            page_size=query.page_size,
        )
