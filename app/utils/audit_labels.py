from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.enums import OperationType
from app.models.inventory import Inventory
from app.models.item import Item

MODULE_LABELS: dict[str, str] = {
    "inventory": "库存",
    "item": "药品",
    "crash_cart": "抢救车",
    "crash_cart_layer": "层级",
    "department": "科室",
    "user": "用户",
    "inspection": "巡检",
}

DEFAULT_OPERATION_LABELS: dict[str, str] = {
    OperationType.CREATE.value: "新增",
    OperationType.UPDATE.value: "修改",
    OperationType.DELETE.value: "删除",
    OperationType.LABEL_PRINT.value: "打印标签",
    OperationType.REPLACE_DONE.value: "完成更换",
}

MODULE_OPERATION_LABELS: dict[str, dict[str, str]] = {
    "inventory": {
        OperationType.CREATE.value: "入库",
        OperationType.UPDATE.value: "修改库存",
        OperationType.DELETE.value: "删除库存",
        OperationType.LABEL_PRINT.value: "标记已贴标签",
        OperationType.REPLACE_DONE.value: "标记已更换",
    },
    "item": {
        OperationType.CREATE.value: "新增药品",
        OperationType.UPDATE.value: "修改药品",
        OperationType.DELETE.value: "停用药品",
    },
    "crash_cart": {
        OperationType.CREATE.value: "新增抢救车",
        OperationType.UPDATE.value: "修改抢救车",
        OperationType.DELETE.value: "删除抢救车",
    },
    "inspection": {
        OperationType.CREATE.value: "提交巡检",
    },
}


def _op_value(operation_type) -> str:
    return operation_type.value if hasattr(operation_type, "value") else str(operation_type)


def operation_title(operation_type, module: str, new_data: dict | None = None) -> str:
    if new_data and isinstance(new_data, dict):
        remark = new_data.get("remark")
        if remark:
            return str(remark)
    op = _op_value(operation_type)
    return MODULE_OPERATION_LABELS.get(module, {}).get(op) or DEFAULT_OPERATION_LABELS.get(op, op)


def audit_target(db: Session, module: str, business_id: int | None) -> str:
    module_label = MODULE_LABELS.get(module, module)
    if business_id is None:
        return module_label
    if module == "inventory":
        inv = db.get(Inventory, business_id)
        if inv:
            item = db.get(Item, inv.item_id)
            if item:
                return f"{module_label}·{item.item_name}"
    if module == "item":
        item = db.get(Item, business_id)
        if item:
            return f"{module_label}·{item.item_name}"
    return f"{module_label}#{business_id}"


def sort_timestamp(dt: datetime | None) -> float:
    if dt is None:
        return 0.0
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.timestamp()
