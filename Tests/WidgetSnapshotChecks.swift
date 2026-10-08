import Foundation

var checks = 0
func expect(_ value: @autoclosure () -> Bool, _ message: String) {
    precondition(value(), message); checks += 1
}
let date = Date.now
let snap = WidgetSnapshot(mood: "fed", pips: [false, true, true], ships: 4, lastReceipt: "QA example", name: "QA", updatedAt: date)
expect(snap.nextLane == 0 && snap.link.absoluteString == "larpy://log/body", "Missing Body is the tap destination")
expect(snap.reminder == "No movement logged today.", "Copy says logged, not that the person did nothing")
expect(snap.done == 2, "Only three qualifying activity checkmarks counted")
let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!
expect(snap.current(at: nextDay).done == 0, "Yesterday's progress does not appear as today's")
var empty = snap; empty.pips = []
expect(empty.done == 0 && !empty.has(2), "Short or legacy pip arrays do not crash")
var active = snap; active.focusEnd = date.addingTimeInterval(100)
expect(active.link.absoluteString == "larpy://focus", "Active countdown opens focus controls")
expect(active.reminder == "Stay with your one thing.", "Active block has focus copy")
var timed = snap; timed.focusMinutes = 120
expect(timed.focusLine == "2h focus recorded today", "Recorded focus never claims hours of verified work")
let data = """
{"mood":"hungry","pips":[false,false,false],"ships":0,"lastReceipt":"","name":"QA","updatedAt":0}
""".data(using: .utf8)!
let legacy = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
expect(legacy.focusMinutes == nil && legacy.focusEnd == nil, "Existing snapshots decode without focus fields")
expect(WidgetSnapshot.empty.reminder == "Open Larpy to get started.", "Missing shared data is explained")
expect(legacy.level == 1, "Legacy widget starts at level one")
var leveled = snap; leveled.totalXP = 900
expect(leveled.level == 10, "Widget uses the same hundred XP level rule")
expect(leveled.current(at: nextDay).level == 10, "Daily reset does not reset lifetime level")
print("PASS: \(checks) widget freshness, copy and routing checks")
