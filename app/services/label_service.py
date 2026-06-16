from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.crash_cart import CrashCart
from app.models.enums import LabelColor, OperationType, UserRole
from app.models.inventory import Inventory
from app.models.item import Item
from app.models.label import LabelPrintRecord
from app.models.operation_reason import OperationReason
from app.models.user import User
from app.repositories.inventory_repository import InventoryRepository
from app.schemas.common import PageResult
from app.utils.audit_labels import audit_target, operation_title, sort_timestamp
from app.utils.helpers import calculate_label_status


class LabelService:
    def __init__(self, db: Session):
        self.db = db
        self.inventory_repo = InventoryRepository(db)

    def list_pending(
        self, operator: User, page: int = 1, page_size: int = 50
    ) -> PageResult[dict]:
        department_id = None if operator.role == UserRole.SUPER_ADMIN else operator.department_id
        items, _ = self.inventory_repo.list_inventories(
            page=1,
            page_size=500,
            department_id=department_id,
        )
        result = []
        for inv in items:
            ls = calculate_label_status(inv.remaining_days)
            item = self.db.get(Item, inv.item_id)
            cart = self.db.get(CrashCart, inv.cart_id)
            has_print = self.db.scalar(
                select(func.count())
                .select_from(LabelPrintRecord)
                .where(LabelPrintRecord.inventory_id == inv.id)
            )
            if ls["label_status"] == "GREEN" and has_print:
                continue
            result.append(
                {
                    "inventory_id": inv.id,
                    "item_name": item.item_name if item else "",
                    "remaining_days": inv.remaining_days,
                    "label_status": ls["label_status"],
                    "label_status_text": ls["label_status_text"],
                    "cart_name": cart.cart_name if cart else "",
                    "has_printed": bool(has_print),
                }
            )
        start = (page - 1) * page_size
        page_items = result[start : start + page_size]
        return PageResult(
            items=page_items, total=len(result), page=page, page_size=page_size
        )

    def print_labels(
        self, inventory_ids: list[int], operator: User, remark: str = "批量打印标签"
    ) -> int:
        from app.services.audit_service import AuditService

        count = 0
        for inv_id in inventory_ids:
            inv = self.inventory_repo.get_by_id(inv_id)
            if not inv:
                continue
            ls = calculate_label_status(inv.remaining_days)
            color = LabelColor(ls["label_status"])
            self.db.add(
                LabelPrintRecord(
                    inventory_id=inv_id,
                    label_color=color,
                    operator_id=operator.id,
                    print_time=datetime.now(timezone.utc),
                    status="PRINTED",
                )
            )
            AuditService.log(
                self.db,
                module="inventory",
                business_id=inv_id,
                operation_type=OperationType.LABEL_PRINT,
                old_data=None,
                new_data={"label_color": color.value if hasattr(color, "value") else str(color), "remark": remark},
                operator_id=operator.id,
                operator_name=operator.real_name,
            )
            count += 1
        self.db.commit()
        return count

    def list_history(self, inventory_id: int) -> list[dict]:
        records = list(
            self.db.scalars(
                select(LabelPrintRecord)
                .where(LabelPrintRecord.inventory_id == inventory_id)
                .order_by(LabelPrintRecord.print_time.desc())
            ).all()
        )
        return [
            {
                "id": r.id,
                "label_color": r.label_color.value if hasattr(r.label_color, "value") else r.label_color,
                "status": r.status,
                "operator_id": r.operator_id,
                "print_time": r.print_time.isoformat(),
            }
            for r in records
        ]


class TimelineService:
    def __init__(self, db: Session):
        self.db = db

    def _operator_name(self, user_id: int | None) -> str:
        if not user_id:
            return ""
        user = self.db.get(User, user_id)
        return user.real_name if user else ""

    def _format_inventory_snapshot(self, inv: Inventory) -> str:
        parts = [f"数量 {inv.quantity}"]
        if inv.batch_no:
            parts.append(f"批号 {inv.batch_no}")
        if inv.expiry_date:
            parts.append(f"有效期 {inv.expiry_date}")
        if inv.remark:
            parts.append(f"备注 {inv.remark}")
        return "，".join(parts)

    def inventory_timeline(self, inventory_id: int) -> list[dict]:
        from app.models.audit_log import AuditLog

        inv = self.db.get(Inventory, inventory_id)
        if not inv:
            return []

        logs = list(
            self.db.scalars(
                select(AuditLog)
                .where(AuditLog.module == "inventory", AuditLog.business_id == inventory_id)
                .order_by(AuditLog.operation_time.asc())
            ).all()
        )
        reasons = list(
            self.db.scalars(
                select(OperationReason)
                .where(
                    OperationReason.module == "inventory",
                    OperationReason.business_id == inventory_id,
                )
                .order_by(OperationReason.created_at.asc())
            ).all()
        )

        items: list[dict] = []
        has_create_log = any(
            (log.operation_type.value if hasattr(log.operation_type, "value") else str(log.operation_type))
            == OperationType.CREATE.value
            for log in logs
        )

        if not has_create_log and inv.created_at:
            items.append(
                {
                    "title": "入库",
                    "operator_name": self._operator_name(inv.created_by),
                    "time": inv.created_at.strftime("%Y-%m-%d %H:%M"),
                    "detail": self._format_inventory_snapshot(inv),
                    "_sort": inv.created_at,
                }
            )

        for log in logs:
            title = operation_title(log.operation_type, log.module, log.new_data)
            detail = ""
            if log.new_data and isinstance(log.new_data, dict):
                if log.new_data.get("remark"):
                    detail = str(log.new_data["remark"])
                elif log.new_data.get("label_color"):
                    detail = f"标签颜色 {log.new_data['label_color']}"
            elif log.old_data and log.new_data:
                detail = f"{log.old_data} → {log.new_data}"
            elif log.new_data:
                detail = f"新建: {log.new_data}"
            elif log.old_data:
                detail = f"删除: {log.old_data}"
            items.append(
                {
                    "title": title,
                    "operator_name": log.operator_name or "",
                    "time": log.operation_time.strftime("%Y-%m-%d %H:%M")
                    if log.operation_time
                    else "",
                    "detail": detail,
                    "_sort": log.operation_time,
                }
            )

        for r in reasons:
            rt = r.reason_type.value if hasattr(r.reason_type, "value") else str(r.reason_type)
            if rt == "INVENTORY_UPDATE":
                continue
            items.append(
                {
                    "title": "操作备注",
                    "operator_name": self._operator_name(r.operator_id),
                    "time": r.created_at.strftime("%Y-%m-%d %H:%M") if r.created_at else "",
                    "detail": r.reason,
                    "_sort": r.created_at,
                }
            )

        items.sort(key=lambda x: sort_timestamp(x.get("_sort")), reverse=True)
        for item in items:
            item.pop("_sort", None)
        return items
