"""initial schema

Revision ID: 001_initial
Revises:
Create Date: 2026-06-15
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "departments",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("name", sa.String(length=128), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name", name="uq_departments_name"),
    )
    op.create_index("ix_departments_is_deleted", "departments", ["is_deleted"])

    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("username", sa.String(length=64), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("real_name", sa.String(length=64), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=True),
        sa.Column("email", sa.String(length=128), nullable=True),
        sa.Column("department_id", sa.Integer(), nullable=True),
        sa.Column("role", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="ACTIVE"),
        sa.Column("last_login_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("created_by", sa.Integer(), nullable=True),
        sa.Column("updated_by", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.ForeignKeyConstraint(["department_id"], ["departments.id"]),
        sa.ForeignKeyConstraint(["updated_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("username", name="uq_users_username"),
    )
    op.create_index("ix_users_username", "users", ["username"])
    op.create_index("ix_users_department_id", "users", ["department_id"])
    op.create_index("ix_users_role", "users", ["role"])
    op.create_index("ix_users_is_deleted", "users", ["is_deleted"])

    op.create_table(
        "crash_carts",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("department_id", sa.Integer(), nullable=False),
        sa.Column("cart_code", sa.String(length=64), nullable=False),
        sa.Column("cart_name", sa.String(length=128), nullable=False),
        sa.Column("location", sa.String(length=256), nullable=True),
        sa.Column("manager_name", sa.String(length=64), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="ACTIVE"),
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("created_by", sa.Integer(), nullable=True),
        sa.Column("updated_by", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.ForeignKeyConstraint(["department_id"], ["departments.id"]),
        sa.ForeignKeyConstraint(["updated_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("cart_code", name="uq_crash_carts_cart_code"),
    )
    op.create_index("ix_crash_carts_department_id", "crash_carts", ["department_id"])
    op.create_index("ix_crash_carts_cart_code", "crash_carts", ["cart_code"])
    op.create_index("ix_crash_carts_is_deleted", "crash_carts", ["is_deleted"])

    op.create_table(
        "crash_cart_layers",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("cart_id", sa.Integer(), nullable=False),
        sa.Column("layer_no", sa.Integer(), nullable=False),
        sa.Column("layer_name", sa.String(length=128), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["cart_id"], ["crash_carts.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("cart_id", "layer_no", name="uq_cart_layer_no"),
    )
    op.create_index("ix_crash_cart_layers_cart_id", "crash_cart_layers", ["cart_id"])
    op.create_index("ix_crash_cart_layers_is_deleted", "crash_cart_layers", ["is_deleted"])

    op.create_table(
        "items",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("item_code", sa.String(length=64), nullable=False),
        sa.Column("item_name", sa.String(length=128), nullable=False),
        sa.Column("item_type", sa.String(length=32), nullable=False),
        sa.Column("specification", sa.String(length=128), nullable=True),
        sa.Column("manufacturer", sa.String(length=128), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("usage_instruction", sa.Text(), nullable=True),
        sa.Column("storage_requirement", sa.String(length=256), nullable=True),
        sa.Column("warning_days", sa.Integer(), nullable=False, server_default="180"),
        sa.Column("default_warning_tag", sa.String(length=64), nullable=True),
        sa.Column("is_enabled", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("created_by", sa.Integer(), nullable=True),
        sa.Column("updated_by", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.ForeignKeyConstraint(["updated_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("item_code", name="uq_items_item_code"),
    )
    op.create_index("ix_items_item_code", "items", ["item_code"])
    op.create_index("ix_items_item_name", "items", ["item_name"])
    op.create_index("ix_items_item_type", "items", ["item_type"])
    op.create_index("ix_items_is_deleted", "items", ["is_deleted"])

    op.create_table(
        "inventories",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("item_id", sa.Integer(), nullable=False),
        sa.Column("cart_id", sa.Integer(), nullable=False),
        sa.Column("layer_id", sa.Integer(), nullable=True),
        sa.Column("batch_no", sa.String(length=64), nullable=True),
        sa.Column("quantity", sa.Numeric(precision=12, scale=2), nullable=False, server_default="0"),
        sa.Column("minimum_quantity", sa.Numeric(precision=12, scale=2), nullable=False, server_default="0"),
        sa.Column("production_date", sa.Date(), nullable=True),
        sa.Column("expiry_date", sa.Date(), nullable=True),
        sa.Column("warning_days", sa.Integer(), nullable=False, server_default="180"),
        sa.Column("warning_tag", sa.String(length=64), nullable=True),
        sa.Column("remaining_days", sa.Integer(), nullable=True),
        sa.Column("expiry_status", sa.String(length=16), nullable=False, server_default="NORMAL"),
        sa.Column("label_color", sa.String(length=16), nullable=False, server_default="GREEN"),
        sa.Column("is_near_expiry", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("is_expired", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("is_low_stock", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("remark", sa.Text(), nullable=True),
        sa.Column("last_check_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("created_by", sa.Integer(), nullable=True),
        sa.Column("updated_by", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["cart_id"], ["crash_carts.id"]),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"]),
        sa.ForeignKeyConstraint(["item_id"], ["items.id"]),
        sa.ForeignKeyConstraint(["layer_id"], ["crash_cart_layers.id"]),
        sa.ForeignKeyConstraint(["updated_by"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_inventories_item_id", "inventories", ["item_id"])
    op.create_index("ix_inventories_cart_id", "inventories", ["cart_id"])
    op.create_index("ix_inventories_layer_id", "inventories", ["layer_id"])
    op.create_index("ix_inventories_batch_no", "inventories", ["batch_no"])
    op.create_index("ix_inventories_expiry_date", "inventories", ["expiry_date"])
    op.create_index("ix_inventories_expiry_status", "inventories", ["expiry_status"])
    op.create_index("ix_inventories_is_near_expiry", "inventories", ["is_near_expiry"])
    op.create_index("ix_inventories_is_expired", "inventories", ["is_expired"])
    op.create_index("ix_inventories_is_low_stock", "inventories", ["is_low_stock"])
    op.create_index("ix_inventories_is_deleted", "inventories", ["is_deleted"])

    op.create_table(
        "inspection_records",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("cart_id", sa.Integer(), nullable=False),
        sa.Column("inspector_id", sa.Integer(), nullable=False),
        sa.Column("inspection_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("result", sa.String(length=16), nullable=False),
        sa.Column("remark", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["cart_id"], ["crash_carts.id"]),
        sa.ForeignKeyConstraint(["inspector_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_inspection_records_cart_id", "inspection_records", ["cart_id"])
    op.create_index("ix_inspection_records_inspector_id", "inspection_records", ["inspector_id"])
    op.create_index("ix_inspection_records_inspection_time", "inspection_records", ["inspection_time"])

    op.create_table(
        "notifications",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=256), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("type", sa.String(length=32), nullable=False),
        sa.Column("is_read", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_notifications_user_id", "notifications", ["user_id"])
    op.create_index("ix_notifications_type", "notifications", ["type"])
    op.create_index("ix_notifications_is_read", "notifications", ["is_read"])

    op.create_table(
        "audit_logs",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("module", sa.String(length=64), nullable=False),
        sa.Column("business_id", sa.Integer(), nullable=True),
        sa.Column("operation_type", sa.String(length=16), nullable=False),
        sa.Column("old_data", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("new_data", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("operator_id", sa.Integer(), nullable=True),
        sa.Column("operator_name", sa.String(length=64), nullable=True),
        sa.Column("operation_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ip_address", sa.String(length=64), nullable=True),
        sa.ForeignKeyConstraint(["operator_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_audit_logs_module", "audit_logs", ["module"])
    op.create_index("ix_audit_logs_business_id", "audit_logs", ["business_id"])
    op.create_index("ix_audit_logs_operation_type", "audit_logs", ["operation_type"])
    op.create_index("ix_audit_logs_operator_id", "audit_logs", ["operator_id"])
    op.create_index("ix_audit_logs_operation_time", "audit_logs", ["operation_time"])

    op.create_table(
        "operation_reasons",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("module", sa.String(length=64), nullable=False),
        sa.Column("business_id", sa.Integer(), nullable=False),
        sa.Column("reason_type", sa.String(length=64), nullable=False),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("operator_id", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["operator_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_operation_reasons_module", "operation_reasons", ["module"])
    op.create_index("ix_operation_reasons_business_id", "operation_reasons", ["business_id"])
    op.create_index("ix_operation_reasons_reason_type", "operation_reasons", ["reason_type"])
    op.create_index("ix_operation_reasons_operator_id", "operation_reasons", ["operator_id"])


def downgrade() -> None:
    op.drop_table("operation_reasons")
    op.drop_table("audit_logs")
    op.drop_table("notifications")
    op.drop_table("inspection_records")
    op.drop_table("inventories")
    op.drop_table("items")
    op.drop_table("crash_cart_layers")
    op.drop_table("crash_carts")
    op.drop_table("users")
    op.drop_table("departments")
