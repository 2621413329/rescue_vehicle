from sqlalchemy import func, select

from app.models.crash_cart import CrashCart
from app.models.inventory import Inventory
from app.models.item import Item
from app.repositories.base import BaseRepository


class InventoryRepository(BaseRepository[Inventory]):
    model = Inventory

    def list_inventories(
        self,
        *,
        page: int,
        page_size: int,
        department_id: int | None = None,
        cart_id: int | None = None,
        layer_id: int | None = None,
        item_id: int | None = None,
        expiry_status: str | None = None,
        is_low_stock: bool | None = None,
        is_near_expiry: bool | None = None,
        is_expired: bool | None = None,
        operator_id: int | None = None,
        keyword: str | None = None,
    ) -> tuple[list[Inventory], int]:
        stmt = select(Inventory).where(Inventory.is_deleted.is_(False)).order_by(Inventory.id.desc())
        if cart_id:
            stmt = stmt.where(Inventory.cart_id == cart_id)
        if layer_id:
            stmt = stmt.where(Inventory.layer_id == layer_id)
        if item_id:
            stmt = stmt.where(Inventory.item_id == item_id)
        if expiry_status:
            stmt = stmt.where(Inventory.expiry_status == expiry_status)
        if is_low_stock is not None:
            stmt = stmt.where(Inventory.is_low_stock.is_(is_low_stock))
        if is_near_expiry is not None:
            stmt = stmt.where(Inventory.is_near_expiry.is_(is_near_expiry))
        if is_expired is not None:
            stmt = stmt.where(Inventory.is_expired.is_(is_expired))
        if operator_id:
            stmt = stmt.where(
                (Inventory.created_by == operator_id) | (Inventory.updated_by == operator_id)
            )
        if department_id or keyword:
            stmt = stmt.join(CrashCart, Inventory.cart_id == CrashCart.id)
            if department_id:
                stmt = stmt.where(CrashCart.department_id == department_id)
        if keyword:
            stmt = stmt.join(Item, Inventory.item_id == Item.id).where(
                Item.item_name.ilike(f"%{keyword}%") | Item.item_code.ilike(f"%{keyword}%")
            )
        return self.paginate(stmt, page, page_size)

    def get_all_active(self) -> list[Inventory]:
        return list(
            self.db.scalars(
                select(Inventory).where(Inventory.is_deleted.is_(False))
            ).all()
        )

    def count_by_flags(
        self,
        *,
        department_id: int | None = None,
        is_near_expiry: bool | None = None,
        is_expired: bool | None = None,
        is_low_stock: bool | None = None,
    ) -> int:
        stmt = select(func.count()).select_from(Inventory).where(Inventory.is_deleted.is_(False))
        if is_near_expiry is not None:
            stmt = stmt.where(Inventory.is_near_expiry.is_(is_near_expiry))
        if is_expired is not None:
            stmt = stmt.where(Inventory.is_expired.is_(is_expired))
        if is_low_stock is not None:
            stmt = stmt.where(Inventory.is_low_stock.is_(is_low_stock))
        if department_id:
            stmt = stmt.join(CrashCart, Inventory.cart_id == CrashCart.id).where(
                CrashCart.department_id == department_id
            )
        return self.db.scalar(stmt) or 0

    def count_all(self, department_id: int | None = None) -> int:
        stmt = select(func.count()).select_from(Inventory).where(Inventory.is_deleted.is_(False))
        if department_id:
            stmt = stmt.join(CrashCart, Inventory.cart_id == CrashCart.id).where(
                CrashCart.department_id == department_id
            )
        return self.db.scalar(stmt) or 0
