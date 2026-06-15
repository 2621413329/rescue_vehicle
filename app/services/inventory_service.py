from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.enums import OperationReasonType, OperationType, UserRole
from app.models.inventory import Inventory
from app.models.user import User
from app.repositories.crash_cart_repository import CrashCartLayerRepository, CrashCartRepository
from app.repositories.inventory_repository import InventoryRepository
from app.repositories.item_repository import ItemRepository
from app.repositories.notification_repository import OperationReasonRepository
from app.schemas.common import PageResult
from app.schemas.inventory import (
    InventoryCreate,
    InventoryDetailOut,
    InventoryOut,
    InventoryQuery,
    InventoryUpdate,
)
from app.schemas.item import OperationReasonOut
from app.services.audit_service import AuditService, OperationReasonService
from app.services.extended_service import NotificationGenerator
from app.utils.helpers import calculate_expiry_fields, calculate_label_status, calculate_low_stock


class InventoryService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = InventoryRepository(db)
        self.item_repo = ItemRepository(db)
        self.cart_repo = CrashCartRepository(db)
        self.layer_repo = CrashCartLayerRepository(db)
        self.reason_repo = OperationReasonRepository(db)

    def _check_cart_access(self, operator: User, cart_id: int) -> None:
        cart = self.cart_repo.get_by_id(cart_id)
        if not cart:
            raise HTTPException(status_code=404, detail="抢救车不存在")
        if operator.role != UserRole.SUPER_ADMIN and operator.department_id != cart.department_id:
            raise HTTPException(status_code=403, detail="无权操作其他科室库存")

    def _apply_calculations(self, inventory: Inventory) -> None:
        expiry_fields = calculate_expiry_fields(inventory.expiry_date, inventory.warning_days)
        inventory.remaining_days = expiry_fields["remaining_days"]
        inventory.expiry_status = expiry_fields["expiry_status"]
        inventory.label_color = expiry_fields["label_color"]
        inventory.is_near_expiry = expiry_fields["is_near_expiry"]
        inventory.is_expired = expiry_fields["is_expired"]
        inventory.is_low_stock = calculate_low_stock(inventory.quantity, inventory.minimum_quantity)

    def _to_detail(self, inventory: Inventory) -> InventoryDetailOut:
        item = self.item_repo.get_by_id(inventory.item_id)
        cart = self.cart_repo.get_by_id(inventory.cart_id)
        layer = self.layer_repo.get_by_id(inventory.layer_id) if inventory.layer_id else None
        ls = calculate_label_status(inventory.remaining_days)
        base = InventoryOut.model_validate(inventory).model_dump()
        return InventoryDetailOut(
            **base,
            item_name=item.item_name if item else None,
            item_code=item.item_code if item else None,
            cart_name=cart.cart_name if cart else None,
            cart_code=cart.cart_code if cart else None,
            layer_name=layer.layer_name if layer else None,
            label_status=ls["label_status"],
            label_status_text=ls["label_status_text"],
            manager_name=cart.manager_name if cart else None,
        )

    def create(
        self, data: InventoryCreate, operator: User, ip_address: str | None = None
    ) -> InventoryDetailOut:
        item = self.item_repo.get_by_id(data.item_id)
        if not item:
            raise HTTPException(status_code=400, detail="物资不存在")
        self._check_cart_access(operator, data.cart_id)
        if data.layer_id and not self.layer_repo.get_by_id(data.layer_id):
            raise HTTPException(status_code=400, detail="层级不存在")

        inventory = Inventory(
            item_id=data.item_id,
            cart_id=data.cart_id,
            layer_id=data.layer_id,
            batch_no=data.batch_no,
            quantity=data.quantity,
            minimum_quantity=data.minimum_quantity,
            production_date=data.production_date,
            expiry_date=data.expiry_date,
            warning_days=item.warning_days,
            warning_tag=item.default_warning_tag,
            remark=data.remark,
            created_by=operator.id,
            updated_by=operator.id,
        )
        self._apply_calculations(inventory)
        self.db.add(inventory)
        self.db.flush()
        AuditService.log_model_change(
            self.db,
            module="inventory",
            obj=inventory,
            operation_type=OperationType.CREATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(inventory)
        NotificationGenerator.on_inventory_status_change(self.db, inventory)
        self.db.commit()
        return self._to_detail(inventory)

    def update(
        self, inventory_id: int, data: InventoryUpdate, operator: User, ip_address: str | None = None
    ) -> InventoryDetailOut:
        inventory = self.repo.get_by_id(inventory_id)
        if not inventory:
            raise HTTPException(status_code=404, detail="库存不存在")
        self._check_cart_access(operator, inventory.cart_id)

        update_data = data.model_dump(exclude_unset=True)
        operation_reason = update_data.pop("operation_reason", None)
        if not operation_reason:
            raise HTTPException(status_code=400, detail="修改库存必须填写操作原因")

        old = Inventory(
            id=inventory.id,
            item_id=inventory.item_id,
            cart_id=inventory.cart_id,
            layer_id=inventory.layer_id,
            batch_no=inventory.batch_no,
            quantity=inventory.quantity,
            minimum_quantity=inventory.minimum_quantity,
            production_date=inventory.production_date,
            expiry_date=inventory.expiry_date,
            warning_days=inventory.warning_days,
            warning_tag=inventory.warning_tag,
            remaining_days=inventory.remaining_days,
            expiry_status=inventory.expiry_status,
            label_color=inventory.label_color,
            is_near_expiry=inventory.is_near_expiry,
            is_expired=inventory.is_expired,
            is_low_stock=inventory.is_low_stock,
            remark=inventory.remark,
        )
        for key, value in update_data.items():
            setattr(inventory, key, value)
        inventory.updated_by = operator.id
        inventory.last_check_time = datetime.now(timezone.utc)
        self._apply_calculations(inventory)

        AuditService.log_model_change(
            self.db,
            module="inventory",
            obj=inventory,
            operation_type=OperationType.UPDATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=old,
            ip_address=ip_address,
        )
        OperationReasonService.record(
            self.db,
            module="inventory",
            business_id=inventory.id,
            reason_type=OperationReasonType.INVENTORY_UPDATE,
            reason=operation_reason,
            operator_id=operator.id,
        )
        self.db.commit()
        self.db.refresh(inventory)
        NotificationGenerator.on_inventory_status_change(self.db, inventory)
        self.db.commit()
        return self._to_detail(inventory)

    def delete(
        self, inventory_id: int, operator: User, operation_reason: str, ip_address: str | None = None
    ) -> None:
        inventory = self.repo.get_by_id(inventory_id)
        if not inventory:
            raise HTTPException(status_code=404, detail="库存不存在")
        self._check_cart_access(operator, inventory.cart_id)
        if not operation_reason:
            raise HTTPException(status_code=400, detail="删除库存必须填写操作原因")

        AuditService.log_model_change(
            self.db,
            module="inventory",
            obj=inventory,
            operation_type=OperationType.DELETE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=inventory,
            ip_address=ip_address,
        )
        OperationReasonService.record(
            self.db,
            module="inventory",
            business_id=inventory.id,
            reason_type=OperationReasonType.INVENTORY_DELETE,
            reason=operation_reason,
            operator_id=operator.id,
        )
        self.repo.soft_delete(inventory)
        self.db.commit()

    def get(self, inventory_id: int) -> InventoryDetailOut:
        inventory = self.repo.get_by_id(inventory_id)
        if not inventory:
            raise HTTPException(status_code=404, detail="库存不存在")
        return self._to_detail(inventory)

    def list(self, query: InventoryQuery, operator: User) -> PageResult[InventoryDetailOut]:
        department_id = query.department_id
        if operator.role != UserRole.SUPER_ADMIN:
            department_id = operator.department_id
        items, total = self.repo.list_inventories(
            page=query.page,
            page_size=query.page_size,
            department_id=department_id,
            cart_id=query.cart_id,
            layer_id=query.layer_id,
            item_id=query.item_id,
            expiry_status=query.expiry_status.value if query.expiry_status else None,
            is_low_stock=query.is_low_stock,
            is_near_expiry=query.is_near_expiry,
            is_expired=query.is_expired,
            operator_id=query.operator_id,
            keyword=query.keyword,
        )
        return PageResult(
            items=[self._to_detail(i) for i in items],
            total=total,
            page=query.page,
            page_size=query.page_size,
        )

    def list_operation_reasons(self, inventory_id: int) -> list[OperationReasonOut]:
        records = self.reason_repo.list_by_business("inventory", inventory_id)
        return [OperationReasonOut.model_validate(r) for r in records]

    def recalculate_all_expiry(self) -> int:
        inventories = self.repo.get_all_active()
        count = 0
        for inventory in inventories:
            old_expired = inventory.is_expired
            old_near = inventory.is_near_expiry
            old_low = inventory.is_low_stock
            self._apply_calculations(inventory)
            if (
                inventory.is_expired != old_expired
                or inventory.is_near_expiry != old_near
                or inventory.is_low_stock != old_low
            ):
                NotificationGenerator.on_inventory_status_change(self.db, inventory)
            count += 1
        self.db.commit()
        return count
