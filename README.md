# 医院抢救车药品与物资效期管理系统 - 后端

## 技术栈

- Python 3.12
- FastAPI
- PostgreSQL
- SQLAlchemy 2.0
- Alembic
- APScheduler
- JWT 认证

## 快速启动

### 1. 配置环境变量

```bash
copy .env.example .env
```

编辑 `.env` 中的 `DATABASE_URL`，默认连接本地 PostgreSQL：

```
postgresql://postgres:root@127.0.0.1:5432/rescue
```

> 当前阶段不使用 Docker 和 Redis。

### 2. 安装依赖

```bash
python_venv\Scripts\activate
pip install -r requirements.txt
```

### 3. 数据库迁移（Alembic）

```bash
alembic upgrade head
alembic current   # 应显示 002_extend (head)
```

迁移版本：

| 版本 | 说明 |
|------|------|
| `001_initial` | 初始 10 张表（科室、用户、抢救车、库存、巡检、通知、审计等） |
| `002_extend` | `crash_carts` 增加巡检周期/上次巡检时间；新增 `label_print_records` |

若库是旧版或未迁移，执行 `alembic upgrade head` 即可，**不要用** `sql/schema.sql` 直接覆盖已有库。

### 4. 初始化种子数据

```bash
python -m scripts.seed_data
```

### 5. 启动服务

**推荐（脚本，端口 7080）：**

```powershell
# 终端 1 — 后端
.\scripts\start-backend.ps1

# 终端 2 — Flutter（本机）
.\scripts\start-mobile.ps1

# Android 模拟器
.\scripts\start-mobile.ps1 emulator

# Android 真机（先改 mobile\.env.android.device 中的局域网 IP）
.\scripts\start-mobile.ps1 device
```

**手动启动：**

```powershell
# 后端（读取 .env 中 APP_HOST / APP_PORT，默认 0.0.0.0:7080）
python_venv\Scripts\uvicorn.exe app.main:app --host 0.0.0.0 --port 7080 --reload

# Flutter
cd mobile
flutter pub get
flutter run
flutter run --dart-define=ENV_FILE=.env.android.emulator
flutter run --dart-define=ENV_FILE=.env.android.device
```

| 服务 | 地址 |
|------|------|
| API 文档 | http://127.0.0.1:7080/docs |
| API 前缀 | http://127.0.0.1:7080/api/v1 |
| PostgreSQL | 127.0.0.1:5432（库 `rescue`） |

> 端口使用 **7080**，避免与常见 8080 服务冲突。移动端 API 地址在 `mobile/.env` 配置，勿写入根目录 `.env`。

## 前后端联调速查

| 场景 | 后端 | Flutter env |
|------|------|-------------|
| 本机 Windows | `--host 0.0.0.0 --port 7080` | `mobile/.env` → `127.0.0.1:7080` |
| Android 模拟器 | 同上 | `.env.android.emulator` → `10.0.2.2:7080` |
| Android 真机 | 同上 + 电脑手机同 WiFi | `.env.android.device` → `<局域网IP>:7080` |

## 默认账号

| 用户名 | 密码 | 角色 |
|--------|------|------|
| admin | admin | 超级管理员 |
| dept_admin | dept_admin | 科室管理员 |
| nurse01 | nurse01 | 护士 |
| viewer01 | viewer01 | 查看人员 |

## 项目结构

```
app/
├── api/           # API 路由层
├── core/          # 配置、数据库、安全、权限
├── models/        # SQLAlchemy 模型
├── schemas/       # Pydantic Schema
├── repositories/  # 数据访问层
├── services/      # 业务逻辑层
├── scheduler/     # 定时任务调度
├── tasks/         # 定时任务实现
└── utils/         # 工具函数
```

## 核心 API

| 模块 | 路径前缀 |
|------|----------|
| 认证 | `/api/v1/auth` |
| 用户 | `/api/v1/users` |
| 科室 | `/api/v1/departments` |
| 抢救车 | `/api/v1/crash-carts` |
| 物资 | `/api/v1/items` |
| 库存 | `/api/v1/inventories` |
| 巡检 | `/api/v1/inspections` |
| 统计 | `/api/v1/dashboard` |
| 通知 | `/api/v1/notifications` |
| 审计 | `/api/v1/audit-logs` |

## 定时任务

- 任务名：`inventory_expiry_scheduler`
- 执行时间：每天凌晨 1:00
- 功能：重新计算所有库存的效期状态、颜色标签、库存不足标记

## 文档

- ER 图：`docs/ER_DIAGRAM.md`
- 建表 SQL：`sql/schema.sql`
