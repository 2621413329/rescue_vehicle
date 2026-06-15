from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.department import Department
from app.models.enums import UserRole
from app.models.enums import UserRole
from app.models.user import User
from app.repositories.crash_cart_repository import CrashCartRepository
from app.repositories.inspection_repository import InspectionRepository
from app.repositories.inventory_repository import InventoryRepository
from app.repositories.item_repository import ItemRepository
from app.repositories.notification_repository import AuditLogRepository, NotificationRepository
from app.schemas.common import PageResult
from app.schemas.notification import (
    AuditLogOut,
    AuditLogQuery,
    CartRiskOut,
    DashboardFullOut,
    DashboardStats,
    ExpiryForecastOut,
    LabelStatsOut,
    NotificationOut,
    NotificationQuery,
    RecentAuditOut,
    ReplacePlanOut,
    TodayTasksOut,
    UserStatsOut,
)
from app.services.extended_service import DashboardExtendedService, RiskService


class DashboardService:
    def __init__(self, db: Session):
        self.db = db
        self.cart_repo = CrashCartRepository(db)
        self.item_repo = ItemRepository(db)
        self.inventory_repo = InventoryRepository(db)
        self.inspection_repo = InspectionRepository(db)

    def get_stats(self, operator: User) -> DashboardStats:
        department_id = None if operator.role == UserRole.SUPER_ADMIN else operator.department_id
        return DashboardStats(
            cart_count=self.cart_repo.count_active(department_id),
            item_count=self.item_repo.count_enabled(),
            inventory_count=self.inventory_repo.count_all(department_id),
            near_expiry_count=self.inventory_repo.count_by_flags(
                department_id=department_id, is_near_expiry=True
            ),
            expired_count=self.inventory_repo.count_by_flags(
                department_id=department_id, is_expired=True
            ),
            low_stock_count=self.inventory_repo.count_by_flags(
                department_id=department_id, is_low_stock=True
            ),
            today_inspection_count=self.inspection_repo.count_today(department_id),
        )

    def get_full(self, operator: User) -> DashboardFullOut:
        department_id = None if operator.role == UserRole.SUPER_ADMIN else operator.department_id
        ext = DashboardExtendedService(self.db)
        dept_name = ""
        if operator.department_id:
            dept = self.db.get(Department, operator.department_id)
            dept_name = dept.name if dept else ""
        stats = self.get_stats(operator)
        risks = RiskService.rank_carts(self.db, department_id, limit=10)
        label = ext.label_stats(department_id)
        return DashboardFullOut(
            user_name=operator.real_name,
            department_name=dept_name,
            stats=stats,
            today_tasks=TodayTasksOut(**ext.today_tasks(department_id)),
            expiry_forecasts=[ExpiryForecastOut(**x) for x in ext.expiry_forecast(department_id)],
            replace_plans=[ReplacePlanOut(**x) for x in ext.replace_plans(department_id)],
            label_stats=LabelStatsOut(**label),
            cart_risks=[CartRiskOut(**r) for r in risks],
            recent_audits=[RecentAuditOut(**x) for x in ext.recent_audits(department_id)],
        )

    def get_user_stats(self, operator: User) -> UserStatsOut:
        data = DashboardExtendedService(self.db).user_stats(operator.id)
        return UserStatsOut(**data)


class NotificationService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = NotificationRepository(db)

    def list(self, operator: User, query: NotificationQuery) -> PageResult[NotificationOut]:
        items, total = self.repo.list_by_user(
            operator.id,
            page=query.page,
            page_size=query.page_size,
            is_read=query.is_read,
            type=query.type.value if query.type else None,
        )
        return PageResult(
            items=[NotificationOut.model_validate(i) for i in items],
            total=total,
            page=query.page,
            page_size=query.page_size,
        )

    def mark_read(self, notification_id: int, operator: User) -> NotificationOut:
        notification = self.repo.get_by_id(notification_id)
        if not notification or notification.user_id != operator.id:
            raise HTTPException(status_code=404, detail="通知不存在")
        notification.is_read = True
        self.db.commit()
        self.db.refresh(notification)
        return NotificationOut.model_validate(notification)


class AuditLogService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = AuditLogRepository(db)

    def list(self, query: AuditLogQuery) -> PageResult[AuditLogOut]:
        items, total = self.repo.list_logs(
            page=query.page,
            page_size=query.page_size,
            module=query.module,
            business_id=query.business_id,
            operator_id=query.operator_id,
            operation_type=query.operation_type.value if query.operation_type else None,
        )
        return PageResult(
            items=[AuditLogOut.model_validate(i) for i in items],
            total=total,
            page=query.page,
            page_size=query.page_size,
        )
