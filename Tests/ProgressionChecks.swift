import Foundation

var checked = 0
func check(_ condition: @autoclosure () -> Bool, _ label: String) { precondition(condition(), label); checked += 1 }
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "Europe/Dublin")!
let now = ISO8601DateFormatter().date(from: "2026-10-28T12:00:00Z")!
func day(_ n: Int) -> Date { calendar.date(byAdding: .day, value: -n, to: now)! }
func workout(_ n: Int, seconds: Int = 600) -> ProofLog {
    ProofLog(quest: .body, proofKind: .number, value: "workout", timerSeconds: seconds, createdAt: day(n))
}
let ten = (0..<10).map { workout($0) }
check(ProgressRules.days(.body, logs: ten, calendar: calendar, now: now) == 10, "Ten dates including DST transition are ten days")
check(ProgressRules.days(.body, logs: Array(repeating: workout(0), count: 10), calendar: calendar, now: now) == 1, "Ten entries on one date cannot farm ten days")
check(!ProgressRules.countsForDay(workout(0, seconds: 599), now: now), "Incomplete workout not counted")
check(ProgressRules.countsForDay(workout(0), now: now), "600 seconds is complete")
check(!ProgressRules.countsForDay(workout(-1), now: now), "Future activity cannot count")
check(ProgressRules.earned(logs: Array(ten.prefix(9)), audience: [], calendar: calendar, now: now) == ["look-03"], "Nine days keeps training skin locked")
check(ProgressRules.earned(logs: ten, audience: [], calendar: calendar, now: now).contains("look-02"), "Tenth day earns training skin")
check(!ProgressRules.earned(logs: ten, audience: [], calendar: calendar, now: now).contains("look-01"), "Body activity cannot earn Work milestone")
let spaced = (0..<10).map { workout($0 * 3) }
check(ProgressRules.earned(logs: spaced, audience: [], calendar: calendar, now: now).contains("look-02"), "Rest days never reset milestones")
let tokens = ProofLog(quest: .learn, proofKind: .number, value: "10000 tok", createdAt: now)
check(!ProgressRules.countsForDay(tokens, now: now), "Manual tokens do not establish learning")
let imported = ProofLog(quest: .learn, proofKind: .number, value: "10000 tok", annotation: "Synced from Codex", source: "codex", createdAt: now)
check(!ProgressRules.countsForDay(imported, now: now), "Imported usage does not establish learning")
let lesson = ProofLog(quest: .learn, proofKind: .link, value: "https://example.com/lesson", annotation: "Test one assumption at a time", createdAt: now)
check(ProgressRules.countsForDay(lesson, now: now), "A source and takeaway count")
check(!ProgressRules.countsForDay(ProofLog(quest: .learn, proofKind: .link, value: "https://example.com", createdAt: now), now: now), "A bookmark alone is not learning")
func followers(_ platform: AudiencePlatform, _ count: Int) -> AudienceRecord {
    AudienceRecord(platform: platform, handle: "qa-example", count: count, photoFilename: "qa.jpg", recordedAt: now)
}
for platform in AudiencePlatform.allCases {
    check(!ProgressRules.earned(logs: [], audience: [followers(platform, 9999)], calendar: calendar, now: now).contains(platform.lookID), "Below \(platform.title) milestone remains locked")
    check(ProgressRules.earned(logs: [], audience: [followers(platform, 10000)], calendar: calendar, now: now).contains(platform.lookID), "Exact \(platform.title) milestone earns its skin")
    check(!followers(platform, -1).valid, "Negative count invalid")
}
let split = [followers(.linkedin, 5000), followers(.instagram, 5000)]
check(ProgressRules.earned(logs: [], audience: split, calendar: calendar, now: now) == ["look-03"], "Platforms cannot pool counts")
var missing = followers(.linkedin, 10000); missing.photoFilename = ""
check(!missing.valid, "Evidence is required")
var future = followers(.linkedin, 10000); future.recordedAt = now.addingTimeInterval(1)
check(!ProgressRules.earned(logs: [], audience: [future], calendar: calendar, now: now).contains("look-23"), "Future follower records do not count")
let roundTrip = try JSONDecoder().decode(AudienceRecord.self, from: JSONEncoder().encode(followers(.x, 10000)))
check(roundTrip == followers(.x, 10000), "Follower evidence survives serialization")
check(Set(ProgressRules.skins.map(\.id)).count == ProgressRules.skins.count, "Milestone identities are unique")
var recorded = ten
for i in recorded.indices { recorded[i].progressDay = "2026-10-\(28-i)" }
var otherZone = calendar; otherZone.timeZone = TimeZone(identifier: "Pacific/Honolulu")!
check(ProgressRules.days(.body, logs: recorded, calendar: calendar, now: now) == ProgressRules.days(.body, logs: recorded, calendar: otherZone, now: now), "Saved active days do not change after travel")
let duplicateSaved = [ProofLog(quest: .work, proofKind: .link, value: "https://example.com/one", progressDay: "2026-10-28", createdAt: day(0)), ProofLog(quest: .work, proofKind: .link, value: "https://example.com/two", progressDay: "2026-10-28", createdAt: day(1))]
check(ProgressRules.days(.work, logs: duplicateSaved, calendar: calendar, now: now) == 1, "The recorded date stays authoritative")
let hundredBody = (0..<100).map { workout($0) }
check(ProgressRules.earned(logs: hundredBody, audience: [], calendar: calendar, now: now).contains("look-55"), "100 unique Body days earns hundred club")
check(!ProgressRules.earned(logs: Array(hundredBody.prefix(99)), audience: [], calendar: calendar, now: now).contains("look-55"), "99 Body days keeps hundred club locked")
check(!ProgressRules.earned(logs: hundredBody, audience: [], calendar: calendar, now: now).contains("season-pumpkin"), "Activities never grant purchased cosmetics")
check(!ProgressRules.skins.contains { $0.id.hasPrefix("season-") }, "Seasonal purchase is separate from achievements")
print("PASS: \(checked) progression checks")
