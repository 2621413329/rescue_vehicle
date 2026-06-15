from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.api.deps import get_client_ip, get_current_user
from app.core.database import get_db
from app.core.permissions import Permission, require_permission
from app.models.user import User
from app.schemas.common import MessageResponse, PageResult
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
from app.services.crash_cart_service import CrashCartService

router = APIRouter(prefix="/crash-carts", tags=["抢救车管理"])


@router.post("", response_model=CrashCartOut)
def create_cart(
    data: CrashCartCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.CART_MANAGE)),
):
    return CrashCartService(db).create_cart(data, current_user, get_client_ip(request))


@router.get("", response_model=PageResult[CrashCartOut])
def list_carts(
    query: CrashCartQuery = Depends(),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INVENTORY_READ)),
):
    return CrashCartService(db).list_carts(query, current_user)


@router.get("/{cart_id}", response_model=CrashCartOut)
def get_cart(
    cart_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.CART_MANAGE)),
):
    return CrashCartService(db).get_cart(cart_id)


@router.put("/{cart_id}", response_model=CrashCartOut)
def update_cart(
    cart_id: int,
    data: CrashCartUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.CART_MANAGE)),
):
    return CrashCartService(db).update_cart(cart_id, data, current_user, get_client_ip(request))


@router.delete("/{cart_id}", response_model=MessageResponse)
def delete_cart(
    cart_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.CART_MANAGE)),
):
    CrashCartService(db).delete_cart(cart_id, current_user, get_client_ip(request))
    return MessageResponse(message="删除成功")


@router.post("/layers", response_model=CrashCartLayerOut)
def create_layer(
    data: CrashCartLayerCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.CART_MANAGE)),
):
    return CrashCartService(db).create_layer(data, current_user, get_client_ip(request))


@router.get("/layers/list", response_model=PageResult[CrashCartLayerOut])
def list_layers(
    query: CrashCartLayerQuery = Depends(),
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    return CrashCartService(db).list_layers(query)


@router.put("/layers/{layer_id}", response_model=CrashCartLayerOut)
def update_layer(
    layer_id: int,
    data: CrashCartLayerUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.CART_MANAGE)),
):
    return CrashCartService(db).update_layer(layer_id, data, current_user, get_client_ip(request))


@router.delete("/layers/{layer_id}", response_model=MessageResponse)
def delete_layer(
    layer_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.CART_MANAGE)),
):
    CrashCartService(db).delete_layer(layer_id, current_user, get_client_ip(request))
    return MessageResponse(message="删除成功")
