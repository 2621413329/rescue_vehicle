from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.orm import Session

from app.api.deps import get_client_ip
from app.core.database import get_db
from app.core.permissions import Permission, require_permission
from app.models.user import User
from app.schemas.common import MessageResponse, PageResult
from app.schemas.item import ItemCreate, ItemOut, ItemQuery, ItemUpdate, OperationReasonOut
from app.services.item_service import ItemService

router = APIRouter(prefix="/items", tags=["药品与物资"])


@router.post("", response_model=ItemOut)
def create_item(
    data: ItemCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ITEM_MANAGE)),
):
    return ItemService(db).create(data, current_user, get_client_ip(request))


@router.get("", response_model=PageResult[ItemOut])
def list_items(
    query: ItemQuery = Depends(),
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.INVENTORY_READ)),
):
    return ItemService(db).list(query)


@router.get("/{item_id}", response_model=ItemOut)
def get_item(
    item_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.INVENTORY_READ)),
):
    return ItemService(db).get(item_id)


@router.put("/{item_id}", response_model=ItemOut)
def update_item(
    item_id: int,
    data: ItemUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ITEM_MANAGE)),
):
    return ItemService(db).update(item_id, data, current_user, get_client_ip(request))


@router.delete("/{item_id}", response_model=MessageResponse)
def delete_item(
    item_id: int,
    request: Request,
    operation_reason: str = Query(..., description="删除原因"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ITEM_MANAGE)),
):
    ItemService(db).delete(item_id, current_user, operation_reason, get_client_ip(request))
    return MessageResponse(message="删除成功")


@router.get("/{item_id}/operation-reasons", response_model=list[OperationReasonOut])
def list_item_operation_reasons(
    item_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.AUDIT_READ)),
):
    return ItemService(db).list_operation_reasons(item_id)
