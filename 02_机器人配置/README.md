# QQ 大肥鱼 · AstrBot + NapCat 部署手册（Windows / Docker）

本目录已经把配置写好了，你只需要按顺序执行。全程 **3 个阶段**：装环境 → 起服务 → 配 AI。

- `docker-compose.yml` — AstrBot + NapCat 两个容器
- `.env` — 令牌、QQ 号、镜像源开关
- `scripts\start.ps1` — 一键拉起（自动处理国内镜像加速）
- `persona\da_feiyu.md` — 大肥鱼人设，直接粘进 AstrBot

---

## 阶段 1：装 WSL2 + Docker Desktop

这台机器目前**没装 WSL2**，Docker 跑不起来，所以这步绕不过。

1. 以**管理员身份**打开 PowerShell（开始菜单搜 PowerShell → 右键 → 以管理员身份运行），执行：

   ```powershell
   wsl --install --no-distribution
   ```

2. **重启电脑**。
3. 重启后安装 Docker Desktop：双击我下载好的 `DockerDesktopInstaller.exe`，一路下一步，勾选 **Use WSL 2 instead of Hyper-V**。
4. 装完启动 Docker Desktop，等左下角鲸鱼图标变绿（Engine running）。

验证（普通 PowerShell 即可）：

```powershell
docker version
docker compose version
```

两条都出信息才算成功。如果 `docker` 命令找不到，把 Docker Desktop 关掉重开，或注销重登一次。

> 如果 `wsl --install` 报错说虚拟化未启用，需要进 BIOS 打开 **Intel VT-x / AMD-V**（通常叫 SVM Mode、Virtualization Technology）。这一步只能你自己在开机时按键进 BIOS 改。

---

## 阶段 2：起服务

在本目录打开 PowerShell，执行：

```powershell
.\scripts\start.ps1
```

脚本会做四件事：检查 docker → 拉镜像（失败自动切国内加速源）→ 启动两个容器 → 打印面板地址和初始密码。

成功后你会看到两个地址：

| 地址 | 是什么 | 登录方式 |
|---|---|---|
| http://127.0.0.1:6185 | **AstrBot 管理面板** | 用户名 `astrbot` + 脚本打印的随机密码 |
| http://127.0.0.1:6099 | **NapCat WebUI** | 令牌在 `.env` 的 `WEBUI_TOKEN`（默认 `ncd_7f3a91c2e4b8d05e`） |

手动起停命令：

```powershell
docker compose up -d      # 启动
docker compose ps         # 看状态
docker compose logs -f astrbot   # 跟日志
docker compose restart    # 重启
docker compose down       # 停止（数据保留在 ./data 和 ./ntqq）
```

---

## 阶段 3：配 AI（全部在 6185 面板里点）

### 3.1 登录并改密码

打开 http://127.0.0.1:6185 → 用 `astrbot` + 日志里的密码登录 → 立刻改成你自己的。

### 3.2 建 OneBot v11 机器人（让 AstrBot 开始监听 6199）

左侧 **机器人** → **创建机器人** → 选 **OneBot v11**：

| 字段 | 填什么 |
|---|---|
| ID | 随便，比如 `qq` |
| 启用 | ✅ 勾上 |
| 反向 WebSocket 主机 | `0.0.0.0` |
| 反向 WebSocket 端口 | `6199` |
| Token | 留空（NapCat 那边没设 token） |

保存。**这一步必须先做**，否则 NapCat 连过来时 AstrBot 还没开门。

### 3.3 接 DeepSeek

左侧 **服务提供商** → **添加提供商** → 选 **OpenAI**（DeepSeek 是 OpenAI 兼容接口）：

| 字段 | 值 |
|---|---|
| API Key | `sk-...`（你在 platform.deepseek.com 申请的） |
| API Base URL | `https://api.deepseek.com/v1` ← **`/v1` 不能少** |
| 模型 | `deepseek-flash` |

> **重要**：deepseek-flash 默认开启思考模式（	hinking），会让每句话先思考 10–30 秒、且思考 token 按输出价计费。务必在提供商配置的 custom_extra_body 里加上 {"thinking": {"type": "disabled"}} 关闭它，否则聊天体验极差。"

