from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.permissions import Permission, require_permission
from app.models.user import User
from app.schemas.common import PageResult
from app.schemas.notification import (
    AuditLogOut,
    AuditLogQuery,
    DashboardFullOut,
    DashboardStats,
    NotificationOut,
    NotificationQuery,
    UserStatsOut,
)
from app.services.dashboard_service import AuditLogService, DashboardService, NotificationService

router = APIRouter(tags=["统计与通知"])


@router.get("/dashboard", response_model=DashboardStats)
def get_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.DASHBOARD_READ)),
):
    return DashboardService(db).get_stats(current_user)


@router.get("/dashboard/full", response_model=DashboardFullOut)
def get_dashboard_full(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.DASHBOARD_READ)),
):
    return DashboardService(db).get_full(current_user)


@router.get("/profile/stats", response_model=UserStatsOut)
def get_profile_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return DashboardService(db).get_user_stats(current_user)


@router.get("/notifications", response_model=PageResult[NotificationOut])
def list_notifications(
    query: NotificationQuery = Depends(),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.NOTIFICATION_READ)),
):
    return NotificationService(db).list(current_user, query)


@router.put("/notifications/{notification_id}/read", response_model=NotificationOut)
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.NOTIFICATION_READ)),
):
    return NotificationService(db).mark_read(notification_id, current_user)


@router.get("/audit-logs", response_model=PageResult[AuditLogOut])
def list_audit_logs(
    query: AuditLogQuery = Depends(),
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.AUDIT_READ)),
):
    return AuditLogService(db).list(query)
