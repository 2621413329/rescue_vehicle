from datetime import datetime

from pydantic import BaseModel, Field

from app.models.enums import ItemType, OperationReasonType
from app.schemas.common import ORMModel, PageParams


class ItemCreate(BaseModel):
    item_code: str | None = Field(default=None, max_length=64)
    item_name: str = Field(min_length=1, max_length=128)
    item_type: ItemType
    specification: str | None = None
    manufacturer: str | None = None
    description: str | None = None
    usage_instruction: str | None = None
    storage_requirement: str | None = None
    warning_days: int = Field(default=180, ge=1)
    default_warning_tag: str | None = None
    is_enabled: bool = True


class ItemUpdate(BaseModel):
    item_code: str | None = Field(default=None, min_length=1, max_length=64)
    item_name: str | None = Field(default=None, min_length=1, max_length=128)
    item_type: ItemType | None = None
    specification: str | None = None
    manufacturer: str | None = None
    description: str | None = None
    usage_instruction: str | None = None
    storage_requirement: str | None = None
    warning_days: int | None = Field(default=None, ge=1)
    default_warning_tag: str | None = None
    is_enabled: bool | None = None
    operation_reason: str | None = Field(
        default=None, description="修改预警规则等敏感操作时必填"
    )


class ItemOut(ORMModel):
    id: int
    item_code: str
    item_name: str
    item_type: ItemType
    specification: str | None
    manufacturer: str | None
    description: str | None
    usage_instruction: str | None
    storage_requirement: str | None
    warning_days: int
    default_warning_tag: str | None
    is_enabled: bool
    created_at: datetime
    updated_at: datetime
    operator_name: str | None = None
    in_use: bool = False


class ItemQuery(PageParams):
    item_type: ItemType | None = None
    keyword: str | None = None
    is_enabled: bool | None = None


class OperationReasonOut(ORMModel):
    id: int
    module: str
    business_id: int
    reason_type: OperationReasonType
    reason: str
    operator_id: int | None
    created_at: datetime
