#Requires -Version 5.1
# 把 DeepSeek API Key 写进 AstrBot 并验证
# 用法：
#   1) 把 key（单行，sk-开头）存到 D:\AstrBot-QQBot\deepseek.key
#   2) 运行本脚本： .\scripts\apply-deepseek.ps1

param(
    [string]$KeyFile = "D:\AstrBot-QQBot\deepseek.key"
)

$ErrorActionPreference = 'Continue'
Set-Location (Split-Path -Parent $PSScriptRoot)
$dockerBin = "C:\Program Files\Docker\Docker\resources\bin"
if ($env:Path -notlike "*$dockerBin*") { $env:Path = "$dockerBin;$env:Path" }

if (-not (Test-Path $KeyFile)) {
    Write-Host "找不到 key 文件: $KeyFile" -ForegroundColor Red
    Write-Host "请把 key 单独一行保存到该路径后重试。" -ForegroundColor Yellow
    exit 1
}
$key = (Get-Content $KeyFile -Raw).Trim()
if ([string]::IsNullOrWhiteSpace($key)) { Write-Host "key 文件是空的" -ForegroundColor Red; exit 1 }
if (-not $key.StartsWith("sk-")) { Write-Host "警告：key 不像 DeepSeek 格式（通常以 sk- 开头）" -ForegroundColor Yellow }

Write-Host "[1/4] 停止 AstrBot ..." -ForegroundColor Cyan
docker compose stop astrbot | Out-Null

Write-Host "[2/4] 写入 provider 配置 ..." -ForegroundColor Cyan
$tmpKey = Join-Path $env:TEMP "deepseek.key"
[System.IO.File]::WriteAllText($tmpKey, $key, (New-Object System.Text.UTF8Encoding($false)))
docker cp $tmpKey astrbot:/tmp/deepseek.key | Out-Null
docker cp ".\scripts\_inject_provider.py" astrbot:/tmp/_inject_provider.py | Out-Null
docker exec astrbot python /tmp/_inject_provider.py
if ($LASTEXITCODE -ne 0) { Write-Host "注入失败" -ForegroundColor Red; docker compose start astrbot | Out-Null; exit 1 }
Remove-Item $tmpKey -Force -ErrorAction SilentlyContinue

Write-Host "[3/4] 启动 AstrBot ..." -ForegroundColor Cyan
docker compose start astrbot | Out-Null
Start-Sleep -Seconds 18

Write-Host "[4/4] 直连 DeepSeek 验证 key ..." -ForegroundColor Cyan
$probe = @'
import json, urllib.request
key = open('/tmp/deepseek.key', encoding='utf-8').read().strip()
req = urllib.request.Request(
    'https://api.deepseek.com/v1/chat/completions',
    data=json.dumps({"model": "deepseek-flash",
                     "messages": [{"role": "user", "content": "只回复两个字：在的"}],
                     "max_tokens": 20}).encode(),
    headers={'Authorization': 'Bearer ' + key, 'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req, timeout=40) as r:
        d = json.loads(r.read())
        print('API OK ->', d['choices'][0]['message']['content'].strip())
except Exception as e:
    print('API 失败 ->', type(e).__name__, str(e)[:300])
'@
$probe | Out-File -FilePath "$env:TEMP\probe_ds.py" -Encoding UTF8
docker cp "$env:TEMP\probe_ds.py" astrbot:/tmp/probe_ds.py | Out-Null
docker exec astrbot python /tmp/probe_ds.py

Write-Host ""
Write-Host "看 AstrBot 是否加载了 provider：" -ForegroundColor Cyan
docker logs --since 90s astrbot 2>&1 | Select-String -Pattern "provider|Provider|deepseek|deepseek-flash" | Select-Object -Last 8 | ForEach-Object { $_.Line }
