from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.enums import LabelColor, TimestampMixin


class LabelPrintRecord(Base, TimestampMixin):
    __tablename__ = "label_print_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    inventory_id: Mapped[int] = mapped_column(Integer, ForeignKey("inventories.id"), nullable=False, index=True)
    label_color: Mapped[LabelColor] = mapped_column(String(16), nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="PRINTED", nullable=False)
    operator_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    print_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
