from datetime import datetime

from pydantic import BaseModel, Field

from app.models.enums import InspectionResult
from app.schemas.common import ORMModel, PageParams


class InspectionCreate(BaseModel):
    cart_id: int
    inspection_time: datetime
    result: InspectionResult
    remark: str | None = None


class InspectionOut(ORMModel):
    id: int
    cart_id: int
    inspector_id: int
    inspection_time: datetime
    result: InspectionResult
    remark: str | None
    created_at: datetime


class InspectionQuery(PageParams):
    cart_id: int | None = None
    inspector_id: int | None = None
    department_id: int | None = None
    start_time: datetime | None = None
    end_time: datetime | None = None
