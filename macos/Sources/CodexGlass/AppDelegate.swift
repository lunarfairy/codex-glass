import AppKit
import ServiceManagement
import GlassCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var overlay: OverlayController!
    private var statusItem: NSStatusItem!
    private var controller: NSWindow?
    private var overlaySwitch: NSButton?
    private var fiveHourSwitch: NSButton?
    private var loginSwitch: NSButton?
    private var opacitySlider: NSSlider?
    private var opacityLabel: NSTextField?
    private var quotaLabel: NSTextField?
    private var statusLabel: NSTextField?
    private var timer: Timer?
    private var client: AppServerClient?
    private var snapshot: QuotaSnapshot?
    private var lastRefresh: Date?
    private var nextRefresh = Date.distantPast
    private var stale = false
    private var sleeping = false
    private var status = "正在读取 Codex 额度…"
    private var desktopRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: "com.openai.codex").isEmpty
    }
    private var overlayEnabled: Bool { UserDefaults.standard.bool(forKey: "overlayEnabled") }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["overlayEnabled": true])
        overlay = OverlayController()
        overlay.meter.onControl = { [weak self] in self?.showControl() }
        overlay.meter.contextMenu = { [weak self] in self?.makeMenu() ?? NSMenu() }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "gauge.with.dots.needle.50percent", accessibilityDescription: "Codex Glass")
        statusItem.button?.toolTip = "Codex Glass · 剩余额度"
        statusItem.menu = makeMenu()

        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(workspaceChanged), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(workspaceChanged), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(willSleep), name: NSWorkspace.willSleepNotification, object: nil)
        center.addObserver(self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        timer = Timer(timeInterval: 2, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        timer?.tolerance = 0.5
        RunLoop.main.add(timer!, forMode: .common)
        tick()
        if !UserDefaults.standard.bool(forKey: "hasLaunched") || CommandLine.arguments.contains("--control") {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            showControl()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showControl()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        client?.cancel()
        overlay?.savePosition()
    }

    @objc private func tick() {
        let visible = OverlayPolicy.isVisible(enabled: overlayEnabled, desktopRunning: desktopRunning, sleeping: sleeping)
        if !visible {
            overlay.panel.orderOut(nil)
            client?.cancel()
            client = nil
            nextRefresh = .distantPast
            if sleeping { status = "Mac 休眠中" }
            else if !overlayEnabled { status = "悬浮条已关闭" }
            else { status = "等待 Codex 桌面端启动" }
            updateViews()
            return
        }
        if !overlay.panel.isVisible { overlay.panel.orderFrontRegardless() }
        updateViews()
        guard client == nil, Date() >= nextRefresh else { return }
        let request = AppServerClient()
        client = request
        if snapshot == nil { status = "正在读取 Codex 额度…"; updateViews() }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let result = Result { try request.readQuota() }
            DispatchQueue.main.async {
                guard let self, self.client === request else { return }
                self.client = nil
                switch result {
                case .success(let value):
                    self.snapshot = value
                    self.lastRefresh = Date()
                    self.stale = false
                    self.status = "额度已更新 · 每分钟自动刷新"
                    self.nextRefresh = Date().addingTimeInterval(60)
                case .failure(let error):
                    self.stale = true
                    self.status = error.localizedDescription
                    if self.snapshot != nil { self.status += " 显示上次数据。" }
                    self.nextRefresh = Date().addingTimeInterval(30)
                }
                self.updateViews()
            }
        }
    }

    @objc private func workspaceChanged() { tick() }
    @objc private func willSleep() { sleeping = true; tick() }
    @objc private func didWake() { sleeping = false; nextRefresh = .distantPast; tick() }
    @objc private func screenChanged() { overlay.clampToScreen() }

    private func updateViews() {
        // Old data is explicitly marked after a wake/reconnect, even before a request fails.
        let old = stale || (lastRefresh.map { Date().timeIntervalSince($0) > 90 } ?? false)
        overlay.update(snapshot: snapshot, stale: old, status: status)
        let five = snapshot?.fiveHour.map { "\($0.remainingPercent)%" } ?? "未提供"
        let week = snapshot?.weekly.map { "\($0.remainingPercent)%" } ?? "未提供"
        quotaLabel?.stringValue = "五小时剩余  \(five)     ·     本周剩余  \(week)"
        var detail = status
        if let lastRefresh {
            let date = DateFormatter.localizedString(from: lastRefresh, dateStyle: .none, timeStyle: .medium)
            detail += "\n上次更新 \(date) · \(Countdown.format(snapshot?.weekly?.resetsAt))"
        }
        statusLabel?.stringValue = detail
        statusItem.button?.toolTip = "Codex Glass · 本周剩余 \(week)\n\(detail)"
        overlaySwitch?.state = overlayEnabled ? .on : .off
        fiveHourSwitch?.state = overlay.showsFiveHourQuota ? .on : .off
        loginSwitch?.state = SMAppService.mainApp.status == .enabled ? .on : .off
        let opacity = (overlay.backgroundOpacity * 100).rounded()
        opacitySlider?.doubleValue = opacity
        opacityLabel?.stringValue = "\(Int(opacity))%"
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
            let value = NSMenuItem(title: title, action: action, keyEquivalent: key)
            value.target = self
            menu.addItem(value)
            return value
        }
        _ = item("Codex Glass 控制面板…", #selector(showControl))
        menu.addItem(.separator())
        let toggle = item("显示悬浮条", #selector(toggleOverlay))
        toggle.tag = 1
        toggle.state = overlayEnabled ? .on : .off
        let fiveHour = item("显示五小时额度", #selector(toggleFiveHourQuota))
        fiveHour.tag = 3
        fiveHour.state = overlay.showsFiveHourQuota ? .on : .off
        let login = item("登录时启动", #selector(toggleLogin))
        login.tag = 2
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        _ = item("立即刷新额度", #selector(refreshNow))
        _ = item("重置悬浮条位置", #selector(resetPosition))
        menu.addItem(.separator())
        _ = item("退出 Codex Glass", #selector(quit), key: "q")
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.item(withTag: 1)?.state = overlayEnabled ? .on : .off
        menu.item(withTag: 2)?.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.item(withTag: 3)?.state = overlay.showsFiveHourQuota ? .on : .off
    }

    @objc func showControl() {
        if controller == nil { buildControl() }
        updateViews()
        controller?.center()
        controller?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildControl() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 448),
                              styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Codex Glass"
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 448))
        window.contentView = root
        func label(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat,
                   size: CGFloat = 13, weight: NSFont.Weight = .regular) -> NSTextField {
            let field = NSTextField(wrappingLabelWithString: text)
            field.frame = NSRect(x: x, y: y, width: width, height: height)
            field.font = .systemFont(ofSize: size, weight: weight)
            root.addSubview(field)
            return field
        }
        _ = label("Codex Glass", x: 28, y: 387, width: 400, height: 32, size: 25, weight: .semibold)
        let subtitle = label("让剩余额度，一眼可见。", x: 28, y: 361, width: 400, height: 24)
        subtitle.textColor = .secondaryLabelColor
        quotaLabel = label("正在读取额度…", x: 28, y: 322, width: 404, height: 24, size: 14, weight: .medium)

        let enabled = NSButton(checkboxWithTitle: "显示悬浮条（仅在 Codex 运行时）", target: self, action: #selector(toggleOverlay))
        enabled.frame = NSRect(x: 26, y: 279, width: 405, height: 24)
        root.addSubview(enabled)
        overlaySwitch = enabled
        let fiveHour = NSButton(checkboxWithTitle: "显示五小时额度", target: self, action: #selector(toggleFiveHourQuota))
        fiveHour.frame = NSRect(x: 26, y: 249, width: 405, height: 24)
        fiveHour.toolTip = "开启后在浮窗并排显示五小时和本周剩余百分比；关闭后仅显示本周数字。"
        root.addSubview(fiveHour)
        fiveHourSwitch = fiveHour
        let login = NSButton(checkboxWithTitle: "登录 Mac 时自动启动", target: self, action: #selector(toggleLogin))
        login.frame = NSRect(x: 26, y: 217, width: 405, height: 24)
        root.addSubview(login)
        loginSwitch = login
        _ = label("背景不透明度", x: 28, y: 180, width: 220, height: 20)
        opacityLabel = label("", x: 372, y: 180, width: 60, height: 20, weight: .medium)
        opacityLabel?.alignment = .right
        let slider = NSSlider(value: overlay.backgroundOpacity * 100, minValue: 0, maxValue: 100,
                              target: self, action: #selector(changeBackgroundOpacity(_:)))
        slider.frame = NSRect(x: 26, y: 150, width: 408, height: 24)
        slider.isContinuous = true
        slider.setAccessibilityLabel("背景不透明度")
        slider.toolTip = "向左更透明，向右保留更多玻璃效果；数字和进度条保持清晰。"
        root.addSubview(slider)
        opacitySlider = slider
        let opacityHint = label("向左更透明 · 只调整背景，数字保持清晰", x: 28, y: 126,
                                width: 404, height: 18, size: 11)
        opacityHint.textColor = .secondaryLabelColor
        statusLabel = label("", x: 28, y: 75, width: 404, height: 48, size: 11)
        statusLabel?.textColor = .secondaryLabelColor
        let refresh = NSButton(title: "立即刷新", target: self, action: #selector(refreshNow))
        refresh.bezelStyle = .rounded
        refresh.frame = NSRect(x: 22, y: 29, width: 100, height: 32)
        root.addSubview(refresh)
        let reset = NSButton(title: "重置位置", target: self, action: #selector(resetPosition))
        reset.bezelStyle = .rounded
        reset.frame = NSRect(x: 128, y: 29, width: 100, height: 32)
        root.addSubview(reset)
        let footer = label("拖动浮窗移动 · 双击浮窗打开设置", x: 242, y: 33, width: 194, height: 28, size: 10)
        footer.textColor = .tertiaryLabelColor
        controller = window
    }

    @objc private func toggleOverlay() {
        UserDefaults.standard.set(!overlayEnabled, forKey: "overlayEnabled")
        tick()
    }

    @objc private func toggleFiveHourQuota() {
        overlay.setShowsFiveHourQuota(!overlay.showsFiveHourQuota)
        updateViews()
    }

    @objc private func changeBackgroundOpacity(_ sender: NSSlider) {
        let percent = sender.doubleValue.rounded()
        overlay.setBackgroundOpacity(percent / 100)
        opacityLabel?.stringValue = "\(Int(percent))%"
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
                try SMAppService.mainApp.unregister()
                status = "登录时启动已关闭"
            } else {
                try SMAppService.mainApp.register()
                if SMAppService.mainApp.status == .requiresApproval {
                    status = "请在系统设置 → 通用 → 登录项中允许 Codex Glass。"
                    SMAppService.openSystemSettingsLoginItems()
                } else {
                    status = "登录时启动已开启"
                }
            }
        } catch {
            status = "无法修改登录项：\(error.localizedDescription)"
        }
        updateViews()
    }

    @objc private func refreshNow() { nextRefresh = .distantPast; tick() }
    @objc private func resetPosition() { overlay.resetPosition() }
    @objc private func quit() { NSApp.terminate(nil) }
}
