from fastapi import APIRouter, Depends, Query, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.deps import get_client_ip
from app.core.database import get_db
from app.core.permissions import Permission, require_permission
from app.models.user import User
from app.schemas.common import MessageResponse, PageResult
from app.schemas.inventory import (
    InventoryCreate,
    InventoryDetailOut,
    InventoryQuery,
    InventoryUpdate,
    TaskActionRequest,
)
from app.schemas.item import OperationReasonOut
from app.services.inventory_service import InventoryService
from app.services.label_service import TimelineService

router = APIRouter(prefix="/inventories", tags=["库存管理"])


@router.post("", response_model=InventoryDetailOut)
def create_inventory(
    data: InventoryCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INVENTORY_MANAGE)),
):
    return InventoryService(db).create(data, current_user, get_client_ip(request))


@router.get("", response_model=PageResult[InventoryDetailOut])
def list_inventories(
    query: InventoryQuery = Depends(),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INVENTORY_READ)),
):
    return InventoryService(db).list(query, current_user)


@router.get("/{inventory_id}", response_model=InventoryDetailOut)
def get_inventory(
    inventory_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.INVENTORY_READ)),
):
    return InventoryService(db).get(inventory_id)


@router.put("/{inventory_id}", response_model=InventoryDetailOut)
def update_inventory(
    inventory_id: int,
    data: InventoryUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INVENTORY_MANAGE)),
):
    return InventoryService(db).update(inventory_id, data, current_user, get_client_ip(request))


@router.delete("/{inventory_id}", response_model=MessageResponse)
def delete_inventory(
    inventory_id: int,
    request: Request,
    operation_reason: str = Query(..., description="删除原因，如：药品报废"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INVENTORY_MANAGE)),
):
    InventoryService(db).delete(
        inventory_id, current_user, operation_reason, get_client_ip(request)
    )
    return MessageResponse(message="删除成功")


@router.get("/{inventory_id}/operation-reasons", response_model=list[OperationReasonOut])
def list_inventory_operation_reasons(
    inventory_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.AUDIT_READ)),
):
    return InventoryService(db).list_operation_reasons(inventory_id)


@router.get("/{inventory_id}/timeline")
def inventory_timeline(
    inventory_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.INVENTORY_READ)),
):
    return TimelineService(db).inventory_timeline(inventory_id)


@router.post("/{inventory_id}/task-actions", response_model=InventoryDetailOut)
def mark_inventory_task_action(
    inventory_id: int,
    body: TaskActionRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INVENTORY_MANAGE)),
):
    return InventoryService(db).mark_task_action(
        inventory_id,
        body.action,
        current_user,
        body.remark,
        get_client_ip(request),
        expiry_date=body.expiry_date,
        batch_no=body.batch_no,
        quantity=body.quantity,
    )
