from fastapi import APIRouter

from app.api.v1 import (
    auth,
    crash_carts,
    dashboard,
    departments,
    health,
    inspections,
    inventories,
    items,
    labels,
    users,
)

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(departments.router)
api_router.include_router(crash_carts.router)
api_router.include_router(items.router)
api_router.include_router(inventories.router)
api_router.include_router(labels.router)
api_router.include_router(inspections.router)
api_router.include_router(dashboard.router)
