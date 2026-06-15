from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.crash_cart import CrashCart, CrashCartLayer
from app.models.enums import OperationType, UserRole
from app.models.user import User
from app.repositories.crash_cart_repository import CrashCartLayerRepository, CrashCartRepository
from app.repositories.department_repository import DepartmentRepository
from app.schemas.common import PageResult
from app.schemas.crash_cart import (
    CrashCartCreate,
    CrashCartLayerCreate,
    CrashCartLayerOut,
    CrashCartLayerQuery,
    CrashCartLayerUpdate,
    CrashCartOut,
    CrashCartQuery,
    CrashCartUpdate,
)
from app.services.audit_service import AuditService


class CrashCartService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = CrashCartRepository(db)
        self.layer_repo = CrashCartLayerRepository(db)
        self.dept_repo = DepartmentRepository(db)

    def _check_department_access(self, operator: User, department_id: int) -> None:
        if operator.role == UserRole.SUPER_ADMIN:
            return
        if operator.department_id != department_id:
            raise HTTPException(status_code=403, detail="无权操作其他科室数据")

    def create_cart(
        self, data: CrashCartCreate, operator: User, ip_address: str | None = None
    ) -> CrashCartOut:
        self._check_department_access(operator, data.department_id)
        if not self.dept_repo.get_by_id(data.department_id):
            raise HTTPException(status_code=400, detail="科室不存在")
        if self.repo.get_by_code(data.cart_code):
            raise HTTPException(status_code=400, detail="抢救车编码已存在")
        cart = CrashCart(**data.model_dump(), created_by=operator.id, updated_by=operator.id)
        self.db.add(cart)
        self.db.flush()
        AuditService.log_model_change(
            self.db,
            module="crash_cart",
            obj=cart,
            operation_type=OperationType.CREATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(cart)
        return CrashCartOut.model_validate(cart)

    def update_cart(
        self, cart_id: int, data: CrashCartUpdate, operator: User, ip_address: str | None = None
    ) -> CrashCartOut:
        cart = self.repo.get_by_id(cart_id)
        if not cart:
            raise HTTPException(status_code=404, detail="抢救车不存在")
        self._check_department_access(operator, cart.department_id)
        old = CrashCart(
            id=cart.id,
            department_id=cart.department_id,
            cart_code=cart.cart_code,
            cart_name=cart.cart_name,
            location=cart.location,
            manager_name=cart.manager_name,
            description=cart.description,
            status=cart.status,
        )
        update_data = data.model_dump(exclude_unset=True)
        if "department_id" in update_data:
            self._check_department_access(operator, update_data["department_id"])
        for key, value in update_data.items():
            setattr(cart, key, value)
        cart.updated_by = operator.id
        AuditService.log_model_change(
            self.db,
            module="crash_cart",
            obj=cart,
            operation_type=OperationType.UPDATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=old,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(cart)
        return CrashCartOut.model_validate(cart)

    def delete_cart(self, cart_id: int, operator: User, ip_address: str | None = None) -> None:
        cart = self.repo.get_by_id(cart_id)
        if not cart:
            raise HTTPException(status_code=404, detail="抢救车不存在")
        self._check_department_access(operator, cart.department_id)
        AuditService.log_model_change(
            self.db,
            module="crash_cart",
            obj=cart,
            operation_type=OperationType.DELETE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=cart,
            ip_address=ip_address,
        )
        self.repo.soft_delete(cart)
        self.db.commit()

    def get_cart(self, cart_id: int) -> CrashCartOut:
        cart = self.repo.get_by_id(cart_id)
        if not cart:
            raise HTTPException(status_code=404, detail="抢救车不存在")
        return CrashCartOut.model_validate(cart)

    def list_carts(self, query: CrashCartQuery, operator: User) -> PageResult[CrashCartOut]:
        department_id = query.department_id
        if operator.role != UserRole.SUPER_ADMIN:
            department_id = operator.department_id
        items, total = self.repo.list_carts(
            page=query.page,
            page_size=query.page_size,
            department_id=department_id,
            keyword=query.keyword,
            status=query.status.value if query.status else None,
        )
        return PageResult(
            items=[CrashCartOut.model_validate(i) for i in items],
            total=total,
            page=query.page,
            page_size=query.page_size,
        )

    def create_layer(
        self, data: CrashCartLayerCreate, operator: User, ip_address: str | None = None
    ) -> CrashCartLayerOut:
        cart = self.repo.get_by_id(data.cart_id)
        if not cart:
            raise HTTPException(status_code=404, detail="抢救车不存在")
        self._check_department_access(operator, cart.department_id)
        layer = CrashCartLayer(**data.model_dump())
        self.db.add(layer)
        self.db.flush()
        AuditService.log_model_change(
            self.db,
            module="crash_cart_layer",
            obj=layer,
            operation_type=OperationType.CREATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(layer)
        return CrashCartLayerOut.model_validate(layer)

    def update_layer(
        self, layer_id: int, data: CrashCartLayerUpdate, operator: User, ip_address: str | None = None
    ) -> CrashCartLayerOut:
        layer = self.layer_repo.get_by_id(layer_id)
        if not layer:
            raise HTTPException(status_code=404, detail="层级不存在")
        cart = self.repo.get_by_id(layer.cart_id)
        if cart:
            self._check_department_access(operator, cart.department_id)
        old = CrashCartLayer(
            id=layer.id,
            cart_id=layer.cart_id,
            layer_no=layer.layer_no,
            layer_name=layer.layer_name,
            description=layer.description,
            sort_order=layer.sort_order,
        )
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(layer, key, value)
        AuditService.log_model_change(
            self.db,
            module="crash_cart_layer",
            obj=layer,
            operation_type=OperationType.UPDATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=old,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(layer)
        return CrashCartLayerOut.model_validate(layer)

    def delete_layer(self, layer_id: int, operator: User, ip_address: str | None = None) -> None:
        layer = self.layer_repo.get_by_id(layer_id)
        if not layer:
            raise HTTPException(status_code=404, detail="层级不存在")
        cart = self.repo.get_by_id(layer.cart_id)
        if cart:
            self._check_department_access(operator, cart.department_id)
        AuditService.log_model_change(
            self.db,
            module="crash_cart_layer",
            obj=layer,
            operation_type=OperationType.DELETE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=layer,
            ip_address=ip_address,
        )
        self.layer_repo.soft_delete(layer)
        self.db.commit()

    def list_layers(self, query: CrashCartLayerQuery) -> PageResult[CrashCartLayerOut]:
        items, total = self.layer_repo.list_layers(
            page=query.page, page_size=query.page_size, cart_id=query.cart_id
        )
        return PageResult(
            items=[CrashCartLayerOut.model_validate(i) for i in items],
            total=total,
            page=query.page,
            page_size=query.page_size,
        )
