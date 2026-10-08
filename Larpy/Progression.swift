import Foundation

enum CareerPath: String, CaseIterable, Identifiable, Codable {
    case founder, trader, vlogger, creator, developer, designer, student, exploring
    var id: String { rawValue }
    var title: String {
        switch self {
        case .founder: "Tech founder"; case .trader: "Trader"; case .vlogger: "Vlogger"
        case .creator: "Content creator"; case .developer: "Developer"; case .designer: "Designer"
        case .student: "Student"; case .exploring: "Still exploring"
        }
    }
    var work: String {
        switch self {
        case .founder: "Ship a feature or finish a customer project"
        case .trader: "Complete a trading journal or paper-trade review"
        case .vlogger: "Publish a video or finish an edit"
        case .creator: "Publish a post, video or newsletter"
        case .developer: "Finish a feature or fix a bug"
        case .designer: "Finish a design or deliver a project"
        case .student: "Finish an assignment or practice project"
        case .exploring: "Finish something you can show"
        }
    }
    var learn: String {
        switch self {
        case .founder: "A lesson about customers, products or building"
        case .trader: "A lesson about risk, research or your process"
        case .vlogger, .creator: "A lesson about storytelling, editing or your audience"
        case .developer: "A technique you can use in your next build"
        case .designer: "A design principle you tried or understood"
        case .student: "A concept you can explain in your own words"
        case .exploring: "One useful idea and how you will use it"
        }
    }
}

/// A gap is a past date after the first qualifying activity. Today is still open.
/// Use the saved day identity so travelling does not rewrite the calendar.
enum ActivityCalendarRules {
    enum Status: Equatable { case beforeStart, future, open, missed, active(Int) }
    static func key(_ date: Date, calendar: Calendar) -> String {
        let f = DateFormatter(); f.calendar = calendar; f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    static func status(on date: Date, logs: [ProofLog], calendar: Calendar, now: Date = .now, lane: QuestKind? = nil) -> Status {
        let dateKey = key(date, calendar: calendar), todayKey = key(now, calendar: calendar)
        if dateKey > todayKey { return .future }
        let eligible = logs.filter { ProgressRules.countsForDay($0, now: now) }
        let matching = eligible.filter { ($0.progressDay ?? key($0.createdAt, calendar: calendar)) == dateKey && (lane == nil || $0.quest == lane) }
        let lanes = Set(matching.map(\.quest.rawValue)).count
        if lanes > 0 { return .active(lanes) }
        if dateKey == todayKey { return .open }
        guard let first = eligible.map({ $0.progressDay ?? key($0.createdAt, calendar: calendar) }).min(), dateKey >= first else { return .beforeStart }
        return .missed
    }
}

/// Read-only presentation of saved receipts. Never awards XP or rewrites a saved day.
struct ActivityProgressSummary {
    struct Day: Identifiable {
        let id: String
        let date: Date
        let logs: [ProofLog]
        let lanes: [QuestKind]
    }
    let weekStart: Date
    let weekEnd: Date
    let history: [Day]
    let activeDays: Int
    let workDays: Int
    let bodyDays: Int
    let learningDays: Int
    let currentStreak: Int
    let bestStreak: Int

    static func date(_ key: String, calendar: Calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar; formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard key.count == 10, let date = formatter.date(from: key), formatter.string(from: date) == key else { return nil }
        return date
    }

