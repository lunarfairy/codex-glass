# Codex Glass

一个常驻桌面的 Windows 浅色玻璃悬浮条：顶部绿色十段条显示五小时剩余额度，底部蓝色条和数字显示本周剩余额度，鼠标移入显示本周重置倒计时。

**[下载最新版安装包](https://github.com/lunarfairy/codex-glass/releases/latest)** · [反馈问题](https://github.com/lunarfairy/codex-glass/issues)

![Windows](https://img.shields.io/badge/platform-Windows%2010%20%2F%2011-0078D4?logo=windows&logoColor=white)
![.NET](https://img.shields.io/badge/.NET-8-512BD4?logo=dotnet&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

> 非 OpenAI 官方产品；与 OpenAI 没有隶属关系。

## 效果预览

| 常态悬浮窗 | 鼠标移入后 |
| :---: | :---: |
| ![Codex Glass 常态悬浮窗，顶部绿色十段额度条与底部蓝色周额度条](docs/images/quota-overlay.png) | ![Codex Glass 鼠标移入后展开本周额度重置倒计时](docs/images/quota-overlay-hover.png) |

顶部绿色十段条表示**五小时剩余额度**，中间百分比和底部蓝色条表示**本周剩余额度**；鼠标移入后展开本周重置倒计时。截图中的额度和时间仅为示例，实际数值随账户更新。

## 功能

- 浅色半透明玻璃胶囊，始终置顶、可拖动。
- 顶部绿色条分为十段，每段约代表 10% 五小时剩余额度，四舍五入显示。
- 中间数字与底部蓝色条显示本周剩余额度；鼠标移入后显示本周重置倒计时。
- 仅在 Codex 桌面端运行时显示。
- 双击桌面“Codex Glass”可打开控制面板，即时开关悬浮条和 Windows 开机自启。
- 使用用户自行安装的官方 Codex CLI，从已登录的 Codex 本机账户读取额度响应；不读取、不保存聊天内容、提示词、源代码或访问令牌。

## 安装

适用于 Windows 10/11 x64。安装包自带 .NET 运行时，无需安装开发工具、编译代码或以管理员身份运行。

1. 按 [Codex 官方安装说明](https://github.com/openai/codex#quickstart) 自行安装 Codex CLI。已安装 Node.js 的用户也可运行 `npm install -g @openai/codex`。安装后重新打开终端，确认 `codex --version` 能正常执行。
2. 在终端运行 `codex`，按提示选择 **Sign in with ChatGPT** 登录；打开 Codex 桌面端并登录同一账户。需要账户返回五小时/周额度数据，仅使用 API Key 的配置不适用。
3. 在 [最新版下载页](https://github.com/lunarfairy/codex-glass/releases/latest) 的 **Assets** 中下载 `CodexGlass-v1.0.3-windows-x64.zip`。不要下载 GitHub 自动生成的 `Source code`。
4. 右键 ZIP → **全部解压缩**，进入解压后的文件夹，双击 **安装.cmd**。请勿在压缩包预览内直接运行，也不要只复制 EXE。
5. 安装完成会自动打开控制面板。保持“悬浮条”开启，打开 Codex 桌面端后即可看到浮窗。首次读取可能需要稍等，正常情况下额度约每分钟刷新。

以后双击桌面的 **Codex Glass** 调整开关；按住浮窗可拖动，位置自动保存。关闭控制面板后浮窗仍在后台运行；关闭 Codex 桌面端后浮窗隐藏。

## 更新和卸载

更新：下载新安装包并解压，直接运行新的 `安装.cmd`，无需先卸载；浮窗位置与开关设置保留，安装时会重新启用开机自启，可在控制面板关闭。

卸载：在解压目录双击 `卸载.cmd`。它会移除 Codex Glass、桌面快捷方式、自启项和本工具设置；不会卸载用户自行安装的 Codex CLI 或 Codex 桌面端，也不会删除 Codex 账户配置。

## 常见问题

- **提示 Codex CLI is required**：先安装官方 CLI。重新打开终端验证 `codex --version`，再运行安装器。若仍找不到，请注销 Windows 后重新登录，以刷新应用继承的 PATH。
- **没有浮窗**：从桌面打开控制面板确认悬浮条已开启，并保持官方 Codex Windows 桌面端运行。只打开 CLI 或浏览器不会触发显示。
- **显示“—”或无法读取额度**：在终端运行 `codex` 确认 ChatGPT 登录有效、官方 CLI 可以联网，再关闭并重新打开 Codex 桌面端。浮窗展示的是 CLI 登录账户的额度。
- **下载或登录超时**：先确认官方 CLI 自身能够联网；如需代理，请使用你自己的代理设置。本工具不预设 7897 或其他端口。
- **Windows 提示未知发布者**：当前安装包未做代码签名。先确认来源是本仓库的 Release，并可对照随包发布的 SHA256 校验文件；不要关闭系统防护。
- **旧版安装/卸载脚本出现乱码或语法报错**：使用最新 Release 中的脚本，完整解压后运行。发布脚本保持 ASCII 内容，以兼容 Windows PowerShell 5.1 和中文用户路径。

仍有问题可提交 [Issue](https://github.com/lunarfairy/codex-glass/issues)，附 Windows 版本、工具版本、`codex --version` 输出及错误截图；请勿上传账户令牌或 `auth.json`。

## 开发

要求：Windows、.NET 8 SDK。

```powershell
dotnet test CodexGlass.sln --configuration Release
./packaging/Build-Release.ps1 -Version '1.0.3'
```

发布包不包含、也不会下载 Codex CLI。安装器会验证用户已经安装可用的官方 CLI，再安装应用、注册开机自启并创建桌面控制台图标。

## 隐私

Codex Glass 只请求本机 Codex app-server 提供的额度信息。它不会建立网络监听端口，不会将信息上传到第三方，也不会代理 Codex 请求。

## 许可证

本项目采用 [MIT License](LICENSE) 开源。

