# Codex Glass for macOS

**简体中文** | [English](README.en.md)

基于本项目 Windows 版设计的原生 Swift / AppKit 移植。最低 macOS 13，无第三方运行时依赖。应用界面为简体中文；构建脚本生成当前 Mac 架构的应用，GitHub Actions 分别构建 Apple Silicon（arm64）和 Intel（x64）。交互检查在 Apple Silicon / macOS 26 上完成，较早 macOS 的实际运行效果尚未验证。

## 安装与运行

先安装并通过 ChatGPT 登录官方 Codex CLI；也能使用已安装的 Codex 桌面端内附的官方 CLI。无需复制或粘贴账户令牌。保持 Codex 桌面端运行，浮窗才会显示。

### 从源码构建（推荐）

需要带 macOS 26 SDK 的 Xcode 26 或 Apple Command Line Tools（`xcode-select --install`）；运行测试还需要 Swift 6 和 Python 3。

在项目根目录运行：

```sh
./macos/test.sh
./macos/build.sh
./macos/install.sh
```

应用安装在 `/Applications/Codex Glass.app`。无该目录写入权限时，可运行 `./macos/install.sh "$HOME/Applications"`。安装脚本不会要求管理员权限。

### 预编译测试包

在仓库的 [Build 工作流](https://github.com/lunarfairy/codex-glass/actions/workflows/build.yml) 中打开一次成功的构建，从 Artifacts 下载 `CodexGlass-macos-arm64`（Apple Silicon）或 `CodexGlass-macos-x64`（Intel）。如果下载的是 GitHub 外层 ZIP，先解压，再解压其中的应用 ZIP。

完整解压后，双击 `Install.command` 安装，或在解压目录运行 `./install.sh`。`Uninstall.command` 用于卸载。包内提供 SHA256 校验文件；也可使用 `shasum -a 256 -c CodexGlass-macos-arm64.zip.sha256` 校验对应 ZIP（Intel 请替换文件名）。

预编译包为 ad-hoc 签名，尚未经过 Apple 公证，macOS 可能阻止从网络下载的应用运行。源码构建是当前推荐方式；不要为安装而关闭 Gatekeeper。面向正式分发时，应使用 Developer ID 签名并公证。

## 使用

- 打开 Codex 桌面端，悬浮条随之显示；退出 Codex，悬浮条隐藏。
- 顶部绿色十段条表示五小时剩余额度，底部蓝条表示周剩余额度。
- 控制面板和右键菜单提供“显示五小时额度”开关，默认开启：浮窗并排显示 `5 H` 与 `WEEK` 剩余百分比。关闭后恢复仅显示本周大数字的简洁样式，绿色十段条保留；开关状态自动保存。
- 成功读取账户额度后，未返回五小时窗口时默认显示 100%，顶部十段条满格；这是显示回退，不代表账户无限额。返回五小时窗口时显示真实值；周额度缺失仍显示 `—`，连接失败不会显示虚假的满额。
- macOS 26 使用系统原生透明玻璃效果（clear Liquid Glass），去掉额外的白色遮罩；较早系统使用更通透的磨砂背景，数字保持清晰。
- 控制面板提供“背景不透明度”滑块（0–100%），调整立即生效并自动保存。低于 5% 使用均匀的半透明白色底层，并关闭玻璃材质和窗口阴影，避免极低不透明度时的灰色噪点；5% 及以上使用玻璃效果，100% 保留完整效果。数字和进度条不随背景淡化。圆角底层最低保留 1% 不透明度，避免 0% 时空白区域点击穿透。
- 鼠标移入浮窗，展开周额度重置倒计时；拖动浮窗可改变位置，位置会保存。拖动过程中保持展开状态不变，松开鼠标后再校正位置和更新展开状态。
- 双击浮窗、重新打开应用，或点击菜单栏的仪表图标，即可打开控制面板。
- 可开关悬浮条、立即刷新、重置位置、设置“登录 Mac 时自动启动”或退出。首次安装默认不启用登录自启。
- 关闭控制面板不会退出悬浮条；应用不占用 Dock 图标。
- 额度每分钟刷新；连接失败每 30 秒重试。橙点表示数据可能过期，连接状态和上次更新时间可在控制面板查看。

当前仅匹配官方 Codex 桌面端的 `com.openai.codex` 标识，不会把终端里的 CLI 或浏览器误认为桌面端。主显示器、其他桌面空间及全屏空间使用原生浮动面板；更换显示器时自动把浮窗移回可见范围。

## 更新与卸载

更新：重新构建并运行安装脚本，浮窗位置与开关设置会保留。

卸载：

```sh
./macos/uninstall.sh
# 如果安装在个人应用目录：
./macos/uninstall.sh "$HOME/Applications"
```

卸载只移除 Codex Glass、它的登录项及偏好设置，不会更改 Codex CLI、桌面端、账户或会话。

也可以在控制面板关闭“登录时启动”，退出 Codex Glass，然后将应用移到废纸篓。

## 验证与隐私

```sh
"/Applications/Codex Glass.app/Contents/MacOS/CodexGlass" --check
codesign --verify --deep --strict "/Applications/Codex Glass.app"
```

`--check` 输出额度百分比和重置时间，不输出账户令牌、原始服务日志或聊天内容。程序只发出 `initialize`、`initialized`、`account/rateLimits/read`，通过标准输入输出和本机官方 CLI 通信；不启动网络监听端口，不调用模型，不读取 `auth.json`，不访问聊天或项目内容。官方 CLI 负责原有的账户认证与联网。详见 [OpenAI App Server 协议](https://learn.chatgpt.com/docs/app-server)。

本地构建使用 ad-hoc 代码签名，未经过 Developer ID 签名和 Apple 公证。不要关闭 Gatekeeper；要在其他 Mac 分发，可由接收者从源码构建，或先使用自己的 Developer ID 签名并公证。

## 打包与持续集成

运行 `./macos/package.sh` 会构建当前架构的应用，在 `macos/dist/` 生成安装 ZIP 和 `.zip.sha256` 文件。包内包含应用、安装/卸载脚本、双语说明及 MIT 许可证，不包含 Codex CLI、个人偏好设置或账户数据。

GitHub Actions 使用 macOS 26 runner 分别运行核心测试、构建并打包 arm64 和 x64 版本。需要图形桌面的 `test-interaction.sh` 在本机单独运行，不在无交互桌面的 CI 环境执行。

### 实现边界

- 原 Windows / WPF 实现保持独立；新增代码集中在 `macos/`。
- 登录项采用 macOS 原生 `SMAppService.mainApp`；可在系统设置中管理。
- 从 Finder 启动时也会检查 Homebrew、用户 `.local/bin` 及官方应用位置，不依赖交互式终端的 PATH。
- 每次查询使用短时子进程，带 30 秒总超时；读取完成、禁用悬浮条或休眠时释放连接。
- 解析器优先选择 `rateLimitsByLimitId.codex`，兼容旧版 `rateLimits`；按 300 / 10080 分钟识别五小时和周窗口。
- 测试覆盖缺失值、多额度桶、顺序变化、百分比边界、重置倒计时、跨显示器位置、协议握手、分段响应、通知、退出、超时和取消。
- 在已登录的 macOS 桌面中运行 `./macos/test-interaction.sh`，可验证 0%、1–4%、5% 临界值两侧、10%、100% 及从玻璃返回低不透明度时，浮窗空白区域是否接收鼠标，覆盖两种额度布局、展开/收起和圆角外的穿透区域。检查使用独立设置域，不更改已安装应用的偏好。
