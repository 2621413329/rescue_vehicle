from datetime import datetime

from sqlalchemy import func, select

from app.models.crash_cart import CrashCart
from app.models.inspection import InspectionRecord
from app.repositories.base import BaseRepository


class InspectionRepository(BaseRepository[InspectionRecord]):
    model = InspectionRecord

    def list_inspections(
        self,
        *,
        page: int,
        page_size: int,
        cart_id: int | None = None,
        inspector_id: int | None = None,
        department_id: int | None = None,
        start_time: datetime | None = None,
        end_time: datetime | None = None,
    ) -> tuple[list[InspectionRecord], int]:
        stmt = select(InspectionRecord).order_by(InspectionRecord.inspection_time.desc())
        if cart_id:
            stmt = stmt.where(InspectionRecord.cart_id == cart_id)
        if inspector_id:
            stmt = stmt.where(InspectionRecord.inspector_id == inspector_id)
        if start_time:
            stmt = stmt.where(InspectionRecord.inspection_time >= start_time)
        if end_time:
            stmt = stmt.where(InspectionRecord.inspection_time <= end_time)
        if department_id:
            stmt = stmt.join(CrashCart, InspectionRecord.cart_id == CrashCart.id).where(
                CrashCart.department_id == department_id
            )
        return self.paginate(stmt, page, page_size)

    def count_today(self, department_id: int | None = None) -> int:
        today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        stmt = (
            select(func.count())
            .select_from(InspectionRecord)
            .where(InspectionRecord.inspection_time >= today_start)
        )
        if department_id:
            stmt = stmt.join(CrashCart, InspectionRecord.cart_id == CrashCart.id).where(
                CrashCart.department_id == department_id
            )
        return self.db.scalar(stmt) or 0
