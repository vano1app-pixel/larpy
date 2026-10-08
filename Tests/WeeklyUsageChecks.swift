import Foundation

@main
enum WeeklyUsageChecks {
    static func main() throws {
        let iso = ISO8601DateFormatter()
        func date(_ value: String) -> Date { iso.date(from: value)! }
        let now = date("2026-10-01T20:00:00Z")
        var checked = 0
        func check(_ value: Bool, _ label: String) {
            precondition(value, label); checked += 1
        }
        func row(_ tokens: Int, _ at: String = "2026-09-30T23:00:00Z", _ source: String = "codex") -> UsageDay {
            UsageDay(id: UUID(), source: source, at: date(at), tokens: tokens)
        }
        func snapshot(_ rows: [UsageDay], generated: Date? = nil, sources: [String] = ["codex", "claude-code"], version: Int = 1) -> UsageSnapshot {
            UsageSnapshot(version: version, generatedAt: generated ?? now, sources: sources, days: rows)
        }
        func summary(_ rows: [UsageDay]) -> WeeklyUsageSummary { WeeklyUsageSummary.from(snapshot(rows), now: now)! }
        let week = summary([row(60_000_000), row(6_000_000, "2026-09-29T23:00:00Z", "claude-code")])
        check(week.total == 66_000_000 && week.compact == "66M", "Combined weekly total")
        check(week.bySource["codex"] == 60_000_000, "Source breakdown")
        check(week.sourceLabel == "Codex + Claude Code", "Honest source label")
        check(week.weekStart == date("2026-09-27T23:00:00Z"), "Dublin Monday boundary")
        check(summary([row(50), row(50)]).total == 50, "Repeated records not doubled")
        check(summary([row(50), row(70)]).total == 70, "Cumulative revisions use max")
        check(summary([row(50), row(50, "2026-09-29T23:00:00Z")]).total == 100, "Separate days sum")
        check(summary([row(99, "2026-09-27T22:59:59Z"), row(1, "2026-09-27T23:00:00Z")]).total == 1, "Previous week excluded")
        check(summary([row(-1), row(0), row(10_000_000_001), row(90, "2026-10-02T23:00:00Z"), row(90, "2026-09-30T23:00:00Z", "unknown")]).total == 0, "Invalid rows excluded")
        check(WeeklyUsageSummary.from(snapshot([], sources: []), now: now) == nil, "Missing sources is unknown, not zero")
        check(WeeklyUsageSummary.from(snapshot([], sources: ["web-chat"]), now: now) == nil, "Web chats unsupported")
        check(WeeklyUsageSummary.from(snapshot([], version: 2), now: now) == nil, "Unknown version rejected")
        check(WeeklyUsageSummary.from(snapshot([], generated: now.addingTimeInterval(301)), now: now) == nil, "Future snapshot rejected")
        check(WeeklyUsageSummary.from(snapshot([], generated: date("2026-09-27T22:59:59Z")), now: now) == nil, "Previous-week snapshot shows waiting")
        check(WeeklyUsageSummary.from(snapshot(Array(repeating: row(1), count: 201)), now: now) == nil, "Oversized snapshot rejected")
        check(summary([]).total == 0, "Connected empty source can report zero")
        for (value, expected) in [(999, "999"), (1_000, "1k"), (1_500, "1.5k"), (1_000_000, "1M"), (1_500_000, "1.5M"), (1_000_000_000, "1B")] {
            check(summary([row(value)]).compact == expected, "Compact formatting \(value)")
        }
        check(week.freshness(now: now) == "Updated just now", "Fresh label")
        check(week.freshness(now: now.addingTimeInterval(120)) == "Updated 2m ago", "Minute label")
        check(week.freshness(now: now.addingTimeInterval(960)) == "Saved · 16m ago", "Stale status")
        check(week.freshness(now: now.addingTimeInterval(7200)) == "Saved · 2h ago", "Offline hours")
        check(week.freshness(now: now.addingTimeInterval(86400)) == "Saved · 1d ago", "Offline days")
        let encoded = try JSONEncoder().encode(snapshot([row(123)]))
        let decoded = try JSONDecoder().decode(UsageSnapshot.self, from: encoded)
        check(WeeklyUsageSummary.from(decoded, now: now)?.total == 123, "Cache round trip")
        let winter = date("2026-10-29T20:00:00Z")
        let winterWeek = WeeklyUsageSummary.from(snapshot([], generated: winter), now: winter)!
        check(winterWeek.weekStart == date("2026-10-26T00:00:00Z"), "Winter Dublin boundary")
        print("PASS: \(checked) weekly token checks")
    }
}
