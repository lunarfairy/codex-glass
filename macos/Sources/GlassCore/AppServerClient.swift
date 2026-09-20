import Foundation
import Darwin

public enum CodexLocator {
    public static var searchPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let inherited = ProcessInfo.processInfo.environment["PATH"] ?? ""
        return "\(home)/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + inherited
    }

    public static func find() -> URL? {
        let fm = FileManager.default
        #if arch(arm64)
        let target = "aarch64-apple-darwin"
        let package = "codex-darwin-arm64"
        #else
        let target = "x86_64-apple-darwin"
        let package = "codex-darwin-x64"
        #endif
        for directory in searchPath.split(separator: ":") {
            let launcher = URL(fileURLWithPath: String(directory)).appendingPathComponent("codex")
            guard fm.isExecutableFile(atPath: launcher.path) else { continue }
            let resolved = launcher.resolvingSymlinksInPath()
            if resolved.pathExtension == "js" {
                let root = resolved.deletingLastPathComponent().deletingLastPathComponent()
                let vendors = [
                    root.appendingPathComponent("node_modules/@openai/\(package)/vendor"),
                    root.deletingLastPathComponent().appendingPathComponent("\(package)/vendor"),
                    root.appendingPathComponent("vendor")
                ]
                for vendor in vendors {
                    for suffix in ["bin/codex", "codex/codex"] {
                        let native = vendor.appendingPathComponent("\(target)/\(suffix)")
                        if fm.isExecutableFile(atPath: native.path) { return native }
                    }
                }
                // Prefer a native executable, so no launcher subprocess can be orphaned.
                continue
            }
            return resolved
        }
        let home = fm.homeDirectoryForCurrentUser.path
        for base in ["/Applications", "\(home)/Applications"] {
            for name in ["Codex", "ChatGPT"] {
                let bundle = URL(fileURLWithPath: base).appendingPathComponent("\(name).app")
                guard Bundle(url: bundle)?.bundleIdentifier == "com.openai.codex" else { continue }
                let native = bundle.appendingPathComponent("Contents/Resources/codex")
                if fm.isExecutableFile(atPath: native.path) { return native }
            }
        }
        return nil
    }
}

/// A short-lived, read-only stdio connection. It never starts a conversation or reads auth.json.
public final class AppServerClient {
    private let lock = NSLock()
    private var process: Process?
    private var cancelled = false
    private let executable: URL?
    private let timeout: TimeInterval

    public init(executable: URL? = CodexLocator.find(), timeout: TimeInterval = 30) {
        self.executable = executable
        self.timeout = timeout
    }

    public func cancel() {
        lock.lock()
        cancelled = true
        if let process, process.isRunning { process.terminate() }
        lock.unlock()
    }

    public func readQuota() throws -> QuotaSnapshot {
        guard let executable else { throw GlassError.cliMissing }
        let child = Process()
        let input = Pipe()
        let output = Pipe()
        // A server exit between reading and writing must throw EPIPE, not kill the app.
        _ = fcntl(input.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1)
        child.executableURL = executable
        child.arguments = ["app-server", "--listen", "stdio://", "-c", "analytics.enabled=false"]
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = executable.deletingLastPathComponent().path + ":" + CodexLocator.searchPath
        child.environment = environment
        child.currentDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        child.standardInput = input
        child.standardOutput = output
        // Never retain raw server logs: errors may contain account details.
        child.standardError = FileHandle.nullDevice
        lock.lock()
        if cancelled { lock.unlock(); throw GlassError.cancelled }
        do {
            try child.run()
            process = child
            lock.unlock()
        } catch {
            lock.unlock()
            throw GlassError.cliMissing
        }
        defer {
            try? input.fileHandleForWriting.close()
            if child.isRunning { child.terminate() }
            let deadline = ProcessInfo.processInfo.systemUptime + 1
            while child.isRunning && ProcessInfo.processInfo.systemUptime < deadline {
                Thread.sleep(forTimeInterval: 0.01)
            }
            if child.isRunning { kill(child.processIdentifier, SIGKILL) }
            child.waitUntilExit()
            try? output.fileHandleForReading.close()
            lock.lock(); process = nil; lock.unlock()
        }
        let reader = JSONLineReader(handle: output.fileHandleForReading,
                                    timeout: timeout, isCancelled: { [weak self] in
            guard let self else { return true }
            self.lock.lock(); defer { self.lock.unlock() }
            return self.cancelled
        })
        try send([
            "id": 0, "method": "initialize",
            "params": ["clientInfo": ["name": "codex-glass", "title": "Codex Glass", "version": "1.0.3-macos.6"]]
        ], to: input.fileHandleForWriting)
        _ = try reader.response(id: 0)
        try send(["method": "initialized", "params": [:]], to: input.fileHandleForWriting)
        try send(["id": 1, "method": "account/rateLimits/read"], to: input.fileHandleForWriting)
        return try QuotaSnapshot.parse(reader.response(id: 1))
    }

    private func send(_ message: [String: Any], to handle: FileHandle) throws {
        var data = try JSONSerialization.data(withJSONObject: message)
        data.append(0x0a)
        do { try handle.write(contentsOf: data) }
        catch { throw GlassError.serverClosed }
    }
}

final class JSONLineReader {
    private let handle: FileHandle
    private let deadline: TimeInterval
    private let isCancelled: () -> Bool
    private var buffer = Data()

    init(handle: FileHandle, timeout: TimeInterval, isCancelled: @escaping () -> Bool) {
        self.handle = handle
        self.deadline = ProcessInfo.processInfo.systemUptime + timeout
        self.isCancelled = isCancelled
    }

    func response(id: Int) throws -> [String: Any] {
        while true {
            if isCancelled() { throw GlassError.cancelled }
            if ProcessInfo.processInfo.systemUptime >= deadline { throw GlassError.timeout }
            if let newline = buffer.firstIndex(of: 0x0a) {
                let line = buffer[..<newline]
                buffer.removeSubrange(...newline)
                guard let message = try? JSONSerialization.jsonObject(with: line) as? [String: Any] else {
                    throw GlassError.invalidResponse
                }
                guard message["id"] as? Int == id else { continue }
                if message["error"] != nil { throw GlassError.serverError }
                return message
            }
            var descriptor = pollfd(fd: handle.fileDescriptor, events: Int16(POLLIN), revents: 0)
            let result = poll(&descriptor, 1, 100)
            if result < 0 {
                if errno == EINTR { continue }
                throw GlassError.serverClosed
            }
            if result == 0 { continue }
            var bytes = [UInt8](repeating: 0, count: 8192)
            let count = Darwin.read(handle.fileDescriptor, &bytes, bytes.count)
            if count <= 0 { throw GlassError.serverClosed }
            buffer.append(contentsOf: bytes.prefix(count))
            if buffer.count > 2_000_000 { throw GlassError.invalidResponse }
        }
    }
}
