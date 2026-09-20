import Foundation
import CoreGraphics

public struct QuotaWindow: Equatable, Codable {
    public let remainingPercent: Int
    public let resetsAt: Date?

    public init(remainingPercent: Int, resetsAt: Date?) {
        self.remainingPercent = min(100, max(0, remainingPercent))
        self.resetsAt = resetsAt
    }

    public var filledSegments: Int { Int((Double(remainingPercent) / 10).rounded()) }
}

public struct QuotaSnapshot: Equatable, Codable {
    public let fiveHour: QuotaWindow?
    public let weekly: QuotaWindow?

    public init(fiveHour: QuotaWindow?, weekly: QuotaWindow?) {
        self.fiveHour = fiveHour
        self.weekly = weekly
    }

    public static func parse(_ response: [String: Any]) throws -> QuotaSnapshot {
        guard let result = response["result"] as? [String: Any] else {
            throw GlassError.invalidResponse
        }
        let byID = result["rateLimitsByLimitId"] as? [String: Any]
        let legacy = result["rateLimits"] as? [String: Any]
        // Never substitute another model's bucket for the core Codex quota.
        let selected = byID?["codex"] as? [String: Any]
        let limits = selected ?? legacy.flatMap { value in
            let id = value["limitId"] as? String
            return id == nil || id == "codex" ? value : nil
        }
        guard let limits else { throw GlassError.noQuota }

        var fiveHour: QuotaWindow?
        var weekly: QuotaWindow?
        for key in ["primary", "secondary"] {
            guard let window = limits[key] as? [String: Any],
                  let duration = window["windowDurationMins"] as? Int,
                  let used = window["usedPercent"] as? Double, used.isFinite else { continue }
            let remaining = Int(min(100, max(0, 100 - used)).rounded())
            let reset = (window["resetsAt"] as? Double).flatMap { value in
                value.isFinite ? Date(timeIntervalSince1970: value) : nil
            }
            let quota = QuotaWindow(remainingPercent: remaining, resetsAt: reset)
            if duration == 300 { fiveHour = quota }
            if duration == 10080 { weekly = quota }
        }
        guard fiveHour != nil || weekly != nil else { throw GlassError.noQuota }
        // A valid quota response without a five-hour window uses the full meter.
        // Keep the guard above: an unavailable account must not appear fully available.
        return QuotaSnapshot(fiveHour: fiveHour ?? QuotaWindow(remainingPercent: 100, resetsAt: nil),
                             weekly: weekly)
    }
}

public enum GlassError: Error, LocalizedError, Equatable {
    case cliMissing, invalidResponse, noQuota, timeout, serverClosed, serverError, cancelled

    public var errorDescription: String? {
        switch self {
        case .cliMissing: return "未找到 Codex CLI，请先安装并登录 Codex。"
        case .invalidResponse: return "Codex 返回的数据无法识别。"
        case .noQuota: return "账户未返回五小时或周额度，请确认已通过 ChatGPT 登录。"
        case .timeout: return "读取超时，请检查 Codex 的网络连接。"
        case .serverClosed: return "Codex 连接已中断，稍后自动重试。"
        case .serverError: return "无法读取额度，请检查 Codex CLI 的登录状态与网络连接。"
        case .cancelled: return "读取已取消。"
        }
    }
}

public enum Countdown {
    public static func format(_ reset: Date?, now: Date = Date()) -> String {
        guard let reset else { return "重置时间未提供" }
        let seconds = reset.timeIntervalSince(now)
        if seconds <= 0 { return "即将重置" }
        let minutes = Int(ceil(min(seconds, 315360000) / 60))
        let days = minutes / 1440
        let hours = minutes % 1440 / 60
        let remainder = minutes % 60
        if days > 0 { return "\(days)天 \(hours)小时 \(remainder)分后重置" }
        return "\(hours)小时 \(remainder)分后重置"
    }
}

public enum OverlayPolicy {
    public static func isVisible(enabled: Bool, desktopRunning: Bool, sleeping: Bool) -> Bool {
        enabled && desktopRunning && !sleeping
    }
}

public enum WindowPlacement {
    public static func clamped(_ frame: CGRect, screens: [CGRect]) -> CGRect {
        guard !screens.isEmpty else { return frame }
        // A disconnected monitor must not leave the overlay off screen.
        let screen = screens.max { lhs, rhs in
            intersectionArea(frame, lhs) < intersectionArea(frame, rhs)
        } ?? screens[0]
        var result = frame
        result.origin.x = min(max(frame.minX, screen.minX), max(screen.minX, screen.maxX - frame.width))
        result.origin.y = min(max(frame.minY, screen.minY), max(screen.minY, screen.maxY - frame.height))
        return result
    }

    private static func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let value = lhs.intersection(rhs)
        return value.isNull ? 0 : value.width * value.height
    }
}
