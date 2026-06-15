from sqlalchemy import select

from app.models.crash_cart import CrashCart, CrashCartLayer
from app.repositories.base import BaseRepository


class CrashCartRepository(BaseRepository[CrashCart]):
    model = CrashCart

    def get_by_code(self, cart_code: str) -> CrashCart | None:
        return self.db.scalar(
            select(CrashCart).where(
                CrashCart.cart_code == cart_code, CrashCart.is_deleted.is_(False)
            )
        )

    def list_carts(
        self,
        *,
        page: int,
        page_size: int,
        department_id: int | None = None,
        keyword: str | None = None,
        status: str | None = None,
    ) -> tuple[list[CrashCart], int]:
        stmt = select(CrashCart).where(CrashCart.is_deleted.is_(False)).order_by(CrashCart.id.desc())
        if department_id:
            stmt = stmt.where(CrashCart.department_id == department_id)
        if status:
            stmt = stmt.where(CrashCart.status == status)
        if keyword:
            stmt = stmt.where(
                CrashCart.cart_code.ilike(f"%{keyword}%")
                | CrashCart.cart_name.ilike(f"%{keyword}%")
            )
        return self.paginate(stmt, page, page_size)

    def count_active(self, department_id: int | None = None) -> int:
        stmt = select(CrashCart).where(CrashCart.is_deleted.is_(False))
        if department_id:
            stmt = stmt.where(CrashCart.department_id == department_id)
        return len(list(self.db.scalars(stmt).all()))


class CrashCartLayerRepository(BaseRepository[CrashCartLayer]):
    model = CrashCartLayer

    def list_layers(
        self, *, page: int, page_size: int, cart_id: int | None = None
    ) -> tuple[list[CrashCartLayer], int]:
        stmt = (
            select(CrashCartLayer)
            .where(CrashCartLayer.is_deleted.is_(False))
            .order_by(CrashCartLayer.sort_order, CrashCartLayer.layer_no)
        )
        if cart_id:
            stmt = stmt.where(CrashCartLayer.cart_id == cart_id)
        return self.paginate(stmt, page, page_size)
