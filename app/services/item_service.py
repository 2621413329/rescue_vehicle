from __future__ import annotations

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

    def create(
        self, data: ItemCreate, operator: User, ip_address: str | None = None
    ) -> ItemOut:
        if self.repo.get_by_code(data.item_code):
            raise HTTPException(status_code=400, detail="物资编码已存在")
        item = Item(**data.model_dump(), created_by=operator.id, updated_by=operator.id)
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
        return ItemOut.model_validate(item)

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
        return ItemOut.model_validate(item)

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
        return ItemOut.model_validate(item)

    def list(self, query: ItemQuery) -> PageResult[ItemOut]:
        items, total = self.repo.list_items(
            page=query.page,
            page_size=query.page_size,
            item_type=query.item_type.value if query.item_type else None,
            keyword=query.keyword,
            is_enabled=query.is_enabled,
        )
        return PageResult(
            items=[ItemOut.model_validate(i) for i in items],
            total=total,
            page=query.page,
            page_size=query.page_size,
        )

    def list_operation_reasons(self, item_id: int) -> list[OperationReasonOut]:
        records = self.reason_repo.list_by_business("item", item_id)
        return [OperationReasonOut.model_validate(r) for r in records]
