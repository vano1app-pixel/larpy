import Foundation

var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ label: String) { precondition(condition(), label); checks += 1 }
var cal = LarpSnapshot.utc
cal.timeZone = TimeZone(identifier: "Europe/Dublin")!
let now = ISO8601DateFormatter().date(from: "2026-10-01T12:00:00Z")!
func log(_ lane: QuestKind, daysAgo: Int = 0) -> ProofLog {
    ProofLog(quest: lane, proofKind: lane == .body ? .number : .link, value: lane == .body ? "workout" : "https://example.com/proof", annotation: lane == .learn ? "A useful takeaway" : nil,
             timerSeconds: lane == .body ? 600 : nil, createdAt: cal.date(byAdding: .day, value: -daysAgo, to: now)!)
}
let blank = LarpProgress.earned([], calendar: cal, now: now)
check(blank.level == 1 && blank.remaining == 100, "Empty account begins level one, not zero")
let all = QuestKind.allCases.map { log($0) }
let day = LarpProgress.earned(all, calendar: cal, now: now)
check(day.xp == 50 && day.intoLevel == 50, "Three qualifying lanes award exactly fifty")
check(LarpProgress.earned(Array(repeating: log(.work), count: 40), calendar: cal, now: now).xp == 30, "Duplicates cannot farm XP")
check(LarpProgress.earned([log(.work)], calendar: cal, now: now).xp == 30, "Work carries three times the XP")
check(LarpProgress.earned([log(.body)], calendar: cal, now: now).xp == 10, "Body evidence gives ten")
check(LarpProgress.earned([log(.learn)], calendar: cal, now: now).xp == 10, "Learning takeaway gives ten")
let twoDays = all + QuestKind.allCases.map { log($0, daysAgo: 1) }
let levelTwo = LarpProgress.earned(twoDays, calendar: cal, now: now)
check(levelTwo.level == 2 && levelTwo.intoLevel == 0 && levelTwo.remaining == 100, "Exact hundred rolls over to new level")
let eighteenDays = (0..<18).flatMap { offset in QuestKind.allCases.map { log($0, daysAgo: offset) } }
check(LarpProgress.earned(eighteenDays, calendar: cal, now: now).level == 10, "Eighteen complete days earn level ten")
check(LarpProgress.earned(eighteenDays, calendar: cal, now: now.addingTimeInterval(86400 * 30)).level == 10, "Inactivity does not decay levels")
var future = log(.work); future.createdAt = now.addingTimeInterval(1)
check(LarpProgress.earned([future], calendar: cal, now: now).xp == 0, "Future evidence rejected")
future = log(.work); future.progressDay = "2026-10-02"
check(LarpProgress.earned([future], calendar: cal, now: now).xp == 0, "Future saved dates cannot earn XP early")
future.progressDay = "2026-02-30"
check(LarpProgress.earned([future], calendar: cal, now: now).xp == 0, "Invalid calendar dates rejected")
let usage = ProofLog(quest: .learn, proofKind: .number, value: "50000000 tok", annotation: "usage", source: "codex", createdAt: now)
check(LarpProgress.earned([usage], calendar: cal, now: now).xp == 0, "Spending tokens does not buy XP")
var short = log(.body); short.timerSeconds = 599
check(LarpProgress.earned([short], calendar: cal, now: now).xp == 0, "Under ten minutes cannot earn Body XP")
var bookmark = log(.learn); bookmark.annotation = nil
check(LarpProgress.earned([bookmark], calendar: cal, now: now).xp == 0, "A bookmark without a takeaway cannot earn XP")
var savedDay = log(.work); savedDay.progressDay = "2026-09-30"
var travelled = cal; travelled.timeZone = TimeZone(identifier: "Pacific/Honolulu")!
check(LarpProgress.earned([savedDay], calendar: cal, now: now) == LarpProgress.earned([savedDay], calendar: travelled, now: now), "Saved day identity survives travel")
let ownID = UUID()
let mine = LarpSnapshot.make(id: ownID, name: "You", logs: twoDays, calendar: cal, now: now)
check(mine.valid(now: now), "Real profile export validates")
check(mine.weekStart == "2026-09-28" && mine.weekEnd == "2026-10-04", "Monday to Sunday inclusive")
let encoded = try JSONEncoder().encode(mine)
let restored = try JSONDecoder().decode(LarpSnapshot.self, from: encoded)
check(restored == mine, "Snapshot round trip preserves progress")
check(!String(data: encoded, encoding: .utf8)!.contains("example.com"), "Export never includes proof contents")
var friend = LarpSnapshot.make(id: UUID(), name: "QA friend", logs: eighteenDays, calendar: cal, now: now)
check(friend.valid(now: now), "Level ten export validates")
let added = try LarpLeague.merge(friend, into: [], ownID: ownID, now: now)
check(added.count == 1, "Friend imported")
let weekly = LarpLeague.standings(mine: mine, friends: added, period: .week, now: now)
check(weekly[0].id == friend.id && weekly[0].score == 200 && weekly[1].score == 100, "Weekly ranking uses same period, not lifetime XP")
let lifetime = LarpLeague.standings(mine: mine, friends: added, period: .lifetime, now: now)
check(lifetime[0].score == 900 && lifetime[0].snapshot.progress.level == 10, "Level board ranks lifetime XP")
var tie = mine; tie.id = UUID(); tie.name = "QA tie"
let tied = LarpLeague.standings(mine: mine, friends: [tie], period: .week, now: now)
check(tied.allSatisfy { $0.rank == 1 }, "Equal XP shares rank")
let lastWeek = LarpSnapshot.make(id: UUID(), name: "QA older", logs: [], calendar: cal, now: now.addingTimeInterval(-86400 * 7))
check(LarpLeague.standings(mine: mine, friends: [lastWeek], period: .week, now: now).count == 1, "Old week excluded")
check(LarpLeague.standings(mine: mine, friends: [lastWeek], period: .lifetime, now: now).count == 2, "Old snapshot remains visible in lifetime board")
func rejects(_ item: LarpSnapshot, saved: [LarpSnapshot] = [], _ expected: LarpLeague.ImportError) -> Bool {
    do { _ = try LarpLeague.merge(item, into: saved, ownID: ownID, now: now); return false }
    catch let error as LarpLeague.ImportError { return error == expected }
    catch { return false }
}
check(rejects(mine, .own), "Own file cannot become a rival")
check(rejects(friend, saved: added, .older), "Same snapshot cannot duplicate a friend")
var older = friend; older.generatedAt = now.addingTimeInterval(-3600)
check(rejects(older, saved: added, .older), "Older snapshot cannot overwrite newer data")
friend.generatedAt = now.addingTimeInterval(60)
let replaced = try LarpLeague.merge(friend, into: added, ownID: ownID, now: now)
check(replaced.count == 1, "New snapshot replaces friend instead of duplicating")
var bad = friend; bad.weekDays["Work"] = 5
check(!bad.valid(now: now), "Thursday cannot claim five Work days this week")
bad = friend; bad.lifetimeDays["Work"] = -1
check(!bad.valid(now: now), "Negative days rejected")
bad = friend; bad.lifetimeDays["Work"] = Int.max
check(!bad.valid(now: now), "Huge imported totals rejected without overflow")
bad = friend; bad.lifetimeDays["Fake"] = 1
check(!bad.valid(now: now), "Unknown lanes rejected")
bad = friend; bad.weekEnd = "2026-10-05"
check(!bad.valid(now: now), "Eight-day comparison windows rejected")
bad = friend; bad.timeZoneID = "Fake/Zone"
check(!bad.valid(now: now), "Unparseable time zones rejected")
bad = friend; bad.generatedAt = now.addingTimeInterval(121)
check(!bad.valid(now: now), "Future snapshot beyond clock tolerance rejected")
bad = friend; bad.name = "Name\nFake ranking"
check(!bad.valid(now: now), "Control characters cannot spoof leaderboard lines")
check(LarpLeague.standings(mine: mine, friends: [friend, friend, mine, bad], period: .week, now: now).count == 2, "Invalid, duplicate and own snapshots filtered")
check(CompanionRecognition.greeting(logs: [log(.work)], calendar: cal, now: now) == "Your first Work day. Our first win.", "First work recognition is evidence based")
check(CompanionRecognition.greeting(logs: all, calendar: cal, now: now) == "Three promises kept. Look at us.", "Complete day gets a specific acknowledgement")
check(CompanionRecognition.greeting(logs: [log(.work, daysAgo: 3)], calendar: cal, now: now) == "Good to have you back. Start small.", "Return after a gap is welcoming")
check(CompanionRecognition.greeting(logs: [], calendar: cal, now: now) == nil, "New users never get invented history")
check(CompanionRecognition.greeting(logs: [usage], calendar: cal, now: now) == nil, "Token usage never creates a false work win")
print("PASS: \(checks) level and leaderboard checks")
