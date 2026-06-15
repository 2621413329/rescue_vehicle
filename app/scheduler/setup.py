import logging

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger

from app.core.config import get_settings
from app.tasks.inventory_expiry_task import run_inventory_expiry_scheduler

logger = logging.getLogger(__name__)
settings = get_settings()
scheduler = BackgroundScheduler(timezone="Asia/Shanghai")


def start_scheduler() -> None:
    scheduler.add_job(
        run_inventory_expiry_scheduler,
        trigger=CronTrigger(
            hour=settings.inventory_expiry_cron_hour,
            minute=settings.inventory_expiry_cron_minute,
        ),
        id="inventory_expiry_scheduler",
        replace_existing=True,
        name="inventory_expiry_scheduler",
    )
    if not scheduler.running:
        scheduler.start()
        logger.info("APScheduler started: inventory_expiry_scheduler at %02d:%02d",
                    settings.inventory_expiry_cron_hour,
                    settings.inventory_expiry_cron_minute)


def shutdown_scheduler() -> None:
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("APScheduler shutdown")
