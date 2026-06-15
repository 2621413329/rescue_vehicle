# 启动 Flutter 移动端
# 用法:
#   .\scripts\start-mobile.ps1                  # 本机 .env
#   .\scripts\start-mobile.ps1 emulator       # Android 模拟器
#   .\scripts\start-mobile.ps1 device         # Android 真机
param(
    [ValidateSet("", "emulator", "device")]
    [string]$Profile = ""
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\mobile")

$args = @("run")
switch ($Profile) {
    "emulator" { $args += "--dart-define=ENV_FILE=.env.android.emulator" }
    "device"   { $args += "--dart-define=ENV_FILE=.env.android.device" }
}

Write-Host ">>> Flutter: flutter $($args -join ' ')"
& flutter @args
