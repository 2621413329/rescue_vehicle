from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.models.enums import UserRole, UserStatus
from app.schemas.common import ORMModel, PageParams


class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=6, max_length=128)
    real_name: str = Field(min_length=1, max_length=64)
    phone: str | None = None
    email: EmailStr | None = None
    department_id: int | None = None
    role: UserRole
    status: UserStatus = UserStatus.ACTIVE


class UserUpdate(BaseModel):
    real_name: str | None = None
    phone: str | None = None
    email: EmailStr | None = None
    department_id: int | None = None
    role: UserRole | None = None
    status: UserStatus | None = None
    password: str | None = Field(default=None, min_length=6, max_length=128)


class UserOut(ORMModel):
    id: int
    username: str
    real_name: str
    phone: str | None
    email: str | None
    department_id: int | None
    role: UserRole
    status: UserStatus
    last_login_time: datetime | None
    created_at: datetime
    updated_at: datetime


class UserQuery(PageParams):
    department_id: int | None = None
    role: UserRole | None = None
    keyword: str | None = None
