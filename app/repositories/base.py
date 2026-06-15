from typing import Generic, TypeVar

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.enums import SoftDeleteMixin

ModelT = TypeVar("ModelT")


class BaseRepository(Generic[ModelT]):
    model: type[ModelT]

    def __init__(self, db: Session):
        self.db = db

    def get_by_id(self, id: int, include_deleted: bool = False) -> ModelT | None:
        stmt = select(self.model).where(self.model.id == id)
        if not include_deleted and issubclass(self.model, SoftDeleteMixin):
            stmt = stmt.where(self.model.is_deleted.is_(False))
        return self.db.scalar(stmt)

    def soft_delete(self, obj) -> None:
        if hasattr(obj, "is_deleted"):
            obj.is_deleted = True
            from datetime import datetime, timezone

            obj.deleted_at = datetime.now(timezone.utc)
        else:
            self.db.delete(obj)

    def paginate(self, stmt, page: int, page_size: int) -> tuple[list, int]:
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = self.db.scalar(count_stmt) or 0
        items = list(
            self.db.scalars(
                stmt.offset((page - 1) * page_size).limit(page_size)
            ).all()
        )
        return items, total
