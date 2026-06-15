from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.department import Department
from app.models.enums import OperationType
from app.models.user import User
from app.repositories.department_repository import DepartmentRepository
from app.schemas.common import PageResult
from app.schemas.department import DepartmentCreate, DepartmentOut, DepartmentQuery, DepartmentUpdate
from app.services.audit_service import AuditService


class DepartmentService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = DepartmentRepository(db)

    def create(
        self, data: DepartmentCreate, operator: User, ip_address: str | None = None
    ) -> DepartmentOut:
        if self.repo.get_by_name(data.name):
            raise HTTPException(status_code=400, detail="科室名称已存在")
        dept = Department(name=data.name, description=data.description)
        self.db.add(dept)
        self.db.flush()
        AuditService.log_model_change(
            self.db,
            module="department",
            obj=dept,
            operation_type=OperationType.CREATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(dept)
        return DepartmentOut.model_validate(dept)

    def update(
        self, dept_id: int, data: DepartmentUpdate, operator: User, ip_address: str | None = None
    ) -> DepartmentOut:
        dept = self.repo.get_by_id(dept_id)
        if not dept:
            raise HTTPException(status_code=404, detail="科室不存在")
        old = Department(id=dept.id, name=dept.name, description=dept.description)
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(dept, key, value)
        AuditService.log_model_change(
            self.db,
            module="department",
            obj=dept,
            operation_type=OperationType.UPDATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=old,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(dept)
        return DepartmentOut.model_validate(dept)

    def delete(self, dept_id: int, operator: User, ip_address: str | None = None) -> None:
        dept = self.repo.get_by_id(dept_id)
        if not dept:
            raise HTTPException(status_code=404, detail="科室不存在")
        AuditService.log_model_change(
            self.db,
            module="department",
            obj=dept,
            operation_type=OperationType.DELETE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=dept,
            ip_address=ip_address,
        )
        self.repo.soft_delete(dept)
        self.db.commit()

    def get(self, dept_id: int) -> DepartmentOut:
        dept = self.repo.get_by_id(dept_id)
        if not dept:
            raise HTTPException(status_code=404, detail="科室不存在")
        return DepartmentOut.model_validate(dept)

    def list(self, query: DepartmentQuery) -> PageResult[DepartmentOut]:
        items, total = self.repo.list_departments(
            page=query.page, page_size=query.page_size, keyword=query.keyword
        )
        return PageResult(
            items=[DepartmentOut.model_validate(i) for i in items],
            total=total,
            page=query.page,
            page_size=query.page_size,
        )
