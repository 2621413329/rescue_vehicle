from sqlalchemy import Boolean, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import ItemType, SoftDeleteMixin, TimestampMixin


class Item(Base, TimestampMixin, SoftDeleteMixin):
    __tablename__ = "items"
    __table_args__ = (
        UniqueConstraint("item_code", name="uq_items_item_code"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    item_code: Mapped[str] = mapped_column(String(64), nullable=False, index=True)
    item_name: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    item_type: Mapped[ItemType] = mapped_column(String(32), nullable=False, index=True)
    specification: Mapped[str | None] = mapped_column(String(128), nullable=True)
    manufacturer: Mapped[str | None] = mapped_column(String(128), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    usage_instruction: Mapped[str | None] = mapped_column(Text, nullable=True)
    storage_requirement: Mapped[str | None] = mapped_column(String(256), nullable=True)
    warning_days: Mapped[int] = mapped_column(Integer, default=180, nullable=False)
    default_warning_tag: Mapped[str | None] = mapped_column(String(64), nullable=True)
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_by: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    updated_by: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)

    inventories = relationship("Inventory", back_populates="item")
