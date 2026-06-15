"""add inspection cycle and label print records

Revision ID: 002_extend
Revises: 001_initial
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "002_extend"
down_revision: Union[str, None] = "001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "crash_carts",
        sa.Column("inspection_cycle_days", sa.Integer(), server_default="1", nullable=False),
    )
    op.add_column(
        "crash_carts",
        sa.Column("last_inspection_time", sa.DateTime(timezone=True), nullable=True),
    )

    op.create_table(
        "label_print_records",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("inventory_id", sa.Integer(), nullable=False),
        sa.Column("label_color", sa.String(length=16), nullable=False),
        sa.Column("status", sa.String(length=32), server_default="PRINTED", nullable=False),
        sa.Column("operator_id", sa.Integer(), nullable=True),
        sa.Column("print_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["inventory_id"], ["inventories.id"]),
        sa.ForeignKeyConstraint(["operator_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_label_print_records_inventory_id", "label_print_records", ["inventory_id"])
    op.create_index("ix_label_print_records_operator_id", "label_print_records", ["operator_id"])


def downgrade() -> None:
    op.drop_table("label_print_records")
    op.drop_column("crash_carts", "last_inspection_time")
    op.drop_column("crash_carts", "inspection_cycle_days")
