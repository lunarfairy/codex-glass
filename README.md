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
- 安装包内置官方 Codex CLI，从已登录的 Codex 本机账户读取额度响应；不读取、不保存聊天内容、提示词、源代码或访问令牌。

## 安装

1. 在 [Releases](../../releases) 下载最新的 `CodexGlass-v*-windows-x64.zip`。
2. 确认已登录 Codex 桌面端，再解压并双击 `安装.cmd`。不需要管理员权限，也不需要配置环境变量或单独安装 Codex CLI。
3. 桌面会出现 **Codex Glass**：双击它即可打开控制台，调整悬浮条与开机自启。

卸载时，在同一目录双击 `卸载.cmd`。

## 开发

要求：Windows、.NET 8 SDK。

```powershell
dotnet test CodexGlass.sln --configuration Release
./packaging/Build-Release.ps1 -CodexCliPath 'C:\\path\\to\\codex.exe' -Version '1.0.1'
```

发布脚本会将官方 Windows x64 Codex CLI 置于安装包的 `app/tools` 中。安装器负责安装应用、注册开机自启并创建桌面控制台图标。

## 隐私

Codex Glass 只请求本机 Codex app-server 提供的额度信息。它不会建立网络监听端口，不会将信息上传到第三方，也不会代理 Codex 请求。

## 许可证

本项目采用 [MIT License](LICENSE) 开源。

发布包中包含官方 Codex CLI（Apache-2.0），其归属与完整许可证见发行包中的 `THIRD_PARTY_NOTICES.txt` 和 `APACHE-2.0.txt`。
