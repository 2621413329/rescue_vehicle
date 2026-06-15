from sqlalchemy import select

from app.models.item import Item
from app.repositories.base import BaseRepository


class ItemRepository(BaseRepository[Item]):
    model = Item

    def get_by_code(self, item_code: str) -> Item | None:
        return self.db.scalar(
            select(Item).where(Item.item_code == item_code, Item.is_deleted.is_(False))
        )

    def list_items(
        self,
        *,
        page: int,
        page_size: int,
        item_type: str | None = None,
        keyword: str | None = None,
        is_enabled: bool | None = None,
    ) -> tuple[list[Item], int]:
        stmt = select(Item).where(Item.is_deleted.is_(False)).order_by(Item.id.desc())
        if item_type:
            stmt = stmt.where(Item.item_type == item_type)
        if is_enabled is not None:
            stmt = stmt.where(Item.is_enabled.is_(is_enabled))
        if keyword:
            stmt = stmt.where(
                Item.item_code.ilike(f"%{keyword}%") | Item.item_name.ilike(f"%{keyword}%")
            )
        return self.paginate(stmt, page, page_size)

    def count_enabled(self) -> int:
        stmt = select(Item).where(Item.is_deleted.is_(False), Item.is_enabled.is_(True))
        return len(list(self.db.scalars(stmt).all()))
