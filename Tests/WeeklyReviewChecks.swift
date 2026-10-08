import Foundation

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Europe/Dublin")!
func date(_ stamp: String) -> Date { ISO8601DateFormatter().date(from: stamp)! }
let now = date("2026-10-06T13:00:00Z")
func work(_ stamp: String, day: String? = nil) -> ProofLog {
    ProofLog(quest: .work, proofKind: .link, value: "https://example.com/result", progressDay: day, createdAt: date(stamp))
}
var count = 0
func check(_ condition: @autoclosure () -> Bool, _ detail: String) {
    precondition(condition(), detail); count += 1
}
let empty = WeeklyReviewSummary(logs: [], weekContaining: now, calendar: calendar, now: now)
check(empty.daysIncluded == 2, "Current week compares Monday and Tuesday only")
check(empty.activeDays == 0 && !empty.hasEarlierActivity, "Empty weeks do not invent progress")
check(empty.headline.contains("first week"), "No fabricated growth without a baseline")
let logs = [work("2026-10-05T12:00:00Z"), work("2026-10-05T14:00:00Z"),
            work("2026-09-28T12:00:00Z"), work("2026-09-29T12:00:00Z"), work("2026-10-02T12:00:00Z"),
            work("2026-10-07T12:00:00Z")]
let current = WeeklyReviewSummary(logs: logs, weekContaining: now, calendar: calendar, now: now)
check(current.activeDays == 1, "Duplicate same-day receipts count once, future logs excluded")
check(current.previousActiveDays == 2, "Last Friday must not be compared with this unfinished Tuesday")
check(current.headline == "1 day fewer than last week.", "Difference describes recorded days only")
check(current.lanes.first?.current == 1, "Work count uses distinct recorded days")
let first = WeeklyReviewSummary(logs: [work("2026-10-05T12:00:00Z")], weekContaining: now, calendar: calendar, now: now)
check(!first.hasEarlierActivity && first.headline.contains("first week"), "First use isn't shown as infinite growth")
let previous = WeeklyReviewSummary(logs: logs, weekContaining: date("2026-09-29T12:00:00Z"), calendar: calendar, now: now)
check(previous.daysIncluded == 7 && previous.activeDays == 3, "Completed weeks compare all seven days")
let imported = WeeklyReviewSummary(logs: [work("2026-10-06T12:00:00Z", day: "2026-09-28")], weekContaining: now, calendar: calendar, now: now)
check(imported.activeDays == 0 && imported.previousActiveDays == 1, "An imported receipt keeps its original date")
let invalid = WeeklyReviewSummary(logs: [work("2026-10-05T12:00:00Z", day: "2026-02-31")], weekContaining: now, calendar: calendar, now: now)
check(invalid.activeDays == 0 && !invalid.hasEarlierActivity, "Invalid stored calendar dates are excluded")
let unproven = ProofLog(quest: .work, proofKind: .number, value: "I worked", createdAt: now)
let noProof = WeeklyReviewSummary(logs: [unproven], weekContaining: now, calendar: calendar, now: now)
check(noProof.activeDays == 0, "Unproven work does not become activity through a review")
print("PASS: \(count) weekly-review calendar and evidence checks")
