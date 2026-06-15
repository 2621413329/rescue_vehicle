from datetime import datetime

from pydantic import BaseModel, Field

from app.models.enums import CartStatus
from app.schemas.common import ORMModel, PageParams


class CrashCartCreate(BaseModel):
    department_id: int
    cart_code: str = Field(min_length=1, max_length=64)
    cart_name: str = Field(min_length=1, max_length=128)
    location: str | None = None
    manager_name: str | None = None
    description: str | None = None
    status: CartStatus = CartStatus.ACTIVE


class CrashCartUpdate(BaseModel):
    department_id: int | None = None
    cart_code: str | None = Field(default=None, min_length=1, max_length=64)
    cart_name: str | None = Field(default=None, min_length=1, max_length=128)
    location: str | None = None
    manager_name: str | None = None
    description: str | None = None
    status: CartStatus | None = None


class CrashCartOut(ORMModel):
    id: int
    department_id: int
    cart_code: str
    cart_name: str
    location: str | None
    manager_name: str | None
    description: str | None
    status: CartStatus
    created_at: datetime
    updated_at: datetime


class CrashCartQuery(PageParams):
    department_id: int | None = None
    keyword: str | None = None
    status: CartStatus | None = None


class CrashCartLayerCreate(BaseModel):
    cart_id: int
    layer_no: int = Field(ge=1)
    layer_name: str = Field(min_length=1, max_length=128)
    description: str | None = None
    sort_order: int = 0


class CrashCartLayerUpdate(BaseModel):
    layer_no: int | None = Field(default=None, ge=1)
    layer_name: str | None = Field(default=None, min_length=1, max_length=128)
    description: str | None = None
    sort_order: int | None = None


class CrashCartLayerOut(ORMModel):
    id: int
    cart_id: int
    layer_no: int
    layer_name: str
    description: str | None
    sort_order: int
    created_at: datetime
    updated_at: datetime


class CrashCartLayerQuery(PageParams):
    cart_id: int | None = None