保存 → 点 **获取模型列表** → 找到 `deepseek-flash` → 点 **+** 添加 → 打开开关启用 → 回 **配置** 页把它设为**会话模型** → 右下角**保存配置**。

### 3.4 贴人设

左侧 **人设** → 新建 → 把 `persona\da_feiyu.md` 的内容整段粘进 System Prompt，Temperature 设 `0.85`。

（`persona\da_feiyu.md` 里带说明，正文从 `---` 之后开始，粘那部分就行。）

---

## 阶段 4：扫码登录 QQ

1. 打开 http://127.0.0.1:6099 ，输入 `.env` 里的 `WEBUI_TOKEN`。
2. 首次进入会让你**添加账号**：填机器人 QQ 号（**用小号**）。
3. 页面会显示**二维码**，用手机 QQ 扫 → 确认登录。
4. 二维码 60 秒过期，过期就刷新页面重新生成。

也可以在终端看二维码：

```powershell
docker logs -f napcat
```

> 如果终端里的二维码是乱码方块，直接用 6099 网页里的图，那个最稳。

登录成功后 NapCat 会自动连上 AstrBot（compose 里 `MODE=astrbot` 已经配好反向 WebSocket）。验证：回到 6185 面板 → **数据与日志 → 日志**，看到蓝色文字

```
aiocqhttp(OneBot v11) 适配器已连接
```

就通了。

---

## 阶段 5：验收

1. 用你自己的 QQ 给机器人小号发一句私聊：`你好`
2. 建个测试群，把机器人拉进去，群里 `@机器人 你是谁`
3. 群里不回消息是**正常的**：默认群聊要 @ 才触发。想改成关键词触发去面板的**群组/会话规则**里调。

---

## 排错对照表

| 现象 | 原因 | 解法 |
|---|---|---|
| `docker` 命令不存在 | Docker Desktop 没启动或没装 | 启动 Docker Desktop，等鲸鱼变绿；仍不行注销重登 |
| pull 卡住 / `TLS handshake timeout` | Docker Hub 被墙 | 把 `.env` 的 `REGISTRY` 改成 `m.daocloud.io/docker.io/`，再跑一次 `start.ps1` |
| AstrBot 面板 404 | 前端静态文件没就绪 | 等 30 秒刷新；仍 404 则 `docker compose restart astrbot` |
| 日志一直 `适配器已被关闭` | NapCat 连不上 6199 | 确认 3.2 已建好 OneBot 机器人且端口是 6199；确认两容器同一 network |
| 扫码后立刻掉线 | 小号被风控 / 多进程冲突 | 换号试；或删 `./ntqq` 目录重新扫码 |
| 群里 @ 了不回 | 群聊默认需 @ / 未启用群 | 面板里检查会话与群组设置 |
| DeepSeek 报 `401` | key 错或 base url 少了 `/v1` | 检查 base url 必须是 `https://api.deepseek.com/v1` |
| 报 `403 Text Not Allowed` | 提供商 WAF 拦了人设里的敏感词 | 人设里别出现 explicit/violence 这类词，用正面表述 |

---

## 安全 & 风险（重要）

- **必须用小号**。这类第三方协议端违反 QQ 用户协议，现实后果是小号被冻结/限制登录。
- 6185 和 6099 **只绑了 127.0.0.1**，不要在路由器上做端口映射，不要改 compose 里的绑定地址。
- `.env` 里的 `WEBUI_TOKEN` 建议改掉，别用默认值。
- 别做批量加群、群发、高频刷屏——这是封号高危动作。
- 电脑睡眠 = 断网 = 机器人掉线。要长期跑，把电源设置里"睡眠"改成"从不"。
- 想搬到云服务器：把整个 `qq-bot` 目录拷过去，`docker compose up -d` 即可，`data` / `ntqq` 里就是全部状态。届时把 6185/6099 继续绑 127.0.0.1，用 SSH 隧道访问。

---

## 升级

```powershell
docker compose pull
docker compose up -d
```

`./data`（AstrBot 配置、对话、插件）和 `./ntqq`（QQ 登录态）都在宿主机上，升级不丢。
