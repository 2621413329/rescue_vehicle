-- 医院抢救车药品与物资效期管理系统 - PostgreSQL 建表脚本
-- Python 3.12 / SQLAlchemy 2.0

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===================== 科室 =====================
CREATE TABLE IF NOT EXISTS departments (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(128) NOT NULL,
    description     TEXT,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_departments_name UNIQUE (name)
);
CREATE INDEX IF NOT EXISTS ix_departments_is_deleted ON departments (is_deleted);

-- ===================== 用户 =====================
CREATE TABLE IF NOT EXISTS users (
    id              SERIAL PRIMARY KEY,
    username        VARCHAR(64) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    real_name       VARCHAR(64) NOT NULL,
    phone           VARCHAR(20),
    email           VARCHAR(128),
    department_id   INTEGER REFERENCES departments(id),
    role            VARCHAR(32) NOT NULL,
    status          VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    last_login_time TIMESTAMPTZ,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      INTEGER REFERENCES users(id),
    updated_by      INTEGER REFERENCES users(id),
    CONSTRAINT uq_users_username UNIQUE (username)
);
CREATE INDEX IF NOT EXISTS ix_users_username ON users (username);
CREATE INDEX IF NOT EXISTS ix_users_department_id ON users (department_id);
CREATE INDEX IF NOT EXISTS ix_users_role ON users (role);
CREATE INDEX IF NOT EXISTS ix_users_is_deleted ON users (is_deleted);

-- ===================== 抢救车 =====================
CREATE TABLE IF NOT EXISTS crash_carts (
    id              SERIAL PRIMARY KEY,
    department_id   INTEGER NOT NULL REFERENCES departments(id),
    cart_code       VARCHAR(64) NOT NULL,
    cart_name       VARCHAR(128) NOT NULL,
    location        VARCHAR(256),
    manager_name    VARCHAR(64),
    description     TEXT,
    status          VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    inspection_cycle_days INTEGER NOT NULL DEFAULT 1,
    last_inspection_time TIMESTAMPTZ,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      INTEGER REFERENCES users(id),
    updated_by      INTEGER REFERENCES users(id),
    CONSTRAINT uq_crash_carts_cart_code UNIQUE (cart_code)
);
CREATE INDEX IF NOT EXISTS ix_crash_carts_department_id ON crash_carts (department_id);
CREATE INDEX IF NOT EXISTS ix_crash_carts_cart_code ON crash_carts (cart_code);
CREATE INDEX IF NOT EXISTS ix_crash_carts_is_deleted ON crash_carts (is_deleted);

-- ===================== 抢救车层级 =====================
CREATE TABLE IF NOT EXISTS crash_cart_layers (
    id              SERIAL PRIMARY KEY,
    cart_id         INTEGER NOT NULL REFERENCES crash_carts(id),
    layer_no        INTEGER NOT NULL,
    layer_name      VARCHAR(128) NOT NULL,
    description     TEXT,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_cart_layer_no UNIQUE (cart_id, layer_no)
);
CREATE INDEX IF NOT EXISTS ix_crash_cart_layers_cart_id ON crash_cart_layers (cart_id);
CREATE INDEX IF NOT EXISTS ix_crash_cart_layers_is_deleted ON crash_cart_layers (is_deleted);

-- ===================== 药品与物资主数据 =====================
CREATE TABLE IF NOT EXISTS items (
    id                  SERIAL PRIMARY KEY,
    item_code           VARCHAR(64) NOT NULL,
    item_name           VARCHAR(128) NOT NULL,
    item_type           VARCHAR(32) NOT NULL,
    specification       VARCHAR(128),
    manufacturer        VARCHAR(128),
    description         TEXT,
    usage_instruction   TEXT,
    storage_requirement VARCHAR(256),
    warning_days        INTEGER NOT NULL DEFAULT 180,
    default_warning_tag VARCHAR(64),
    is_enabled          BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by          INTEGER REFERENCES users(id),
    updated_by          INTEGER REFERENCES users(id),
    CONSTRAINT uq_items_item_code UNIQUE (item_code)
);
CREATE INDEX IF NOT EXISTS ix_items_item_code ON items (item_code);
CREATE INDEX IF NOT EXISTS ix_items_item_name ON items (item_name);
CREATE INDEX IF NOT EXISTS ix_items_item_type ON items (item_type);
CREATE INDEX IF NOT EXISTS ix_items_is_deleted ON items (is_deleted);

