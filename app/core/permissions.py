from enum import Enum

from fastapi import Depends, HTTPException, status

from app.api.deps import get_current_user
from app.models.enums import UserRole
from app.models.user import User


class Permission(str, Enum):
    USER_MANAGE = "user:manage"
    DEPARTMENT_MANAGE = "department:manage"
    CART_MANAGE = "cart:manage"
    ITEM_MANAGE = "item:manage"
    INVENTORY_MANAGE = "inventory:manage"
    INVENTORY_READ = "inventory:read"
    INSPECTION_MANAGE = "inspection:manage"
    AUDIT_READ = "audit:read"
    DASHBOARD_READ = "dashboard:read"
    NOTIFICATION_READ = "notification:read"


ROLE_PERMISSIONS: dict[UserRole, set[Permission]] = {
    UserRole.SUPER_ADMIN: set(Permission),
    UserRole.DEPARTMENT_ADMIN: {
        Permission.DEPARTMENT_MANAGE,
        Permission.CART_MANAGE,
        Permission.ITEM_MANAGE,
        Permission.INVENTORY_MANAGE,
        Permission.INVENTORY_READ,
        Permission.INSPECTION_MANAGE,
        Permission.AUDIT_READ,
        Permission.DASHBOARD_READ,
        Permission.NOTIFICATION_READ,
    },
    UserRole.NURSE: {
        Permission.INVENTORY_MANAGE,
        Permission.INVENTORY_READ,
        Permission.INSPECTION_MANAGE,
        Permission.DASHBOARD_READ,
        Permission.NOTIFICATION_READ,
    },
    UserRole.VIEWER: {
        Permission.INVENTORY_READ,
        Permission.DASHBOARD_READ,
        Permission.NOTIFICATION_READ,
    },
}


def has_permission(user: User, permission: Permission) -> bool:
    return permission in ROLE_PERMISSIONS.get(user.role, set())


def require_permission(permission: Permission):
    def checker(current_user: User = Depends(get_current_user)) -> User:
        if not has_permission(current_user, permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="权限不足",
            )
        return current_user

    return checker


def require_roles(*roles: UserRole):
    def checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="角色权限不足",
            )
        return current_user

    return checker
