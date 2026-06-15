from sqlalchemy import select

from app.models.audit_log import AuditLog
from app.models.notification import Notification
from app.models.operation_reason import OperationReason
from app.repositories.base import BaseRepository


class NotificationRepository(BaseRepository[Notification]):
    model = Notification

    def list_by_user(
        self,
        user_id: int,
        *,
        page: int,
        page_size: int,
        is_read: bool | None = None,
        type: str | None = None,
    ) -> tuple[list[Notification], int]:
        stmt = (
            select(Notification)
            .where(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
        )
        if is_read is not None:
            stmt = stmt.where(Notification.is_read.is_(is_read))
        if type:
            stmt = stmt.where(Notification.type == type)
        return self.paginate(stmt, page, page_size)


class AuditLogRepository(BaseRepository[AuditLog]):
    model = AuditLog

    def list_logs(
        self,
        *,
        page: int,
        page_size: int,
        module: str | None = None,
        business_id: int | None = None,
        operator_id: int | None = None,
        operation_type: str | None = None,
    ) -> tuple[list[AuditLog], int]:
        stmt = select(AuditLog).order_by(AuditLog.operation_time.desc())
        if module:
            stmt = stmt.where(AuditLog.module == module)
        if business_id:
            stmt = stmt.where(AuditLog.business_id == business_id)
        if operator_id:
            stmt = stmt.where(AuditLog.operator_id == operator_id)
        if operation_type:
            stmt = stmt.where(AuditLog.operation_type == operation_type)
        return self.paginate(stmt, page, page_size)


class OperationReasonRepository(BaseRepository[OperationReason]):
    model = OperationReason

    def list_by_business(self, module: str, business_id: int) -> list[OperationReason]:
        return list(
            self.db.scalars(
                select(OperationReason)
                .where(
                    OperationReason.module == module,
                    OperationReason.business_id == business_id,
                )
                .order_by(OperationReason.created_at.desc())
            ).all()
        )