    init(logs: [ProofLog], weekContaining date: Date, calendar: Calendar, now: Date = .now) {
        var cal = calendar; cal.firstWeekday = 2; cal.minimumDaysInFirstWeek = 4
        let start = cal.dateInterval(of: .weekOfYear, for: date)!.start
        let end = cal.date(byAdding: .day, value: 7, to: start)!
        weekStart = start; weekEnd = end
        let today = ActivityCalendarRules.key(now, calendar: cal)
        let from = ActivityCalendarRules.key(start, calendar: cal)
        let until = ActivityCalendarRules.key(end, calendar: cal)
        let saved = logs.filter {
            let key = $0.progressDay ?? ActivityCalendarRules.key($0.createdAt, calendar: cal)
            return $0.isEligible && $0.createdAt <= now && key <= today && Self.date(key, calendar: cal) != nil
        }
        let grouped = Dictionary(grouping: saved) { $0.progressDay ?? ActivityCalendarRules.key($0.createdAt, calendar: cal) }
        let activeKeys = grouped.keys.filter { key in grouped[key]!.contains { ProgressRules.countsForDay($0, now: now) } }.sorted()
        let keys = Set(activeKeys)
        history = grouped.keys.filter { $0 >= from && $0 < until }.sorted(by: >).map { key in
            let records = grouped[key]!.sorted { $0.createdAt > $1.createdAt }
            let lanes = [QuestKind.work, .body, .learn].filter { lane in
                records.contains { $0.quest == lane && ProgressRules.countsForDay($0, now: now) }
            }
            return Day(id: key, date: Self.date(key, calendar: cal)!, logs: records, lanes: lanes)
        }
        activeDays = history.filter { !$0.lanes.isEmpty }.count
        workDays = history.filter { $0.lanes.contains(.work) }.count
        bodyDays = history.filter { $0.lanes.contains(.body) }.count
        learningDays = history.filter { $0.lanes.contains(.learn) }.count

        var best = 0, run = 0, previous: Date?
        for key in activeKeys {
            let date = Self.date(key, calendar: cal)!
            run = previous.flatMap { cal.dateComponents([.day], from: $0, to: date).day } == 1 ? run + 1 : 1
            best = max(best, run); previous = date
        }
        bestStreak = best
        var cursor = cal.startOfDay(for: now), streak = 0
        if !keys.contains(today) { cursor = cal.date(byAdding: .day, value: -1, to: cursor)! }
        while keys.contains(ActivityCalendarRules.key(cursor, calendar: cal)) {
            streak += 1; cursor = cal.date(byAdding: .day, value: -1, to: cursor)!
        }
        currentStreak = streak
    }
}

enum AudiencePlatform: String, CaseIterable, Codable, Identifiable {
    case linkedin, instagram, x
    var id: String { rawValue }
    var title: String { switch self { case .linkedin: "LinkedIn"; case .instagram: "Instagram"; case .x: "X" } }
    var lookID: String { switch self { case .linkedin: "look-23"; case .instagram: "look-52"; case .x: "look-16" } }
    var symbol: String { switch self { case .linkedin: "person.2"; case .instagram: "camera"; case .x: "bubble.left" } }
}

/// Manual evidence is explicitly self-reported. No provider verification is implied.
struct AudienceRecord: Codable, Equatable, Identifiable {
    var platform: AudiencePlatform
    var handle: String
    var count: Int
    var photoFilename: String
    var recordedAt: Date
    var id: String { platform.rawValue }
    var valid: Bool { count >= 0 && count <= 1_000_000_000 && !handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !photoFilename.isEmpty && !photoFilename.contains("/") && !photoFilename.contains("..") }
}

struct SkinMilestone: Identifiable {
    let id: String
    let title: String
    let lane: QuestKind?
    let platform: AudiencePlatform?
    let target: Int
    var requirement: String {
        if let platform { return "10,000 \(platform.title) followers" }
        guard let lane else { return "Your starter skin" }
        return "\(target) \(lane == .body ? "active" : lane == .work ? "Work" : "learning") days"
    }
    func progress(logs: [ProofLog], audience: [AudienceRecord], calendar: Calendar, now: Date = .now) -> Int {
        if let platform { return audience.first { $0.platform == platform && $0.valid && $0.recordedAt <= now }?.count ?? 0 }
        if let lane { return ProgressRules.days(lane, logs: logs, calendar: calendar, now: now) }
        return 0
    }
}

enum ProgressRules {
    static let skins: [SkinMilestone] = [
        .init(id: "look-03", title: "First chapter", lane: nil, platform: nil, target: 0),
        .init(id: "look-02", title: "Training club", lane: .body, platform: nil, target: 10),
        .init(id: "look-20", title: "Early riser", lane: .body, platform: nil, target: 25),
        .init(id: "look-47", title: "Distance club", lane: .body, platform: nil, target: 50),
        .init(id: "look-07", title: "Field notes", lane: .learn, platform: nil, target: 10),
        .init(id: "look-19", title: "Deep reader", lane: .learn, platform: nil, target: 25),
        .init(id: "look-33", title: "Lifelong learner", lane: .learn, platform: nil, target: 50),
        .init(id: "look-01", title: "The keynote", lane: .work, platform: nil, target: 10),
        .init(id: "look-06", title: "After hours", lane: .work, platform: nil, target: 25),
        .init(id: "look-30", title: "Launch day", lane: .work, platform: nil, target: 50),
        .init(id: "look-55", title: "The hundred club", lane: .body, platform: nil, target: 100),
        .init(id: "look-56", title: "Built different", lane: .work, platform: nil, target: 100),
        .init(id: "look-57", title: "The wise one", lane: .learn, platform: nil, target: 100),
        .init(id: "look-23", title: "The networker", lane: nil, platform: .linkedin, target: 10_000),
        .init(id: "look-52", title: "The viewfinder", lane: nil, platform: .instagram, target: 10_000),
        .init(id: "look-16", title: "The broadcaster", lane: nil, platform: .x, target: 10_000)
    ]
    static func countsForDay(_ log: ProofLog, now: Date = .now) -> Bool {
        guard log.isEligible, log.createdAt <= now else { return false }
        switch log.quest {
        case .body: return log.proofKind == .photo || (log.timerSeconds ?? 0) >= 600
        case .work: return true
        case .learn:
            guard log.source != "codex", log.source != "claude-code" else { return false }
            let takeaway = (log.annotation ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return !takeaway.isEmpty && (log.proofKind == .link || log.proofKind == .photo || log.value.hasPrefix("note:"))
        }
    }
    static func days(_ lane: QuestKind, logs: [ProofLog], calendar: Calendar, now: Date = .now) -> Int {
        let formatter = DateFormatter()
        formatter.calendar = calendar; formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
        return Set(logs.filter { $0.quest == lane && countsForDay($0, now: now) }.map { $0.progressDay ?? formatter.string(from: $0.createdAt) }).count
    }
    static func earned(logs: [ProofLog], audience: [AudienceRecord], calendar: Calendar, now: Date = .now) -> Set<String> {
        Set(skins.filter { $0.progress(logs: logs, audience: audience, calendar: calendar, now: now) >= $0.target }.map(\.id))
    }
}


/// Voice changes tone, never the underlying facts. Roast is explicitly opt-in.
enum CompanionPersonality: String, CaseIterable, Identifiable {
    case buddy, coach, roast
    var id: String { rawValue }
    var title: String { switch self { case .buddy: "Buddy"; case .coach: "Coach"; case .roast: "Little menace" } }
    var detail: String { switch self {
    case .buddy: "Warm company. Small wins count."
    case .coach: "Clear next steps. A little more push."
    case .roast: "Playful roasting about habits. Never your worth."
    } }
    func greeting(done: Int, hello: Bool) -> String {
        switch self {
        case .buddy: return hello ? "Hey. My favourite human." : done == 3 ? "Look at us go." : done > 0 ? "A little more you, every day." : "What will we do today?"
        case .coach: return hello ? "You and me. One thing at a time." : done == 3 ? "Three promises kept. Take the win." : done > 0 ? "Momentum looks good on you." : "Pick one thing. Make it real."
        case .roast: return hello ? "Petting me is not a deliverable." : done == 3 ? "Fine. You cooked today." : done > 0 ? "Evidence? From you? I love this arc." : "Big plans. Tiny first step. Go."
        }
    }
}

/// User-shared snapshots, not authenticated accounts or live leaderboards.
struct FriendSnapshot: Codable {
    var version = 1
    var id: UUID
    var name: String
    var generatedAt: Date
    var weekStart: String
    var weekEnd: String
    var days: [String: Int]
    var followers: [String: Int]
    var followerDates: [String: Date]
    var tokens: [String: Int]
    func valid(now: Date = .now) -> Bool {
        let dayPattern = #"^\d{4}-\d{2}-\d{2}$"#
        return version == 1 && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 60
            && generatedAt <= now.addingTimeInterval(120) && generatedAt > Date(timeIntervalSince1970: 0)
            && weekStart.range(of: dayPattern, options: .regularExpression) != nil
            && weekEnd.range(of: dayPattern, options: .regularExpression) != nil && weekStart <= weekEnd
            && Set(days.keys).isSubset(of: ["Body", "Work", "Learn"]) && days.values.allSatisfy { (0...7).contains($0) }
            && Set(followers.keys).isSubset(of: ["linkedin", "instagram", "x"]) && followers.values.allSatisfy { (0...1_000_000_000).contains($0) }
            && Set(followerDates.keys) == Set(followers.keys) && followerDates.values.allSatisfy { $0 <= generatedAt }
            && Set(tokens.keys).isSubset(of: ["codex", "claude-code"]) && tokens.values.allSatisfy { (0...70_000_000_000).contains($0) }
    }
}
