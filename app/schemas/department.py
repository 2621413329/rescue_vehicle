from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel, PageParams


class DepartmentCreate(BaseModel):
    name: str = Field(min_length=1, max_length=128)
    description: str | None = None


class DepartmentUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=128)
    description: str | None = None


class DepartmentOut(ORMModel):
    id: int
    name: str
    description: str | None
    created_at: datetime
    updated_at: datetime


class DepartmentQuery(PageParams):
    keyword: str | None = None
