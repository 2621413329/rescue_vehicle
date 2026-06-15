# 启动 FastAPI 后端（默认 0.0.0.0:7080）
$ErrorActionPreference = "Stop"
$env:PYTHONUTF8 = "1"
Set-Location (Join-Path $PSScriptRoot "..")

$hostAddr = if ($env:APP_HOST) { $env:APP_HOST } else { "0.0.0.0" }
$port = if ($env:APP_PORT) { $env:APP_PORT } else { "7080" }

Write-Host ">>> Backend: http://${hostAddr}:${port}  (docs: http://127.0.0.1:${port}/docs)"
& ".\python_venv\Scripts\uvicorn.exe" app.main:app --host $hostAddr --port $port --reload
