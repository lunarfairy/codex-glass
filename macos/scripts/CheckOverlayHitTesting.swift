import AppKit
import GlassCore

// Run in a logged-in macOS desktop session. This renders the real overlay in an
// isolated preferences domain and asks WindowServer where a mouse-down would go.
@main
enum CheckOverlayHitTesting {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        guard let screen = NSScreen.main else {
            fputs("A macOS desktop session is required.\n", stderr)
            exit(2)
        }
        let suite = "io.github.lunarfairy.codex-glass.hit-test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let overlay = OverlayController(defaults: defaults)
        overlay.meter.onHover = nil
        overlay.panel.setFrameOrigin(NSPoint(x: screen.visibleFrame.minX + 40,
                                             y: screen.visibleFrame.maxY - 260))
        overlay.update(snapshot: QuotaSnapshot(
            fiveHour: QuotaWindow(remainingPercent: 100, resetsAt: nil),
            weekly: QuotaWindow(remainingPercent: 70, resetsAt: nil)),
            stale: false, status: "Interaction regression check")
        overlay.panel.orderFrontRegardless()

        // Exercise the low-opacity fallback, both sides of its 5% boundary,
        // and a return from full glass so stale material does not break input.
        let states = [0.0, 0.01, 0.02, 0.03, 0.04, 0.049, 0.05, 0.051, 0.1, 1.0, 0.04, 0.0].flatMap { opacity in
            [false, true].flatMap { expanded in
                [false, true].map { fiveHour in (opacity, expanded, fiveHour) }
            }
        }
        var failures = 0
        var checks = 0
        func runState(_ index: Int) {
            guard index < states.count else {
                overlay.panel.orderOut(nil)
                defaults.removePersistentDomain(forName: suite)
                print("Overlay mouse hit tests: \(checks - failures)/\(checks) passed")
                exit(failures == 0 ? 0 : 1)
            }
            let (opacity, expanded, fiveHour) = states[index]
            overlay.setBackgroundOpacity(opacity)
            overlay.setExpanded(expanded)
            overlay.setShowsFiveHourQuota(fiveHour)
            overlay.panel.display()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                var points = [NSPoint(x: 92, y: 12), NSPoint(x: 92, y: 42),
                              NSPoint(x: 10, y: 28), NSPoint(x: 174, y: 28)]
                if expanded { points += [NSPoint(x: 92, y: 61), NSPoint(x: 20, y: 73)] }
                for point in points {
                    let screenPoint = overlay.panel.convertPoint(toScreen: overlay.meter.convert(point, to: nil))
                    let hit = NSWindow.windowNumber(at: screenPoint, belowWindowWithWindowNumber: 0)
                    checks += 1
                    if hit != overlay.panel.windowNumber {
                        failures += 1
                        print("FAIL opacity=\(opacity) expanded=\(expanded) fiveHour=\(fiveHour) point=\(point)")
                    }
                }
                if opacity < 0.05 {
                    // Keep the empty corners outside the capsule click-through.
                    for point in [NSPoint(x: 1, y: 1), NSPoint(x: 183, y: 1)] {
                        let screenPoint = overlay.panel.convertPoint(toScreen: overlay.meter.convert(point, to: nil))
                        checks += 1
                        if NSWindow.windowNumber(at: screenPoint, belowWindowWithWindowNumber: 0) == overlay.panel.windowNumber {
                            failures += 1
                            print("FAIL transparent corner intercepted mouse at \(point)")
                        }
                    }
                }
                runState(index + 1)
            }
        }
        DispatchQueue.main.async { runState(0) }
        app.run()
    }
}
