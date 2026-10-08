import Foundation

@main
enum DesktopDialogueChecks {
    static func main() {
        var checks = 0
        func check(_ value: Bool, _ name: String) {
            precondition(value, name); checks += 1
        }
        let now = Date(timeIntervalSince1970: 1_000)
        for personality in ["Buddy", "Coach", "Little menace"] {
            for moment in DesktopDialogue.Moment.allCases {
                let bank = DesktopDialogue.lines(moment, personality: personality)
                check(bank.count >= 4, "Variety for \(personality)/\(moment)")
                check(Set(bank).count == bank.count, "Unique authored lines")
                check(bank.allSatisfy { $0.count <= 72 }, "Bubble copy length")
                var dialogue = DesktopDialogue(previous: bank[0])
                var previous = bank[0]
                for _ in 0..<30 {
                    let next = dialogue.next(moment, personality: personality, now: now)
                    check(next != previous, "No immediate repeats, including relaunch")
                    check(bank.contains(next), "Correct context and personality")
                    previous = next
                }
            }
        }
        var dialogue = DesktopDialogue()
        _ = dialogue.next(.welcome, personality: "Buddy", now: now)
        check(!dialogue.isDue(now: now.addingTimeInterval(74), enabled: true, paused: false), "Keep idle lines readable")
        check(dialogue.isDue(now: now.addingTimeInterval(75), enabled: true, paused: false), "Idle rotation")
        check(!dialogue.isDue(now: now.addingTimeInterval(999), enabled: false, paused: false), "Quiet setting")
        check(!dialogue.isDue(now: now.addingTimeInterval(999), enabled: true, paused: true), "Pause stops chatter")
        _ = dialogue.next(.started, personality: "Coach", now: now, focusing: true)
        check(!dialogue.isDue(now: now.addingTimeInterval(179), enabled: true, paused: false), "Focus is quieter")
        check(dialogue.isDue(now: now.addingTimeInterval(180), enabled: true, paused: false), "Focus rotation")
        dialogue.record("An important event", now: now.addingTimeInterval(180), focusing: true)
        check(!dialogue.isDue(now: now.addingTimeInterval(181), enabled: true, paused: false), "Do not overwrite an event")
        print("PASS: \(checks) dialogue checks — all personalities, no adjacent repeats, timing, quiet mode and event protection.")
    }
}
