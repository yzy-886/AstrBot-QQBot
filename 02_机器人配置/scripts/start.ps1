#Requires -Version 5.1
# 一键拉起 AstrBot + NapCat
# 用法：在 qq-bot 目录执行  .\scripts\start.ps1

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
Set-Location (Split-Path -Parent $PSScriptRoot)

function Info($m) { Write-Host $m -ForegroundColor Cyan }
function Ok($m)   { Write-Host $m -ForegroundColor Green }
function Warn($m) { Write-Host $m -ForegroundColor Yellow }
function Fail($m) { Write-Host $m -ForegroundColor Red }

# docker 不在 PATH 时补上（Docker Desktop 装完但没重新登录时常见）
$dockerBin = "C:\Program Files\Docker\Docker\resources\bin"
if ((Test-Path $dockerBin) -and ($env:Path -notlike "*$dockerBin*")) { $env:Path = "$dockerBin;$env:Path" }

# ---------- 1. 检查 Docker 引擎（没起就自动拉起）----------
Info "`n[1/4] 检查 Docker 引擎 ..."
$engineOk = $false
try {
    $null = docker version --format '{{.Server.Version}}' 2>&1
    if ($LASTEXITCODE -eq 0) { $engineOk = $true }
} catch {}

if (-not $engineOk) {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Fail "找不到 docker 命令。Docker Desktop 可能没装成功，请先完成 README 阶段 1。"
        exit 1
    }
    $dd = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dd) {
        Warn "引擎未运行，正在启动 Docker Desktop ...（首次可能要 1-2 分钟）"
        Start-Process $dd | Out-Null
        for ($i = 0; $i -lt 60; $i++) {
            Start-Sleep -Seconds 3
            try {
                $null = docker version --format '{{.Server.Version}}' 2>&1
                if ($LASTEXITCODE -eq 0) { $engineOk = $true; break }
            } catch {}
            if ($i % 5 -eq 0) { Write-Host "  ... 等待引擎就绪 ($($i*3)s)" -ForegroundColor DarkGray }
        }
    }
}

if (-not $engineOk) {
    Fail "Docker 引擎仍然不可用。常见原因："
    Fail "  · WSL2 组件还没生效 —— 装完必须重启一次电脑"
    Fail "  · Docker Desktop 打开后卡在欢迎页，需要手动点 Accept"
    Fail "  · BIOS 里虚拟化被关（本机已确认开启，一般不是这条）"
    exit 1
}
Ok "Docker 引擎正常。"

# ---------- 2. 拉镜像 ----------
Info "`n[2/4] 拉取镜像 ..."
docker compose pull
if ($LASTEXITCODE -ne 0) {
    Warn "直连拉取失败，切换到国内加速源重试 ..."
    $env:REGISTRY = "m.daocloud.io/docker.io/"
    docker compose pull
    if ($LASTEXITCODE -ne 0) {
        Fail "仍然失败。请检查 Docker Desktop → Settings → Resources → Proxies 是否配了代理，"
        Fail "或把 .env 里的 REGISTRY 改成 docker.1ms.run/ 后重试。"
        exit 1
    }
}
Ok "镜像就绪。"

# ---------- 3. 启动 ----------
Info "`n[3/4] 启动容器 ..."
docker compose up -d
if ($LASTEXITCODE -ne 0) { Fail "启动失败，看上面的报错。"; exit 1 }

# ---------- 4. 等待面板 ----------
Info "`n[4/4] 等待 AstrBot 面板就绪 ..."
$ready = $false
for ($i = 0; $i -lt 45; $i++) {
    try {
        $r = Invoke-WebRequest -Uri "http://127.0.0.1:6185" -UseBasicParsing -TimeoutSec 3
        if ($r.StatusCode -eq 200) { $ready = $true; break }
    } catch {}
    Start-Sleep -Seconds 2
}
if ($ready) { Ok "面板已就绪。" } else { Warn "面板还没起来，稍等 30 秒刷新 http://127.0.0.1:6185" }

# ---------- 输出 ----------
Write-Host ""
Info "════════════════════════════════════════"
Ok   "  AstrBot 面板   http://127.0.0.1:6185"
Ok   "  NapCat WebUI   http://127.0.0.1:6099"
Info "════════════════════════════════════════"

$token = (Select-String -Path ".env" -Pattern '^WEBUI_TOKEN=(.*)$' | Select-Object -First 1).Matches.Groups[1].Value
Write-Host "`nNapCat WebUI 令牌：$token"

Write-Host "`nAstrBot 初始密码（找不到就手动 docker logs astrbot）："
docker logs astrbot 2>&1 | Select-String -Pattern "密码|password|Password" | Select-Object -Last 5 | ForEach-Object { $_.Line }

Write-Host ""
Info "下一步：README.md 阶段 3 —— 先在 6185 建 OneBot v11 机器人（端口 6199），再接 DeepSeek。"
