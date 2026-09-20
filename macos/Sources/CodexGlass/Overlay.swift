import AppKit
import GlassCore

final class GlassPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class MeterView: NSView {
    var snapshot: QuotaSnapshot?
    var expanded = false
    var showsFiveHourQuota = true
    var surfaceOpacity: CGFloat = 0.01
    var stale = false
    var status = "正在读取 Codex 额度…"
    var onHover: ((Bool) -> Void)?
    var onMoved: (() -> Void)?
    var onControl: (() -> Void)?
    var contextMenu: (() -> NSMenu)?
    private var tracking: NSTrackingArea?
    private var dragEndTimer: Timer?
    private(set) var isDragging = false
    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(area)
        tracking = area
    }

    override func mouseEntered(with event: NSEvent) { if !isDragging { onHover?(true) } }
    override func mouseMoved(with event: NSEvent) { if !isDragging { onHover?(true) } }
    override func mouseExited(with event: NSEvent) { if !isDragging { onHover?(false) } }
    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 { onControl?(); return }
        guard let window else { return }
        isDragging = true
        // Native dragging returns immediately and may consume mouseUp. Keep the
        // hover size stable until the button is released, then clamp and save.
        dragEndTimer?.invalidate()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            if NSEvent.pressedMouseButtons & 1 == 0 { self?.finishDragging() }
        }
        dragEndTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        window.performDrag(with: event)
    }
    override func mouseUp(with event: NSEvent) { finishDragging() }
    override func rightMouseDown(with event: NSEvent) {
        if let menu = contextMenu?() { NSMenu.popUpContextMenu(menu, with: event, for: self) }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // WindowServer passes mouse-downs through alpha-zero pixels. Retain a
        // barely visible capsule even when the user hides the glass backdrop.
        // At very low opacity this also provides a plain, noise-free backdrop;
        // the native glass material is hidden instead of being faded near zero.
        NSColor.white.withAlphaComponent(surfaceOpacity).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 28, yRadius: 28).fill()
        let ink = NSColor(srgbRed: 0.09, green: 0.13, blue: 0.20, alpha: 1)
        let track = ink.withAlphaComponent(0.13)
        let green = NSColor(srgbRed: 0.24, green: 0.68, blue: 0.42, alpha: 0.86)
        let blue = NSColor(srgbRed: 0.31, green: 0.50, blue: 0.95, alpha: 0.85)
        let filled = snapshot?.fiveHour?.filledSegments ?? 0
        for index in 0..<10 {
            (index < filled ? green : track).setFill()
            NSBezierPath(roundedRect: NSRect(x: 19 + Double(index) * 14.8, y: 7, width: 12.8, height: 2.5),
                         xRadius: 1.25, yRadius: 1.25).fill()
        }
        let percent = snapshot?.weekly.map { "\($0.remainingPercent)%" } ?? "—"
        if showsFiveHourQuota {
            let five = snapshot?.fiveHour.map { "\($0.remainingPercent)%" } ?? "—"
            text("5 H", rect: NSRect(x: 19, y: 14, width: 64, height: 11),
                 font: .systemFont(ofSize: 7.5, weight: .semibold), color: ink.withAlphaComponent(0.58))
            text("W E E K", rect: NSRect(x: 101, y: 14, width: 64, height: 11),
                 font: .systemFont(ofSize: 7.5, weight: .semibold), color: ink.withAlphaComponent(0.58), align: .right)
            text(five, rect: NSRect(x: 19, y: 22, width: 68, height: 24),
                 font: .monospacedDigitSystemFont(ofSize: 20, weight: .semibold), color: ink)
            text(percent, rect: NSRect(x: 97, y: 22, width: 68, height: 24),
                 font: .monospacedDigitSystemFont(ofSize: 20, weight: .semibold), color: ink, align: .right)
            track.setFill()
            NSRect(x: 92, y: 18, width: 0.5, height: 23).fill()
        } else {
            text("W E E K", rect: NSRect(x: 19, y: 25, width: 60, height: 15),
                 font: .systemFont(ofSize: 8.5, weight: .semibold), color: ink.withAlphaComponent(0.58))
            text(percent, rect: NSRect(x: 70, y: 11, width: 95, height: 35),
                 font: .monospacedDigitSystemFont(ofSize: 28, weight: .semibold), color: ink, align: .right)
        }
        if stale {
            NSColor.systemOrange.setFill()
            NSBezierPath(ovalIn: NSRect(x: showsFiveHourQuota ? 90 : 67, y: 28, width: 4, height: 4)).fill()
        }
        track.setFill()
        NSBezierPath(roundedRect: NSRect(x: 19, y: 47, width: 146, height: 2.5), xRadius: 1.25, yRadius: 1.25).fill()
        if let weekly = snapshot?.weekly {
            blue.setFill()
            NSBezierPath(roundedRect: NSRect(x: 19, y: 47, width: 146 * Double(weekly.remainingPercent) / 100, height: 2.5),
                         xRadius: 1.25, yRadius: 1.25).fill()
        }
        if expanded {
            track.setFill()
            NSRect(x: 19, y: 57, width: 146, height: 0.5).fill()
            let label = snapshot == nil ? "双击查看连接状态" : Countdown.format(snapshot?.weekly?.resetsAt)
            text(label, rect: NSRect(x: 8, y: 65, width: 168, height: 16),
                 font: .systemFont(ofSize: 10.5), color: ink.withAlphaComponent(0.72), align: .center)
        }
    }

    private func finishDragging() {
        guard isDragging else { return }
        dragEndTimer?.invalidate()
        dragEndTimer = nil
        isDragging = false
        onMoved?()
        if let window {
            let point = convert(window.mouseLocationOutsideOfEventStream, from: nil)
            onHover?(bounds.contains(point))
        }
    }

    deinit { dragEndTimer?.invalidate() }

    private func text(_ value: String, rect: NSRect, font: NSFont, color: NSColor,
                      align: NSTextAlignment = .left) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = align
        (value as NSString).draw(in: rect, withAttributes: [
            .font: font, .foregroundColor: color, .paragraphStyle: paragraph
        ])
    }
}

