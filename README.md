# Codex Glass

一个轻量、常驻桌面的 Windows 悬浮条：查看 Codex 的本周额度，并在鼠标移入时显示重置倒计时。

![Windows](https://img.shields.io/badge/platform-Windows%2010%20%2F%2011-0078D4?logo=windows&logoColor=white)
![.NET](https://img.shields.io/badge/.NET-8-512BD4?logo=dotnet&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

> 非 OpenAI 官方产品；与 OpenAI 没有隶属关系。

## 功能

- 浅色半透明玻璃胶囊，始终置顶、可拖动。
- 默认仅显示本周额度；鼠标移入后显示本周重置倒计时。
- 仅在 Codex 桌面端运行时显示。
- 桌面“Codex Glass 控制台”可即时开关悬浮条和 Windows 开机自启。
- 使用用户自行安装的官方 Codex CLI，从已登录的 Codex 本机账户读取额度响应；不读取、不保存聊天内容、提示词、源代码或访问令牌。

## 安装

1. 按 [Codex 官方安装说明](https://github.com/openai/codex#install) 安装最新版 Codex CLI，并在终端确认 `codex --version` 能正常执行。
2. 登录 Codex 桌面端。
3. 在 [Releases](../../releases) 下载最新的 `CodexGlass-v*-windows-x64.zip`，解压后双击 `安装.cmd`。不需要管理员权限。
4. 桌面会出现 **Codex Glass**：双击它即可打开控制台，调整悬浮条与开机自启。

卸载时，在同一目录双击 `卸载.cmd`。

## 开发

要求：Windows、.NET 8 SDK。

```powershell
dotnet test CodexGlass.sln --configuration Release
./packaging/Build-Release.ps1 -Version '1.0.2'
```

发布包不包含、也不会下载 Codex CLI。安装器会验证用户已经安装可用的官方 CLI，再安装应用、注册开机自启并创建桌面控制台图标。

## 隐私

Codex Glass 只请求本机 Codex app-server 提供的额度信息。它不会建立网络监听端口，不会将信息上传到第三方，也不会代理 Codex 请求。

## 许可证

本项目采用 [MIT License](LICENSE) 开源。

