import logging

from app.core.database import SessionLocal
from app.services.inventory_service import InventoryService

logger = logging.getLogger(__name__)


def run_inventory_expiry_scheduler() -> None:
    """每天凌晨1点重新计算所有库存效期状态。"""
    db = SessionLocal()
    try:
        count = InventoryService(db).recalculate_all_expiry()
        logger.info("inventory_expiry_scheduler completed, updated %s records", count)
    except Exception:
        logger.exception("inventory_expiry_scheduler failed")
        db.rollback()
    finally:
        db.close()
