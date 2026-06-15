from datetime import date
from decimal import Decimal
from typing import Any

from app.models.enums import ExpiryStatus, LabelColor


def model_to_dict(obj: Any, exclude: set[str] | None = None) -> dict[str, Any]:
    exclude = exclude or set()
    data: dict[str, Any] = {}
    for column in obj.__table__.columns:
        if column.name in exclude:
            continue
        value = getattr(obj, column.name)
        if hasattr(value, "value"):
            value = value.value
        elif isinstance(value, (date,)):
            value = value.isoformat()
        elif isinstance(value, Decimal):
            value = float(value)
        data[column.name] = value
    return data


def calculate_expiry_fields(
    expiry_date: date | None,
    warning_days: int,
    current_date: date | None = None,
) -> dict[str, Any]:
    today = current_date or date.today()
    if expiry_date is None:
        return {
            "remaining_days": None,
            "expiry_status": ExpiryStatus.NORMAL,
            "label_color": LabelColor.GREEN,
            "is_near_expiry": False,
            "is_expired": False,
        }

    remaining_days = (expiry_date - today).days
    if remaining_days < 0:
        return {
            "remaining_days": remaining_days,
            "expiry_status": ExpiryStatus.EXPIRED,
            "label_color": LabelColor.RED,
            "is_near_expiry": False,
            "is_expired": True,
        }
    if remaining_days <= warning_days:
        return {
            "remaining_days": remaining_days,
            "expiry_status": ExpiryStatus.WARNING,
            "label_color": LabelColor.YELLOW,
            "is_near_expiry": True,
            "is_expired": False,
        }
    return {
        "remaining_days": remaining_days,
        "expiry_status": ExpiryStatus.NORMAL,
        "label_color": LabelColor.GREEN,
        "is_near_expiry": False,
        "is_expired": False,
    }


def calculate_low_stock(quantity: Decimal | float, minimum_quantity: Decimal | float) -> bool:
    return Decimal(str(quantity)) < Decimal(str(minimum_quantity))


def calculate_label_status(remaining_days: int | None) -> dict[str, str]:
    """标签规则：绿>180，黄≤180，红≤90。"""
    if remaining_days is None:
        return {"label_status": "GREEN", "label_status_text": "正常"}
    if remaining_days <= 90:
        return {"label_status": "RED", "label_status_text": "需立即更换"}
    if remaining_days <= 180:
        return {"label_status": "YELLOW", "label_status_text": "待更新标签"}
    return {"label_status": "GREEN", "label_status_text": "标签正常"}


def needs_label_action(remaining_days: int | None, last_print_days: int | None = None) -> str | None:
    if remaining_days is None:
        return None
    if remaining_days <= 90:
        return "NEED_REPLACE"
    if remaining_days <= 180:
        return "NEED_UPDATE"
    if last_print_days is None:
        return "NEED_PRINT"
    return None
