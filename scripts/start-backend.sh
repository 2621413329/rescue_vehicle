#!/usr/bin/env bash
# 抢救车效期管理系统 — Linux 服务器后端启动脚本
#
# 用法:
#   ./scripts/start-backend.sh setup    # 首次部署：创建 venv、安装依赖、迁移、种子数据
#   ./scripts/start-backend.sh migrate  # 仅执行数据库迁移
#   ./scripts/start-backend.sh seed     # 仅初始化种子数据
#   ./scripts/start-backend.sh start    # 前台启动（开发/调试）
#   ./scripts/start-backend.sh run      # 同 start
#   ./scripts/start-backend.sh daemon   # 后台启动，日志写入 logs/backend.log
#   ./scripts/start-backend.sh stop     # 停止后台进程
#   ./scripts/start-backend.sh status   # 查看运行状态
#   ./scripts/start-backend.sh health   # 本地健康检查
#
# 环境变量（可在 .env 或 export 中配置）:
#   APP_HOST=0.0.0.0
#   APP_PORT=7080
#   DATABASE_URL=postgresql://user:pass@127.0.0.1:5432/rescue

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VENV_DIR="${VENV_DIR:-$ROOT_DIR/venv}"
PID_FILE="${PID_FILE:-$ROOT_DIR/logs/backend.pid}"
LOG_FILE="${LOG_FILE:-$ROOT_DIR/logs/backend.log}"
PYTHON="${VENV_DIR}/bin/python"
UVICORN="${VENV_DIR}/bin/uvicorn"
ALEMBIC="${VENV_DIR}/bin/alembic"

APP_HOST="${APP_HOST:-0.0.0.0}"
APP_PORT="${APP_PORT:-7080}"
WORKERS="${WORKERS:-1}"

export PYTHONUTF8=1

log() { printf '>>> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

load_env() {
  if [[ -f "$ROOT_DIR/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$ROOT_DIR/.env"
    set +a
    APP_HOST="${APP_HOST:-0.0.0.0}"
    APP_PORT="${APP_PORT:-7080}"
  else
    log "未找到 .env，将使用默认配置（请先 cp .env.example .env 并修改 DATABASE_URL）"
  fi
}

require_venv() {
  [[ -x "$PYTHON" ]] || die "虚拟环境不存在，请先执行: ./scripts/start-backend.sh setup"
}

require_env_file() {
  [[ -f "$ROOT_DIR/.env" ]] || die "缺少 .env，请执行: cp .env.example .env 并编辑 DATABASE_URL"
}

cmd_setup() {
  require_env_file

  if [[ ! -d "$VENV_DIR" ]]; then
    log "创建虚拟环境: $VENV_DIR"
    python3 -m venv "$VENV_DIR"
  fi

  log "安装 Python 依赖"
  "$PYTHON" -m pip install --upgrade pip
  "$PYTHON" -m pip install -r requirements.txt

  cmd_migrate
  cmd_seed

  log "部署完成。启动服务: ./scripts/start-backend.sh daemon"
}

cmd_migrate() {
  require_venv
  require_env_file
  log "执行数据库迁移 (alembic upgrade head)"
  "$ALEMBIC" upgrade head
  "$ALEMBIC" current
}

cmd_seed() {
  require_venv
  require_env_file
  log "初始化种子数据"
  "$PYTHON" -m scripts.seed_data
}

cmd_start() {
  require_venv
  load_env
  mkdir -p "$ROOT_DIR/logs"

  log "启动后端: http://${APP_HOST}:${APP_PORT}"
  log "API 文档: http://127.0.0.1:${APP_PORT}/docs"
  log "健康检查: http://127.0.0.1:${APP_PORT}/health"

  exec "$UVICORN" app.main:app \
    --host "$APP_HOST" \
    --port "$APP_PORT" \
    --workers "$WORKERS"
}

cmd_daemon() {
  require_venv
  load_env
  mkdir -p "$ROOT_DIR/logs"

  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    die "后端已在运行 (PID $(cat "$PID_FILE"))，请先 stop"
  fi

  log "后台启动: http://${APP_HOST}:${APP_PORT}，日志 $LOG_FILE"

  nohup "$UVICORN" app.main:app \
    --host "$APP_HOST" \
    --port "$APP_PORT" \
    --workers "$WORKERS" \
    >>"$LOG_FILE" 2>&1 &

  echo $! >"$PID_FILE"
  sleep 1

  if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    log "已启动，PID $(cat "$PID_FILE")"
  else
    rm -f "$PID_FILE"
    die "启动失败，请查看日志: $LOG_FILE"
  fi
}

cmd_stop() {
  if [[ ! -f "$PID_FILE" ]]; then
    log "未找到 PID 文件，服务可能未在后台运行"
    exit 0
  fi

  pid="$(cat "$PID_FILE")"
  if kill -0 "$pid" 2>/dev/null; then
    log "停止进程 PID $pid"
    kill "$pid"
    rm -f "$PID_FILE"
    log "已停止"
  else
    log "进程 $pid 不存在，清理 PID 文件"
    rm -f "$PID_FILE"
  fi
}

cmd_status() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    log "运行中，PID $(cat "$PID_FILE")，端口 ${APP_PORT}"
    cmd_health || true
  else
    log "未在后台运行"
    exit 1
  fi
}

cmd_health() {
  load_env
  if command -v curl >/dev/null 2>&1; then
    curl -fsS "http://127.0.0.1:${APP_PORT}/health" && echo
  else
    "$PYTHON" - <<PY
import urllib.request
print(urllib.request.urlopen("http://127.0.0.1:${APP_PORT}/health", timeout=5).read().decode())
PY
  fi
}

usage() {
  sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
  local action="${1:-start}"
  case "$action" in
    setup) cmd_setup ;;
    migrate) require_venv; cmd_migrate ;;
    seed) require_venv; cmd_seed ;;
    start|run) cmd_start ;;
    daemon) cmd_daemon ;;
    stop) cmd_stop ;;
    status) cmd_status ;;
    health) cmd_health ;;
    -h|--help|help) usage ;;
    *) die "未知命令: $action（执行 ./scripts/start-backend.sh help 查看帮助）" ;;
  esac
}

main "${@:-start}"
