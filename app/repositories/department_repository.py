from sqlalchemy import select

from app.models.department import Department
from app.repositories.base import BaseRepository


class DepartmentRepository(BaseRepository[Department]):
    model = Department

    def get_by_name(self, name: str) -> Department | None:
        return self.db.scalar(
            select(Department).where(Department.name == name, Department.is_deleted.is_(False))
        )

    def list_departments(
        self, *, page: int, page_size: int, keyword: str | None = None
    ) -> tuple[list[Department], int]:
        stmt = select(Department).where(Department.is_deleted.is_(False)).order_by(Department.id)
        if keyword:
            stmt = stmt.where(Department.name.ilike(f"%{keyword}%"))
        return self.paginate(stmt, page, page_size)
