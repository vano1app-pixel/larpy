import Foundation

/// XP measures days with qualifying evidence, not hours, income or human worth.
/// There is one award per lane per saved day. Existing receipts count automatically.
struct LarpProgress: Equatable {
    let days: [String: Int]
    static func award(_ lane: QuestKind) -> Int { lane == .work ? 30 : 10 }
    var xp: Int { QuestKind.allCases.reduce(0) { $0 + max(0, min(100_000, days[$1.rawValue] ?? 0)) * Self.award($1) } }
    var level: Int { 1 + xp / 100 }
    var intoLevel: Int { xp % 100 }
    var remaining: Int { 100 - intoLevel }
    var title: String {
        switch level { case 1..<5: "Getting started"; case 5..<10: "Showing up"; case 10..<25: "Putting in work"; case 25..<50: "Built a habit"; default: "Long game" }
    }
    static func earned(_ logs: [ProofLog], calendar: Calendar, now: Date = .now, from start: String? = nil, through end: String? = nil) -> Self {
        var days: [String: Int] = [:]
        let today = ActivityCalendarRules.key(now, calendar: calendar)
        for lane in QuestKind.allCases {
            let keys = logs.filter { $0.quest == lane && ProgressRules.countsForDay($0, now: now) }.compactMap { log -> String? in
                let key = log.progressDay ?? ActivityCalendarRules.key(log.createdAt, calendar: calendar)
                guard LarpSnapshot.date(key) != nil, key <= today, start == nil || key >= start!, end == nil || key <= end! else { return nil }
                return key
            }
            days[lane.rawValue] = Set(keys).count
        }
        return Self(days: days)
    }
}

/// An intentionally small, user-shared file. Contains totals only, never receipts.
/// These are editable snapshots, not authenticated proof or live rankings.
struct LarpSnapshot: Codable, Identifiable, Equatable {
    var version = 1
    var id: UUID
    var name: String
    var generatedAt: Date
    var timeZoneID: String
    var weekStart: String
    var weekEnd: String
    var lifetimeDays: [String: Int]
    var weekDays: [String: Int]
    var progress: LarpProgress { LarpProgress(days: lifetimeDays) }
    var weeklyXP: Int { LarpProgress(days: weekDays).xp }
    static var utc: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; c.firstWeekday = 2; return c }
    static func date(_ key: String) -> Date? {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.calendar = utc; f.timeZone = utc.timeZone; f.dateFormat = "yyyy-MM-dd"; f.isLenient = false
        guard key.count == 10, let date = f.date(from: key), f.string(from: date) == key else { return nil }
        return date
    }
    static func window(at now: Date, calendar: Calendar) -> (start: String, end: String) {
        var c = Calendar(identifier: .gregorian); c.timeZone = calendar.timeZone; c.firstWeekday = 2; c.minimumDaysInFirstWeek = 4
        let start = c.dateInterval(of: .weekOfYear, for: now)!.start
        return (ActivityCalendarRules.key(start, calendar: c), ActivityCalendarRules.key(c.date(byAdding: .day, value: 6, to: start)!, calendar: c))
    }
    static func make(id: UUID, name: String, logs: [ProofLog], calendar: Calendar, now: Date = .now) -> Self {
        let window = window(at: now, calendar: calendar)
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return Self(id: id, name: trimmed.isEmpty ? "My Larpy" : String(trimmed.prefix(60)), generatedAt: now, timeZoneID: calendar.timeZone.identifier,
                    weekStart: window.start, weekEnd: window.end,
                    lifetimeDays: LarpProgress.earned(logs, calendar: calendar, now: now).days,
                    weekDays: LarpProgress.earned(logs, calendar: calendar, now: now, from: window.start, through: window.end).days)
    }
    func valid(now: Date = .now) -> Bool {
        guard version == 1, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name.count <= 60,
              !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              generatedAt > Date(timeIntervalSince1970: 0), generatedAt <= now.addingTimeInterval(120),
              let zone = TimeZone(identifier: timeZoneID), let start = Self.date(weekStart), let end = Self.date(weekEnd),
              Self.utc.component(.weekday, from: start) == 2,
              Self.utc.dateComponents([.day], from: start, to: end).day == 6 else { return false }
        var c = Self.utc; c.timeZone = zone
        let expected = Self.window(at: generatedAt, calendar: c)
        guard weekStart == expected.start, weekEnd == expected.end else { return false }
        let elapsed = min(7, (Self.utc.dateComponents([.day], from: start, to: Self.date(ActivityCalendarRules.key(generatedAt, calendar: c))!).day ?? 0) + 1)
        let keys = Set(QuestKind.allCases.map(\.rawValue))
        return Set(lifetimeDays.keys) == keys && Set(weekDays.keys) == keys && keys.allSatisfy {
            (0...100_000).contains(lifetimeDays[$0]!) && (0...elapsed).contains(weekDays[$0]!) && weekDays[$0]! <= lifetimeDays[$0]!
        }
    }
}

