import Foundation

var checked = 0
func check(_ condition: @autoclosure () -> Bool, _ label: String) { precondition(condition(), label); checked += 1 }
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Europe/Dublin")!
let now = ISO8601DateFormatter().date(from: "2026-10-28T12:00:00Z")!
func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: now)! }
let first = ProofLog(quest: .body, proofKind: .number, value: "10m", timerSeconds: 600, createdAt: day(-4))
let logs = [first]
func status(_ offset: Int, _ values: [ProofLog] = logs) -> ActivityCalendarRules.Status {
    ActivityCalendarRules.status(on: day(offset), logs: values, calendar: calendar, now: now)
}
check(status(0) == .open, "Today never becomes missed while still open")
check(status(1) == .future, "Future dates cannot be missed")
check(status(-5) == .beforeStart, "No missed days before first activity")
check(status(-3) == .missed, "A past gap after first activity is missed")
check(status(-4) == .active(1), "First day counts across DST boundary")
check(status(-4, [first, first]) == .active(1), "Duplicate lane does not inflate daily completion")
check(status(-1, []) == .beforeStart, "New user has no missed days")
let tokens = ProofLog(quest: .learn, proofKind: .number, value: "1000 tok", createdAt: day(-1))
check(status(-1, logs + [tokens]) == .missed, "Token usage cannot fill a day")
var travel = first
travel.progressDay = ActivityCalendarRules.key(day(-2), calendar: calendar)
check(status(-2, [travel]) == .active(1), "Persisted local day identity survives travel")
check(status(-4, [travel]) == .beforeStart, "Travel does not fill two dates")
let work = ProofLog(quest: .work, proofKind: .link, value: "https://example.com", createdAt: day(-4))
check(status(-4, logs + [work]) == .active(2), "Two different activities are counted")
check(status(1, [ProofLog(quest: .work, proofKind: .link, value: "https://example.com", createdAt: day(1))]) == .future, "Future-dated receipt cannot fill a date")
check(ActivityCalendarRules.status(on: day(-4), logs: logs + [work], calendar: calendar, now: now, lane: .work) == .active(1), "Lane filter counts only that activity")
check(ActivityCalendarRules.status(on: day(-4), logs: logs, calendar: calendar, now: now, lane: .work) == .missed, "A Body day is a gap in the Work view")
check(ActivityCalendarRules.status(on: now, logs: logs, calendar: calendar, now: now, lane: .work) == .open, "Filtered today stays open")
print("Passed \(checked) calendar checks")
