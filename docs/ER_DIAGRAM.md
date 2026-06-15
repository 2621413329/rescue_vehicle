# ER 图 - 医院抢救车药品与物资效期管理系统

```mermaid
erDiagram
    DEPARTMENTS ||--o{ USERS : has
    DEPARTMENTS ||--o{ CRASH_CARTS : owns
    CRASH_CARTS ||--o{ CRASH_CART_LAYERS : contains
    CRASH_CARTS ||--o{ INVENTORIES : stores
    CRASH_CART_LAYERS ||--o{ INVENTORIES : locates
    ITEMS ||--o{ INVENTORIES : references
    USERS ||--o{ INVENTORIES : creates_updates
    USERS ||--o{ INSPECTION_RECORDS : inspects
    CRASH_CARTS ||--o{ INSPECTION_RECORDS : inspected
    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ AUDIT_LOGS : operates
    USERS ||--o{ OPERATION_REASONS : records
    INVENTORIES ||--o{ LABEL_PRINT_RECORDS : prints
    USERS ||--o{ LABEL_PRINT_RECORDS : prints

    DEPARTMENTS {
        int id PK
        string name UK
        string description
        bool is_deleted
        datetime deleted_at
        datetime created_at
        datetime updated_at
    }

    USERS {
        int id PK
        string username UK
        string password_hash
        string real_name
        string phone
        string email
        int department_id FK
        string role
        string status
        datetime last_login_time
        bool is_deleted
        datetime created_at
        datetime updated_at
        int created_by FK
        int updated_by FK
    }

    CRASH_CARTS {
        int id PK
        int department_id FK
        string cart_code UK
        string cart_name
        string location
        string manager_name
        string status
        int inspection_cycle_days
        datetime last_inspection_time
        bool is_deleted
        datetime created_at
        datetime updated_at
    }

    CRASH_CART_LAYERS {
        int id PK
        int cart_id FK
        int layer_no
        string layer_name
        int sort_order
        bool is_deleted
    }

    ITEMS {
        int id PK
        string item_code UK
        string item_name
        string item_type
        int warning_days
        string default_warning_tag
        bool is_enabled
        bool is_deleted
    }

    INVENTORIES {
        int id PK
        int item_id FK
        int cart_id FK
        int layer_id FK
        string batch_no
        decimal quantity
        decimal minimum_quantity
        date expiry_date
        int warning_days
        int remaining_days
        string expiry_status
        string label_color
        bool is_near_expiry
        bool is_expired
        bool is_low_stock
        bool is_deleted
    }

    INSPECTION_RECORDS {
        int id PK
        int cart_id FK
        int inspector_id FK
        datetime inspection_time
        string result
        string remark
    }

    NOTIFICATIONS {
        int id PK
        int user_id FK
        string title
        string content
        string type
        bool is_read
    }

    AUDIT_LOGS {
        int id PK
        string module
        int business_id
        string operation_type
        jsonb old_data
        jsonb new_data
        int operator_id FK
        string operator_name
        datetime operation_time
        string ip_address
    }

    OPERATION_REASONS {
        int id PK
        string module
        int business_id
        string reason_type
        string reason
        int operator_id FK
    }

    LABEL_PRINT_RECORDS {
        int id PK
        int inventory_id FK
        string label_color
        string status
        int operator_id FK
        datetime print_time
        datetime created_at
        datetime updated_at
    }
```

## 索引设计说明

| 表 | 索引 | 用途 |
|---|---|---|
| users | username, department_id, role, is_deleted | 登录、科室筛选、权限 |
| items | item_code, item_name, item_type | 主数据检索 |
| inventories | expiry_status, is_near_expiry, is_expired, is_low_stock | 效期/库存预警查询 |
| audit_logs | module, business_id, operator_id, operation_time | 审计追溯 |
| operation_reasons | module, business_id | 操作原因查询 |

## 软删除设计

以下表支持软删除（`is_deleted` + `deleted_at`）：

- departments
- users
- crash_carts
- crash_cart_layers
- items
- inventories

查询层默认过滤 `is_deleted = false`。

## 唯一约束

- users.username
- departments.name
- crash_carts.cart_code
- crash_cart_layers(cart_id, layer_no)
- items.item_code
