from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.enums import OperationReasonType, TimestampMixin


class OperationReason(Base, TimestampMixin):
    __tablename__ = "operation_reasons"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    module: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    business_id: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    reason_type: Mapped[OperationReasonType] = mapped_column(String(64), nullable=False, index=True)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    operator_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"), nullable=True, index=True)
