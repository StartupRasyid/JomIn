
# JomIn - Android USB Port Forwarding

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "`nConnecting to Android device..." -ForegroundColor Cyan

if (-not (Test-Path $adb)) {
    Write-Host "ADB not found!" -ForegroundColor Red
    exit 1
}

# Check connected devices
& $adb devices

# Enable reverse port forwarding
& $adb reverse tcp:3000 tcp:3000

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nJomIn USB forwarding is ready!" -ForegroundColor Green
} else {
    Write-Host "`nFailed to establish USB forwarding." -ForegroundColor Red
    exit 1
}