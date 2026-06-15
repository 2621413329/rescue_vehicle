from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import ExpiryStatus, LabelColor, SoftDeleteMixin, TimestampMixin


class Inventory(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "inventories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    item_id: Mapped[int] = mapped_column(Integer, ForeignKey("items.id"), nullable=False, index=True)
    cart_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("crash_carts.id"), nullable=False, index=True
    )
    layer_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("crash_cart_layers.id"), nullable=True, index=True
    )
    batch_no: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    quantity: Mapped[float] = mapped_column(Numeric(12, 2), default=0, nullable=False)
    minimum_quantity: Mapped[float] = mapped_column(Numeric(12, 2), default=0, nullable=False)
    production_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    expiry_date: Mapped[date | None] = mapped_column(Date, nullable=True, index=True)
    warning_days: Mapped[int] = mapped_column(Integer, default=180, nullable=False)
    warning_tag: Mapped[str | None] = mapped_column(String(64), nullable=True)
    remaining_days: Mapped[int | None] = mapped_column(Integer, nullable=True)
    expiry_status: Mapped[ExpiryStatus] = mapped_column(
        String(16), default=ExpiryStatus.NORMAL, nullable=False, index=True
    )
    label_color: Mapped[LabelColor] = mapped_column(
        String(16), default=LabelColor.GREEN, nullable=False
    )
    is_near_expiry: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    is_expired: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    is_low_stock: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    remark: Mapped[str | None] = mapped_column(Text, nullable=True)
    last_check_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_by: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    updated_by: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)

    item = relationship("Item", back_populates="inventories")
    cart = relationship("CrashCart", back_populates="inventories")
    layer = relationship("CrashCartLayer", back_populates="inventories")
