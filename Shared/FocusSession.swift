import Foundation

/// Time spent is a plan followed, never a receipt or an achievement by itself.
struct FocusSession: Codable, Equatable, Identifiable {
    var id = UUID()
    let task: String
    let startedAt: Date
    let endsAt: Date
    let blocksDistractions: Bool
    var breaks: [FocusBreak]? = nil

    func remaining(at date: Date = .now) -> Int {
        max(0, Int(ceil(endsAt.timeIntervalSince(date))))
    }
    var activityName: String { "larpy.focus.\(id.uuidString)" }
    var valid: Bool {
        !task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && task.count <= 140
            && endsAt.timeIntervalSince(startedAt) >= 15 * 60
            && endsAt.timeIntervalSince(startedAt) <= 60 * 60
            && validBreaks
    }
    private var validBreaks: Bool {
        var previousEnd = startedAt
        for pause in breaks ?? [] {
            guard pause.valid, pause.startedAt >= previousEnd, pause.endsAt <= endsAt else { return false }
            previousEnd = pause.endsAt
        }
        return true
    }
    func activeBreak(at date: Date = .now) -> FocusBreak? {
        (breaks ?? []).last { $0.startedAt <= date && $0.endsAt > date }
    }
    func takingBreak(reason: String, minutes: Int, at now: Date = .now) -> FocusSession? {
        guard valid, blocksDistractions, [5, 10, 15].contains(minutes), remaining(at: now) > 0,
              now >= startedAt, activeBreak(at: now) == nil else { return nil }
        let pause = FocusBreak(reason: reason.trimmingCharacters(in: .whitespacesAndNewlines), startedAt: now,
                               endsAt: min(endsAt, now.addingTimeInterval(Double(minutes * 60))))
        guard pause.valid else { return nil }
        var copy = self; copy.breaks = (breaks ?? []) + [pause]
        return copy.valid ? copy : nil
    }
    func resuming(at now: Date = .now) -> FocusSession {
        var copy = self
        if let index = copy.breaks?.lastIndex(where: { $0.startedAt <= now && $0.endsAt > now }) {
            if now == copy.breaks![index].startedAt { copy.breaks!.remove(at: index) }
            else { copy.breaks![index].endsAt = now }
        }
        return copy
    }
    func focusedSeconds(in interval: DateInterval) -> Int {
        let start = max(startedAt, interval.start), end = min(endsAt, interval.end)
        guard end > start else { return 0 }
        let paused = (breaks ?? []).reduce(0.0) { $0 + max(0, min($1.endsAt, end).timeIntervalSince(max($1.startedAt, start))) }
        return max(0, Int(end.timeIntervalSince(start) - paused))
    }
}

struct FocusBreak: Codable, Equatable, Identifiable {
    var id = UUID()
    let reason: String
    let startedAt: Date
    var endsAt: Date
    var activityName: String { "larpy.break.\(id.uuidString)" }
    var valid: Bool {
        (3...140).contains(reason.trimmingCharacters(in: .whitespacesAndNewlines).count)
            && endsAt > startedAt && endsAt.timeIntervalSince(startedAt) <= 15 * 60
    }
    // DeviceActivity requires a >=15m interval. Its warning callback closes shorter breaks.
    var monitorEnd: Date { startedAt.addingTimeInterval(15 * 60) }
    var warningSeconds: Int { max(0, Int(monitorEnd.timeIntervalSince(endsAt))) }
}

enum FocusStorage {
    static let group = "group.com.vano.larpy"
    static let activeKey = "focus.active.v1"
    static let finishedKey = "focus.finished.v1"
    static let selectionKey = "focus.selection.v1"
    static let breakRequestKey = "focus.breakRequest.v1"
    static let storeName = "larpy.focus"
    static let completedPrefix = "focus.completed."
    static var shared: UserDefaults? { UserDefaults(suiteName: group) }

    static func read(_ key: String, from defaults: UserDefaults) -> FocusSession? {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(FocusSession.self, from: data), value.valid else { return nil }
        return value
    }
    static func write(_ session: FocusSession, key: String, to defaults: UserDefaults) {
        guard session.valid, let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: key)
    }
    static func complete(_ session: FocusSession, to defaults: UserDefaults, now: Date = .now) {
        guard session.valid, session.endsAt <= now else { return }
        // A key per session makes app/extension completion idempotent.
        write(session, key: completedPrefix + session.id.uuidString, to: defaults)
        write(session, key: finishedKey, to: defaults)
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(completedPrefix) {
            if let old = read(key, from: defaults), old.endsAt < now.addingTimeInterval(-32 * 86_400) { defaults.removeObject(forKey: key) }
        }
    }
    static func recordedSeconds(on date: Date, from defaults: UserDefaults, calendar: Calendar = .current) -> Int {
        guard let day = calendar.dateInterval(of: .day, for: date) else { return 0 }
        let recorded = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(completedPrefix) }.reduce(0) { total, key in
            guard let value = read(key, from: defaults) else { return total }
            return total + value.focusedSeconds(in: day)
        }
        // A timer-only block can expire while Larpy is closed. Derive its elapsed time
        // without counting a running or cancelled block, or duplicating extension completion.
        if let pending = read(activeKey, from: defaults), pending.endsAt <= date,
           defaults.data(forKey: completedPrefix + pending.id.uuidString) == nil {
            return recorded + pending.focusedSeconds(in: day)
        }
        return recorded
    }

    /// Weekly display of retained, finished blocks. Breaks are excluded; a pending
    /// expired timer is included once even before the app processes its completion.
    static func recordedSeconds(in interval: DateInterval, from defaults: UserDefaults, now: Date = .now) -> Int {
        var sessions: [UUID: FocusSession] = [:]
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(completedPrefix) {
            if let session = read(key, from: defaults), session.endsAt <= now { sessions[session.id] = session }
        }
        if let pending = read(activeKey, from: defaults), pending.endsAt <= now { sessions[pending.id] = pending }
        return sessions.values.reduce(0) { $0 + $1.focusedSeconds(in: interval) }
    }
}
