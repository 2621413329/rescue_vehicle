from __future__ import annotations

from datetime import date, datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.audit_log import AuditLog
from app.models.crash_cart import CrashCart
from app.models.enums import NotificationType, UserRole
from app.models.inspection import InspectionRecord
from app.models.inventory import Inventory
from app.models.item import Item
from app.models.label import LabelPrintRecord
from app.models.notification import Notification
from app.models.user import User
from app.utils.helpers import calculate_label_status, inventory_needs_label, inventory_needs_replace
from app.utils.audit_labels import audit_target, operation_title


class RiskService:
    @staticmethod
    def score_cart(db: Session, cart_id: int) -> dict:
        inv_stmt = select(Inventory).where(
            Inventory.cart_id == cart_id, Inventory.is_deleted.is_(False)
        )
        inventories = list(db.scalars(inv_stmt).all())
        expired = sum(1 for i in inventories if i.is_expired)
        near = sum(1 for i in inventories if i.is_near_expiry and not i.is_expired)
        low = sum(1 for i in inventories if i.is_low_stock)
        label_pending = sum(
            1
            for i in inventories
            if calculate_label_status(i.remaining_days)["label_status"] in ("YELLOW", "RED")
        )

        cart = db.get(CrashCart, cart_id)
        overdue = False
        if cart:
            if cart.last_inspection_time is None:
                overdue = True
            else:
                due = cart.last_inspection_time + timedelta(days=cart.inspection_cycle_days)
                overdue = datetime.now(timezone.utc) > due.replace(tzinfo=timezone.utc)

        score = min(
            100,
            expired * 25 + near * 8 + low * 10 + (10 if overdue else 0) + label_pending * 5,
        )
        return {
            "cart_id": cart_id,
            "risk_score": score,
            "expired_count": expired,
            "near_expiry_count": near,
            "low_stock_count": low,
            "label_pending_count": label_pending,
            "inspection_overdue": overdue,
        }

    @staticmethod
    def rank_carts(db: Session, department_id: int | None = None, limit: int = 10) -> list[dict]:
        stmt = select(CrashCart).where(CrashCart.is_deleted.is_(False))
        if department_id:
            stmt = stmt.where(CrashCart.department_id == department_id)
        carts = list(db.scalars(stmt).all())
        ranked = []
        for cart in carts:
            s = RiskService.score_cart(db, cart.id)
            ranked.append(
                {
                    **s,
                    "cart_name": cart.cart_name,
                    "location": cart.location or "",
                    "rank": 0,
                }
            )
        ranked.sort(key=lambda x: x["risk_score"], reverse=True)
        for i, r in enumerate(ranked[:limit], start=1):
            r["rank"] = i
        return ranked[:limit]


class NotificationGenerator:
    @staticmethod
    def notify_user(
        db: Session,
        *,
        user_id: int,
        title: str,
        content: str,
        ntype: NotificationType,
    ) -> None:
        exists = db.scalar(
            select(func.count())
            .select_from(Notification)
            .where(
                Notification.user_id == user_id,
                Notification.title == title,
                Notification.is_read.is_(False),
            )
        )
        if exists:
            return
        db.add(
            Notification(user_id=user_id, title=title, content=content, type=ntype, is_read=False)
        )

    @staticmethod
    def notify_department_admins(
        db: Session,
        department_id: int,
        title: str,
        content: str,
        ntype: NotificationType,
    ) -> None:
        users = list(
            db.scalars(
                select(User).where(
                    User.department_id == department_id,
                    User.is_deleted.is_(False),
                    User.role.in_([UserRole.DEPARTMENT_ADMIN, UserRole.NURSE]),
                )
            ).all()
        )
        for u in users:
            NotificationGenerator.notify_user(
                db, user_id=u.id, title=title, content=content, ntype=ntype
            )

    @staticmethod
    def on_inventory_status_change(db: Session, inventory: Inventory) -> None:
        cart = db.get(CrashCart, inventory.cart_id)
        if not cart:
            return
        item = db.get(Item, inventory.item_id)
        name = item.item_name if item else f"库存#{inventory.id}"
        if inventory.is_expired:
            NotificationGenerator.notify_department_admins(
                db,
                cart.department_id,
                title="库存已过期",
                content=f"{name}（{cart.cart_name}）已过期，请立即处理",
                ntype=NotificationType.EXPIRED,
            )
        elif inventory.is_near_expiry:
            NotificationGenerator.notify_department_admins(
                db,
                cart.department_id,
                title="库存临期预警",
                content=f"{name}（{cart.cart_name}）剩余{inventory.remaining_days}天",
                ntype=NotificationType.EXPIRY_WARNING,
            )
        if inventory.is_low_stock:
            NotificationGenerator.notify_department_admins(
                db,
                cart.department_id,
                title="库存不足",
                content=f"{name}（{cart.cart_name}）低于最低库存",
                ntype=NotificationType.LOW_STOCK,
            )


