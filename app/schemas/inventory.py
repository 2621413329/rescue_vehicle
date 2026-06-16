from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.models.enums import ExpiryStatus, LabelColor
from app.schemas.common import ORMModel, PageParams


class InventoryCreate(BaseModel):
    item_id: int
    cart_id: int
    layer_id: int | None = None
    batch_no: str | None = None
    quantity: Decimal = Field(default=Decimal("0"), ge=0)
    minimum_quantity: Decimal = Field(default=Decimal("0"), ge=0)
    production_date: date | None = None
    expiry_date: date | None = None
    remark: str | None = None


class InventoryUpdate(BaseModel):
    layer_id: int | None = None
    batch_no: str | None = None
    quantity: Decimal | None = Field(default=None, ge=0)
    minimum_quantity: Decimal | None = Field(default=None, ge=0)
    production_date: date | None = None
    expiry_date: date | None = None
    remark: str | None = None
    operation_reason: str | None = Field(
        default=None, description="修改或删除库存时必填"
    )


class InventoryOut(ORMModel):
    id: int
    item_id: int
    cart_id: int
    layer_id: int | None
    batch_no: str | None
    quantity: Decimal
    minimum_quantity: Decimal
    production_date: date | None
    expiry_date: date | None
    warning_days: int
    warning_tag: str | None
    remaining_days: int | None
    expiry_status: ExpiryStatus
    label_color: LabelColor
    is_near_expiry: bool
    is_expired: bool
    is_low_stock: bool
    remark: str | None
    last_check_time: datetime | None
    task_replace_done: bool = False
    task_label_done: bool = False
    task_replace_done_at: datetime | None = None
    task_label_done_at: datetime | None = None
    created_at: datetime
    updated_at: datetime


class InventoryDetailOut(InventoryOut):
    item_name: str | None = None
    item_code: str | None = None
    cart_name: str | None = None
    cart_code: str | None = None
    layer_name: str | None = None
    layer_no: int | None = None
    label_status: str | None = None
    label_status_text: str | None = None
    manager_name: str | None = None


class InventoryQuery(PageParams):
    department_id: int | None = None
    cart_id: int | None = None
    layer_id: int | None = None
    item_id: int | None = None
    expiry_status: ExpiryStatus | None = None
    is_low_stock: bool | None = None
    is_near_expiry: bool | None = None
    is_expired: bool | None = None
    operator_id: int | None = None
    keyword: str | None = None


class TaskActionRequest(BaseModel):
    action: str
    remark: str | None = None
    expiry_date: date | None = None
    batch_no: str | None = None
    quantity: Decimal | None = Field(default=None, ge=0)
