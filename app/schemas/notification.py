from datetime import datetime

from pydantic import BaseModel

from app.models.enums import NotificationType, OperationType
from app.schemas.common import ORMModel, PageParams


class NotificationOut(ORMModel):
    id: int
    user_id: int
    title: str
    content: str
    type: NotificationType
    is_read: bool
    created_at: datetime


class NotificationQuery(PageParams):
    is_read: bool | None = None
    type: NotificationType | None = None


class AuditLogOut(ORMModel):
    id: int
    module: str
    business_id: int | None
    operation_type: OperationType
    old_data: dict | None
    new_data: dict | None
    operator_id: int | None
    operator_name: str | None
    operation_time: datetime
    ip_address: str | None


class AuditLogQuery(PageParams):
    module: str | None = None
    business_id: int | None = None
    operator_id: int | None = None
    operation_type: OperationType | None = None


class DashboardStats(BaseModel):
    cart_count: int
    item_count: int
    inventory_count: int
    near_expiry_count: int
    expired_count: int
    low_stock_count: int
    today_inspection_count: int


class TodayTasksOut(BaseModel):
    pending_inspection: int
    completed_inspection: int
    pending_replace: int
    completed_replace: int = 0
    total_replace: int = 0
    pending_labels: int
    completed_labels: int = 0
    total_labels: int = 0
    low_stock: int
    pending_confirm: int
    pending_exceptions: int


class ExpiryForecastOut(BaseModel):
    days: int
    label: str
    count: int


class ReplacePlanOut(BaseModel):
    period: str
    count: int
    items: list[str]


class LabelStatsOut(BaseModel):
    label_pending: int
    label_need_update: int
    label_need_print: int


class CartRiskOut(BaseModel):
    rank: int
    cart_id: int
    cart_name: str
    location: str
    risk_score: int
    expired_count: int
    near_expiry_count: int
    low_stock_count: int
    inspection_overdue: bool
    label_pending_count: int = 0


class RecentAuditOut(BaseModel):
    operator_name: str
    action: str
    target: str
    time: str


class UserStatsOut(BaseModel):
    today_workload: str
    month_inspections: int
    month_inventory_ops: int


class DashboardFullOut(BaseModel):
    user_name: str
    department_name: str
    stats: DashboardStats
    today_tasks: TodayTasksOut
    expiry_forecasts: list[ExpiryForecastOut]
    replace_plans: list[ReplacePlanOut]
    label_stats: LabelStatsOut
    cart_risks: list[CartRiskOut]
    recent_audits: list[RecentAuditOut]
