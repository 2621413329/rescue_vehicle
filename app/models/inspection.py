from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.enums import InspectionResult, TimestampMixin


class InspectionRecord(Base, TimestampMixin):
    __tablename__ = "inspection_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    cart_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("crash_carts.id"), nullable=False, index=True
    )
    inspector_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id"), nullable=False, index=True
    )
    inspection_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    result: Mapped[InspectionResult] = mapped_column(String(16), nullable=False)
    remark: Mapped[str | None] = mapped_column(Text, nullable=True)
