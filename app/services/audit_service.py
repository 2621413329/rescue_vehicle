from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.audit_log import AuditLog
from app.models.enums import OperationType
from app.models.operation_reason import OperationReason, OperationReasonType
from app.utils.helpers import model_to_dict


class AuditService:
    AUDIT_MODULES = {
        "user",
        "department",
        "crash_cart",
        "crash_cart_layer",
        "item",
        "inventory",
        "inspection",
    }

    @staticmethod
    def log(
        db: Session,
        *,
        module: str,
        business_id: int | None,
        operation_type: OperationType,
        old_data: dict | None,
        new_data: dict | None,
        operator_id: int | None,
        operator_name: str | None,
        ip_address: str | None = None,
    ) -> AuditLog:
        audit = AuditLog(
            module=module,
            business_id=business_id,
            operation_type=operation_type,
            old_data=old_data,
            new_data=new_data,
            operator_id=operator_id,
            operator_name=operator_name,
            operation_time=datetime.now(timezone.utc),
            ip_address=ip_address,
        )
        db.add(audit)
        return audit

    @staticmethod
    def log_model_change(
        db: Session,
        *,
        module: str,
        obj,
        operation_type: OperationType,
        operator_id: int | None,
        operator_name: str | None,
        old_obj=None,
        ip_address: str | None = None,
    ) -> AuditLog:
        old_data = model_to_dict(old_obj) if old_obj else None
        new_data = model_to_dict(obj) if operation_type != OperationType.DELETE else None
        if operation_type == OperationType.DELETE and old_obj:
            old_data = model_to_dict(old_obj)
        return AuditService.log(
            db,
            module=module,
            business_id=getattr(obj, "id", None) or getattr(old_obj, "id", None),
            operation_type=operation_type,
            old_data=old_data,
            new_data=new_data,
            operator_id=operator_id,
            operator_name=operator_name,
            ip_address=ip_address,
        )


class OperationReasonService:
    @staticmethod
    def record(
        db: Session,
        *,
        module: str,
        business_id: int,
        reason_type: OperationReasonType,
        reason: str,
        operator_id: int | None,
    ) -> OperationReason:
        record = OperationReason(
            module=module,
            business_id=business_id,
            reason_type=reason_type,
            reason=reason,
            operator_id=operator_id,
        )
        db.add(record)
        return record
