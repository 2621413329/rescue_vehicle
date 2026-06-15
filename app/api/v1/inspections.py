from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.api.deps import get_client_ip
from app.core.database import get_db
from app.core.permissions import Permission, require_permission
from app.models.user import User
from app.schemas.common import PageResult
from app.schemas.inspection import InspectionCreate, InspectionOut, InspectionQuery
from app.services.inspection_service import InspectionService

router = APIRouter(prefix="/inspections", tags=["巡检管理"])


@router.post("", response_model=InspectionOut)
def create_inspection(
    data: InspectionCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INSPECTION_MANAGE)),
):
    return InspectionService(db).create(data, current_user, get_client_ip(request))


@router.get("", response_model=PageResult[InspectionOut])
def list_inspections(
    query: InspectionQuery = Depends(),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INSPECTION_MANAGE)),
):
    return InspectionService(db).list(query, current_user)


@router.get("/{record_id}", response_model=InspectionOut)
def get_inspection(
    record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.INSPECTION_MANAGE)),
):
    return InspectionService(db).get(record_id)
