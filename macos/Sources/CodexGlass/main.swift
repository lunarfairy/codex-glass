import AppKit
import GlassCore
import ServiceManagement

if CommandLine.arguments.contains("--quit") {
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: "io.github.lunarfairy.codex-glass")
        .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
    for app in running { app.terminate() }
    let deadline = Date().addingTimeInterval(5)
    while running.contains(where: { !$0.isTerminated }) && Date() < deadline {
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }
    exit(running.contains(where: { !$0.isTerminated }) ? 1 : 0)
}

// Diagnostics print only percentages and dates; never credentials or raw server responses.
if CommandLine.arguments.contains("--check") {
    do {
        let snapshot = try AppServerClient().readQuota()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        print(String(decoding: data, as: UTF8.self))
        exit(0)
    } catch {
        fputs("Codex Glass: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}
if CommandLine.arguments.contains("--disable-login") {
    do {
        if SMAppService.mainApp.status != .notRegistered { try SMAppService.mainApp.unregister() }
        exit(0)
    } catch { fputs("\(error.localizedDescription)\n", stderr); exit(1) }
}

// Launch Services normally handles this; direct executable launches are protected too.
let app = NSApplication.shared
let identifier = Bundle.main.bundleIdentifier ?? "io.github.lunarfairy.codex-glass"
let others = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
    .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
if let existing = others.first, let url = existing.bundleURL {
    NSWorkspace.shared.openApplication(at: url, configuration: .init()) { _, _ in exit(0) }
    RunLoop.main.run()
    exit(0)
}
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