class DashboardExtendedService:
    def __init__(self, db: Session):
        self.db = db

    def _dept(self, operator: User) -> int | None:
        return None if operator.role == UserRole.SUPER_ADMIN else operator.department_id

    def expiry_forecast(self, department_id: int | None) -> list[dict]:
        today = date.today()
        buckets = [7, 30, 90, 180, 365]
        result = []
        stmt = select(Inventory).where(
            Inventory.is_deleted.is_(False), Inventory.expiry_date.is_not(None)
        )
        if department_id:
            stmt = stmt.join(CrashCart, Inventory.cart_id == CrashCart.id).where(
                CrashCart.department_id == department_id
            )
        inventories = list(self.db.scalars(stmt).all())
        for days in buckets:
            deadline = today + timedelta(days=days)
            count = sum(
                1
                for i in inventories
                if i.expiry_date and today <= i.expiry_date <= deadline
            )
            result.append({"days": days, "label": f"{days}天内", "count": count})
        return result

    def replace_plans(self, department_id: int | None) -> list[dict]:
        import calendar

        today = date.today()
        last_day = calendar.monthrange(today.year, today.month)[1]
        month_end = today.replace(day=last_day)
        next_month_start = month_end + timedelta(days=1)
        next_month_last = calendar.monthrange(next_month_start.year, next_month_start.month)[1]
        next_month_end = next_month_start.replace(day=next_month_last)
        ranges = [
            ("本月需更换", today.replace(day=1), month_end),
            ("下月需更换", next_month_start, next_month_end),
            ("三个月内", today, today + timedelta(days=90)),
            ("半年内", today, today + timedelta(days=180)),
        ]
        stmt = select(Inventory, Item).join(Item, Inventory.item_id == Item.id).where(
            Inventory.is_deleted.is_(False), Inventory.expiry_date.is_not(None)
        )
        if department_id:
            stmt = stmt.join(CrashCart, Inventory.cart_id == CrashCart.id).where(
                CrashCart.department_id == department_id
            )
        rows = list(self.db.execute(stmt).all())
        plans = []
        for period, start, end in ranges:
            items = []
            for inv, item in rows:
                if inv.task_replace_done:
                    continue
                if inv.expiry_date and start <= inv.expiry_date <= end:
                    items.append(f"{item.item_name}×{int(inv.quantity)}")
            plans.append({"period": period, "count": len(items), "items": items[:5]})
        return plans

    def label_stats(self, department_id: int | None) -> dict:
        stmt = select(Inventory).where(Inventory.is_deleted.is_(False))
        if department_id:
            stmt = stmt.join(CrashCart, Inventory.cart_id == CrashCart.id).where(
                CrashCart.department_id == department_id
            )
        inventories = list(self.db.scalars(stmt).all())
        pending, need_update, need_print = 0, 0, 0
        completed_labels = 0
        total_labels = 0
        for inv in inventories:
            has_print = self.db.scalar(
                select(func.count())
                .select_from(LabelPrintRecord)
                .where(LabelPrintRecord.inventory_id == inv.id)
            )
            needs = inventory_needs_label(inv.remaining_days, bool(has_print))
            if not needs and not inv.task_label_done:
                continue
            total_labels += 1
            if inv.task_label_done:
                completed_labels += 1
            ls = calculate_label_status(inv.remaining_days)
            if ls["label_status"] == "RED":
                need_update += 1
            elif ls["label_status"] == "YELLOW":
                need_update += 1
            if not has_print and inv.remaining_days and inv.remaining_days <= 180:
                need_print += 1
            if not has_print and not inv.task_label_done:
                pending += 1
        return {
            "label_pending": pending,
            "label_need_update": need_update,
            "label_need_print": need_print,
            "label_completed": completed_labels,
            "label_total": total_labels,
        }

    def today_tasks(self, department_id: int | None) -> dict:
        now = datetime.now(timezone.utc)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

        cart_stmt = select(CrashCart).where(CrashCart.is_deleted.is_(False))
        if department_id:
            cart_stmt = cart_stmt.where(CrashCart.department_id == department_id)
        carts = list(self.db.scalars(cart_stmt).all())

        pending_inspection = 0
        for cart in carts:
            if cart.last_inspection_time is None:
                pending_inspection += 1
            else:
                due = cart.last_inspection_time + timedelta(days=cart.inspection_cycle_days)
                if now > due:
                    pending_inspection += 1

        insp_stmt = (
            select(func.count())
            .select_from(InspectionRecord)
            .where(InspectionRecord.inspection_time >= today_start)
        )
        if department_id:
            insp_stmt = insp_stmt.join(CrashCart, InspectionRecord.cart_id == CrashCart.id).where(
                CrashCart.department_id == department_id
            )
        completed = self.db.scalar(insp_stmt) or 0

        inv_stmt = select(Inventory).where(Inventory.is_deleted.is_(False))
        if department_id:
            inv_stmt = inv_stmt.join(CrashCart, Inventory.cart_id == CrashCart.id).where(
                CrashCart.department_id == department_id
            )
        inventories = list(self.db.scalars(inv_stmt).all())

        replace_items = [
            i
            for i in inventories
            if inventory_needs_replace(i.remaining_days, i.is_expired, i.is_near_expiry)
            or i.task_replace_done
        ]
        total_replace = len(replace_items)
        completed_replace = sum(1 for i in replace_items if i.task_replace_done)
        pending_replace = total_replace - completed_replace

        label_items = []
        for inv in inventories:
            has_print = self.db.scalar(
                select(func.count())
                .select_from(LabelPrintRecord)
                .where(LabelPrintRecord.inventory_id == inv.id)
            )
            if inventory_needs_label(inv.remaining_days, bool(has_print)) or inv.task_label_done:
                label_items.append(inv)
        total_labels = len(label_items)
        completed_labels = sum(1 for i in label_items if i.task_label_done)
        pending_labels = total_labels - completed_labels

        low_stock = sum(1 for i in inventories if i.is_low_stock)
        pending_confirm = sum(
            1 for i in inventories if i.last_check_time is None or i.last_check_time < today_start
        )

        return {
            "pending_inspection": pending_inspection,
            "completed_inspection": completed,
            "pending_replace": pending_replace,
            "completed_replace": completed_replace,
            "total_replace": total_replace,
            "pending_labels": pending_labels,
            "completed_labels": completed_labels,
            "total_labels": total_labels,
            "low_stock": low_stock,
            "pending_confirm": min(pending_confirm, 99),
            "pending_exceptions": sum(1 for i in inventories if i.is_expired),
        }

    def recent_audits(self, department_id: int | None, limit: int = 10) -> list[dict]:
        stmt = select(AuditLog).order_by(AuditLog.operation_time.desc()).limit(limit)
        logs = list(self.db.scalars(stmt).all())
        return [
            {
                "operator_name": log.operator_name or "系统",
                "action": operation_title(log.operation_type, log.module, log.new_data),
                "target": audit_target(self.db, log.module, log.business_id),
                "time": log.operation_time.strftime("%H:%M") if log.operation_time else "",
            }
            for log in logs
        ]

    def user_stats(self, user_id: int) -> dict:
        month_start = datetime.now(timezone.utc).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        inspections = self.db.scalar(
            select(func.count())
            .select_from(InspectionRecord)
            .where(
                InspectionRecord.inspector_id == user_id,
                InspectionRecord.inspection_time >= month_start,
            )
        ) or 0
        inventory_ops = self.db.scalar(
            select(func.count())
            .select_from(AuditLog)
            .where(
                AuditLog.operator_id == user_id,
                AuditLog.module == "inventory",
                AuditLog.operation_time >= month_start,
            )
        ) or 0
        today_inspections = self.db.scalar(
            select(func.count())
            .select_from(InspectionRecord)
            .where(
                InspectionRecord.inspector_id == user_id,
                InspectionRecord.inspection_time
                >= datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0),
            )
        ) or 0
        return {
            "today_workload": f"巡检{today_inspections}次 · 处理库存{inventory_ops}项",
            "month_inspections": inspections,
            "month_inventory_ops": inventory_ops,
        }
