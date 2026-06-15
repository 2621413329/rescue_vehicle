from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.enums import OperationType, UserRole
from app.models.inspection import InspectionRecord
from app.models.user import User
from app.repositories.crash_cart_repository import CrashCartRepository
from app.repositories.inspection_repository import InspectionRepository
from app.schemas.common import PageResult
from app.schemas.inspection import InspectionCreate, InspectionOut, InspectionQuery
from app.services.audit_service import AuditService


class InspectionService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = InspectionRepository(db)
        self.cart_repo = CrashCartRepository(db)

    def create(
        self, data: InspectionCreate, operator: User, ip_address: str | None = None
    ) -> InspectionOut:
        cart = self.cart_repo.get_by_id(data.cart_id)
        if not cart:
            raise HTTPException(status_code=404, detail="抢救车不存在")
        if operator.role != UserRole.SUPER_ADMIN and operator.department_id != cart.department_id:
            raise HTTPException(status_code=403, detail="无权操作其他科室巡检")

        record = InspectionRecord(
            cart_id=data.cart_id,
            inspector_id=operator.id,
            inspection_time=data.inspection_time,
            result=data.result,
            remark=data.remark,
        )
        self.db.add(record)
        self.db.flush()
        cart.last_inspection_time = data.inspection_time
        AuditService.log_model_change(
            self.db,
            module="inspection",
            obj=record,
            operation_type=OperationType.CREATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(record)
        return InspectionOut.model_validate(record)

    def get(self, record_id: int) -> InspectionOut:
        record = self.repo.get_by_id(record_id)
        if not record:
            raise HTTPException(status_code=404, detail="巡检记录不存在")
        return InspectionOut.model_validate(record)

    def list(self, query: InspectionQuery, operator: User) -> PageResult[InspectionOut]:
        department_id = query.department_id
        if operator.role != UserRole.SUPER_ADMIN:
            department_id = operator.department_id
        items, total = self.repo.list_inspections(
            page=query.page,
            page_size=query.page_size,
            cart_id=query.cart_id,
            inspector_id=query.inspector_id,
            department_id=department_id,
            start_time=query.start_time,
            end_time=query.end_time,
        )
        return PageResult(
            items=[InspectionOut.model_validate(i) for i in items],
            total=total,
            page=query.page,
            page_size=query.page_size,
        )
