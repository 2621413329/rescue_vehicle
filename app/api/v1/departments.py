from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.api.deps import get_client_ip
from app.core.database import get_db
from app.core.permissions import Permission, require_permission
from app.models.user import User
from app.schemas.common import MessageResponse, PageResult
from app.schemas.department import DepartmentCreate, DepartmentOut, DepartmentQuery, DepartmentUpdate
from app.services.department_service import DepartmentService

router = APIRouter(prefix="/departments", tags=["科室管理"])


@router.post("", response_model=DepartmentOut)
def create_department(
    data: DepartmentCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.DEPARTMENT_MANAGE)),
):
    return DepartmentService(db).create(data, current_user, get_client_ip(request))


@router.get("", response_model=PageResult[DepartmentOut])
def list_departments(
    query: DepartmentQuery = Depends(),
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.DEPARTMENT_MANAGE)),
):
    return DepartmentService(db).list(query)


@router.get("/{dept_id}", response_model=DepartmentOut)
def get_department(
    dept_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_permission(Permission.DEPARTMENT_MANAGE)),
):
    return DepartmentService(db).get(dept_id)


@router.put("/{dept_id}", response_model=DepartmentOut)
def update_department(
    dept_id: int,
    data: DepartmentUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.DEPARTMENT_MANAGE)),
):
    return DepartmentService(db).update(dept_id, data, current_user, get_client_ip(request))


@router.delete("/{dept_id}", response_model=MessageResponse)
def delete_department(
    dept_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.DEPARTMENT_MANAGE)),
):
    DepartmentService(db).delete(dept_id, current_user, get_client_ip(request))
    return MessageResponse(message="删除成功")
