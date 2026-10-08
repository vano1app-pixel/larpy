import Foundation

struct WidgetSnapshot: Codable {
    var mood: String        // "fed" | "hungry"
    var pips: [Bool]        // Train, Load, Ship today
    var ships: Int          // this week
    var lastReceipt: String
    var name: String
    var updatedAt: Date
    var focusMinutes: Int? = nil
    var focusEnd: Date? = nil
    var breakEnd: Date? = nil
    var totalXP: Int? = nil
    var level: Int { 1 + max(0, totalXP ?? 0) / 100 }

    var done: Int { pips.prefix(3).filter { $0 }.count }
    func has(_ lane: Int) -> Bool { pips.indices.contains(lane) && pips[lane] }
    var nextLane: Int { !has(0) ? 0 : !has(2) ? 2 : !has(1) ? 1 : 2 }
    var link: URL { URL(string: focusEnd == nil ? "larpy://log/" + ["body", "learn", "work"][nextLane] : "larpy://focus")! }
    var reminder: String {
        if updatedAt == .distantPast { return "Open Larpy to get started." }
        if breakEnd != nil { return "A little break. Then back to it." }
        if focusEnd != nil { return "Stay with your one thing." }
        switch nextLane {
        case 0: return "No movement logged today."
        case 1: return "What did you learn today?"
        default: return has(2) ? "You showed up today." : "Your Work proof is waiting."
        }
    }
    var focusLine: String {
        let minutes = focusMinutes ?? 0
        if minutes == 0 { return "No focus time recorded today" }
        let duration = minutes >= 60 ? "\(minutes / 60)h\(minutes % 60 == 0 ? "" : " \(minutes % 60)m")" : "\(minutes)m"
        return duration + " focus recorded today"
    }

    static let empty = WidgetSnapshot(mood: "hungry", pips: [false, false, false], ships: 0, lastReceipt: "", name: "", updatedAt: .distantPast)
    static let sample = WidgetSnapshot(mood: "fed", pips: [true, false, true], ships: 2, lastReceipt: "Work · a finished project", name: "Larpy", updatedAt: .now)
    var fed: Bool { mood == "fed" && Calendar.current.isDateInToday(updatedAt) }
    func current(at date: Date) -> WidgetSnapshot {
        var result = self
        if !Calendar.current.isDate(updatedAt, inSameDayAs: date) {
            result.mood = "hungry"; result.pips = [false, false, false]; result.lastReceipt = "A new day. Start small."
        }
        var calendar = Calendar.current; calendar.firstWeekday = 2
        if calendar.dateInterval(of: .weekOfYear, for: date)?.start != calendar.dateInterval(of: .weekOfYear, for: updatedAt)?.start { result.ships = 0 }
        if let defaults = FocusStorage.shared {
            result.focusMinutes = FocusStorage.recordedSeconds(on: date, from: defaults) / 60
            if let session = FocusStorage.read(FocusStorage.activeKey, from: defaults), session.endsAt > date {
                result.focusEnd = session.endsAt
                result.breakEnd = session.activeBreak(at: date)?.endsAt
            } else { result.focusEnd = nil; result.breakEnd = nil }
        }
        return result
    }
}
