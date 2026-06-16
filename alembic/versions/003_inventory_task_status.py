"""add inventory task status fields and ensure cart layers 3-5

Revision ID: 003_task_status
Revises: 002_extend
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "003_task_status"
down_revision: Union[str, None] = "002_extend"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "inventories",
        sa.Column("task_replace_done", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )
    op.add_column(
        "inventories",
        sa.Column("task_label_done", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )
    op.add_column(
        "inventories",
        sa.Column("task_replace_done_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "inventories",
        sa.Column("task_label_done_at", sa.DateTime(timezone=True), nullable=True),
    )

    conn = op.get_bind()
    conn.execute(
        sa.text(
            """
            INSERT INTO crash_cart_layers (cart_id, layer_no, layer_name, sort_order, is_deleted, created_at, updated_at)
            SELECT c.id, n.no, n.no::text, n.no, false, now(), now()
            FROM crash_carts c
            CROSS JOIN (VALUES (3), (4), (5)) AS n(no)
            WHERE c.is_deleted = false
              AND NOT EXISTS (
                SELECT 1 FROM crash_cart_layers l
                WHERE l.cart_id = c.id AND l.layer_no = n.no AND l.is_deleted = false
              )
            """
        )
    )


def downgrade() -> None:
    op.drop_column("inventories", "task_label_done_at")
    op.drop_column("inventories", "task_replace_done_at")
    op.drop_column("inventories", "task_label_done")
    op.drop_column("inventories", "task_replace_done")
