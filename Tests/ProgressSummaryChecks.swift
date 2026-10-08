import Foundation

@main
enum ProgressSummaryChecks {
    static func main() throws {
        var checks = 0
        func check(_ value: Bool, _ reason: String) { precondition(value, reason); checks += 1 }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Dublin")!
        let now = ISO8601DateFormatter().date(from: "2026-10-28T12:00:00Z")!
        func date(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: now)! }
        func work(_ offset: Int, key: String? = nil) -> ProofLog {
            ProofLog(quest: .work, proofKind: .link, value: "https://example.com/finished", progressDay: key, createdAt: date(offset))
        }
        func result(_ logs: [ProofLog], week: Date? = nil) -> ActivityProgressSummary {
            ActivityProgressSummary(logs: logs, weekContaining: week ?? now, calendar: cal, now: now)
        }
        let empty = result([])
        check(empty.activeDays == 0 && empty.history.isEmpty && empty.currentStreak == 0 && empty.bestStreak == 0, "Empty has no invented progress")
        check(ActivityCalendarRules.key(empty.weekStart, calendar: cal) == "2026-10-26", "Week starts Monday")
        check(ActivityCalendarRules.key(empty.weekEnd, calendar: cal) == "2026-11-02", "Week ends exclusively next Monday")
        let continuous = (-5...0).map { work($0) }
        let run = result(continuous)
        check(run.currentStreak == 6 && run.bestStreak == 6, "Consecutive days across DST")
        check(run.activeDays == 3 && run.workDays == 3, "Prior week excluded")
        check(result(Array(continuous.dropLast())).currentStreak == 5, "Yesterday anchors open streak")
        check(result([work(-3), work(-2)]).currentStreak == 0, "Gap ends current streak")
        check(result([work(-3), work(-2)]).bestStreak == 2, "Best survives gap")
        check(result([work(0), work(0), work(-1)]).currentStreak == 2, "Duplicate dates cannot grow streak")
        check(result([work(0), work(0)]).workDays == 1, "Multiple outputs one Work day")
        check(result([work(1)]).activeDays == 0, "Future receipt excluded")
        check(result([work(0, key: "2026-10-29")]).activeDays == 0, "Future saved day excluded")
        check(result([work(0, key: "2026-02-30")]).history.isEmpty, "Invalid date not normalized")
        let tokens = ProofLog(quest: .learn, proofKind: .number, value: "2000000 tok", annotation: "Synced from Codex", source: "codex", createdAt: now)
        check(result([tokens]).history.count == 1, "Token records remain readable")
        check(result([tokens]).learningDays == 0 && result([tokens]).currentStreak == 0, "Tokens do not inflate days")
        let body = ProofLog(quest: .body, proofKind: .number, value: "10m", timerSeconds: 600, createdAt: now)
        let learn = ProofLog(quest: .learn, proofKind: .number, value: "note: Try one idea", annotation: "Test assumptions", createdAt: now)
        let combined = result([body, learn, work(0)])
        check(combined.activeDays == 1 && combined.workDays == 1 && combined.bodyDays == 1 && combined.learningDays == 1, "Three activities one active day")
        check(result([work(-4), work(-1)]).history.first?.id == "2026-10-27", "History newest first")
        check(result(continuous, week: date(-7)).activeDays == 3, "Selected week respected")
        check(result(continuous, week: date(-7)).currentStreak == 6, "Current streak independent of viewed week")
        let travelled = [work(-2, key: "2026-10-27"), work(-1, key: "2026-10-28")]
        var away = cal; away.timeZone = TimeZone(identifier: "Pacific/Honolulu")!
        let awaySummary = ActivityProgressSummary(logs: travelled, weekContaining: now, calendar: away, now: now)
        check(awaySummary.currentStreak == 2 && awaySummary.history.map(\.id) == ["2026-10-28", "2026-10-27"], "Saved dates survive travel")
        let suite = "larpy.progress.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let start = now.addingTimeInterval(-3600)
        var session = FocusSession(task: "QA focus", startedAt: start, endsAt: start.addingTimeInterval(1500), blocksDistractions: true)
        session.breaks = [FocusBreak(reason: "QA break", startedAt: start.addingTimeInterval(300), endsAt: start.addingTimeInterval(600))]
        let interval = DateInterval(start: empty.weekStart, end: empty.weekEnd)
        FocusStorage.write(session, key: FocusStorage.activeKey, to: defaults)
        check(FocusStorage.recordedSeconds(in: interval, from: defaults, now: now) == 1200, "Expired timer counted with break removed")
        FocusStorage.complete(session, to: defaults, now: now)
        check(FocusStorage.recordedSeconds(in: interval, from: defaults, now: now) == 1200, "Completed plus active deduped")
        FocusStorage.write(session, key: FocusStorage.completedPrefix + "duplicate", to: defaults)
        check(FocusStorage.recordedSeconds(in: interval, from: defaults, now: now) == 1200, "Session identity dedupes copies")
        let ongoing = FocusSession(task: "Still working", startedAt: now, endsAt: now.addingTimeInterval(1500), blocksDistractions: false)
        FocusStorage.write(ongoing, key: FocusStorage.activeKey, to: defaults)
        check(FocusStorage.recordedSeconds(in: interval, from: defaults, now: now) == 1200, "Running timer not completed")
        check(FocusStorage.recordedSeconds(in: DateInterval(start: date(-14), end: date(-7)), from: defaults, now: now) == 0, "Focus respects week bounds")
        print("PASS: \(checks) progress summary and weekly focus checks")
    }
}
