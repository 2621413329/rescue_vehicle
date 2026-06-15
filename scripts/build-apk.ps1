# 打包 Release APK（Android 真机 / 模拟器）
param(
    [string]$ApiBaseUrl = "http://172.16.30.130:7080/api/v1"
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..\mobile")

Write-Host ">>> flutter clean"
& flutter clean

Write-Host ">>> flutter pub get"
& flutter pub get

Write-Host ">>> build apk: $ApiBaseUrl"
& flutter build apk --release --dart-define="API_BASE_URL=$ApiBaseUrl"

$apk = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    Write-Host ""
    Write-Host "OK: $(Resolve-Path $apk)"
} else {
    Write-Error "APK not found"
}
