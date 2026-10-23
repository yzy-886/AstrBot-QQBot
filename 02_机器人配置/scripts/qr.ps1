#Requires -Version 5.1
# 看 NapCat 登录二维码 / 日志
Set-Location (Split-Path -Parent $PSScriptRoot)

Write-Host "打开 NapCat WebUI（推荐用网页里的二维码，比终端清楚）：" -ForegroundColor Cyan
Write-Host "  http://127.0.0.1:6099" -ForegroundColor Green
$token = (Select-String -Path ".env" -Pattern '^WEBUI_TOKEN=(.*)$' | Select-Object -First 1).Matches.Groups[1].Value
Write-Host "  令牌：$token"
Start-Process "http://127.0.0.1:6099"

Write-Host "`n终端二维码 / 最近日志（Ctrl+C 退出）：" -ForegroundColor Cyan
docker logs -f --tail 60 napcat