final class OverlayController: NSObject, NSWindowDelegate {
    let panel: GlassPanel
    let meter = MeterView(frame: NSRect(x: 0, y: 0, width: 184, height: 56))
    private let defaults: UserDefaults
    private var backgroundView: NSView!
    private var expanding = false

    var backgroundOpacity: Double {
        let saved = defaults.object(forKey: "backgroundOpacity") as? Double ?? 1
        return saved.isFinite ? min(1, max(0, saved)) : 1
    }

    var showsFiveHourQuota: Bool {
        defaults.object(forKey: "showFiveHourQuota") as? Bool ?? true
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        panel = GlassPanel(contentRect: NSRect(x: 0, y: 0, width: 184, height: 56),
                          styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        super.init()
        panel.title = "Codex Glass 悬浮条"
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.delegate = self
        meter.autoresizingMask = [.width, .height]
        meter.showsFiveHourQuota = showsFiveHourQuota
        meter.setAccessibilityElement(true)
        meter.setAccessibilityRole(.group)
        meter.setAccessibilityLabel("Codex 剩余额度，拖动调整位置，双击打开控制面板")
        let container = NSView(frame: meter.frame)
        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView(frame: meter.frame)
            glass.style = .clear
            glass.cornerRadius = 28
            glass.appearance = NSAppearance(named: .aqua)
            // Keep the meter in a separate sibling so backdrop opacity never fades text.
            glass.contentView = NSView(frame: meter.frame)
            backgroundView = glass
        } else {
            let effect = NSVisualEffectView(frame: meter.frame)
            effect.material = .underWindowBackground
            effect.blendingMode = .behindWindow
            effect.state = .active
            effect.appearance = NSAppearance(named: .aqua)
            effect.wantsLayer = true
            effect.layer?.cornerRadius = 28
            effect.layer?.masksToBounds = true
            effect.layer?.borderWidth = 0.75
            effect.layer?.borderColor = NSColor.white.withAlphaComponent(0.5).cgColor
            backgroundView = effect
        }
        backgroundView.autoresizingMask = [.width, .height]
        container.addSubview(backgroundView)
        container.addSubview(meter, positioned: .above, relativeTo: backgroundView)
        panel.contentView = container
        applyBackgroundOpacity()
        meter.onHover = { [weak self] expanded in self?.setExpanded(expanded) }
        meter.onMoved = { [weak self] in self?.clampToScreen(); self?.savePosition() }
        restorePosition()
    }

