import enum
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class SoftDeleteMixin:
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class UserRole(str, enum.Enum):
    SUPER_ADMIN = "SUPER_ADMIN"
    DEPARTMENT_ADMIN = "DEPARTMENT_ADMIN"
    NURSE = "NURSE"
    VIEWER = "VIEWER"


class UserStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    LOCKED = "LOCKED"


class ItemType(str, enum.Enum):
    MEDICINE = "MEDICINE"
    CONSUMABLE = "CONSUMABLE"
    EQUIPMENT = "EQUIPMENT"
    RESCUE_SUPPLY = "RESCUE_SUPPLY"


class ExpiryStatus(str, enum.Enum):
    NORMAL = "NORMAL"
    WARNING = "WARNING"
    EXPIRED = "EXPIRED"


class LabelColor(str, enum.Enum):
    GREEN = "GREEN"
    YELLOW = "YELLOW"
    RED = "RED"


class CartStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    MAINTENANCE = "MAINTENANCE"


class InspectionResult(str, enum.Enum):
    PASS = "PASS"
    FAIL = "FAIL"
    PARTIAL = "PARTIAL"


class NotificationType(str, enum.Enum):
    EXPIRY_WARNING = "EXPIRY_WARNING"
    EXPIRED = "EXPIRED"
    LOW_STOCK = "LOW_STOCK"
    INSPECTION = "INSPECTION"
    SYSTEM = "SYSTEM"


class OperationType(str, enum.Enum):
    CREATE = "CREATE"
    UPDATE = "UPDATE"
    DELETE = "DELETE"
    LABEL_PRINT = "LABEL_PRINT"
    REPLACE_DONE = "REPLACE_DONE"


class OperationReasonType(str, enum.Enum):
    ITEM_WARNING_UPDATE = "ITEM_WARNING_UPDATE"
    INVENTORY_DELETE = "INVENTORY_DELETE"
    INVENTORY_UPDATE = "INVENTORY_UPDATE"
    INVENTORY_TASK = "INVENTORY_TASK"
    ITEM_DELETE = "ITEM_DELETE"
    OTHER = "OTHER"
