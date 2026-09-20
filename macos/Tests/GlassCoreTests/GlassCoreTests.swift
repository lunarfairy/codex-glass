import Foundation
import Testing
import CoreGraphics
@testable import GlassCore

struct QuotaTests {
    private func parse(_ json: String) throws -> QuotaSnapshot {
        try QuotaSnapshot.parse(JSONSerialization.jsonObject(with: Data(json.utf8)) as! [String: Any])
    }

    @Test func testSelectsCodexBucketAndWindowsByDuration() throws {
        let value = try parse(#"{"result":{"rateLimits":{"primary":{"usedPercent":99,"windowDurationMins":10080}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":61.6,"windowDurationMins":10080,"resetsAt":1787472000},"secondary":{"usedPercent":28.4,"windowDurationMins":300}},"other":{"primary":{"usedPercent":100,"windowDurationMins":10080}}}}}"#)
        #expect(value.weekly?.remainingPercent == 38)
        #expect(value.fiveHour?.remainingPercent == 72)
        #expect(value.weekly?.resetsAt == Date(timeIntervalSince1970: 1787472000))
    }

    @Test func testMissingFiveHourDefaultsToFullForValidQuota() throws {
        let value = try parse(#"{"result":{"rateLimits":{"primary":{"usedPercent":36,"windowDurationMins":10080},"secondary":null}}}"#)
        #expect(value.weekly?.remainingPercent == 64)
        #expect(value.fiveHour?.remainingPercent == 100)
        #expect(value.fiveHour?.filledSegments == 10)
        #expect(value.fiveHour?.resetsAt == nil)
    }

    @Test func testMissingWeeklyStillDisplaysAvailableFiveHour() throws {
        let value = try parse(#"{"result":{"rateLimitsByLimitId":null,"rateLimits":{"primary":{"usedPercent":20,"windowDurationMins":300,"resetsAt":null}}}}"#)
        #expect(value.weekly == nil)
        #expect(value.fiveHour?.remainingPercent == 80)
        #expect(value.fiveHour?.resetsAt == nil)
    }

    @Test func testMalformedAndOtherBucketsAreNotAccepted() {
        for json in [
            #"{"result":{"rateLimits":null}}"#,
            #"{"result":{"rateLimits":{"limitId":"other","primary":{"usedPercent":4,"windowDurationMins":10080}}}}"#,
            #"{"result":{"rateLimits":{"primary":{"usedPercent":null,"windowDurationMins":10080}}}}"#,
            #"{"result":{"rateLimits":{"primary":{"usedPercent":20,"windowDurationMins":15}}}}"#
        ] { #expect(throws: GlassError.self) { try parse(json) } }
    }

    @Test func testClampingAndRounding() throws {
        for (used, remaining) in [(-12.0, 100), (110.0, 0), (23.5, 77)] {
            let value = try parse("{\"result\":{\"rateLimits\":{\"primary\":{\"usedPercent\":\(used),\"windowDurationMins\":10080}}}}")
            #expect(value.weekly?.remainingPercent == remaining)
        }
        #expect(QuotaWindow(remainingPercent: 75, resetsAt: nil).filledSegments == 8)
        #expect(QuotaWindow(remainingPercent: 0, resetsAt: nil).filledSegments == 0)
    }

    @Test func testCountdownBoundaries() {
        let now = Date(timeIntervalSince1970: 1700000000)
        #expect(Countdown.format(nil, now: now) == "重置时间未提供")
        #expect(Countdown.format(now.addingTimeInterval(-1), now: now) == "即将重置")
        #expect(Countdown.format(now.addingTimeInterval(1), now: now) == "0小时 1分后重置")
        #expect(Countdown.format(now.addingTimeInterval(2 * 86400 + 3 * 3600 + 4 * 60), now: now) == "2天 3小时 4分后重置")
    }

    @Test func testVisibilityRequiresDesktopAndEnabledAndAwake() {
        for enabled in [true, false] {
            for running in [true, false] {
                for sleeping in [true, false] {
                    #expect(OverlayPolicy.isVisible(enabled: enabled, desktopRunning: running, sleeping: sleeping)
                            == (enabled && running && !sleeping))
                }
            }
        }
    }

    @Test func testDisconnectedMonitorAndNegativeCoordinates() {
        let main = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let removed = CGRect(x: 2500, y: 1100, width: 184, height: 56)
        let clamped = WindowPlacement.clamped(removed, screens: [main])
        #expect(main.contains(clamped))
        let second = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let onSecond = CGRect(x: -400, y: 700, width: 184, height: 56)
        #expect(WindowPlacement.clamped(onSecond, screens: [main, second]) == onSecond)
    }
}

final class AppServerTests {
    private var directory: URL!
    init() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    deinit { try? FileManager.default.removeItem(at: directory) }

    private func mock(_ script: String) throws -> URL {
        let url = directory.appendingPathComponent("mock-server")
        try ("#!/usr/bin/env python3\n" + script).write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        return url
    }

    @Test func testReadOnlyHandshakeFragmentedResponsesAndNotifications() throws {
        let server = try mock("""
        import sys,json,time
        assert sys.argv[1:4] == ['app-server','--listen','stdio://']
        first=json.loads(input()); assert first['method']=='initialize'
        print(json.dumps({'id':0,'result':{}}),flush=True)
        assert json.loads(input())['method']=='initialized'
        assert json.loads(input())['method']=='account/rateLimits/read'
        print(json.dumps({'method':'account/updated','params':{}}),flush=True)
        response=json.dumps({'id':1,'result':{'rateLimits':{'primary':{'usedPercent':36,'windowDurationMins':10080}}}})+'\\n'
        for part in [response[:20],response[20:]]:
            sys.stdout.write(part);sys.stdout.flush();time.sleep(.01)
        for line in sys.stdin:
            raise AssertionError('unexpected additional request')
        """)
        let result = try AppServerClient(executable: server, timeout: 5).readQuota()
        #expect(result.weekly?.remainingPercent == 64)
        #expect(result.fiveHour?.remainingPercent == 100)
    }

    @Test func testHungServerTimesOutAndIsTerminated() throws {
        let pidFile = directory.appendingPathComponent("pid")
        let server = try mock("""
        import os,time
        open('\(pidFile.path)','w').write(str(os.getpid()))
        time.sleep(60)
        """)
        let start = Date()
        #expect(throws: GlassError.timeout) { try AppServerClient(executable: server, timeout: 2).readQuota() }
        #expect(Date().timeIntervalSince(start) < 5)
        let pid = Int32(try String(contentsOf: pidFile))!
        #expect(kill(pid, 0) == -1)
    }

    @Test func testExitAndRPCErrorAreReportedWithoutRawAccountDetails() throws {
        let closed = try mock("import sys;sys.exit(0)")
        #expect(throws: GlassError.serverClosed) { try AppServerClient(executable: closed, timeout: 3).readQuota() }
        let errorServer = try mock("""
        import json
        input()
        print(json.dumps({'id':0,'error':{'message':'private-account-detail'}}),flush=True)
        input()
        """)
        #expect(throws: GlassError.serverError) { try AppServerClient(executable: errorServer, timeout: 3).readQuota() }
        #expect(!GlassError.serverError.localizedDescription.contains("private-account-detail"))
    }

    @Test func testCancellationStopsInflightServer() async throws {
        let server = try mock("import time;time.sleep(60)")
        let client = AppServerClient(executable: server, timeout: 30)
        let task = Task.detached { try client.readQuota() }
        try await Task.sleep(nanoseconds: 150_000_000)
        client.cancel()
        await #expect(throws: GlassError.self) { try await task.value }
    }

    @Test func testMissingCLIAndPrecancelledRequest() throws {
        #expect(throws: GlassError.cliMissing) { try AppServerClient(executable: nil).readQuota() }
        let server = try mock("raise AssertionError('must never launch')")
        let client = AppServerClient(executable: server)
        client.cancel()
        #expect(throws: GlassError.cancelled) { try client.readQuota() }
    }
}
