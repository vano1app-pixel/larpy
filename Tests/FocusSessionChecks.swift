import Foundation

var checks = 0
func expect(_ value: @autoclosure () -> Bool, _ message: String) {
    precondition(value(), message); checks += 1
}
let suite = "larpy.focus.tests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(secondsFromGMT: 0)!
let noon = Date(timeIntervalSince1970: 1_780_401_600)
let start = calendar.startOfDay(for: noon).addingTimeInterval(23 * 3600 + 50 * 60)
let session = FocusSession(task: "Finish the draft", startedAt: start, endsAt: start.addingTimeInterval(1500), blocksDistractions: true)
expect(session.valid, "25 minute focus is valid")
expect(session.remaining(at: start) == 1500, "Countdown starts at actual duration")
expect(session.remaining(at: session.endsAt.addingTimeInterval(60)) == 0, "Countdown never goes negative")
expect(!FocusSession(task: " ", startedAt: start, endsAt: session.endsAt, blocksDistractions: false).valid, "Blank goal rejected")
expect(!FocusSession(task: "x", startedAt: start, endsAt: start.addingTimeInterval(60), blocksDistractions: true).valid, "Screen Time intervals shorter than 15 minutes rejected")
expect(!FocusSession(task: "x", startedAt: start, endsAt: start.addingTimeInterval(4000), blocksDistractions: true).valid, "Unexpected long interval rejected")
FocusStorage.write(session, key: FocusStorage.activeKey, to: defaults)
expect(FocusStorage.read(FocusStorage.activeKey, from: defaults) == session, "Session survives persistence")
expect(FocusStorage.recordedSeconds(on: start, from: defaults, calendar: calendar) == 0, "Running timer is not completed focus time")
FocusStorage.complete(session, to: defaults, now: start)
expect(FocusStorage.read(FocusStorage.finishedKey, from: defaults) == nil, "Early stop never becomes completed focus")
FocusStorage.complete(session, to: defaults, now: session.endsAt)
FocusStorage.complete(session, to: defaults, now: session.endsAt)
let firstDay = start.addingTimeInterval(9 * 60)
expect(FocusStorage.recordedSeconds(on: firstDay, from: defaults, calendar: calendar) == 600, "Midnight splits completed duration across days")
expect(FocusStorage.recordedSeconds(on: session.endsAt, from: defaults, calendar: calendar) == 900, "Remaining minutes belong to next day, no duplicate completion")
expect(defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(FocusStorage.completedPrefix) }.count == 1, "Repeated app and extension callbacks count once")
defaults.removeObject(forKey: FocusStorage.completedPrefix + session.id.uuidString)
expect(FocusStorage.recordedSeconds(on: session.endsAt, from: defaults, calendar: calendar) == 900, "Expired timer-only session is visible without reopening app")
defaults.removeObject(forKey: FocusStorage.activeKey)
expect(FocusStorage.recordedSeconds(on: session.endsAt, from: defaults, calendar: calendar) == 0, "Cancelled timer cannot earn recorded time")
defaults.set(Data("invalid".utf8), forKey: FocusStorage.activeKey)
expect(FocusStorage.read(FocusStorage.activeKey, from: defaults) == nil, "Corrupt session is not restored or trusted")
let breakStart = start.addingTimeInterval(300)
expect(session.takingBreak(reason: "  ", minutes: 5, at: breakStart) == nil, "A blank reason never grants a break")
expect(session.takingBreak(reason: "Reply", minutes: 60, at: breakStart) == nil, "Unbounded durations rejected")
expect(session.takingBreak(reason: "Reply", minutes: 5, at: start.addingTimeInterval(-1)) == nil, "Break cannot precede focus")
expect(session.takingBreak(reason: "Reply", minutes: 5, at: session.endsAt) == nil, "Expired session cannot grant a break")
let paused = session.takingBreak(reason: " Reply to a friend ", minutes: 5, at: breakStart)!
let pause = paused.activeBreak(at: breakStart)!
expect(pause.reason == "Reply to a friend", "Reason normalized before saving")
expect(pause.endsAt == breakStart.addingTimeInterval(300), "Five minutes has an exact wall-clock end")
expect(pause.monitorEnd.timeIntervalSince(pause.startedAt) == 900 && pause.warningSeconds == 600, "Five-minute break uses a valid fifteen-minute monitor and ten-minute warning")
expect(paused.activeBreak(at: pause.endsAt) == nil, "Expired break no longer allows access")
expect(paused.takingBreak(reason: "Again", minutes: 5, at: breakStart.addingTimeInterval(20)) == nil, "A break cannot be extended by overlapping requests")
let resumed = paused.resuming(at: breakStart.addingTimeInterval(120))
expect(resumed.valid && resumed.activeBreak(at: breakStart.addingTimeInterval(120)) == nil, "Returning early closes the break")
expect(resumed.breaks!.first!.endsAt == breakStart.addingTimeInterval(120), "Only actual break time is deducted after early return")
expect(paused.resuming(at: breakStart).breaks!.isEmpty, "Immediate return produces no invalid zero-length break")
let interval = DateInterval(start: start, end: session.endsAt)
expect(paused.focusedSeconds(in: interval) == 1200, "Five minutes is excluded from a twenty-five minute session")
expect(resumed.focusedSeconds(in: interval) == 1380, "Early return restores unused focus minutes")
FocusStorage.write(paused, key: FocusStorage.activeKey, to: defaults)
expect(FocusStorage.read(FocusStorage.activeKey, from: defaults) == paused, "Break and reason survive app restart")
FocusStorage.complete(paused, to: defaults, now: paused.endsAt)
expect(FocusStorage.recordedSeconds(on: firstDay, from: defaults, calendar: calendar) == 300, "Break minutes are deducted on the correct side of midnight")
expect(FocusStorage.recordedSeconds(on: session.endsAt, from: defaults, calendar: calendar) == 900, "Next-day focus remains intact")
let late = session.takingBreak(reason: "Reply", minutes: 15, at: session.endsAt.addingTimeInterval(-60))!
expect(late.breaks!.last!.endsAt == session.endsAt, "Break cannot outlive the parent focus session")
var invalidBreaks = paused; invalidBreaks.breaks!.append(pause)
expect(!invalidBreaks.valid, "Overlapping stored breaks are rejected")
let timerOnly = FocusSession(task: "Timer", startedAt: start, endsAt: session.endsAt, blocksDistractions: false)
expect(timerOnly.takingBreak(reason: "Reply", minutes: 5, at: breakStart) == nil, "Timer-only sessions never pretend to unlock apps")
var legacyJSON = try JSONSerialization.jsonObject(with: JSONEncoder().encode(session)) as! [String: Any]
legacyJSON.removeValue(forKey: "breaks")
let legacy = try JSONDecoder().decode(FocusSession.self, from: JSONSerialization.data(withJSONObject: legacyJSON))
expect(legacy.valid && legacy.breaks == nil, "Pre-break session files still load")
let tenMinute = session.takingBreak(reason: "Post finished work", minutes: 10, at: start)!
expect(tenMinute.breaks!.last!.warningSeconds == 300, "Ten-minute break warning fires five minutes before monitor end")
let fifteenMinute = session.takingBreak(reason: "Post finished work", minutes: 15, at: start)!
expect(fifteenMinute.breaks!.last!.warningSeconds == 0, "Fifteen-minute break uses interval end without a warning")
print("PASS: \(checks) focus persistence, breaks, midnight and completion checks")
