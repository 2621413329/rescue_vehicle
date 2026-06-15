from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.permissions import Permission, require_permission
from app.models.user import User
from app.schemas.common import MessageResponse, PageResult
from app.schemas.notification import CartRiskOut
from app.services.extended_service import RiskService
from app.services.label_service import LabelService

router = APIRouter(prefix="/labels", tags=["标签管理"])


class PrintLabelsRequest(BaseModel):
    inventory_ids: list[int]


@router.get("", response_model=PageResult[dict])
def list_pending_labels(
    page: int = 1,
    page_size: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INVENTORY_READ)),
):
    return LabelService(db).list_pending(current_user, page, page_size)


@router.post("/print", response_model=MessageResponse)
def print_labels(
    body: PrintLabelsRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INVENTORY_MANAGE)),
):
    count = LabelService(db).print_labels(body.inventory_ids, current_user)
    return MessageResponse(message=f"已记录 {count} 条标签打印")


@router.get("/history/{inventory_id}")
def label_history(
    inventory_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INVENTORY_READ)),
):
    return LabelService(db).list_history(inventory_id)


@router.get("/cart-risks", response_model=list[CartRiskOut])
def cart_risk_ranking(
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.DASHBOARD_READ)),
):
    from app.models.enums import UserRole

    department_id = None if current_user.role == UserRole.SUPER_ADMIN else current_user.department_id
    return RiskService.rank_carts(db, department_id, limit=limit)
