from __future__ import annotations

import time

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.enums import OperationReasonType, OperationType
from app.models.item import Item
from app.models.user import User
from app.repositories.item_repository import ItemRepository
from app.schemas.common import PageResult
from app.schemas.item import ItemCreate, ItemOut, ItemQuery, ItemUpdate, OperationReasonOut
from app.services.audit_service import AuditService, OperationReasonService
from app.repositories.notification_repository import OperationReasonRepository


class ItemService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = ItemRepository(db)
        self.reason_repo = OperationReasonRepository(db)

    def _to_out(self, item: Item) -> ItemOut:
        operator_name = None
        if item.updated_by:
            operator = self.db.get(User, item.updated_by)
            operator_name = operator.real_name if operator else None
        return ItemOut(
            id=item.id,
            item_code=item.item_code,
            item_name=item.item_name,
            item_type=item.item_type,
            specification=item.specification,
            manufacturer=item.manufacturer,
            description=item.description,
            usage_instruction=item.usage_instruction,
            storage_requirement=item.storage_requirement,
            warning_days=item.warning_days,
            default_warning_tag=item.default_warning_tag,
            is_enabled=item.is_enabled,
            created_at=item.created_at,
            updated_at=item.updated_at,
            operator_name=operator_name,
            in_use=self.repo.has_inventory(item.id),
        )

    def _generate_item_code(self) -> str:
        return f"IT{int(time.time() * 1000)}"

    def create(
        self, data: ItemCreate, operator: User, ip_address: str | None = None
    ) -> ItemOut:
        item_code = (data.item_code or "").strip() or self._generate_item_code()
        if self.repo.get_by_code(item_code):
            raise HTTPException(status_code=400, detail="物资编码已存在")
        payload = data.model_dump()
        payload["item_code"] = item_code
        item = Item(**payload, created_by=operator.id, updated_by=operator.id)
        self.db.add(item)
        self.db.flush()
        AuditService.log_model_change(
            self.db,
            module="item",
            obj=item,
            operation_type=OperationType.CREATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            ip_address=ip_address,
        )
        self.db.commit()
        self.db.refresh(item)
        return self._to_out(item)

    def update(
        self, item_id: int, data: ItemUpdate, operator: User, ip_address: str | None = None
    ) -> ItemOut:
        item = self.repo.get_by_id(item_id)
        if not item:
            raise HTTPException(status_code=404, detail="物资不存在")
        update_data = data.model_dump(exclude_unset=True)
        operation_reason = update_data.pop("operation_reason", None)
        warning_changed = "warning_days" in update_data and update_data["warning_days"] != item.warning_days

        if warning_changed and not operation_reason:
            raise HTTPException(status_code=400, detail="修改预警天数必须填写操作原因")

        if update_data.get("is_enabled") is False and item.is_enabled and self.repo.has_inventory(item.id):
            raise HTTPException(status_code=400, detail="该药品已被库存使用，不可停用")

        old = Item(
            id=item.id,
            item_code=item.item_code,
            item_name=item.item_name,
            item_type=item.item_type,
            specification=item.specification,
            manufacturer=item.manufacturer,
            description=item.description,
            usage_instruction=item.usage_instruction,
            storage_requirement=item.storage_requirement,
            warning_days=item.warning_days,
            default_warning_tag=item.default_warning_tag,
            is_enabled=item.is_enabled,
        )
        for key, value in update_data.items():
            setattr(item, key, value)
        item.updated_by = operator.id

        AuditService.log_model_change(
            self.db,
            module="item",
            obj=item,
            operation_type=OperationType.UPDATE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=old,
            ip_address=ip_address,
        )
        if warning_changed and operation_reason:
            OperationReasonService.record(
                self.db,
                module="item",
                business_id=item.id,
                reason_type=OperationReasonType.ITEM_WARNING_UPDATE,
                reason=operation_reason,
                operator_id=operator.id,
            )
        self.db.commit()
        self.db.refresh(item)
        return self._to_out(item)

    def disable(
        self, item_id: int, operator: User, ip_address: str | None = None
    ) -> ItemOut:
        return self.update(item_id, ItemUpdate(is_enabled=False), operator, ip_address)

    def delete(
        self, item_id: int, operator: User, operation_reason: str, ip_address: str | None = None
    ) -> None:
        item = self.repo.get_by_id(item_id)
        if not item:
            raise HTTPException(status_code=404, detail="物资不存在")
        if not operation_reason:
            raise HTTPException(status_code=400, detail="删除物资必须填写操作原因")
        AuditService.log_model_change(
            self.db,
            module="item",
            obj=item,
            operation_type=OperationType.DELETE,
            operator_id=operator.id,
            operator_name=operator.real_name,
            old_obj=item,
            ip_address=ip_address,
        )
        OperationReasonService.record(
            self.db,
            module="item",
            business_id=item.id,
            reason_type=OperationReasonType.ITEM_DELETE,
            reason=operation_reason,
            operator_id=operator.id,
        )
        self.repo.soft_delete(item)
        self.db.commit()

    def get(self, item_id: int) -> ItemOut:
        item = self.repo.get_by_id(item_id)
        if not item:
            raise HTTPException(status_code=404, detail="物资不存在")
        return self._to_out(item)

    def list(self, query: ItemQuery) -> PageResult[ItemOut]:
        items, total = self.repo.list_items(
            page=query.page,
            page_size=query.page_size,
            item_type=query.item_type.value if query.item_type else None,
            keyword=query.keyword,
            is_enabled=query.is_enabled,
        )
        return PageResult(
            items=[self._to_out(i) for i in items],
            total=total,
            page=query.page,
            page_size=query.page_size,
        )

    def list_operation_reasons(self, item_id: int) -> list[OperationReasonOut]:
        records = self.reason_repo.list_by_business("item", item_id)
        return [OperationReasonOut.model_validate(r) for r in records]