enum LarpLeague {
    enum Period: String, CaseIterable, Identifiable { case week = "This week", lifetime = "Levels"; var id: String { rawValue } }
    struct Standing: Identifiable {
        let snapshot: LarpSnapshot
        let rank: Int
        let score: Int
        var id: UUID { snapshot.id }
    }
    enum ImportError: String, Error { case invalid = "This is not a valid Larpy leaderboard file. Ask your friend to export a new one from Larp."
        case own = "That is your own snapshot. Import a friend’s file instead."
        case older = "You already have this snapshot or a newer one."
        case full = "Your board has 50 friends. Remove someone before adding another."
    }
    static func merge(_ snapshot: LarpSnapshot, into saved: [LarpSnapshot], ownID: UUID, now: Date = .now) throws -> [LarpSnapshot] {
        guard snapshot.valid(now: now) else { throw ImportError.invalid }
        guard snapshot.id != ownID else { throw ImportError.own }
        let current = saved.filter { $0.valid(now: now) && $0.id != ownID }
        if let previous = current.first(where: { $0.id == snapshot.id }), previous.generatedAt >= snapshot.generatedAt { throw ImportError.older }
        let others = current.filter { $0.id != snapshot.id }
        guard others.count < 50 else { throw ImportError.full }
        return others + [snapshot]
    }
    static func standings(mine: LarpSnapshot, friends: [LarpSnapshot], period: Period, now: Date = .now) -> [Standing] {
        var latest: [UUID: LarpSnapshot] = [:]
        for item in friends where item.valid(now: now) && item.id != mine.id {
            if latest[item.id] == nil || latest[item.id]!.generatedAt < item.generatedAt { latest[item.id] = item }
        }
        latest[mine.id] = mine
        let items = latest.values.filter { period == .lifetime || ($0.weekStart == mine.weekStart && $0.weekEnd == mine.weekEnd) }
        func score(_ item: LarpSnapshot) -> Int { period == .week ? item.weeklyXP : item.progress.xp }
        let sorted = items.sorted { score($0) == score($1) ? $0.id.uuidString < $1.id.uuidString : score($0) > score($1) }
        return sorted.enumerated().map { index, item in
            Standing(snapshot: item, rank: (sorted.firstIndex { score($0) == score(item) } ?? index) + 1, score: score(item))
        }
    }
}

/// Recognition is tied to saved evidence. A break gets a welcome, never a penalty.
enum CompanionRecognition {
    static func greeting(logs: [ProofLog], calendar: Calendar, now: Date = .now) -> String? {
        let today = ActivityCalendarRules.key(now, calendar: calendar)
        let eligible = logs.filter { ProgressRules.countsForDay($0, now: now) }
        let todayLogs = eligible.filter { ($0.progressDay ?? ActivityCalendarRules.key($0.createdAt, calendar: calendar)) == today }
        if Set(todayLogs.map(\.quest)).count == 3 { return "Three promises kept. Look at us." }
        if todayLogs.contains(where: { $0.quest == .work }) {
            let days = LarpProgress.earned(logs, calendar: calendar, now: now).days["Work"] ?? 0
            return days == 1 ? "Your first Work day. Our first win." : "\(days) Work days. It’s adding up."
        }
        if !todayLogs.isEmpty { return nil }
        if let last = eligible.map({ $0.progressDay ?? ActivityCalendarRules.key($0.createdAt, calendar: calendar) }).filter({ $0 <= today }).max(),
           let lastDate = LarpSnapshot.date(last), let todayDate = LarpSnapshot.date(today),
           (LarpSnapshot.utc.dateComponents([.day], from: lastDate, to: todayDate).day ?? 0) >= 2 {
            return "Good to have you back. Start small."
        }
        return nil
    }
}
