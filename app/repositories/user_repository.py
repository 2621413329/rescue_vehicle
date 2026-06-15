from sqlalchemy import or_, select

from app.models.user import User
from app.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    model = User

    def get_by_username(self, username: str) -> User | None:
        return self.db.scalar(
            select(User).where(User.username == username, User.is_deleted.is_(False))
        )

    def list_users(
        self,
        *,
        page: int,
        page_size: int,
        department_id: int | None = None,
        role: str | None = None,
        keyword: str | None = None,
    ) -> tuple[list[User], int]:
        stmt = select(User).where(User.is_deleted.is_(False)).order_by(User.id.desc())
        if department_id:
            stmt = stmt.where(User.department_id == department_id)
        if role:
            stmt = stmt.where(User.role == role)
        if keyword:
            stmt = stmt.where(
                or_(User.username.ilike(f"%{keyword}%"), User.real_name.ilike(f"%{keyword}%"))
            )
        return self.paginate(stmt, page, page_size)