-- ===================== 库存 =====================
CREATE TABLE IF NOT EXISTS inventories (
    id                  SERIAL PRIMARY KEY,
    item_id             INTEGER NOT NULL REFERENCES items(id),
    cart_id             INTEGER NOT NULL REFERENCES crash_carts(id),
    layer_id            INTEGER REFERENCES crash_cart_layers(id),
    batch_no            VARCHAR(64),
    quantity            NUMERIC(12,2) NOT NULL DEFAULT 0,
    minimum_quantity    NUMERIC(12,2) NOT NULL DEFAULT 0,
    production_date     DATE,
    expiry_date         DATE,
    warning_days        INTEGER NOT NULL DEFAULT 180,
    warning_tag         VARCHAR(64),
    remaining_days      INTEGER,
    expiry_status       VARCHAR(16) NOT NULL DEFAULT 'NORMAL',
    label_color         VARCHAR(16) NOT NULL DEFAULT 'GREEN',
    is_near_expiry      BOOLEAN NOT NULL DEFAULT FALSE,
    is_expired          BOOLEAN NOT NULL DEFAULT FALSE,
    is_low_stock        BOOLEAN NOT NULL DEFAULT FALSE,
    remark              TEXT,
    last_check_time     TIMESTAMPTZ,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by          INTEGER REFERENCES users(id),
    updated_by          INTEGER REFERENCES users(id)
);
CREATE INDEX IF NOT EXISTS ix_inventories_item_id ON inventories (item_id);
CREATE INDEX IF NOT EXISTS ix_inventories_cart_id ON inventories (cart_id);
CREATE INDEX IF NOT EXISTS ix_inventories_layer_id ON inventories (layer_id);
CREATE INDEX IF NOT EXISTS ix_inventories_batch_no ON inventories (batch_no);
CREATE INDEX IF NOT EXISTS ix_inventories_expiry_date ON inventories (expiry_date);
CREATE INDEX IF NOT EXISTS ix_inventories_expiry_status ON inventories (expiry_status);
CREATE INDEX IF NOT EXISTS ix_inventories_is_near_expiry ON inventories (is_near_expiry);
CREATE INDEX IF NOT EXISTS ix_inventories_is_expired ON inventories (is_expired);
CREATE INDEX IF NOT EXISTS ix_inventories_is_low_stock ON inventories (is_low_stock);
CREATE INDEX IF NOT EXISTS ix_inventories_is_deleted ON inventories (is_deleted);

-- ===================== 巡检记录 =====================
CREATE TABLE IF NOT EXISTS inspection_records (
    id              SERIAL PRIMARY KEY,
    cart_id         INTEGER NOT NULL REFERENCES crash_carts(id),
    inspector_id    INTEGER NOT NULL REFERENCES users(id),
    inspection_time TIMESTAMPTZ NOT NULL,
    result          VARCHAR(16) NOT NULL,
    remark          TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_inspection_records_cart_id ON inspection_records (cart_id);
CREATE INDEX IF NOT EXISTS ix_inspection_records_inspector_id ON inspection_records (inspector_id);
CREATE INDEX IF NOT EXISTS ix_inspection_records_inspection_time ON inspection_records (inspection_time);

-- ===================== 通知中心 =====================
CREATE TABLE IF NOT EXISTS notifications (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES users(id),
    title       VARCHAR(256) NOT NULL,
    content     TEXT NOT NULL,
    type        VARCHAR(32) NOT NULL,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_notifications_user_id ON notifications (user_id);
CREATE INDEX IF NOT EXISTS ix_notifications_type ON notifications (type);
CREATE INDEX IF NOT EXISTS ix_notifications_is_read ON notifications (is_read);

-- ===================== 审计日志 =====================
CREATE TABLE IF NOT EXISTS audit_logs (
    id              SERIAL PRIMARY KEY,
    module          VARCHAR(64) NOT NULL,
    business_id     INTEGER,
    operation_type  VARCHAR(16) NOT NULL,
    old_data        JSONB,
    new_data        JSONB,
    operator_id     INTEGER REFERENCES users(id),
    operator_name   VARCHAR(64),
    operation_time  TIMESTAMPTZ NOT NULL,
    ip_address      VARCHAR(64)
);
CREATE INDEX IF NOT EXISTS ix_audit_logs_module ON audit_logs (module);
CREATE INDEX IF NOT EXISTS ix_audit_logs_business_id ON audit_logs (business_id);
CREATE INDEX IF NOT EXISTS ix_audit_logs_operation_type ON audit_logs (operation_type);
CREATE INDEX IF NOT EXISTS ix_audit_logs_operator_id ON audit_logs (operator_id);
CREATE INDEX IF NOT EXISTS ix_audit_logs_operation_time ON audit_logs (operation_time);

-- ===================== 操作原因 =====================
CREATE TABLE IF NOT EXISTS operation_reasons (
    id          SERIAL PRIMARY KEY,
    module      VARCHAR(64) NOT NULL,
    business_id INTEGER NOT NULL,
    reason_type VARCHAR(64) NOT NULL,
    reason      TEXT NOT NULL,
    operator_id INTEGER REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_operation_reasons_module ON operation_reasons (module);
CREATE INDEX IF NOT EXISTS ix_operation_reasons_business_id ON operation_reasons (business_id);
CREATE INDEX IF NOT EXISTS ix_operation_reasons_reason_type ON operation_reasons (reason_type);
CREATE INDEX IF NOT EXISTS ix_operation_reasons_operator_id ON operation_reasons (operator_id);

-- ===================== 标签打印记录（002_extend） =====================
CREATE TABLE IF NOT EXISTS label_print_records (
    id              SERIAL PRIMARY KEY,
    inventory_id    INTEGER NOT NULL REFERENCES inventories(id),
    label_color     VARCHAR(16) NOT NULL,
    status          VARCHAR(32) NOT NULL DEFAULT 'PRINTED',
    operator_id     INTEGER REFERENCES users(id),
    print_time      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_label_print_records_inventory_id ON label_print_records (inventory_id);
CREATE INDEX IF NOT EXISTS ix_label_print_records_operator_id ON label_print_records (operator_id);
