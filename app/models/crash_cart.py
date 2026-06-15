from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import CartStatus, SoftDeleteMixin, TimestampMixin


class CrashCart(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "crash_carts"
    __table_args__ = (
        UniqueConstraint("cart_code", name="uq_crash_carts_cart_code"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    department_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("departments.id"), nullable=False, index=True
    )
    cart_code: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    cart_name: Mapped[str] = mapped_column(String(128), nullable=False)
    location: Mapped[str | None] = mapped_column(String(256), nullable=True)
    manager_name: Mapped[str | None] = mapped_column(String(64), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[CartStatus] = mapped_column(String(32), default=CartStatus.ACTIVE, nullable=False)
    inspection_cycle_days: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    last_inspection_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_by: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    updated_by: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)

    department = relationship("Department", back_populates="crash_carts")
    layers = relationship("CrashCartLayer", back_populates="cart", cascade="all, delete-orphan")
    inventories = relationship("Inventory", back_populates="cart")


class CrashCartLayer(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "crash_cart_layers"
    __table_args__ = (
        UniqueConstraint("cart_id", "layer_no", name="uq_cart_layer_no"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    cart_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("crash_carts.id"), nullable=False, index=True
    )
    layer_no: Mapped[int] = mapped_column(Integer, nullable=False)
    layer_name: Mapped[str] = mapped_column(String(128), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    cart = relationship("CrashCart", back_populates="layers")
    inventories = relationship("Inventory", back_populates="layer")