    func setBackgroundOpacity(_ value: Double) {
        guard value.isFinite else { return }
        defaults.set(min(1, max(0, value)), forKey: "backgroundOpacity")
        applyBackgroundOpacity()
    }

    func setShowsFiveHourQuota(_ enabled: Bool) {
        defaults.set(enabled, forKey: "showFiveHourQuota")
        meter.showsFiveHourQuota = enabled
        meter.needsDisplay = true
    }

    private func applyBackgroundOpacity() {
        let opacity = backgroundOpacity
        // Fading the native glass into 0–4% produces visible stippling on macOS.
        // Use a plain translucent capsule there, retaining the 1% input floor.
        let usesGlass = opacity >= 0.05
        if #available(macOS 26.0, *) {
            backgroundView.alphaValue = opacity
        } else {
            backgroundView.alphaValue = opacity * 0.48
        }
        backgroundView.isHidden = !usesGlass
        meter.surfaceOpacity = usesGlass ? 0.01 : max(0.01, opacity)
        meter.needsDisplay = true
        panel.hasShadow = usesGlass
        panel.invalidateShadow()
    }

    func update(snapshot: QuotaSnapshot?, stale: Bool, status: String) {
        meter.snapshot = snapshot
        meter.stale = stale
        meter.status = status
        let five = snapshot?.fiveHour.map { "\($0.remainingPercent)%" } ?? "账户未提供"
        let week = snapshot?.weekly.map { "\($0.remainingPercent)%" } ?? "账户未提供"
        meter.toolTip = "五小时剩余：\(five)\n本周剩余：\(week)\n\(status)\n拖动移动 · 双击设置 · 右键菜单"
        let visibleQuota = showsFiveHourQuota
            ? "五小时剩余 \(five)，本周剩余 \(week)"
            : "本周剩余 \(week)"
        meter.setAccessibilityValue("\(visibleQuota)。\(status)")
        meter.needsDisplay = true
    }

    func setExpanded(_ expanded: Bool) {
        guard !meter.isDragging, meter.expanded != expanded else { return }
        expanding = true
        meter.expanded = expanded
        let height: CGFloat = expanded ? 88 : 56
        var frame = panel.frame
        frame.origin.y = frame.maxY - height
        frame.size.height = height
        panel.setFrame(frame, display: true)
        meter.needsDisplay = true
        expanding = false
    }

    func restorePosition() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let x = defaults.object(forKey: "overlayX") as? Double ?? screen.maxX - 208
        let top = defaults.object(forKey: "overlayTop") as? Double ?? screen.maxY - 80
        panel.setFrameOrigin(NSPoint(x: x, y: top - panel.frame.height))
        clampToScreen()
    }

    func resetPosition() {
        defaults.removeObject(forKey: "overlayX")
        defaults.removeObject(forKey: "overlayTop")
        restorePosition()
        savePosition()
    }

    func clampToScreen() {
        panel.setFrame(WindowPlacement.clamped(panel.frame, screens: NSScreen.screens.map(\.visibleFrame)), display: true)
    }

    func savePosition() {
        defaults.set(panel.frame.minX, forKey: "overlayX")
        defaults.set(panel.frame.maxY, forKey: "overlayTop")
    }

    func windowDidMove(_ notification: Notification) { if !expanding { savePosition() } }
}
