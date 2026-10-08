import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import UIKit
import UserNotifications
import Security
import WidgetKit
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Palette

/// Default is light cream paper. Dark is Settings → Appearance.
enum Theme { static var isDark = false }

enum Palette {
    static var isDark: Bool { Theme.isDark }
    static var bg: Color      { isDark ? Color(hex: 0x161412) : Color(hex: 0xF5F0E6) }
    static var card: Color    { isDark ? Color(hex: 0x1E1C1A) : Color(hex: 0xEFE8DA) }
    static var line: Color    { isDark ? Color(hex: 0x2A2724) : Color(hex: 0xE1D8C6) }
    static var text: Color    { isDark ? Color(hex: 0xF3EDE4) : Color(hex: 0x1A1714) }
    static var muted: Color   { isDark ? Color(hex: 0x8A837A) : Color(hex: 0x7A6B58) }
    static let gold = Color(hex: 0xC4A35A)
    // Lane hits — a 1s wash on the row when a receipt lands
    static let train = Color(hex: 0xFF5A3D)
    static let load = Color(hex: 0x5B8CFF)
    static let ship = Color(hex: 0xC4A35A)
    static let creature = Color(hex: 0xF4E4C8)   // the egg/dumpling is cream in both themes
    static let blush = Color(hex: 0xE89B8A)
    static let hoodie = Color(hex: 0x2A3340)
    static let tv = Color(hex: 0x3A6FA8)
    static let ink = Color(hex: 0x2A241C)        // face line on cream, both themes
    /// Cream stage behind Larpy: full scenery in light, a pool in dark.
    static let stage = Color(hex: 0xF4E4C8)
    static var stagePoolOpacity: Double { isDark ? 0.34 : 0.75 }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Base

/// One body colour. The egg is cream in both themes; the costume and the room carry the variety.
enum LarpyBase: String, CaseIterable, Identifiable {
    case cream
    var id: String { rawValue }
    var displayName: String { "Cream" }
    var color: Color { Color(hex: 0xF2E6D4) }
}

// MARK: - Life model

enum Face { case asleep, stirring, fed, cleared
    var word: String {
        switch self {
        case .asleep: "asleep"
        case .stirring: "stirring"
        case .fed: "fed"
        case .cleared: "cleared"
        }
    }
}

enum Gear: Equatable { case none, work, body, learn }
enum Posture { case asleep, normal, stressed, sofa, upright }

struct LifeState {
    var face: Face
    var gear: Gear
    var posture: Posture
    var bodyTone: Double
    var growScale: Double = 1.0
    var bubble: String?
    var label: String
    var cleared: Bool

    static let neutral = LifeState(
        face: .fed, gear: .none, posture: .normal,
        bodyTone: 1, growScale: 1, bubble: nil, label: "fed", cleared: false
    )

    static let sofaPreview = LifeState(
        face: .asleep, gear: .none, posture: .sofa,
        bodyTone: 1, growScale: 1, bubble: "i should be grinding", label: "asleep", cleared: false
    )

    static let neutralAsleep = LifeState(
        face: .asleep, gear: .none, posture: .asleep,
        bodyTone: 1, growScale: 1, bubble: nil, label: "asleep", cleared: false
    )

    static let clearedPreview = LifeState(
        face: .cleared, gear: .none, posture: .upright,
        bodyTone: 1, growScale: 1, bubble: nil, label: "cleared", cleared: true
    )
}

// MARK: - Time (Europe/Dublin)

enum LarpyTime {
    static var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }

    static func startOfToday() -> Date { cal.startOfDay(for: Date()) }

    static func dayKey(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = cal
        f.timeZone = cal.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - Weekly stats + life engine (pure, derived from ProofStore)

struct WeekStats {
    var bodyN = 0, learnN = 0, workN = 0
    var emptyStreak = 0
    var clearedN = 0
    var todayCount = 0
    var codedLabel = "quiet"
    var streak = 0 // consecutive cleared days ending today/yesterday
    var monthCleared = 0
    var monthElapsed = 1

    // extra local stats
    var proofsYesterday = 0
    var yesterdayCleared = false
    var bodyToday = false
    var bodyYesterday = false
    var bodyLastWeek = 0
    var lastBody: Date?
    var lastLearn: Date?
    var lastWork: Date?
    var lastAny: Date?

    var streakLine: String { "\(streak) in a row · \(monthCleared)/\(monthElapsed) this month" }
}

struct TokenStats {
    var thisWeek = 0, lastWeek = 0, allTime = 0, highWater = 0
    init(_ a: AgentStore) {
        thisWeek = a.weekTotal; lastWeek = a.lastWeekTotal
        allTime = a.allTime; highWater = a.highWaterWeek
    }
    init() {}
    /// this week < 60% of last week, and last week was real (>= 100k)
    var isDown: Bool { lastWeek >= 100_000 && Double(thisWeek) < 0.6 * Double(lastWeek) }
    /// hit >= 1M in some week, and this week is under half of it
    var belowHighWater: Bool { highWater >= 1_000_000 && thisWeek * 2 < highWater }
}

func weekdayName(_ d: Date) -> String {
    let f = DateFormatter(); f.calendar = LarpyTime.cal; f.timeZone = LarpyTime.cal.timeZone
    f.dateFormat = "EEE"
    return f.string(from: d)
}

enum LifeEngine {
    static func laneDone(_ logs: [ProofLog], _ quest: QuestKind, on day: Date) -> Bool {
        logs.contains { $0.quest == quest && ProgressRules.countsForDay($0) && ($0.progressDay ?? LarpyTime.dayKey($0.createdAt)) == LarpyTime.dayKey(day) }
    }

    static func anyDone(_ logs: [ProofLog], on day: Date) -> Bool {
        QuestKind.allCases.contains { laneDone(logs, $0, on: day) }
    }

    static func cleared(_ logs: [ProofLog], on day: Date) -> Bool {
        QuestKind.allCases.allSatisfy { laneDone(logs, $0, on: day) }
    }

    static func stats(_ logs: [ProofLog]) -> WeekStats {
        let cal = LarpyTime.cal
        let today = cal.startOfDay(for: Date())
        let monday = cal.dateInterval(of: .weekOfYear, for: today)!.start
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }.filter { $0 <= today }

        var s = WeekStats()
        s.bodyN = days.filter { laneDone(logs, .body, on: $0) }.count
        s.learnN = days.filter { laneDone(logs, .learn, on: $0) }.count
        s.workN = logs.filter { $0.quest == .work && $0.isEligible && $0.createdAt >= monday && $0.createdAt <= Date() }.count
        s.clearedN = days.filter { cleared(logs, on: $0) }.count
        s.todayCount = QuestKind.allCases.filter { laneDone(logs, $0, on: today) }.count

        // emptyStreak: consecutive empty days ending yesterday — but only counting
        // back to the user's first-ever log, so a brand-new user reads as asleep, not sofa.
        var streakEmpty = 0
        if let firstLog = logs.map(\.createdAt).min() {
            let firstDay = cal.startOfDay(for: firstLog)
            var d = cal.date(byAdding: .day, value: -1, to: today)!
            while d >= firstDay, !anyDone(logs, on: d) {
                streakEmpty += 1
                d = cal.date(byAdding: .day, value: -1, to: d)!
                if streakEmpty > 90 { break }
            }
        }
        s.emptyStreak = streakEmpty

        // cleared streak ending today (or yesterday if today not yet cleared)
        var clearedStreak = 0
        var c = today
        if !cleared(logs, on: c) { c = cal.date(byAdding: .day, value: -1, to: c)! }
        while cleared(logs, on: c) {
            clearedStreak += 1
            c = cal.date(byAdding: .day, value: -1, to: c)!
            if clearedStreak > 365 { break }
        }
        s.streak = clearedStreak

        // Month: cleared days so far this month / days elapsed. One miss breaks the
        // row streak above, not the month tally.
        let dayOfMonth = cal.component(.day, from: today)
        s.monthElapsed = dayOfMonth
        if let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: today)) {
            s.monthCleared = (0..<dayOfMonth).filter { offset in
                guard let d = cal.date(byAdding: .day, value: offset, to: monthStart) else { return false }
                return cleared(logs, on: d)
            }.count
        }

        // Yesterday + last-week + last-seen dates
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        s.proofsYesterday = QuestKind.allCases.filter { laneDone(logs, $0, on: yesterday) }.count
        s.yesterdayCleared = cleared(logs, on: yesterday)
        s.bodyToday = laneDone(logs, .body, on: today)
        s.bodyYesterday = laneDone(logs, .body, on: yesterday)
        s.bodyLastWeek = (7..<14).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
            .filter { laneDone(logs, .body, on: $0) }.count
        s.lastBody = logs.filter { $0.quest == .body }.map(\.createdAt).max()
        s.lastLearn = logs.filter { $0.quest == .learn }.map(\.createdAt).max()
        s.lastWork = logs.filter { $0.quest == .work }.map(\.createdAt).max()
        s.lastAny = logs.map(\.createdAt).max()

        s.codedLabel = codedLabel(for: gear(s), stats: s)
        return s
    }

    /// One short fact under the pet, only when it matters. nil = say nothing.
    static func fact(_ s: WeekStats, tokens t: TokenStats) -> String? {
        if s.streak >= 2, s.todayCount < 3 { return "\(s.streak) in a row ends tonight" }
        if t.isDown { return "\(fmtTokens(t.thisWeek)) vs \(fmtTokens(t.lastWeek)) last week" }
        if s.todayCount == 0, s.emptyStreak >= 1, let last = s.lastAny { return "empty since \(weekdayName(last))" }
        return nil
    }

    static func gear(_ s: WeekStats) -> Gear {
        if s.workN >= 3, s.workN >= s.bodyN + 2, s.workN >= s.learnN + 1 { return .work }
        if s.bodyN >= 3, s.bodyN >= s.workN + 2 { return .body }
        if s.learnN >= 3, s.learnN >= s.workN + 2 { return .learn }
        return .none
    }

    static func codedLabel(for gear: Gear, stats s: WeekStats) -> String {
        switch gear {
        case .work: "work-coded"
        case .body: "body-coded"
        case .learn: "learn-coded"
        case .none: s.clearedN >= 3 ? "balanced" : "quiet"
        }
    }

    static func life(_ logs: [ProofLog], now: Date = Date()) -> LifeState {
        let s = stats(logs)
        let cal = LarpyTime.cal

        let face: Face = switch s.todayCount {
        case 0: .asleep
        case 1: .stirring
        case 2: .fed
        default: .cleared
        }

        let g = gear(s)

        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let after2130 = hour > 21 || (hour == 21 && minute >= 30)

        var posture: Posture = .normal
        var bubble: String?

        if s.todayCount == 3 {
            posture = .upright
        } else if s.emptyStreak >= 2 || (s.todayCount == 0 && after2130) {
            posture = .sofa
            bubble = rotate(["i should be grinding", "this is the sofa era", "open the gym"], now: now)
        } else if s.todayCount <= 1 && s.emptyStreak == 1 {
            posture = .stressed
            bubble = rotate(["still time", "one thing"], now: now)
        } else if s.todayCount == 0 && s.emptyStreak == 0 {
            posture = .asleep
        } else {
            posture = .normal
        }
        // Level = ships this week. Three ships and he stands up straight. No badge grid.
        if s.workN >= 3, posture == .normal { posture = .upright }

        // Gym: thicker arms from Body days in the last 7. No anatomy, just sturdier.
        let bodyTone: Double = s.bodyN >= 4 ? 1.28 : (s.bodyN >= 2 ? 1.15 : 1.0)
        let growScale: Double = s.workN >= 7 ? 1.06 : 1.0
        return LifeState(
            face: face, gear: g, posture: posture, bodyTone: bodyTone, growScale: growScale,
            bubble: bubble, label: face.word, cleared: s.todayCount == 3
        )
    }

    private static func rotate(_ options: [String], now: Date) -> String {
        let doy = LarpyTime.cal.ordinality(of: .day, in: .year, for: now) ?? 0
        return options[doy % options.count]
    }
}

// MARK: - Voice (a pissed mentor; speaks only from receipts we actually have)

enum Voice {
    static let bank: [String] = [
        "Ship something or you're larping.",
        "Tokens aren't a product.",
        "Did you wake up from the dream.",
        "I don't see a ship.",
        "Gym's still empty.",
        "Are you building.",
        "That's homework.",
        "Close something.",
        "You watched Hormozi. Cool. What shipped.",
        "Founders don't get a participation check.",
        "Are you building or decorating the LARP.",
        "That's homework. Where's the thing.",
        "Receipts or it didn't happen.",
        "Nobody's impressed by the tab count.",
        "The demo is the pitch. Where is it.",
        "Cursor's open. Is anything leaving it.",
        "One rep. One page. One ship. Pick.",
        "Talk less about the plan.",
        "Your future self wants a screenshot, not a vibe.",
        "Ship ugly. Fix loud.",
        "A clip isn't a course. A course isn't a company.",
        "Still larping? Prove me wrong.",
        "Solo LARP is just a diary."
    ]

    /// Time-aware, never surveillance-aware: only what today's receipts say.
    /// `friendShipped` = the one friend's name when we HAVE their Ship receipt for today (sync, later). Never guessed.
    static func line(train: Bool, load: Bool, ship: Bool, isEgg: Bool, friendShipped: String? = nil, now: Date = Date()) -> String {
        if isEgg { return "Big character. Zero receipts." }
        if let f = friendShipped, !ship { return "\(f) shipped. You didn't." }
        if train && load && ship { return "Alive. Screenshot it." }
        let hour = LarpyTime.cal.component(.hour, from: now)
        if hour < 12, !train { return "Gym's still a thought." }
        if hour >= 18, !ship { return "I don't see a ship." }
        if load, !ship { return "Tokens aren't a product." }
        let day = LarpyTime.cal.ordinality(of: .day, in: .year, for: now) ?? 0
        let lines = ship ? ["It exists. Now make it matter.", "One less thing trapped in your head.", "A receipt looks good on you.", "You earned the screenshot.", "The costume finally has a witness."]
            : load ? ["Homework has a receipt. Your product doesn't.", "Inputs are full. The exit is empty.", "Nice load. Where's the payload.", "You fed the brain. Feed the market.", "The research phase has a door. Use it."]
            : ["Your ambition called. It wants evidence.", "Main character. Missing scene.", "The idea can't screenshot itself.", "Dress the part. Then do the part.", "Your launch is still a rumour."]
        return lines[day % lines.count]
    }

    /// Only output advances the weekly level.
    static func xp(train: Bool, load: Bool, ship: Bool) -> Int {
        ship ? 1 : 0
    }
}

extension QuestKind {
    var tint: Color {
        switch self {
        case .body: Palette.train
        case .learn: Palette.load
        case .work: Palette.ship
        }
    }
}

/// LOAD = what the human loaded today (tokens / minutes / pages). Never model spend, never Ship.
struct LoadEntry: Codable { var at: Date; var tokens: Int; var minutes: Int; var pages: Int; var lessons: Int?; var id: UUID? }

@MainActor final class LoadLedger: ObservableObject {
    private let d = UserDefaults.standard
    @Published private(set) var entries: [LoadEntry] = []

    init() {
        if let data = d.data(forKey: "loadLedger"),
           let list = try? JSONDecoder().decode([LoadEntry].self, from: data) { entries = list }
    }

    func add(tokens: Int = 0, minutes: Int = 0, pages: Int = 0, lessons: Int = 0, at: Date = .now, id: UUID? = nil) {
        if let id, entries.contains(where: { $0.id == id }) { return }
        guard tokens > 0 || minutes > 0 || pages > 0 || lessons > 0 else { return }
        entries.append(LoadEntry(at: at, tokens: tokens, minutes: minutes, pages: pages, lessons: lessons, id: id))
        d.set(try? JSONEncoder().encode(entries), forKey: "loadLedger")
    }

    func syncUsage(_ usage: UsageDay) {
        if entries.contains(where: { $0.id == usage.id && $0.tokens == usage.tokens }) { return }
        entries.removeAll { $0.id == usage.id }
        entries.append(LoadEntry(at: usage.at, tokens: usage.tokens, minutes: 0, pages: 0, lessons: 0, id: usage.id))
        d.set(try? JSONEncoder().encode(entries), forKey: "loadLedger")
    }

    var todays: [LoadEntry] { entries.filter { LarpyTime.cal.isDateInToday($0.at) } }
    var todayTokens: Int { todays.map(\.tokens).reduce(0, +) }
    var usageSummary: String {
        let synced = todays.filter { $0.id != nil }.map(\.tokens).reduce(0, +)
        let manual = todays.filter { $0.id == nil }.map(\.tokens).reduce(0, +)
        if synced > 0 && manual > 0 { return "\(fmtTokens(synced)) synced · \(fmtTokens(manual)) manual" }
        if synced > 0 { return "\(fmtTokens(synced)) synced today" }
        return "\(fmtTokens(manual)) manually logged"
    }
    var todayMinutes: Int { todays.map(\.minutes).reduce(0, +) }
    var todayPages: Int { todays.map(\.pages).reduce(0, +) }

    var todayLessons: Int { todays.map { $0.lessons ?? 0 }.reduce(0, +) }
    var todayDetail: String {
        if todayTokens > 0 { return "tokens loaded" + (todayPages > 0 ? " · \(todayPages) pages" : "") + (todayLessons > 0 ? " · \(todayLessons) lesson\(todayLessons == 1 ? "" : "s")" : "") }
        if todayPages > 0 { return "pages loaded" }
        if todayMinutes > 0 { return "minutes loaded" }
        if todayLessons > 0 { return todayLessons == 1 ? "lesson loaded" : "lessons loaded" }
        return "inputs, not outputs"
    }
    /// Units never combine tokens and pages into an invented total.
    var todayLabel: String {
        if todayTokens > 0 { return fmtTokens(todayTokens) }
        if todayPages > 0 { return "\(todayPages)" }
        if todayMinutes > 0 { return "\(todayMinutes)" }
        if todayLessons > 0 { return "\(todayLessons)" }
        return "0"
    }
}

// MARK: - ProofStore helpers (Dublin day math; store stays source of truth)

extension ProofStore {
    func doneToday(_ quest: QuestKind) -> Bool {
        LifeEngine.laneDone(logs, quest, on: LarpyTime.startOfToday())
    }

    var todayCount: Int {
        QuestKind.allCases.filter { doneToday($0) }.count
    }

    var emptyLanesToday: [QuestKind] {
        QuestKind.allCases.filter { !doneToday($0) }
    }

    func count(on day: Date) -> Int {
        QuestKind.allCases.filter { LifeEngine.laneDone(logs, $0, on: day) }.count
    }

    func latestToday(for quest: QuestKind) -> ProofLog? {
        logs.first { $0.quest == quest && ProgressRules.countsForDay($0) && ($0.progressDay ?? LarpyTime.dayKey($0.createdAt)) == LarpyTime.dayKey() }
    }

    func logsOn(_ day: Date) -> [ProofLog] {
        logs.filter { $0.isEligible && LarpyTime.cal.isDate($0.createdAt, inSameDayAs: day) }
    }

    /// One word from today's proof: focused / tokens / git / music / gym / learn / ship. One chip max.
    func badgeWord(weekTokens: Int = 0) -> String? {
        if todayCount == 3 { return "focused" }
        if weekTokens >= 1_000_000 { return "tokens" }
        let todays = logsOn(LarpyTime.startOfToday())
        if let work = todays.first(where: { $0.quest == .work }),
           work.proofKind == .link, isGitHost(work.value) { return "git" }
        if todays.contains(where: { $0.proofKind == .link && isMusicLink($0.value) }) { return "music" }
        if doneToday(.body) { return "gym" }
        if doneToday(.learn) { return "learn" }
        if doneToday(.work) { return "ship" }
        return nil
    }

    /// Sum of pasted token counts logged in the last 7 days (0 if none).
    var tokensThisWeek: Int {
        let cal = LarpyTime.cal
        let start = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date()))!
        return logs
            .filter { $0.quest == .work && $0.proofKind == .number && $0.value.hasSuffix("tok") && $0.createdAt >= start }
            .compactMap { Int($0.value.replacingOccurrences(of: " tok", with: "").trimmingCharacters(in: .whitespaces)) }
            .reduce(0, +)
    }
}

func isMusicLink(_ s: String) -> Bool {
    guard let u = URL(string: s), let h = u.host?.lowercased() else { return false }
    return h.contains("youtube") || h.contains("youtu.be") || h.contains("music")
        || h.contains("spotify") || h.contains("soundcloud")
}

func shortTokens(_ n: Int) -> String {
    n >= 1000 ? "\(n / 1000)k" : "\(n)"
}

func isGitHost(_ string: String) -> Bool {
    guard let u = URL(string: string), let h = u.host?.lowercased() else { return false }
    return h.contains("github.com") || h.contains("gitlab.com") || h.contains("bitbucket.org")
}

/// Short row summary: `42m`, `github.com`, `note`.
func summaryChip(_ log: ProofLog) -> String {
    if log.value.hasPrefix("note: ") { return "note" }
    return switch log.proofKind {
    case .link: linkHost(log.value)
    case .photo: log.value.isEmpty ? "photo" : log.value
    case .number: log.value
    }
}

/// Today-row chip. Body = duration or nothing (the ✓ says it). Load = token count or "1 lesson", never minutes. Ship = the usual.
func rowChip(_ log: ProofLog) -> String {
    switch log.quest {
    case .body:
        if let m = log.value.range(of: #"\b\d+m\b"#, options: .regularExpression) { return String(log.value[m]) }
        return ""
    case .learn:
        if log.value.hasSuffix(" tok") { return String(log.value.dropLast(4)) }
        if log.proofKind == .link { return linkHost(log.value) }
        return "1 lesson"
    case .work:
        return summaryChip(log)
    }
}

/// "184k" → 184000 · "2.1m" → 2100000 · "184,000" → 184000
func parseTokens(_ s: String) -> Int {
    let t = s.lowercased().replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard t.range(of: #"^\d+(\.\d+)?[km]?$"#, options: .regularExpression) != nil else { return 0 }
    let mult: Double = t.hasSuffix("m") ? 1_000_000 : t.hasSuffix("k") ? 1_000 : 1
    let value = (Double(t.filter { $0.isNumber || $0 == "." }) ?? 0) * mult
    guard value.isFinite, value > 0, value <= 1_000_000_000_000 else { return 0 }
    return Int(value)
}

func linkHost(_ s: String) -> String {
    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
    let withScheme = t.contains("://") ? t : "https://" + t
    guard let h = URL(string: withScheme)?.host?.lowercased() else { return "link" }
    return h.hasPrefix("www.") ? String(h.dropFirst(4)) : h
}

// MARK: - Preferences (persisted)

enum Kit: String, CaseIterable, Identifiable {
    case bare, hoodie, tee, rollneck, glasses, cap, collar, cans
    var id: String { rawValue }
    var label: String {
        switch self {
        case .bare: "Bare"
        case .hoodie: "Hoodie"
        case .tee: "Gray tee"
        case .rollneck: "Black rollneck"
        case .glasses: "Round glasses"
        case .cap: "Cap"
        case .collar: "Clean collar"
        case .cans: "Cans"
        }
    }
    /// One word, for the wardrobe grid where the scene carries the rest of the line.
    var shortLabel: String {
        switch self {
        case .bare: "Bare"
        case .hoodie: "Hoodie"
        case .tee: "Tee"
        case .rollneck: "Rollneck"
        case .glasses: "Glasses"
        case .cap: "Cap"
        case .collar: "Collar"
        case .cans: "Cans"
        }
    }
}

let lockableApps = ["Instagram", "TikTok", "X", "YouTube", "Reddit", "Snapchat", "Netflix", "Safari"]

/// Costumes = founder / movie scenes on the same body. One at a time; maps onto a kit.
enum Costume: String, CaseIterable, Identifiable {
    case none, hoodie, rollneck, gymTee, collar
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: "None"
        case .hoodie: "Hoodie"
        case .rollneck: "Rollneck"
        case .gymTee: "Gym tee"
        case .collar: "Collar"
        }
    }
    var kit: Kit {
        switch self {
        case .none: .bare
        case .hoodie: .hoodie
        case .rollneck: .rollneck
        case .gymTee: .tee
        case .collar: .collar
        }
    }
    static func from(kit: Kit) -> Costume { allCases.first { $0.kit == kit } ?? .none }
}

final class Prefs: ObservableObject {
    private let d = UserDefaults.standard

    @Published var baseID: String { didSet { d.set(baseID, forKey: "base") } }
    @Published var kitID: String { didSet { d.set(kitID, forKey: "kit") } }
    @Published var selectedLookID: String { didSet { d.set(selectedLookID, forKey: "selectedLookID") } }
    @Published var selectedSceneID: String { didSet { d.set(selectedSceneID, forKey: "selectedSceneID") } }
    @Published var blush: Bool { didSet { d.set(blush, forKey: "blush") } }
    @Published var name: String { didSet { d.set(name, forKey: "name") } }
    @Published var county: String { didSet { d.set(county, forKey: "county") } }

    // Proof sources (stored only — never used to block anything)
    @Published var github: String { didSet { d.set(github, forKey: "github") } }
    @Published var linkedin: String { didSet { d.set(linkedin, forKey: "linkedin") } }
    @Published var appsToLock: String { didSet { d.set(appsToLock, forKey: "appsToLock") } }
    @Published var showFocused: Bool { didSet { d.set(showFocused, forKey: "showFocused") } }
    @Published var notificationsOn: Bool { didSet { d.set(notificationsOn, forKey: "notificationsOn") } }
    @Published var isDark: Bool { didSet { d.set(isDark, forKey: "isDark"); Theme.isDark = isDark } }
    @Published var providerID: String { didSet { d.set(providerID, forKey: "provider") } }

    // 2-field profile: name + one line. That's all a friend sees.
    @Published var shipping: String { didSet { d.set(shipping, forKey: "shipping") } }
    // One-time moments (Peak-End): invite after the first receipt, widget card next open, icon after the first Ship.
    @Published var inviteShown: Bool { didSet { d.set(inviteShown, forKey: "inviteShown") } }
    @Published var widgetCardShown: Bool { didSet { d.set(widgetCardShown, forKey: "widgetCardShown") } }
    @Published var iconOfferShown: Bool { didSet { d.set(iconOfferShown, forKey: "iconOfferShown") } }
    /// "" = Default · "LarpyHungry" · "LarpyRollneck"
    @Published var iconChoice: String { didSet { d.set(iconChoice, forKey: "iconChoice") } }
    /// Tomorrow's one thing. One field, never a list. `tomorrowIntentFor` is the day key it is for.
    @Published var tomorrowIntent: String { didSet { d.set(tomorrowIntent, forKey: "tomorrowIntent") } }
    @Published var tomorrowIntentFor: String { didSet { d.set(tomorrowIntentFor, forKey: "tomorrowIntentFor") } }
    /// The day 'Week two. Still here.' was earned. Said once.
    @Published var weekTwoLineDay: String { didSet { d.set(weekTwoLineDay, forKey: "weekTwoLineDay") } }
    /// First eligible receipt, epoch seconds. Starts the free month of wardrobe.
    @Published var firstReceiptAt: Double { didSet { d.set(firstReceiptAt, forKey: "firstReceiptAt") } }
    /// The day-one pill has opened the share sheet once.
    @Published var firstSharePillDone: Bool { didSet { d.set(firstSharePillDone, forKey: "firstSharePillDone") } }
    /// Friday Tape: the week key it was sealed or skipped for, the bet, the week the bet was made, and whether it landed.
    @Published var tapeWeek: String { didSet { d.set(tapeWeek, forKey: "tapeWeek") } }
    @Published var fridayBet: String { didSet { d.set(fridayBet, forKey: "fridayBet") } }
    @Published var fridayBetWeek: String { didSet { d.set(fridayBetWeek, forKey: "fridayBetWeek") } }
    @Published var fridayBetLanded: Bool { didSet { d.set(fridayBetLanded, forKey: "fridayBetLanded") } }
    /// The day the card was last sent to the witness. Once a day at most.
    @Published var witnessSentDay: String { didSet { d.set(witnessSentDay, forKey: "witnessSentDay") } }

    init() {
        isDark = d.bool(forKey: "isDark")            // default: light cream paper
        Theme.isDark = d.bool(forKey: "isDark")
        providerID = d.string(forKey: "provider") ?? "claude"
        shipping = d.string(forKey: "shipping") ?? ""
        inviteShown = d.bool(forKey: "inviteShown")
        widgetCardShown = d.bool(forKey: "widgetCardShown")
        iconOfferShown = d.bool(forKey: "iconOfferShown")
        iconChoice = (d.string(forKey: "iconChoice") ?? "").replacingOccurrences(of: "LarpyJobs", with: "LarpyRollneck")
        tomorrowIntent = d.string(forKey: "tomorrowIntent") ?? ""
        tomorrowIntentFor = d.string(forKey: "tomorrowIntentFor") ?? ""
        weekTwoLineDay = d.string(forKey: "weekTwoLineDay") ?? ""
        firstReceiptAt = d.double(forKey: "firstReceiptAt")
        firstSharePillDone = d.bool(forKey: "firstSharePillDone")
        tapeWeek = d.string(forKey: "tapeWeek") ?? ""
        fridayBet = d.string(forKey: "fridayBet") ?? ""
        fridayBetWeek = d.string(forKey: "fridayBetWeek") ?? ""
        fridayBetLanded = d.bool(forKey: "fridayBetLanded")
        witnessSentDay = d.string(forKey: "witnessSentDay") ?? ""
        baseID = d.string(forKey: "base") ?? "cream"
        kitID = d.string(forKey: "kit") ?? "bare"        // default: no clothes. Costumes are Settings-only.
        selectedLookID = d.string(forKey: "selectedLookID") ?? ""
        selectedSceneID = d.string(forKey: "selectedSceneID") ?? ""
        blush = d.object(forKey: "blush") as? Bool ?? true
        name = d.string(forKey: "name") ?? "You"
        county = d.string(forKey: "county") ?? ""
        github = d.string(forKey: "github") ?? ""
        linkedin = d.string(forKey: "linkedin") ?? ""
        appsToLock = d.string(forKey: "appsToLock") ?? ""
        showFocused = d.object(forKey: "showFocused") as? Bool ?? true
        notificationsOn = d.object(forKey: "notificationsOn") as? Bool ?? false
    }

    var base: LarpyBase { LarpyBase(rawValue: baseID) ?? .cream }
    var kit: Kit { Kit(rawValue: kitID) ?? .bare }
    var provider: Provider { Provider(rawValue: providerID) ?? .claude }
}

// MARK: - People (local only)

struct CircleMember: Identifiable, Codable {
    var id = UUID()
    var name: String
    var code: String
    var base: String
    var todayCount: Int?
    var lastSeen: Date?
}

struct MeInvite: Codable {
    var code: String
    var createdAt: Date
}

/// The one friend. Not a graph. Their receipts arrive only when a sync layer exists — never guessed here.
struct Friend: Codable {
    var code: String
    var name: String
    var shipping: String
    var joinedAt: Date
    var lastShipAt: Date? = nil
    var lastReceipt: String? = nil
}

final class CircleStore: ObservableObject {
    private let d = UserDefaults.standard
    @Published var members: [CircleMember] { didSet { persistMembers() } }
    @Published private(set) var invite: MeInvite
    @Published var friend: Friend? {
        didSet {
            if let f = friend, let data = try? JSONEncoder().encode(f) { d.set(data, forKey: "circle.friend") }
            else { d.removeObject(forKey: "circle.friend") }
        }
    }

    /// larpy://join/CODE?n=Name&s=what-I'm-shipping — opens straight into the friend's one slot.
    func inviteLink(name: String, shipping: String) -> URL {
        var c = URLComponents()
        c.scheme = "larpy"; c.host = "join"; c.path = "/\(invite.code)"
        c.queryItems = [URLQueryItem(name: "n", value: name), URLQueryItem(name: "s", value: shipping)]
        return c.url ?? URL(string: "larpy://join/\(invite.code)")!
    }

    /// The share-sheet text. Link for phones with Larpy, code for everyone else.
    func inviteText(name: String, shipping: String) -> String {
        let who = name.isEmpty || name == "You" ? "I'm" : "\(name) is"
        return "\(who) keeping Larpy alive. One friend sees the receipts — you.\n\(inviteLink(name: name, shipping: shipping).absoluteString)\nCode: \(invite.code)"
    }

    /// One slot. Own code rejected. Same code re-added just refreshes the name.
    @discardableResult
    func setFriend(code raw: String, name: String, shipping: String) -> Bool {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 6, code.allSatisfy({ "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains($0) }), code != invite.code else { return false }
        if let f = friend, f.code != code { return false }      // one person this version
        friend = Friend(code: code, name: name.isEmpty ? "Friend" : name, shipping: shipping,
                        joinedAt: friend?.joinedAt ?? .now, lastShipAt: friend?.lastShipAt, lastReceipt: friend?.lastReceipt)
        return true
    }

    init() {
        if let data = d.data(forKey: "circle.friend"),
           let f = try? JSONDecoder().decode(Friend.self, from: data) { friend = f } else { friend = nil }
        if let data = d.data(forKey: "circle.invite"),
           let m = try? JSONDecoder().decode(MeInvite.self, from: data) {
            invite = m
        } else {
            let m = MeInvite(code: CircleStore.newCode(), createdAt: .now)
            invite = m
            d.set(try? JSONEncoder().encode(m), forKey: "circle.invite")
        }

        if let data = d.data(forKey: "circle.members"),
           let list = try? JSONDecoder().decode([CircleMember].self, from: data) {
            members = list
        } else {
            members = []
        }
    }

    var shareURL: URL { URL(string: "https://larpy.app/join/\(invite.code)")! }

    /// Returns false if rejected (own code or full or duplicate).
    @discardableResult
    func add(code raw: String) -> Bool {
        let code = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 6 else { return false }
        guard code != invite.code else { return false }
        guard members.count < 1 else { return false }
        guard !members.contains(where: { $0.code == code }) else { return false }
        members.append(CircleMember(name: "Friend · \(code)", code: code, base: "cream"))
        return true
    }

    private func persistMembers() {
        d.set(try? JSONEncoder().encode(members), forKey: "circle.members")
    }

    static func newCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - Agents (pasted token totals, local only)

struct AgentEntry: Identifiable, Codable {
    var id = UUID()
    var source: String   // Claude / Cursor / Grok
    var tokens: Int
    var at: Date
    var modelSpend: Bool?
}

let agentSources = ["Claude", "Cursor", "Grok"]

final class AgentStore: ObservableObject {
    private let d = UserDefaults.standard
    @Published private(set) var entries: [AgentEntry] = []

    init() {
        if let data = d.data(forKey: "agents"),
           let list = try? JSONDecoder().decode([AgentEntry].self, from: data) {
            entries = list
        }
    }

    /// Add overwrites that source for today.
    func add(source: String, tokens: Int) {
        let cal = LarpyTime.cal
        entries.removeAll { $0.source == source && cal.isDateInToday($0.at) }
        entries.append(AgentEntry(source: source, tokens: tokens, at: .now))
        d.set(try? JSONEncoder().encode(entries), forKey: "agents")
    }

    func total(daysAgoFrom start: Int, to end: Int) -> Int {
        // sums entries whose Dublin day is in [today-start ... today-end] (start >= end)
        let cal = LarpyTime.cal
        let today = cal.startOfDay(for: .now)
        guard let lo = cal.date(byAdding: .day, value: -start, to: today),
              let hi = cal.date(byAdding: .day, value: -end + 1, to: today) else { return 0 }
        return entries.filter { $0.at >= lo && $0.at < hi }.map(\.tokens).reduce(0, +)
    }

    var weekTotal: Int { total(daysAgoFrom: 6, to: 0) }
    var lastWeekTotal: Int { total(daysAgoFrom: 13, to: 7) }
    var allTime: Int { entries.map(\.tokens).reduce(0, +) }

    /// Highest rolling-7-day total ever.
    var highWaterWeek: Int {
        let cal = LarpyTime.cal
        guard let first = entries.map(\.at).min() else { return 0 }
        let today = cal.startOfDay(for: .now)
        var best = 0
        var d = cal.startOfDay(for: first)
        while d <= today {
            let lo = cal.date(byAdding: .day, value: -6, to: d)!
            let hi = cal.date(byAdding: .day, value: 1, to: d)!
            let s = entries.filter { $0.at >= lo && $0.at < hi }.map(\.tokens).reduce(0, +)
            best = max(best, s)
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }
        return best
    }

    var modelTokensThisWeek: Int {
        let start = LarpyTime.cal.dateInterval(of: .weekOfYear, for: .now)!.start
        return entries.filter { $0.modelSpend == true && $0.at >= start }.map(\.tokens).reduce(0, +)
    }
    /// Model spend from "Ask an agent" — separate from Today's LOAD count.
    func recordSpend(_ n: Int, provider: String) {
        guard n > 0 else { return }
        entries.append(AgentEntry(source: provider, tokens: n, at: .now, modelSpend: true))
        d.set(try? JSONEncoder().encode(entries), forKey: "agents")
    }

    func todayTokens(for source: String) -> Int? {
        entries.first { $0.source == source && LarpyTime.cal.isDateInToday($0.at) }?.tokens
    }
}

// MARK: - Agents: provider + key on device + one job (a week sentence)

enum Provider: String, CaseIterable, Identifiable {
    case apple, claude, openai, grok
    var id: String { rawValue }
    var label: String {
        switch self {
        case .apple: "Apple"
        case .claude: "Claude"
        case .openai: "ChatGPT"
        case .grok: "Grok"
        }
    }
    var needsKey: Bool { self != .apple }
}

/// Keys live in the Keychain, never in UserDefaults.
enum Keychain {
    private static func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "com.larpy.app.agents",
         kSecAttrAccount as String: key]
    }
    static func set(_ value: String, for key: String) {
        delete(key)
        var q = query(key)
        q[kSecValueData as String] = Data(value.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }
    static func get(_ key: String) -> String? {
        var q = query(key)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func delete(_ key: String) { SecItemDelete(query(key) as CFDictionary) }
}

final class AgentKeys: ObservableObject {
    @Published private(set) var stored: Set<Provider> = []
    init() { stored = Set(Provider.allCases.filter { $0.needsKey && Keychain.get($0.rawValue) != nil }) }
    func key(for p: Provider) -> String? { Keychain.get(p.rawValue) }
    func set(_ key: String, for p: Provider) {
        let k = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else { return }
        Keychain.set(k, for: p.rawValue); stored.insert(p)
    }
    func clear(_ p: Provider) { Keychain.delete(p.rawValue); stored.remove(p) }
    func clearAll() { Provider.allCases.forEach { clear($0) } }

    /// Apple = on-device Foundation Models; no key. Only when the device says it's available.
    static var appleAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }
    func canRun(_ p: Provider) -> Bool { p == .apple ? AgentKeys.appleAvailable : stored.contains(p) }
    var anyAvailable: Bool { Provider.allCases.contains { canRun($0) } }
}

struct AgentError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// The one job: one sentence about this week's logs.
enum WeekAgent {
    static let instructions = """
    You write exactly one sentence, at most 22 words, in a short spoken tone. \
    No coach-speak, no emoji, no hashtags, never the phrase "giving up". \
    Be specific to the logs you are given.
    """

    static func prompt(days: [(label: String, proofs: [String])]) -> String {
        let lines = days.map { d in "\(d.label): " + (d.proofs.isEmpty ? "nothing" : d.proofs.joined(separator: ", ")) }
        return "This week's proof log (Mon to Sun):\n" + lines.joined(separator: "\n") + "\n\nWrite one sentence about the week."
    }

    /// Returns the sentence and the model tokens it cost (0 for on-device Apple).
    static func sentence(days: [(label: String, proofs: [String])], provider: Provider, key: String?) async throws -> (text: String, spend: Int) {
        let user = prompt(days: days)
        switch provider {
        case .apple:
            #if canImport(FoundationModels)
            if #available(iOS 26, *) {
                let session = LanguageModelSession(instructions: instructions)
                return (try await session.respond(to: user).content.trimmingCharacters(in: .whitespacesAndNewlines), 0)
            }
            #endif
            throw AgentError(message: "Apple Intelligence isn't available on this device.")
        case .claude:
            guard let key else { throw AgentError(message: "Add a Claude key in Settings → Agents.") }
            return try await claude(key: key, user: user)
        case .openai:
            guard let key else { throw AgentError(message: "Add a ChatGPT key in Settings → Agents.") }
            return try await chatCompletions(url: "https://api.openai.com/v1/chat/completions", model: "gpt-4o-mini", key: key, user: user)
        case .grok:
            guard let key else { throw AgentError(message: "Add a Grok key in Settings → Agents.") }
            return try await chatCompletions(url: "https://api.x.ai/v1/chat/completions", model: "grok-3-mini", key: key, user: user)
        }
    }

    // Anthropic Messages API — raw HTTP (no Swift SDK). Refusal fallbacks on by default.
    private static func claude(key: String, user: String) async throws -> (text: String, spend: Int) {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        let body: [String: Any] = [
            "model": "claude-opus-5",
            "max_tokens": 200,                      // one sentence; deliberately short
            "fallbacks": "default",
            "system": instructions,
            "messages": [["role": "user", "content": user]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try check(resp, data)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw AgentError(message: "Bad reply.") }
        if json["stop_reason"] as? String == "refusal" { throw AgentError(message: "Claude declined that one.") }
        let text = (json["content"] as? [[String: Any]] ?? [])
            .filter { $0["type"] as? String == "text" }
            .compactMap { $0["text"] as? String }
            .joined()
        let usage = json["usage"] as? [String: Any]
        let spend = (usage?["input_tokens"] as? Int ?? 0) + (usage?["output_tokens"] as? Int ?? 0)
        return (text.trimmingCharacters(in: .whitespacesAndNewlines), spend)
    }

    // OpenAI-shaped chat completions (ChatGPT, Grok). Just another key.
    private static func chatCompletions(url: String, model: String, key: String, user: String) async throws -> (text: String, spend: Int) {
        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 120,
            "messages": [["role": "system", "content": instructions], ["role": "user", "content": user]]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        try check(resp, data)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let msg = choices.first?["message"] as? [String: Any],
              let text = msg["content"] as? String else { throw AgentError(message: "Bad reply.") }
        let spend = (json["usage"] as? [String: Any])?["total_tokens"] as? Int ?? 0
        return (text.trimmingCharacters(in: .whitespacesAndNewlines), spend)
    }

    private static func check(_ resp: URLResponse, _ data: Data) throws {
        guard let http = resp as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let snippet = String(data: data, encoding: .utf8)?.prefix(160) ?? ""
            throw AgentError(message: "HTTP \(http.statusCode). \(snippet)")
        }
    }
}

/// 8.4k / 184k / 2.1M
func fmtTokens(_ n: Int) -> String {
    if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000).replacingOccurrences(of: ".0M", with: "M") }
    if n >= 10_000 { return "\(n / 1000)k" }
    if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000).replacingOccurrences(of: ".0k", with: "k") }
    return "\(n)"
}

// MARK: - Root

struct ContentView: View {
    @StateObject private var store = ProofStore()
    @StateObject private var prefs = Prefs()
    @StateObject private var circle = CircleStore()
    @StateObject private var agents = AgentStore()
    @StateObject private var keys = AgentKeys()
    @StateObject private var loads = LoadLedger()
    @StateObject private var connections = ConnectionsStore()
    @Environment(\.scenePhase) private var scenePhase

    @State private var dayRefresh = Date.now
    private let dayClock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @State private var tab = 0
    @State private var activeLane: QuestKind?
    @State private var showSettings = false
    @State private var showAsk = false
    @State private var draft: ShareDraft?
    @AppStorage("journeySetupDone") private var setupDone = false
    @State private var showPeople = false

    var body: some View {
        TabView(selection: $tab) {
            home
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(0)

            JourneyProgressView(store: store, prefs: prefs, keys: keys, agents: agents, loads: loads)
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .tag(1)

            WardrobeView(store: store, prefs: prefs, embedded: true)
                .tabItem { Label("Skins", systemImage: "tshirt.fill") }
                .tag(2)
        }
        .onReceive(dayClock) { date in if !Calendar.current.isDate(dayRefresh, inSameDayAs: date) { dayRefresh = date; refreshAll() } }
        .id("\(prefs.isDark)-\(LarpyTime.dayKey(dayRefresh))")                                   // rebuild the tree when the theme flips
        .tint(Palette.gold)
        .environmentObject(connections)
        .preferredColorScheme(prefs.isDark ? .dark : .light)
        .alert("Receipt not saved", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK") { store.errorMessage = nil }
        } message: { Text(store.errorMessage ?? "Try again.") }
        .sheet(isPresented: $showSettings) {
            SimpleSettingsView(store: store, prefs: prefs, loads: loads, agents: agents)
        }
        .fullScreenCover(isPresented: Binding(get: { !setupDone }, set: { if !$0 { setupDone = true } })) {
            JourneyProfileView(prefs: prefs, store: store, loads: loads, onboarding: true)
        }
        .sheet(isPresented: $showPeople) { PeopleView(circle: circle, prefs: prefs, store: store, onSettings: { showSettings = true }) }
        .sheet(isPresented: $showAsk) { AskView(store: store, prefs: prefs) }
        // No popups after a receipt. The day-one pill and the widget card live inline on Today.
        .sheet(item: $draft) { d in DraftSheet(draft: d, store: store, loads: loads) }
        #if DEBUG
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-skipSetup") { setupDone = true }
            if args.contains("-openSetup") { setupDone = false }
            if args.contains("-openSettings") { DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showSettings = true } }
            if args.contains("-openAsk") { DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showAsk = true } }
            if args.contains("-dark") { prefs.isDark = true }
            if args.contains("-light") { prefs.isDark = false }
            if args.contains("-tailCard") { prefs.widgetCardShown = false }
            if args.contains("-openWeek") { tab = 1 }
            if args.contains("-openPeople") { tab = 2 }
            if let index = args.firstIndex(of: "-qaUsageFolder"), args.indices.contains(index + 1) {
                connections.connectUsage(folder: URL(fileURLWithPath: args[index + 1]), store: store, loads: loads)
            }
        }
        #endif
        .onAppear {
            refreshAll()
            pickUpDraft()
            connections.start(store: store, loads: loads)
            if prefs.firstReceiptAt == 0, let first = store.logs.filter(\.isEligible).map(\.createdAt).min() {
                prefs.firstReceiptAt = first.timeIntervalSince1970
            }
        }
        .onChange(of: store.logs) { refreshAll() }
        .onChange(of: agents.weekTotal) { refreshAll() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshAll()
            pickUpDraft()
            connections.refresh(store: store, loads: loads)
        }
        .onOpenURL { url in
            guard url.scheme == "larpy" else { return }
            // larpy://draft — the share extension parked something
            if url.host == "draft" { pickUpDraft(); return }
            // larpy://join/CODE?n=Name&s=shipping — become each other's one slot
            if url.host == "join" {
                let code = url.pathComponents.last ?? ""
                let q = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
                let n = q.first { $0.name == "n" }?.value ?? "Friend"
                let s = q.first { $0.name == "s" }?.value ?? ""
                if circle.setFriend(code: code, name: n, shipping: s) { showPeople = true }
                return
            }
            // larpy://log/body|learn|work
            let lane = url.pathComponents.last ?? url.host
            switch lane {
            case "body": activeLane = .body; tab = 0
            case "learn": activeLane = .learn; tab = 0
            case "work": activeLane = .work; tab = 0
            default: break
            }
        }
    }

    @ViewBuilder private var home: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-companionPreview") || ProcessInfo.processInfo.arguments.contains("-roomPreview") {
            CompanionDesignPreview(store: store, prefs: prefs, loads: loads, circle: circle,
                                   onSettings: { showSettings = true })
        } else {
            TodayView(store: store, prefs: prefs, loads: loads, circle: circle, active: $activeLane, onSettings: { showSettings = true })
        }
        #else
        TodayView(store: store, prefs: prefs, loads: loads, circle: circle, active: $activeLane, onSettings: { showSettings = true })
        #endif
    }

    private func refreshAll() {
        LarpyReminders.refresh(store: store, agents: agents)
        WidgetBridge.write(store: store, prefs: prefs)
    }

    /// Something shared in from another app → open it prefilled. The user confirms the lane.
    private func pickUpDraft() {
        ShareInbox.importLoads(store: store, loads: loads)
        guard draft == nil, let d = ShareInbox.take() else { return }
        activeLane = nil
        tab = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { draft = d }
    }

}

private struct GearButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Palette.muted)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today

/// Today keeps the character and three actions readable at the user's chosen text size.
private struct TodayView: View {
    @AppStorage("careerPath") private var careerID = CareerPath.exploring.rawValue
    private var career: CareerPath { CareerPath(rawValue: careerID) ?? .exploring }
    @ObservedObject var store: ProofStore
    @ObservedObject var prefs: Prefs
    @ObservedObject var loads: LoadLedger
    @ObservedObject var circle: CircleStore
    @Binding var active: QuestKind?
    let onSettings: () -> Void
    @State private var prefillLoad = false
    @State private var prefillNote = ""
    @State private var flashLane: QuestKind?
    @State private var feedSequence = 0
    @State private var fedLane = 0
    @State private var showWardrobe = false
    @State private var showConnections = false
    @EnvironmentObject private var connections: ConnectionsStore
    @State private var showShare = false
    @State private var shareImage: UIImage?
    @State private var lanesOpen = false
    @State private var intentDraft = ""
    @State private var betDraft = ""
    @State private var forceTape = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var stackedControls: Bool { dynamicTypeSize >= .xxxLarge }
    private var controlsLayout: AnyLayout {
        stackedControls ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout())
    }

    private var life: LifeState { LifeEngine.life(store.logs) }
    private var stats: WeekStats { LifeEngine.stats(store.logs) }
    private var founderID: String? { CharacterStyle.lookID(logs: store.logs, selected: prefs.selectedLookID) }
    private var sceneKit: Kit { FounderLook.find(founderID)?.kit ?? prefs.kit }
    private var todayScene: MovieScene {
        CharacterStyle.scene(logs: store.logs, selected: prefs.selectedSceneID, kit: sceneKit)
    }
    private var friendShipped: String? {
        guard let f = circle.friend, let at = f.lastShipAt, LarpyTime.cal.isDateInToday(at) else { return nil }
        return f.name
    }
    /// Day zero: nothing has ever been logged. The first receipt is the setup.
    private var dayZero: Bool { store.logs.isEmpty }
    /// Three or more empty days and nothing yet today: the sofa era. One receipt ends it.
    private var returnDoor: Bool { !dayZero && stats.emptyStreak >= 3 && stats.todayCount == 0 }
    private var hour: Int { LarpyTime.cal.component(.hour, from: .now) }
    private var todayKey: String { LarpyTime.dayKey() }
    private var tomorrowKey: String { LarpyTime.dayKey(LarpyTime.cal.date(byAdding: .day, value: 1, to: .now) ?? .now) }
    private var intentForToday: String? { prefs.tomorrowIntentFor == todayKey && !prefs.tomorrowIntent.isEmpty ? prefs.tomorrowIntent : nil }
    private var intentForTomorrow: String? { prefs.tomorrowIntentFor == tomorrowKey && !prefs.tomorrowIntent.isEmpty ? prefs.tomorrowIntent : nil }
    private var asksForIntent: Bool { !dayZero && intentForTomorrow == nil && (stats.todayCount == 3 || hour >= 20) }

    // MARK: Friday Tape (Friday noon to Sunday night, once per week, sealed or skipped)
    private var weekKey: String {
        let f = DateFormatter(); f.calendar = LarpyTime.cal; f.dateFormat = "YYYY-'W'ww"; return f.string(from: .now)
    }
    private var weekNumber: Int { LarpyTime.cal.component(.weekOfYear, from: .now) }
    private var tapeWindow: Bool {
        let wd = LarpyTime.cal.component(.weekday, from: .now)     // 1 Sun … 6 Fri, 7 Sat
        return (wd == 6 && hour >= 12) || wd == 7 || wd == 1
    }
    private var showsTape: Bool { !dayZero && (forceTape || (tapeWindow && prefs.tapeWeek != weekKey)) }
    private struct WeekCounts { var work = 0, body = 0, learn = 0 }
    private func counts(weeksAgo: Int) -> WeekCounts? {
        let cal = LarpyTime.cal
        guard let thisMonday = cal.dateInterval(of: .weekOfYear, for: cal.startOfDay(for: .now))?.start,
              let monday = cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: thisMonday),
              let end = cal.date(byAdding: .weekOfYear, value: 1, to: monday) else { return nil }
        if weeksAgo > 0, !store.logs.contains(where: { $0.createdAt < end }) { return nil }   // no history before this week
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
        var c = WeekCounts()
        c.work = store.logs.filter { $0.quest == .work && $0.isEligible && $0.createdAt >= monday && $0.createdAt < end }.count
        c.body = days.filter { LifeEngine.laneDone(store.logs, .body, on: $0) }.count
        c.learn = days.filter { LifeEngine.laneDone(store.logs, .learn, on: $0) }.count
        return c
    }
    private var tapeVerdict: String {
        guard let last = counts(weeksAgo: 1) else { return "Week one. Nothing to beat yet." }
        let d = stats.workN - last.work
        if d == 0 { return "Same as last week." }
        let words = ["one", "two", "three", "four", "five", "six", "seven"]
        let n = abs(d) <= 7 ? words[abs(d) - 1] : "\(abs(d))"
        return d > 0 ? "Up \(n)." : "Down \(n)."
    }

    /// The one line a person is guaranteed to read. Keyed to receipts, never to the day of the year for the first three.
    private var headline: String {
        if dayZero { return "Show me the thing." }
        if returnDoor { return "Sofa era. One thing and it ends." }
        let eligible = store.logs.filter(\.isEligible)
        if eligible.count == 1, let only = eligible.first {
            switch only.quest {
            case .work: return "Out in the world. Now the next one."
            case .body: return "Body's in. The product's still a rumour."
            case .learn: return "Loaded. Where does it go."
            }
        }
        if eligible.count == 2 {
            return eligible.contains { $0.quest == .work } ? "Second receipt. Now it's a pattern, not a mood." : "Two receipts. Neither left the building."
        }
        if stats.todayCount == 0, stats.proofsYesterday > 0 { return "Yesterday's receipt expired at midnight." }
        if let intent = intentForToday, hour >= 18, !store.doneToday(.work) { return "You said \u{201C}\(intent)\u{201D}. Where is it." }
        if LarpyTime.cal.component(.weekday, from: .now) == 2, stats.workN == 0, stats.todayCount == 0 { return "New week. Costume's back on." }
        if prefs.weekTwoLineDay == todayKey { return "Week two. Still here." }
        return Voice.line(train: store.doneToday(.body), load: store.doneToday(.learn), ship: store.doneToday(.work), isEgg: false, friendShipped: friendShipped)
    }

    private var caption: String {
        if dayZero { return "BARE. ZERO RECEIPTS." }
        if returnDoor { return "\(stats.emptyStreak) DAYS. 0 RECEIPTS." }
        if stats.todayCount == 0 { return "WAITING FOR EVIDENCE" }
        return todayScene.caption
    }

    private var dateLine: String {
        let f = DateFormatter(); f.calendar = LarpyTime.cal; f.dateFormat = "EEE d MMM"
        let count = stats.todayCount == 0 ? "NOTHING IN" : "\(stats.todayCount)/3 IN"
        return "\(f.string(from: .now).uppercased()) · \(count)"
    }

    private var lastWorkLine: String? {
        guard let last = store.logs.first(where: { $0.quest == .work && $0.isEligible }) else { return nil }
        let f = DateFormatter(); f.calendar = LarpyTime.cal; f.dateFormat = "EEE"
        let host = last.proofKind == .link ? linkHost(last.value).uppercased() : "SCREENSHOT"
        return "LAST WORK · \(f.string(from: last.createdAt).uppercased()) · \(host)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Build your next chapter.")
                        .font(.system(.title2, design: .serif).weight(.medium)).tracking(-0.6)
                        .foregroundStyle(Palette.text)
                    Text(career == .exploring ? "Three small actions. A character that grows with you." : "Your path · \(career.title)")
                        .font(.subheadline).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4).padding(.bottom, 14)

                let stageHeight: CGFloat = 168
                LarpyCharacterView(life: life, base: .cream, kit: sceneKit,
                                   width: 106, scene: todayScene, sceneCorner: 24, interactive: true,
                                   fedTick: feedSequence, fedLane: fedLane, level: stats.workN, founderID: founderID)
                    .frame(maxWidth: .infinity).frame(height: stageHeight)
                controlsLayout {
                    Text(FounderLook.find(founderID)?.styleName ?? "Your Larpy").font(.subheadline).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if !stackedControls { Spacer(minLength: 8) }
                    Button { showWardrobe = true } label: {
                        Label("Skins", systemImage: "tshirt")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.text)
                            .fixedSize(horizontal: false, vertical: true).frame(minHeight: 44)
                    }.buttonStyle(ReceiptPressStyle())
                }
                NextSkinView(store: store) { showWardrobe = true }
                controlsLayout {
                    Text("What did you do today?").font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    if !stackedControls { Spacer() }
                    Text("\(stats.todayCount) of 3").font(.subheadline).monospacedDigit().foregroundStyle(Palette.muted)
                }.foregroundStyle(Palette.text).padding(.top, 8).padding(.bottom, 12)
                rows
                Text("One qualifying day per activity. Every earned skin stays yours.")
                    .font(.footnote).foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 12)
                Button { showConnections = true } label: {
                    HStack { Text("AI usage"); Spacer(); Text(loads.usageSummary); Image(systemName: "chevron.right") }
                        .font(.subheadline).foregroundStyle(Palette.muted).frame(minHeight: 44)
                }.padding(.top, 10)
            }.padding(.horizontal, 22).padding(.top, 6).padding(.bottom, 24)
        }.scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            header.padding(.horizontal, 22).padding(.bottom, 8).background(Palette.bg)
        }
        .background(Palette.bg.ignoresSafeArea())
        .sheet(isPresented: $showConnections) { ConnectionsView(store: store, loads: loads) }
        .sheet(item: $active) { quest in
            LogSheet(quest: quest, store: store, loads: loads, prefillLoad: prefillLoad && quest == .learn, prefillNote: quest == .work ? prefillNote : "")
        }
        .sheet(isPresented: $showWardrobe) { WardrobeView(store: store, prefs: prefs) }
        #if DEBUG
        // Screenshot hooks: `simctl launch <sim> com.larpy.app -openWardrobe` / `-openShare`. Debug builds only.
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-openWardrobe") { showWardrobe = true } }
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-openConnections") { showConnections = true } }
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-friday") { forceTape = true } }
        .onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-openShare") else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                renderShare()
                if let png = shareImage?.pngData() {
                    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("share-card.png")
                    try? png.write(to: url)
                }
                showShare = true
            }
        }
        #endif
        .sheet(isPresented: $showShare) {
            VStack(spacing: 18) {
                if let shareImage {
                    Image(uiImage: shareImage).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 18))
                    ShareLink(item: Image(uiImage: shareImage), preview: SharePreview("Larpy · receipt edition", image: Image(uiImage: shareImage))) {
                        Label("Share the proof", systemImage: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity, minHeight: 54).background(Palette.gold, in: Capsule())
                    }
                }
            }.padding(24).background(Palette.bg).presentationDetents([.large])
        }
        .onChange(of: store.logs.first?.id) { _, _ in
            guard let log = store.logs.first, LarpyTime.cal.isDateInToday(log.createdAt) else { return }
            fedLane = log.quest == .body ? 1 : log.quest == .learn ? 2 : 3
            feedSequence += 1
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeOut(duration: 0.2)) { flashLane = log.quest }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { withAnimation { flashLane = nil } }
            // Week two, said once, on the first receipt day of the second calendar week.
            if prefs.weekTwoLineDay.isEmpty, let first = store.logs.map(\.createdAt).min(),
               let firstWeek = LarpyTime.cal.dateInterval(of: .weekOfYear, for: first),
               let next = LarpyTime.cal.date(byAdding: .weekOfYear, value: 1, to: firstWeek.start),
               LarpyTime.cal.isDate(.now, equalTo: next, toGranularity: .weekOfYear) {
                prefs.weekTwoLineDay = todayKey
            }
            if prefs.firstReceiptAt == 0, log.isEligible { prefs.firstReceiptAt = log.createdAt.timeIntervalSince1970 }
        }
    }

    // MARK: pieces

    private var header: some View {
        controlsLayout {
            Text("Today").font(.largeTitle.weight(.bold)).tracking(-1)
                .foregroundStyle(Palette.text).lineLimit(1).minimumScaleFactor(0.75)
            if !stackedControls { Spacer(minLength: 8) }
            HStack(spacing: 2) {
                if stats.todayCount >= 1 {
                    Button { renderShare(); showShare = true } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .medium)).foregroundStyle(Palette.muted)
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Share today")
                        .transition(reduceMotion ? .identity : .opacity)
                }
                GearButton(action: onSettings).frame(width: 44, height: 44).accessibilityLabel("Settings")
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: stats.todayCount)
    }

    @ViewBuilder private var captionBlock: some View {
        VStack(spacing: 5) {
            Text(caption)
                .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(1.7)
                .foregroundStyle(Palette.muted)
            if let intent = intentForToday {
                let done = stats.todayCount > 0
                Button {
                    prefillNote = done ? "" : intent; prefillLoad = false; active = .work
                } label: {
                    HStack(spacing: 6) {
                        if !done { Circle().fill(Palette.gold).frame(width: 5, height: 5) }
                        Text(intent)
                            .font(done ? .system(size: 10, weight: .medium, design: .monospaced) : .system(size: 12, design: .serif).italic())
                            .strikethrough(done, color: Palette.muted)
                            .foregroundStyle(done ? Palette.muted : Palette.text)
                            .lineLimit(1)
                    }
                }.buttonStyle(.plain).accessibilityLabel("Today's one thing: \(intent)")
            }
        }
        .padding(.top, 8).frame(minHeight: 26)
        .contentShape(Rectangle()).onTapGesture { showWardrobe = true }
    }

    /// Seven segments, one per day Monday to Sunday. Gold where Work landed. Dashed where the day hasn't come.
    private var weekBlock: some View {
        let cal = LarpyTime.cal
        let today = cal.startOfDay(for: .now)
        let monday = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let days = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
        return VStack(spacing: 7) {
            HStack(spacing: 3) {
                ForEach(days, id: \.self) { d in
                    let future = d > today
                    let shipped = LifeEngine.laneDone(store.logs, .work, on: d)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(shipped ? Palette.gold : future ? Color.clear : Palette.line)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Palette.line, style: StrokeStyle(lineWidth: 1, dash: future ? [2, 2] : [])).opacity(future ? 1 : 0))
                        .frame(height: 6)
                        .accessibilityHidden(true)
                }
            }
            HStack {
                Text("\(stats.workN) out this week").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.text)
                Spacer()
                Text(stats.workN >= 7 ? "EARNED" : "NEXT AT \(ShipLevel.next(stats.workN))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(Palette.muted)
            }.monospacedDigit()
            HStack {
                Text(ShipLevel.title(stats.workN).uppercased()).tracking(1.4)
                Spacer()
                if let lastWorkLine { Text(lastWorkLine).tracking(1.2).lineLimit(1).minimumScaleFactor(0.7) }
            }.font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(Palette.muted)
        }.padding(.top, 14).padding(.horizontal, 2)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(stats.workN) Work receipts this week. \(ShipLevel.title(stats.workN)).")
    }

    /// After a Work receipt, once a day, when a witness is named: send them the card. Success is a reply.
    @ViewBuilder private var witnessLine: some View {
        if let friend = circle.friend, store.doneToday(.work), prefs.witnessSentDay != todayKey, let img = shareImage ?? renderedShare() {
            HStack {
                Spacer()
                ShareLink(item: Image(uiImage: img), subject: Text("\(stats.workN) out this week."), message: Text("\(stats.workN) out this week."),
                          preview: SharePreview("Larpy · \(stats.workN) out this week", image: Image(uiImage: img))) {
                    Text("Send to \(friend.name)").font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.gold)
                        .frame(minHeight: 36)
                }
                .simultaneousGesture(TapGesture().onEnded { prefs.witnessSentDay = todayKey })
            }.padding(.top, 4)
        }
    }

    /// Friday Tape, the small version. Three numbers against last week, one verdict, one bet, one seal.
    private var fridayTape: some View {
        let last = counts(weeksAgo: 1)
        let previousBet = !prefs.fridayBet.isEmpty && prefs.fridayBetWeek != weekKey ? prefs.fridayBet : nil
        return VStack(alignment: .leading, spacing: 14) {
            Text("FRIDAY TAPE · W\(weekNumber)").font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(2).foregroundStyle(Palette.muted)
            HStack(alignment: .top, spacing: 0) {
                tapeNumber(stats.workN, last?.work, "WORK", Palette.gold)
                tapeNumber(stats.bodyN, last?.body, "BODY DAYS", Palette.train)
                tapeNumber(stats.learnN, last?.learn, "LEARNT DAYS", Palette.load)
            }
            Text(tapeVerdict).font(.system(size: 27, weight: .medium, design: .serif)).tracking(-0.8).foregroundStyle(Palette.text)
            if let previousBet {
                HStack(spacing: 10) {
                    Text(prefs.fridayBetLanded ? "BET · LANDED" : "BET · STILL A THOUGHT").font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(1.4).foregroundStyle(prefs.fridayBetLanded ? Palette.gold : Palette.muted)
                    Text(previousBet).font(.system(size: 13, design: .serif).italic()).foregroundStyle(Palette.text).lineLimit(1)
                    Spacer()
                    if !prefs.fridayBetLanded {
                        Button("That was it") { prefs.fridayBetLanded = true }.font(.system(size: 12, weight: .semibold)).foregroundStyle(Palette.gold).buttonStyle(.plain)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                TextField("What ships by Friday?", text: $betDraft).font(.system(size: 17, design: .serif)).foregroundStyle(Palette.text)
                    .onChange(of: betDraft) { _, v in if v.count > 60 { betDraft = String(v.prefix(60)) } }
                HandDrawnUnderline().stroke(Palette.gold, style: StrokeStyle(lineWidth: 1.5, lineCap: .round)).frame(height: 5)
            }
            HStack(spacing: 18) {
                Button { seal(bet: betDraft) } label: {
                    Text("Seal the tape").font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: 44).background(Palette.gold, in: Capsule())
                }.buttonStyle(.plain)
                Button("Skip") { seal(bet: "") }.font(.system(size: 14, weight: .medium)).foregroundStyle(Palette.muted).buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Palette.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Palette.line, lineWidth: 1))
        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
    }
    private func tapeNumber(_ now: Int, _ before: Int?, _ label: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(now)").font(.system(size: 44, weight: .medium, design: .serif)).tracking(-2).foregroundStyle(Palette.text)
                if let before {
                    let d = now - before
                    Text(d == 0 ? "=" : d > 0 ? "+\(d)" : "\(d)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(d > 0 ? Palette.gold : Palette.muted)
                }
            }
            HStack(spacing: 5) {
                Circle().fill(tint).frame(width: 5, height: 5)
                Text(label).font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.2).foregroundStyle(Palette.muted)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func seal(bet: String) {
        let t = bet.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty { prefs.fridayBet = t; prefs.fridayBetWeek = weekKey; prefs.fridayBetLanded = false }
        withAnimation(.easeOut(duration: 0.26)) { prefs.tapeWeek = weekKey; forceTape = false }
        betDraft = ""
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private var dayZeroLevel: some View {
        HStack {
            Text("LARPING").tracking(1.4)
            Spacer()
            Text("FIRST PROOF AT 1")
        }.font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(Palette.muted)
            .padding(.top, 14).padding(.horizontal, 2)
    }

    /// One field, never a list. Tomorrow's one thing, also the Friday bet.
    private var intentField: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                TextField("Tomorrow's one thing", text: $intentDraft)
                    .font(.system(size: 17, design: .serif)).foregroundStyle(Palette.text)
                    .submitLabel(.done).onSubmit(commitIntent)
                    .onChange(of: intentDraft) { _, v in if v.count > 60 { intentDraft = String(v.prefix(60)) }; if v.contains("\n") { intentDraft = v.replacingOccurrences(of: "\n", with: " ") } }
                HandDrawnUnderline().stroke(Palette.gold, style: StrokeStyle(lineWidth: 1.5, lineCap: .round)).frame(height: 5)
            }
            Button(action: commitIntent) {
                Image(systemName: "arrow.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.ink)
                    .frame(width: 32, height: 32).background(Palette.gold, in: Circle())
            }.buttonStyle(.plain).disabled(intentDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(intentDraft.trimmingCharacters(in: .whitespaces).isEmpty ? 0.35 : 1)
                .accessibilityLabel("Keep tomorrow's one thing")
        }
    }
    private func commitIntent() {
        let t = intentDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        prefs.tomorrowIntent = t; prefs.tomorrowIntentFor = tomorrowKey; intentDraft = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @ViewBuilder private var rows: some View {
        VStack(spacing: 8) {
                ForEach([QuestKind.body, .work, .learn]) { q in
                    let latest = store.latestToday(for: q)
                    let hint = q == .work ? career.work : q == .learn ? career.learn : "Record a workout or add a photo"
                    QuestRow(quest: q, latest: latest, hint: hint, flash: flashLane == q) {
                        prefillLoad = false; prefillNote = ""; active = q
                    }
                }
        }
    }

    /// After the first receipt ever: one pill, one person. Stays until the share sheet has opened once or the day ends.
    @ViewBuilder private var firstReceiptPill: some View {
        if !prefs.firstSharePillDone, let first = store.logs.last, LarpyTime.cal.isDateInToday(first.createdAt), store.logs.count <= 3 {
            let img = shareImage ?? renderedShare()
            if let img {
                ShareLink(item: Image(uiImage: img), preview: SharePreview("Larpy · day one", image: Image(uiImage: img))) {
                    Text("Screenshot this. Send it to one person.")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: 44).background(Palette.gold, in: Capsule())
                }
                .simultaneousGesture(TapGesture().onEnded { prefs.firstSharePillDone = true })
                .padding(.top, 14)
            }
        }
    }

    /// The widget, offered inline, once. 'Later' and it never returns.
    @ViewBuilder private var tailCard: some View {
        if !dayZero, !prefs.widgetCardShown {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("He's hungry again at midnight.").font(.system(size: 18, weight: .medium, design: .serif)).foregroundStyle(Palette.text)
                        Text("Put him on the Home Screen so you see it before I say it.").font(.system(size: 13)).foregroundStyle(Palette.muted)
                    }
                    Spacer(minLength: 0)
                    VStack(spacing: 2) {
                        LarpyCharacterView(life: life, base: .cream, kit: sceneKit, width: 34, showScene: false, level: stats.workN, founderID: founderID)
                            .frame(width: 46, height: 50)
                        Text("\(stats.workN)").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.text)
                    }
                }
                HStack {
                    Text("Hold the Home Screen · + · Larpy").font(.system(size: 13, weight: .medium)).foregroundStyle(Palette.text)
                    Spacer()
                    Button("Later") { withAnimation { prefs.widgetCardShown = true } }
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.muted).buttonStyle(.plain)
                }
            }
            .padding(18)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Palette.line, lineWidth: 1))
            .padding(.top, 14)
        }
    }

    @MainActor private func renderedShare() -> UIImage? {
        let renderer = ImageRenderer(content: shareCard())
        renderer.scale = 3
        return renderer.uiImage
    }
    @MainActor private func shareCard() -> ShareCard {
        let first = store.logs.count == 1
        return ShareCard(life: life, base: .cream, kit: sceneKit,
                         name: prefs.name, loadLabel: fmtTokens(loads.todayTokens), ships: stats.workN,
                         pips: QuestKind.allCases.map { store.doneToday($0) }, loadDetail: loads.todayDetail,
                         founderID: founderID, scene: todayScene,
                         footer: first ? "DAY ONE · FIRST PROOF · \(store.logs.first.map { $0.proofKind == .link ? linkHost($0.value).uppercased() : "SCREENSHOT" } ?? "")" : nil)
    }
    @MainActor private func renderShare() { shareImage = renderedShare() }
}

/// One Path, two off control points, drawn once. The gold line under tomorrow's one thing.
private struct HandDrawnUnderline: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY + 1))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.midY),
                   control1: CGPoint(x: r.width * 0.30, y: r.minY - 1),
                   control2: CGPoint(x: r.width * 0.72, y: r.maxY + 1))
        return p
    }
}

private struct QuestRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let quest: QuestKind
    let latest: ProofLog?
    var hint: String? = nil
    var flash = false
    let onTap: () -> Void
    private var isShip: Bool { quest == .work }
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: latest == nil ? quest.glyph : "checkmark.circle.fill")
                    .font(.system(size: 21, weight: .medium))
                    .frame(width: 30).foregroundStyle(isShip ? Palette.ink : Palette.text)
                VStack(alignment: .leading, spacing: 3) {
                    Text(quest.actionTitle).font(.headline)
                    Text(quest == .learn && hint?.contains("tokens today") == true ? hint! : latest.map { "\($0.source == nil ? "Logged" : "Synced") · \(rowChip($0).isEmpty ? "Photo attached" : rowChip($0))" } ?? hint ?? "")
                        .font(.subheadline).lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2).fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(isShip ? Palette.ink.opacity(0.72) : Palette.muted)
                }
                Spacer(minLength: 4)
                Image(systemName: "plus").font(.system(size: 17, weight: .medium))
            }
            .foregroundStyle(isShip ? Palette.ink : Palette.text)
            .padding(.horizontal, 15).padding(.vertical, 12).frame(minHeight: 72)
            .background(isShip ? Palette.gold : Palette.card.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).fill(Palette.gold.opacity(flash ? 0.28 : 0)))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }.buttonStyle(ReceiptPressStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("\(quest.actionTitle). \(latest == nil ? "No activity today" : "Activity logged"). \(hint ?? "")")
            .accessibilityHint(latest == nil ? "Opens the form to save this activity." : "Opens the form to add another receipt.")
    }
}
private struct ReceiptPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1).animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

// MARK: - Log sheet (routes to per-lane content)

/// Tap a lane → a sheet, never an instant check. Leave ONE receipt: a photo or one sentence.
struct LogSheet: View {
    let quest: QuestKind
    @ObservedObject var store: ProofStore
    @ObservedObject var loads: LoadLedger
    var prefillLoad = false
    var prefillNote = ""
    @State private var rejecting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .center) {
                        Text(quest.actionTitle)
                            .font(.headline).foregroundStyle(Palette.muted)
                        Spacer()
                        // The egg watches. It slumps while the field holds a sentence instead of a link.
                        LarpyCharacterView(life: rejecting ? .neutralAsleep : LifeEngine.life(store.logs), base: .cream,
                                           kit: SceneWardrobe.kit(for: store.logsOn(.now)), width: 30, showScene: false)
                            .frame(width: 40, height: 44)
                            .animation(.easeOut(duration: 0.3), value: rejecting)
                    }
                    .overlay(alignment: .top) { Rectangle().fill(quest == .work ? Palette.gold : Palette.line).frame(height: 2).offset(y: -12) }

                    switch quest {
                    case .body: TrainContent(store: store) { dismiss() }
                    case .learn: LoadContent(store: store, loads: loads, prefill: prefillLoad) { dismiss() }
                    case .work: ShipContent(store: store, prefillNote: prefillNote, rejecting: $rejecting) { dismiss() }
                    }
                }
                .padding(22).padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Palette.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.tint(Palette.muted)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Train (gym, run, walk) — receipt: a PHOTO or a TIMER. A sentence alone is rejected.

private struct TrainContent: View {
    @ObservedObject var store: ProofStore
    let done: () -> Void
    @AppStorage("bodyTimerStart") private var startValue: Double = 0
    @State private var endedAt: Date?
    @State private var showCamera = false
    @State private var note = ""
    @State private var error = ""
    private var start: Date? { startValue > 0 ? Date(timeIntervalSince1970: startValue) : nil }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gym, a run, a walk.").font(.title.weight(.semibold)).foregroundStyle(Palette.text)
            Text("Add a photo, or time your activity.").font(.body).foregroundStyle(Palette.muted)
            BigButton("Attach a photo", icon: "camera.fill") { showCamera = true }
            if let start {
                TimelineView(.periodic(from: .now, by: 1)) { clock in
                    let secs = max(0, Int((endedAt ?? clock.date).timeIntervalSince(start)))
                    HStack {
                        Text(String(format: "%02d:%02d", secs / 60, secs % 60))
                            .font(.system(size: 42, weight: .regular, design: .monospaced)).monospacedDigit()
                        Spacer()
                        if endedAt == nil { SmallButton("Stop") { endedAt = .now } }
                        else { SmallButton("Restart") { startValue = Date().timeIntervalSince1970; endedAt = nil } }
                    }.foregroundStyle(Palette.text)
                    Text(secs < 600 ? "10 minutes earns an active day. Rest days are fine." : "This workout earns one active day.")
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    if let endedAt {
                        BigButton("Save activity", icon: "checkmark") {
                            if store.logTimer(start: start, end: endedAt, note: note) {
                                startValue = 0; done()
                            } else { error = store.errorMessage ?? "Try again." }
                        }.disabled(secs < 600).opacity(secs < 600 ? 0.4 : 1)
                    }
                }
            } else {
                SmallButton("Or start a timer") { startValue = Date().timeIntervalSince1970 }
            }
            NoteField(text: $note, placeholder: "gym / run / walk (optional)")
            Text("A 10-minute timer earns an active day. Photos are self-reported evidence.").font(.footnote).foregroundStyle(Palette.muted)
            if !error.isEmpty { Text(error).font(.system(size: 12)).foregroundStyle(Palette.train) }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                guard let data = image?.jpegData(compressionQuality: 0.82) else { return }
                do { try store.logPhoto(quest: .body, imageData: data, value: note.isEmpty ? "photo" : note); startValue = 0; done() }
                catch { self.error = error.localizedDescription }
            }.ignoresSafeArea()
        }
    }
}

private struct LoadContent: View {
    @AppStorage("careerPath") private var careerID = CareerPath.exploring.rawValue
    @ObservedObject var store: ProofStore
    @ObservedObject var loads: LoadLedger
    var prefill = false
    let done: () -> Void
    @State private var mode = 1
    @State private var tokens = ""
    @State private var pages = ""
    @State private var url = ""
    @State private var title = ""
    @State private var use = ""
    @State private var error = ""
    private var count: Int { parseTokens(tokens) }
    private var pageCount: Int { Int(pages) ?? 0 }
    private var trimmedUse: String { use.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var valid: Bool {
        mode == 0 ? count > 0 : !trimmedUse.isEmpty && (isValidURL(url) || !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pageCount > 0)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What did you learn?").font(.title.weight(.semibold)).foregroundStyle(Palette.text)
            Text((CareerPath(rawValue: careerID) ?? .exploring).learn).font(.subheadline).foregroundStyle(Palette.muted)
            Picker("Input", selection: $mode) { Text("Tokens").tag(0); Text("A lesson").tag(1) }
                .pickerStyle(.segmented)
            if mode == 0 {
                Text("AI tokens used").font(.subheadline).foregroundStyle(Palette.muted)
                TextField("e.g. 10k", text: $tokens).font(.system(size: 42, weight: .medium)).foregroundStyle(Palette.text)
                    .keyboardType(.numbersAndPunctuation).autocorrectionDisabled().textInputAutocapitalization(.never)
                HStack(spacing: 10) {
                    ForEach(["1k", "10k", "100k"], id: \.self) { amount in
                        SmallButton(amount) { tokens = amount }
                    }
                }
                NoteField(text: $title, placeholder: "Cursor / Claude / where it went (optional)")
                Text("Enter the count from your AI tool.").font(.footnote).foregroundStyle(Palette.muted)
            } else {
                LinkField(text: $url, placeholder: "Video / book / deck link")
                NoteField(text: $title, placeholder: "…or what you read")
                LabeledNumber(text: $pages, unit: "pages · optional")
                Text("What are you using this for?").font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.text)
                NoteField(text: $use, placeholder: "One line. Make the input useful.")
            }
            BigButton("Log learning", icon: "arrow.down") { save() }.disabled(!valid).opacity(valid ? 1 : 0.4)
            Text(mode == 0 ? "Usage is a tracker. Tokens alone do not earn a learning day." : "A lesson and your own takeaway earn one learning day. Counted once per date.").font(.footnote).foregroundStyle(Palette.muted)
            if !error.isEmpty { Text(error).font(.system(size: 12)).foregroundStyle(Palette.train) }
        }
    }
    private func save() {
        let value = mode == 0 ? "\(fmtTokens(count)) tok" : isValidURL(url) ? url : "note: \(title.isEmpty ? "\(pageCount) pages" : title)"
        let annotation = mode == 0 ? title : trimmedUse
        if store.logTextProof(quest: .learn, proofKind: mode == 1 && isValidURL(url) ? .link : .number, value: value, annotation: annotation) {
            loads.add(tokens: mode == 0 ? count : 0, pages: mode == 1 ? max(0, min(pageCount, 100_000)) : 0, lessons: mode == 1 ? 1 : 0)
            done()
        } else { error = store.errorMessage ?? "Couldn't file this receipt." }
    }
}

private struct ShipContent: View {
    @AppStorage("careerPath") private var careerID = CareerPath.exploring.rawValue
    @ObservedObject var store: ProofStore
    var prefillNote = ""
    @Binding var rejecting: Bool
    let done: () -> Void
    @State private var url = ""
    @State private var note = ""
    @State private var showCamera = false
    @State private var error = ""
    @State private var showRejection = false
    @State private var copiedLink: String?
    @State private var clipboardHasURL = false
    private var hasNote: Bool { !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var valid: Bool { isValidURL(url) }
    /// The same site again. Still allowed, just named.
    private var repeatHost: Bool {
        guard valid else { return false }
        let host = linkHost(url)
        return store.logs.contains { $0.quest == .work && $0.proofKind == .link && linkHost($0.value) == host }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What did you make?").font(.title.weight(.semibold)).foregroundStyle(Palette.text)
            Text("A feature, a design, a post, a finished task. Add a link or screenshot.").font(.body).foregroundStyle(Palette.muted)
            if clipboardHasURL, copiedLink == nil {
                Button {
                    // User-initiated read. The system paste notice is the honest price of one tap.
                    if let s = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), isValidURL(s) { url = s; copiedLink = s }
                    else { clipboardHasURL = false }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "link").font(.system(size: 13, weight: .semibold))
                        Text("Use copied link").font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.down.left").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Palette.ink).padding(.horizontal, 14).frame(minHeight: 40)
                    .background(Palette.gold, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }.buttonStyle(.plain)
            }
            LinkField(text: $url, placeholder: "Paste a link to your work", autoFocus: false)
            if showRejection {
                Text("A sentence isn't a receipt. Paste the link or attach a screenshot.")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Palette.ink)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(Palette.gold.opacity(0.12), in: Capsule())
                    .transition(.opacity)
            }
            SmallButton("Attach a screenshot") { showCamera = true }
            NoteField(text: $note, placeholder: "What did you finish? (optional)")
            BigButton(valid ? "Save Work" : hasNote ? "Save to Learnt instead" : "Save Work", icon: "checkmark") {
                let shipped = valid
                if store.logTextProof(quest: shipped ? .work : .learn, proofKind: shipped ? .link : .number,
                                      value: shipped ? url : "note: \(note)", annotation: shipped ? note : nil) { done() }
                else { error = store.errorMessage ?? "Couldn't file this receipt." }
            }.disabled(!valid && !hasNote).opacity(valid || hasNote ? 1 : 0.4)
            Text((CareerPath(rawValue: careerID) ?? .exploring).work + ". Add a link or screenshot of the finished result.").font(.footnote).foregroundStyle(Palette.muted)
            if !error.isEmpty { Text(error).font(.system(size: 12)).foregroundStyle(Palette.train) }
        }
        .onAppear {
            note = prefillNote
            clipboardHasURL = UIPasteboard.general.hasURLs || UIPasteboard.general.hasStrings && UIPasteboard.general.contains(pasteboardTypes: ["public.url"])
        }
        .onChange(of: url) { _, v in
            let bad = !v.trimmingCharacters(in: .whitespaces).isEmpty && !isValidURL(v)
            rejecting = bad
            guard bad else { withAnimation(.easeOut(duration: 0.2)) { showRejection = false }; return }
            let snapshot = v
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                if url == snapshot, !isValidURL(url), !url.trimmingCharacters(in: .whitespaces).isEmpty {
                    withAnimation(.easeOut(duration: 0.2)) { showRejection = true }
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(preferLibrary: true) { image in
                guard let data = image?.jpegData(compressionQuality: 0.82) else { return }
                do { try store.logPhoto(quest: .work, imageData: data, value: note.isEmpty ? "screenshot" : note); done() }
                catch { self.error = error.localizedDescription }
            }.ignoresSafeArea()
        }
    }
}

func isValidURL(_ s: String) -> Bool { ReceiptRules.webURL(s) != nil }

// MARK: - Sheet building blocks

private struct BigButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    init(_ title: String, icon: String, action: @escaping () -> Void) {
        self.title = title; self.icon = icon; self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Palette.gold, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SmallButton: View {
    let title: String
    let action: () -> Void
    init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct LinkField: View {
    @Binding var text: String
    let placeholder: String
    var autoFocus = false
    @FocusState private var focused: Bool
    var body: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $text)
                .focused($focused)
                .onAppear {
                    if autoFocus { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focused = true } }
                }
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.text)
                .padding(14)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Palette.line, lineWidth: 1))

            // System paste control: one tap, never a "would like to paste" prompt.
            // iOS disables it by itself when the clipboard holds no matching payload.
            PasteButton(payloadType: String.self) { strings in
                if let s = strings.first?.trimmingCharacters(in: .whitespacesAndNewlines), isValidURL(s) { text = s }
            }
            .labelStyle(.iconOnly)
            .buttonBorderShape(.capsule)
            .tint(Palette.gold)
        }
    }
}

/// One-sentence receipt field, same skin as LinkField.
private struct NoteField: View {
    @Binding var text: String
    let placeholder: String
    var autoFocus = false
    @FocusState private var focused: Bool
    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(1...3)
            .focused($focused)
            .onAppear { if autoFocus { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focused = true } } }
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Palette.text)
            .padding(14)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }
}

private struct MinutesField: View {
    @Binding var text: String
    var body: some View {
        HStack {
            TextField("Minutes", text: $text)
                .keyboardType(.numberPad)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.text)
            Text("min").foregroundStyle(Palette.muted).font(.system(size: 14, weight: .semibold))
        }
        .padding(14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }
}

private struct LabeledNumber: View {
    @Binding var text: String
    let unit: String
    var body: some View {
        HStack {
            TextField("0", text: $text)
                .keyboardType(.numberPad)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Palette.text)
            Text(unit).foregroundStyle(Palette.muted).font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Palette.line, lineWidth: 1))
    }
}

// MARK: - Camera picker (camera-first, library fallback)

struct CameraPicker: UIViewControllerRepresentable {
    var preferLibrary = false          // "Roll": open the library instead of the camera
    let onImage: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        let cameraOK = UIImagePickerController.isSourceTypeAvailable(.camera)
        picker.sourceType = (!preferLibrary && cameraOK) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            parent.onImage(image)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Week

/// Seven days of proof, not analytics: a face per day, one line, optional agent sentence.
struct WeekView: View {
    @ObservedObject var store: ProofStore
    @ObservedObject var prefs: Prefs
    @ObservedObject var keys: AgentKeys
    @ObservedObject var agents: AgentStore
    @ObservedObject var loads: LoadLedger
    let onSettings: () -> Void
    @State private var detailDay: Date?
    @State private var shareImage: UIImage?
    @State private var showWardrobe = false

    /// Mon…Sun of the current week.
    private var days: [Date] {
        var cal = LarpyTime.cal; cal.firstWeekday = 2
        let today = cal.startOfDay(for: .now)
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let monday = cal.date(from: comps) ?? today
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    private var today: Date { LarpyTime.startOfToday() }
    private var isEmpty: Bool { days.allSatisfy { store.count(on: $0) == 0 } }
    private var daysSoFar: [Date] { days.filter { $0 <= today } }
    private var daysAlive: Int { daysSoFar.filter { store.count(on: $0) > 0 }.count }
    private var holes: Int { daysSoFar.filter { !LifeEngine.laneDone(store.logs, .work, on: $0) }.count }
    private var shipsThisWeek: Int { LifeEngine.stats(store.logs).workN }
    private func lanes(on day: Date) -> [Bool] { QuestKind.allCases.map { LifeEngine.laneDone(store.logs, $0, on: day) } }

    /// One sentence from counts. No model, no key, nothing to disclose.
    private var verdict: String {
        let weekday = LarpyTime.cal.component(.weekday, from: .now)   // 1 = Sunday
        let closing = weekday == 6 || weekday == 7 || weekday == 1
        if closing { return "\(daysAlive) of 7 days had receipts. \(shipsThisWeek) shipped. \(holes) still larping." }
        return "\(daysAlive) of \(daysSoFar.count) so far. \(shipsThisWeek) shipped."
    }

    @MainActor private func renderShareCard() -> UIImage? {
        let lookID = CharacterStyle.lookID(logs: store.logs, selected: prefs.selectedLookID)
        let kit = FounderLook.find(lookID)?.kit ?? prefs.kit
        let card = ShareCard(life: LifeEngine.life(store.logs), base: prefs.base, kit: kit,
                             name: prefs.name, loadLabel: fmtTokens(loads.todayTokens), ships: shipsThisWeek,
                             pips: QuestKind.allCases.map { store.doneToday($0) }, loadDetail: loads.todayDetail,
                             founderID: lookID,
                             scene: CharacterStyle.scene(logs: store.logs, selected: prefs.selectedSceneID, kit: kit))
        let r = ImageRenderer(content: card)
        r.scale = 3
        return r.uiImage
    }

    enum Slot { case thriving, warning, cracked, empty }
    private func slot(_ day: Date) -> Slot {
        if day > today { return .empty }
        switch store.count(on: day) {
        case 3: return .thriving
        case 1, 2: return .warning
        default: return .cracked
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Seven days of proof.")
                    .font(.system(size: 30, weight: .medium, design: .serif)).tracking(-1)
                    .foregroundStyle(Palette.text)

                if isEmpty {
                    VStack(spacing: 10) {
                        LarpyCharacterView(life: .neutralAsleep, base: prefs.base, blush: prefs.blush,
                                           kit: prefs.kit, width: 150, interactive: true)
                            .frame(height: 210)
                        Text("No receipts. Still larping.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Palette.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                } else {
                    HStack(spacing: 6) {
                        ForEach(days, id: \.self) { day in
                            Button { if day <= today { detailDay = day } } label: {
                                FaceSlot(slot: slot(day), lanes: lanes(on: day), day: day, base: prefs.base, kit: SceneWardrobe.kit(for: store.logsOn(day)), founderID: store.logsOn(day).first?.founderID)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(verdict)
                        .font(.system(size: 20, weight: .medium, design: .serif)).tracking(-0.4)
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 16) {
                        Text("\(shipsThisWeek) pieces of Work.")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.text)
                        Spacer()
                        Button { showWardrobe = true } label: {
                            Text("Looks").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.gold)
                        }.buttonStyle(.plain)
                        if let img = shareImage {
                            ShareLink(item: Image(uiImage: img), preview: SharePreview("Larpy — today", image: Image(uiImage: img))) {
                                Text("Share today").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.gold)
                            }
                        }
                    }
                    .onAppear { shareImage = renderShareCard() }
                    .onChange(of: store.logs.first?.id) { _, _ in shareImage = renderShareCard() }
                }
                if isEmpty {
                    Button { showWardrobe = true } label: {
                        Text("Looks").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.gold)
                    }.buttonStyle(.plain)
                }
                AchievementSection(store: store)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.bg.ignoresSafeArea())
        .sheet(isPresented: $showWardrobe) { WardrobeView(store: store, prefs: prefs) }
        .sheet(item: Binding(get: { detailDay.map { IdentifiableDate(date: $0) } },
                             set: { detailDay = $0?.date })) { wrapped in
            DayDetail(day: wrapped.date, store: store)
        }
    }
}

/// The still that gets shared: Larpy in today's costume, LOAD, ships this week. 360×450 @3x = 1080×1350.
private struct ShareCard: View {
    let life: LifeState
    let base: LarpyBase
    let kit: Kit
    let name: String
    let loadLabel: String
    let ships: Int
    var pips: [Bool] = [false, false, false]
    var loadDetail = "inputs, not outputs"
    var founderID: String? = nil
    /// The share image carries the same room the app is showing — the scene is the picture.
    var scene: MovieScene? = nil
    /// Day-one override for the footer line.
    var footer: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("TOKENS TODAY").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2)
                    Text(loadLabel).font(.system(size: 39, design: .serif)).tracking(-2)
                    Text(loadDetail).font(.system(size: 10))
                }
                Spacer()
                Text("LARPY /\nRECEIPT EDITION").font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(1)
                    .multilineTextAlignment(.trailing).padding(.top, 4)
            }.padding(.horizontal, 28).padding(.top, 28)
            Text("Become the person.")
                .font(.system(size: 27, design: .serif)).tracking(-0.8).padding(.top, 20)
            LarpyCharacterView(life: life, base: .cream, kit: kit, width: 168, scene: scene, sceneCorner: 22, level: ships, founderID: founderID)
                .frame(height: 250).padding(.horizontal, 22).padding(.top, 14)
            if let scene {
                Text(scene.caption).font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1.6)
                    .foregroundStyle(Palette.muted).padding(.top, 11).padding(.bottom, 3)
            }
            HStack(spacing: 16) {
                ForEach(Array(QuestKind.allCases.enumerated()), id: \.offset) { i, q in
                    HStack(spacing: 5) {
                        Circle().stroke(q.tint, style: StrokeStyle(lineWidth: 1.2, dash: pips[i] ? [] : [2, 2]))
                            .background(Circle().fill(pips[i] ? q.tint : .clear)).frame(width: 7, height: 7)
                        Text(q.title).font(.system(size: 10, weight: .medium))
                    }
                }
            }
            Text("\(ships) out in the world this week.")
                .font(.system(size: 25, design: .serif)).padding(.top, 14)
            Text(footer ?? "\(ShipLevel.title(ships).uppercased()) · \(name.isEmpty || name == "You" ? "LARP MAXING" : name.uppercased())")
                .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(1.4).padding(.top, 8)
            Spacer(minLength: 10)
        }
        .foregroundStyle(Palette.ink).frame(width: 360, height: 566).background(Color(hex: 0xF5F0E6))
    }
}

private struct IdentifiableDate: Identifiable { let date: Date; var id: TimeInterval { date.timeIntervalSince1970 } }

/// One day = one small face. thriving / warning / cracked / empty.
private struct FaceSlot: View {
    let slot: WeekView.Slot
    let lanes: [Bool]          // Train, Load, Ship — colour pips under the face
    let day: Date
    let base: LarpyBase
    let kit: Kit
    var founderID: String? = nil

    private var isToday: Bool { LarpyTime.cal.isDateInToday(day) }
    private var initial: String {
        let f = DateFormatter(); f.calendar = LarpyTime.cal; f.dateFormat = "EEEEE"
        return f.string(from: day)
    }
    private var life: LifeState {
        switch slot {
        case .thriving: .clearedPreview
        case .warning: LifeState(face: .stirring, gear: .none, posture: .normal, bodyTone: 1, growScale: 1, bubble: nil, label: "warning", cleared: false)
        case .cracked: .neutralAsleep
        case .empty: .neutralAsleep
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if slot == .empty {
                    Circle().strokeBorder(Palette.line, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                        .frame(width: 40, height: 40)
                } else {
                    LarpyCharacterView(life: life, base: base, blush: slot == .thriving, kit: kit, width: 30, showScene: false, level: lanes[2] ? 1 : 0, founderID: founderID)
                        .frame(width: 44, height: 44)
                        .saturation(slot == .cracked ? 0.45 : 1)
                        .opacity(slot == .cracked ? 0.6 : 1)
                }
            }
            .frame(height: 48)
            HStack(spacing: 3) {
                ForEach(Array(QuestKind.allCases.enumerated()), id: \.offset) { i, q in
                    Circle().fill(lanes.indices.contains(i) && lanes[i] ? q.tint : Palette.line)
                        .frame(width: 5, height: 5)
                }
            }
            Text(initial)
                .font(.system(size: 12, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? Palette.text : Palette.muted)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DayDetail: View {
    let day: Date
    @ObservedObject var store: ProofStore
    private var room: String? {
        guard let first = store.logsOn(day).first else { return nil }
        if let id = first.sceneID, let scene = MovieScene(rawValue: id) { return scene.title }
        return MovieScene.forLane(first.quest, seed: 0).title
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 28, design: .serif)).foregroundStyle(Palette.text)
                    if let room {
                        Text(room.uppercased()).font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(1.6).foregroundStyle(Palette.muted)
                    }
                }
                ForEach(QuestKind.allCases) { quest in
                    let receipts = store.logsOn(day).filter { $0.quest == quest }
                    Text(quest.title.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(quest == .work ? Palette.gold : quest.tint)
                    if receipts.isEmpty { Text("The hole is still here.").font(.system(size: 13)).foregroundStyle(Palette.muted) }
                    ForEach(receipts) { log in
                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 1.5).fill(quest == .work ? Palette.gold : quest.tint).frame(width: 3)
                            VStack(alignment: .leading, spacing: 8) {
                                if let url = store.photoURL(for: log), let image = UIImage(contentsOfFile: url.path) {
                                    Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                if log.proofKind == .link, let url = ReceiptRules.webURL(log.value) {
                                    Link(destination: url) { Label(log.value, systemImage: "arrow.up.right").font(.system(size: 13)).lineLimit(2) }.tint(Palette.text)
                                } else { Text(log.value.replacingOccurrences(of: "note: ", with: "")).font(.system(size: 14)).foregroundStyle(Palette.text) }
                                if let use = log.annotation, !use.isEmpty {
                                    Text(use).font(.system(size: 14, design: .serif)).foregroundStyle(Palette.muted)
                                }
                                Text(log.createdAt.formatted(date: .omitted, time: .shortened)).font(.system(size: 10, design: .monospaced)).foregroundStyle(Palette.muted)
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }.padding(24)
        }.background(Palette.bg).presentationDetents([.large])
    }
}

// MARK: - People

/// People = one human. Their latest receipt and their Ship hole. Not a feed. Not five friends.
private struct PeopleView: View {
    @ObservedObject var circle: CircleStore
    @ObservedObject var prefs: Prefs
    @ObservedObject var store: ProofStore
    let onSettings: () -> Void
    @State private var showInvite = false
    @State private var showProfile = false
    @State private var showCode = false
    @State private var pasted = ""
    @State private var feedback = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .top) {
                    Text("One friend.\nKeep each other honest.")
                        .font(.system(size: 30, weight: .medium, design: .serif)).tracking(-1).foregroundStyle(Palette.text)
                    Spacer(minLength: 8)
                    GearButton(action: onSettings).frame(width: 44, height: 44).accessibilityLabel("Settings")
                }
                Button { showProfile = true } label: {
                    HStack(spacing: 15) {
                        LarpyCharacterView(life: LifeEngine.life(store.logs), base: .cream,
                            kit: SceneWardrobe.kit(for: store.logsOn(.now)), width: 42, showScene: false).frame(width: 58, height: 68)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(prefs.name.isEmpty || prefs.name == "You" ? "Your profile" : prefs.name).font(.system(size: 19, weight: .semibold))
                            Text(prefs.shipping.isEmpty ? "Your name + what you're building" : prefs.shipping).font(.system(size: 14)).foregroundStyle(Palette.muted).lineLimit(2)
                        }
                        Spacer(); Image(systemName: "pencil").font(.system(size: 15)).foregroundStyle(Palette.muted)
                    }.foregroundStyle(Palette.text).padding(.vertical, 10)
                }.buttonStyle(.plain)
                Rectangle().fill(Palette.line).frame(height: 1)
                if let friend = circle.friend {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 14) {
                            Text(String(friend.name.prefix(1)).uppercased()).font(.system(size: 25, design: .serif))
                                .frame(width: 54, height: 54).background(Palette.card, in: Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(friend.name).font(.system(size: 21, weight: .semibold))
                                Text(friend.shipping.isEmpty ? "Your witness" : friend.shipping).font(.system(size: 14)).foregroundStyle(Palette.muted)
                            }
                        }.foregroundStyle(Palette.text)
                        let known = friend.lastShipAt.map { Calendar.current.isDateInToday($0) } == true
                        HStack(spacing: 12) {
                            Image(systemName: known ? "checkmark.circle.fill" : "circle.dashed").foregroundStyle(Palette.gold)
                            Text(known ? "Work receipt attached." : "Waiting for a connection.").font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.text)
                        }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                        Text("Live receipt sharing isn't connected yet. Their activity stays unknown until it is.")
                            .font(.system(size: 14)).foregroundStyle(Palette.muted)
                        Button("Remove friend") { circle.friend = nil }.font(.system(size: 14)).tint(Palette.muted).frame(minHeight: 44)
                    }
                } else {
                    VStack(spacing: 18) {
                        Image(systemName: "person.crop.circle.badge.plus").font(.system(size: 42, weight: .ultraLight)).foregroundStyle(Palette.muted)
                        Text("Who will call you out?").font(.system(size: 23, weight: .semibold)).foregroundStyle(Palette.text)
                        Text("A friend, a cofounder, your gym mate.\nOne person who cares if you actually do it.")
                            .font(.system(size: 16)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                        BigButton("Invite one friend", icon: "arrow.up.right") { showInvite = true }
                        Text("For now, send them the card.").font(.system(size: 12)).foregroundStyle(Palette.muted)
                    }.frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                if circle.friend == nil {
                    Button { withAnimation(.easeOut(duration: 0.2)) { showCode.toggle() } } label: {
                        HStack { Text("Have their invite code?"); Spacer(); Image(systemName: showCode ? "minus" : "plus") }
                            .font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.muted).frame(minHeight: 44)
                    }.buttonStyle(.plain)
                    if showCode {
                        HStack {
                            TextField("Paste link or code", text: $pasted).font(.system(size: 17)).autocorrectionDisabled().padding(16)
                                .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
                            Button("Add") { addPasted() }.font(.system(size: 17, weight: .semibold)).tint(Palette.text).frame(width: 54, height: 52)
                        }
                    }
                    if !feedback.isEmpty { Text(feedback).font(.system(size: 14)).foregroundStyle(Palette.muted) }
                }
            }.padding(26)
        }.background(Palette.bg.ignoresSafeArea())
        .sheet(isPresented: $showInvite) { InviteView(prefs: prefs, circle: circle, store: store) }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Who are you becoming?").font(.system(size: 29, design: .serif)).foregroundStyle(Palette.text)
                    FieldRow(title: "Name", text: $prefs.name, placeholder: "What your friend calls you")
                    FieldRow(title: "Building", text: $prefs.shipping, placeholder: "One line. Something real.")
                    Text("Two fields. That's the profile.").font(.system(size: 15)).foregroundStyle(Palette.muted)
                    Spacer()
                }.padding(26).background(Palette.bg)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showProfile = false } } }
            }.presentationDetents([.medium, .large])
        }
    }
    private func addPasted() {
        let raw = pasted.trimmingCharacters(in: .whitespacesAndNewlines)
        var code = raw, name = "Friend", shipping = ""
        if let range = raw.range(of: "larpy://"), let token = raw[range.lowerBound...].split(whereSeparator: { $0.isWhitespace }).first,
           let url = URL(string: String(token)), url.host == "join" {
            code = url.lastPathComponent
            let q = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            name = q.first { $0.name == "n" }?.value ?? "Friend"; shipping = q.first { $0.name == "s" }?.value ?? ""
        }
        if circle.setFriend(code: code, name: name, shipping: shipping) { pasted = ""; showCode = false }
        else { feedback = "Use their six-character code. You can't add yourself." }
    }
}

// MARK: - One-time moments: Invite (after first receipt) · Widget card (next open) · Icon (after first Ship)

/// Hick: one decision. Von Restorff: Invite is the only loud thing. Skip is text, not a second button.
struct InviteView: View {
    @ObservedObject var prefs: Prefs
    @ObservedObject var circle: CircleStore
    @ObservedObject var store: ProofStore
    @Environment(\.dismiss) private var dismiss
    @State private var shared = false

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 20)
                LarpyCharacterView(life: LifeEngine.life(store.logs), base: prefs.base, blush: prefs.blush,
                                   kit: prefs.kit, width: 170, interactive: true)
                    .frame(height: 210)
                Text("Pick your witness.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Palette.text)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
                Text("Solo LARP is just a diary. Pick one person.")
                    .font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.text)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                Text("One person who will notice the missing Work.")
                    .font(.system(size: 13)).foregroundStyle(Palette.muted)
                    .padding(.top, 6)
                VStack(spacing: 12) {
                    NoteField(text: $prefs.name, placeholder: "What your friend calls you")
                    NoteField(text: $prefs.shipping, placeholder: "What you're shipping")
                }.padding(.top, 24)
                Text("Invite preview · live receipt sync isn't connected yet.")
                    .font(.system(size: 11)).foregroundStyle(Palette.muted).padding(.top, 10)
                Spacer()
                ShareLink(item: circle.inviteText(name: prefs.name, shipping: prefs.shipping)) {
                    Text("Invite one witness")
                        .font(.system(size: 18, weight: .bold)).foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity).frame(minHeight: 56)
                        .background(Palette.gold, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(prefs.name.trimmingCharacters(in: .whitespaces).isEmpty || prefs.name == "You" || prefs.shipping.trimmingCharacters(in: .whitespaces).isEmpty)
                .simultaneousGesture(TapGesture().onEnded { shared = true })
                Button { dismiss() } label: {
                    Text(shared ? "Done" : "Skip")
                        .font(.system(size: 15, weight: .medium)).foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity).frame(minHeight: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 24)
        }
    }
}

/// Peak-End: leave the first session with Larpy on the Home Screen. Mood from receipts only.
enum LarpyIcon {
    static let all: [(id: String, label: String, asset: String)] = [
        ("", "Default", "LarpyPrimary"),
        ("LarpyHungry", "Hungry", "LarpyHungry"),
        ("LarpyRollneck", "Rollneck", "LarpyRollneck")
    ]

    @MainActor
    static func apply(_ choice: String, userChosen: Bool) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let target: String? = choice.isEmpty ? nil : choice
        guard UIApplication.shared.alternateIconName != target else { return }
        let d = UserDefaults.standard, today = LarpyTime.dayKey()
        if !userChosen, d.string(forKey: "lastIconSwapDay") == today { return }   // once a day, max
        UIApplication.shared.setAlternateIconName(target)
        if !userChosen { d.set(today, forKey: "lastIconSwapDay") }
    }
}

// MARK: - Share inbox ("Load in Larpy" / "Ship in Larpy" — the extension parks a draft, the user confirms the lane)

struct ShareDraft: Codable, Identifiable {
    var url: String?
    var text: String?
    var imageFile: String?
    var at: Date
    var id: TimeInterval { at.timeIntervalSince1970 }

    /// A URL that looks like a thing that shipped, not a thing to watch. Git hosts, TestFlight, App Store, deploy hosts.
    var looksLive: Bool {
        guard let u = url, let h = URL(string: u)?.host?.lowercased() else { return false }
        if isGitHost(u) { return true }
        return ["testflight.apple.com", "apps.apple.com", "vercel.app", "netlify.app", "pages.dev", "fly.dev", "railway.app"]
            .contains { h.contains($0) }
    }
}

enum ShareInbox {
    static let suite = WidgetBridge.suite
    struct Input: Codable { var id: UUID; var url: String?; var text: String?; var use: String; var at: Date }
    @MainActor static func importLoads(store: ProofStore, loads: LoadLedger) {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suite) {
            let folder = container.appendingPathComponent("LearningInbox", isDirectory: true)
            for file in (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [] where file.pathExtension == "json" {
                guard let data = try? Data(contentsOf: file), let input = try? JSONDecoder().decode(Input.self, from: data) else { continue }
                let isLink = input.url.map { isValidURL($0) } ?? false
                let value = isLink ? input.url! : "note: " + (input.text ?? "Shared learning")
                if store.logTextProof(quest: .learn, proofKind: isLink ? .link : .number, value: value,
                                      annotation: input.use, id: input.id, createdAt: input.at) {
                    loads.add(lessons: 1, at: input.at, id: input.id)
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
        // Import any queue left by earlier app versions as well.
        guard let defaults = UserDefaults(suiteName: suite), let data = defaults.data(forKey: "incomingLoads"),
              let queue = try? JSONDecoder().decode([Input].self, from: data) else { return }
        var remaining: [Input] = []
        for input in queue {
            let isLink = input.url.map { isValidURL($0) } ?? false
            let value = isLink ? input.url! : "note: " + (input.text ?? input.url ?? "Shared input")
            if store.logTextProof(quest: .learn, proofKind: isLink ? .link : .number, value: value,
                                  annotation: input.use, id: input.id, createdAt: input.at) {
                loads.add(lessons: 1, at: input.at, id: input.id)
            } else { remaining.append(input) }
        }
        defaults.set(try? JSONEncoder().encode(remaining), forKey: "incomingLoads")
    }

    /// Read the parked draft and clear it. One draft at a time.
    static func take() -> ShareDraft? {
        guard let d = UserDefaults(suiteName: suite), let data = d.data(forKey: "shareDraft"),
              let draft = try? JSONDecoder().decode(ShareDraft.self, from: data) else { return nil }
        return draft
    }

    static func imageData(_ draft: ShareDraft) -> Data? {
        guard let f = draft.imageFile,
              let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suite) else { return nil }
        let url = base.appendingPathComponent("ShareInbox", isDirectory: true).appendingPathComponent(f)
        let data = try? Data(contentsOf: url)
        return data
    }
}

/// The shared thing lands here prefilled. Load by default; Ship offered only when the URL looks live. They confirm.
struct DraftSheet: View {
    let draft: ShareDraft
    @ObservedObject var store: ProofStore
    @ObservedObject var loads: LoadLedger
    @Environment(\.dismiss) private var dismiss

    @State private var lane: QuestKind = .learn
    @State private var title = ""
    @State private var tokens = ""
    @State private var image: UIImage?

    private var note: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var tok: Int { parseTokens(tokens) }
    private var canSave: Bool {
        if lane == .work { return draft.url.map { isValidURL($0) } == true || image != nil }      // Ship = link or screenshot, always
        return draft.url.map { isValidURL($0) } == true || image != nil || !note.isEmpty || tok > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(lane == .work ? "WORK" : "LEARNT")
                        .font(.system(size: 13, weight: .semibold)).kerning(3).foregroundStyle(lane.tint)
                    Text(lane == .work ? "Log Work" : "Log learning")
                        .font(.system(size: 26, weight: .bold)).foregroundStyle(Palette.text)

                    // What came in
                    HStack(spacing: 12) {
                        if let img = image {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            if let u = draft.url {
                                Text(linkHost(u)).font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
                                Text(u).font(.system(size: 12)).foregroundStyle(Palette.muted).lineLimit(2)
                            } else if image != nil {
                                Text("Screenshot").font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.text)
                            } else if let t = draft.text {
                                Text(t).font(.system(size: 14)).foregroundStyle(Palette.text).lineLimit(3)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Lane: Load by default; Ship only when it looks live
                    if draft.url.map({ isValidURL($0) }) == true || image != nil {
                        HStack(spacing: 10) {
                            lanePill(.learn); lanePill(.work)
                        }
                    }

                    NoteField(text: $title, placeholder: lane == .work ? "what left the building (optional)" : "What are you using this for? (optional)")
                    if lane == .learn {
                        LabeledNumber(text: $tokens, unit: "tokens")
                    }

                    BigButton("Save", icon: "checkmark") { save() }
                        .opacity(canSave ? 1 : 0.4)
                        .disabled(!canSave)

                    Text(lane == .work ? "A link or screenshot of the finished thing." : "Inputs go in Learnt. Finished output goes in Work.")
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                }
                .padding(24)
            }
            .background(Palette.bg.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if let d = ShareInbox.imageData(draft) { image = UIImage(data: d) }
            if let t = draft.text, draft.url == nil { title = t }
        }
    }

    private func lanePill(_ q: QuestKind) -> some View {
        Button { lane = q } label: {
            Text(q.title).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(lane == q ? Palette.bg : Palette.text)
                .frame(maxWidth: .infinity).frame(minHeight: 44)
                .background(lane == q ? q.tint : Palette.card, in: Capsule())
                .overlay(Capsule().stroke(lane == q ? q.tint : Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func save() {
        var saved = false
        if let img = image, let data = img.jpegData(compressionQuality: 0.8) {
            do { try store.logPhoto(quest: lane, imageData: data, value: note.isEmpty ? "photo" : note); saved = true }
            catch { store.errorMessage = error.localizedDescription }
        } else if let u = draft.url, isValidURL(u) {
            saved = store.logTextProof(quest: lane, proofKind: .link, value: u, annotation: note)
        } else if !note.isEmpty || tok > 0 {
            saved = store.logTextProof(quest: .learn, proofKind: .number, value: note.isEmpty ? "\(fmtTokens(tok)) tok" : "note: \(note)")
        }
        guard saved else { return }
        if lane == .learn { loads.add(tokens: tok, lessons: tok > 0 ? 0 : 1) }
        UserDefaults(suiteName: ShareInbox.suite)?.removeObject(forKey: "shareDraft")
        if let file = draft.imageFile, let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ShareInbox.suite) {
            try? FileManager.default.removeItem(at: base.appendingPathComponent("ShareInbox").appendingPathComponent(file))
        }
        dismiss()
    }
}

// MARK: - Widget bridge (App Group snapshot: mood + pips + ships + last receipt — nothing else)

struct WidgetSnapshot: Codable {
    var mood: String        // "fed" | "hungry"
    var pips: [Bool]        // Train, Load, Ship today
    var ships: Int          // this week
    var lastReceipt: String
    var name: String
    var updatedAt: Date
}

enum WidgetBridge {
    static let suite = "group.com.larpy.app"

    @MainActor
    static func write(store: ProofStore, prefs: Prefs) {
        let s = LifeEngine.stats(store.logs)
        let last = store.logs.first.map { "\($0.quest.title) · \(summaryChip($0))" } ?? ""
        let snap = WidgetSnapshot(mood: store.todayCount > 0 ? "fed" : "hungry",
                                  pips: QuestKind.allCases.map { store.doneToday($0) },
                                  ships: s.workN, lastReceipt: last, name: prefs.name, updatedAt: .now)
        UserDefaults(suiteName: suite)?.set(try? JSONEncoder().encode(snap), forKey: "snapshot")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct KitChips: View {
    @Binding var kitID: String
    var body: some View {
        FlowChips(items: Kit.allCases.map { ($0.rawValue, $0.label) }, selected: kitID) { id in
            withAnimation(.easeInOut(duration: 0.25)) { kitID = id }
        }
    }
}

/// Simple wrapping chip row.
struct FlowChips: View {
    let items: [(id: String, label: String)]
    let selected: String
    let onTap: (String) -> Void

    var body: some View {
        let cols = [GridItem(.adaptive(minimum: 92), spacing: 8)]
        LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.id) { item in
                let on = selected == item.id
                Button { onTap(item.id) } label: {
                    Text(item.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(on ? Palette.bg : Palette.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(on ? Palette.gold : Palette.card, in: Capsule())
                        .overlay(Capsule().stroke(Palette.line, lineWidth: on ? 0 : 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Multi-select checklist of apps (stored as a comma-joined string). Nothing is blocked.
struct AppsChecklist: View {
    @Binding var value: String
    @State private var other = ""

    private var selected: Set<String> {
        Set(value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }

    private func write(_ s: Set<String>) { value = s.sorted().joined(separator: ", ") }

    private func toggle(_ app: String) {
        var s = selected
        if s.contains(app) { s.remove(app) } else { s.insert(app) }
        write(s)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let cols = [GridItem(.adaptive(minimum: 120), spacing: 8)]
            LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
                ForEach(lockableApps, id: \.self) { app in
                    tick(app, on: selected.contains(app)) { toggle(app) }
                }
            }
            HStack(spacing: 8) {
                TextField("Other", text: $other)
                    .autocorrectionDisabled()
                    .font(.system(size: 14)).foregroundStyle(Palette.text)
                    .padding(10)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Palette.line, lineWidth: 1))
                Button("Add") {
                    let t = other.trimmingCharacters(in: .whitespaces)
                    guard !t.isEmpty else { return }
                    var s = selected; s.insert(t); write(s); other = ""
                }
                .font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.bg)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Palette.gold, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .buttonStyle(.plain)
            }
        }
    }

    private func tick(_ label: String, on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle").font(.system(size: 14))
                Text(label).font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(on ? Palette.gold : Palette.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 9).padding(.horizontal, 10)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(on ? Palette.gold.opacity(0.5) : Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct SettingCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.system(size: 13, weight: .semibold)).kerning(2).foregroundStyle(Palette.gold)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct FieldRow: View {
    let title: String
    @Binding var text: String
    var placeholder = ""
    var body: some View {
        HStack {
            Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(Palette.text)
            Spacer()
            TextField(placeholder, text: $text)
                .multilineTextAlignment(.trailing)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: 190)
        }
    }
}

// MARK: - Settings

/// One list, six rows. No cards-inside-cards, no menus, no playground.
struct SettingsView: View {
    @ObservedObject var store: ProofStore
    @ObservedObject var prefs: Prefs
    @ObservedObject var agents: AgentStore
    @ObservedObject var keys: AgentKeys
    @Environment(\.dismiss) private var dismiss
    @State private var confirmSignOut = false
    @State private var showAsk = false
    @State private var showAppearance = false

    private var rowFont: Font { .system(size: 16, weight: .medium) }
    private var hasShipped: Bool { store.logs.contains { $0.quest == .work && $0.isEligible } }
    private var wardrobeLine: String {
        if Larp.unlocked { return "Yours. It never renews." }
        if !Larp.wardrobeOpen { return "Paused. Looks and rooms are holding." }
        if let days = Larp.daysLeft { return days == 0 ? "Last free day." : "Free for \(days) more day\(days == 1 ? "" : "s")." }
        return "Free. The first receipt starts the month."
    }

    var body: some View {
        NavigationStack {
            List {
                // 1 · Appearance
                HStack {
                    Text("Appearance").font(rowFont).foregroundStyle(Palette.text)
                    Spacer()
                    Picker("", selection: $prefs.isDark) {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                .frame(minHeight: 44)
                .listRowBackground(Palette.card)

                // 2 · Larpy: name + costume (one at a time, same body)
                VStack(spacing: 10) {
                    HStack {
                        Text("Larpy").font(rowFont).foregroundStyle(Palette.text)
                        Spacer()
                        TextField("You", text: $prefs.name)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Palette.muted)
                            .frame(maxWidth: 180)
                    }
                    Button { showAppearance = true } label: {
                        HStack {
                            Text("Outfit & scene").font(.system(size: 14)).foregroundStyle(Palette.muted)
                            Spacer()
                            Text("Customize").foregroundStyle(Palette.text)
                            Image(systemName: "chevron.right").foregroundStyle(Palette.muted)
                        }.frame(minHeight: 44)
                    }.buttonStyle(.plain)
                    HStack {
                        Text("Icon").font(.system(size: 14)).foregroundStyle(Palette.muted)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { prefs.iconChoice },
                            set: { prefs.iconChoice = $0; LarpyIcon.apply($0, userChosen: true) })) {
                            ForEach(LarpyIcon.all.filter { Larp.wardrobeOpen || $0.id.isEmpty }, id: \.id) { o in Text(o.label).tag(o.id) }
                        }
                        .pickerStyle(.menu)
                        .tint(Palette.gold)
                    }
                }
                .padding(.vertical, 4)
                .frame(minHeight: 44)
                .listRowBackground(Palette.card)

                // 2b · Wardrobe: the only thing for sale, reached from here and the paused card. Never automatic.
                Button { showAsk = true } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wardrobe").font(rowFont).foregroundStyle(Palette.text)
                            Text(wardrobeLine).font(.system(size: 11)).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Text(Larp.unlocked ? "Kept" : Larp.fallbackPrice + " once").font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.gold)
                    }
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .listRowBackground(Palette.card)

                // 3 · Agents
                NavigationLink {
                    AgentsView(prefs: prefs, keys: keys)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Optional AI features").font(rowFont).foregroundStyle(Palette.text)
                            Text("Your own key. A model reads your week when you ask.").font(.system(size: 11)).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Text(agentsSummary).font(.system(size: 14)).foregroundStyle(Palette.muted)
                    }
                    .frame(minHeight: 44)
                }
                .listRowBackground(Palette.card)

                // 4 · Tokens = model spend for "Ask an agent". NOT Today's LOAD count.
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tokens").font(rowFont).foregroundStyle(Palette.text)
                            Text("model spend · your own key").font(.system(size: 11)).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Text("\(fmtTokens(agents.modelTokensThisWeek)) this week")
                            .font(.system(size: 13)).foregroundStyle(Palette.muted)
                    }

                }
                .padding(.vertical, 6)
                .frame(minHeight: 44)
                .listRowBackground(Palette.card)

                // 5 · Notifications: 10:00 "Body?" and 18:00 "Ship?" only
                Toggle(isOn: $prefs.notificationsOn) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications").font(rowFont).foregroundStyle(Palette.text)
                        Text(UserDefaults.standard.bool(forKey: "remindersQuiet") && !prefs.notificationsOn
                             ? "Larpy went quiet after three unanswered pings. Turn him back on."
                             : "10:00 Body? · 18:00 Work?").font(.system(size: 11)).foregroundStyle(Palette.muted)
                    }
                }
                .tint(Palette.gold)
                .frame(minHeight: 44)
                .listRowBackground(Palette.card)
                .onChange(of: prefs.notificationsOn) {
                    if prefs.notificationsOn {
                        UserDefaults.standard.set(false, forKey: "remindersQuiet"); UserDefaults.standard.set(0, forKey: "pingUnanswered")
                        LarpyReminders.requestAuthorization()
                    }
                    LarpyReminders.refresh(store: store, agents: agents)
                }

                // 5b · Feedback, hidden until the first completed Work. Rows the user opens, never a prompt.
                if hasShipped {
                    if !Feedback.appStoreID.isEmpty {
                        Button { Feedback.rate() } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Rate Larpy").font(rowFont).foregroundStyle(Palette.text)
                                Text("Leave a receipt on the App Store.").font(.system(size: 11)).foregroundStyle(Palette.muted)
                            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }.buttonStyle(.plain).listRowBackground(Palette.card)
                    }
                    Button { Feedback.ask(store: store) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ask for something").font(rowFont).foregroundStyle(Palette.text)
                            Text("One line. It gets read.").font(.system(size: 11)).foregroundStyle(Palette.muted)
                        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }.buttonStyle(.plain).listRowBackground(Palette.card)
                }

                // 5c · Where the receipts live. One sentence, no account.
                Text("Receipts live on this phone. Deleting the app deletes them.")
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                    .listRowBackground(Color.clear)

                // 6 · Sign out (no account: clears keys and name on this phone, keeps proofs)
                Button(role: .destructive) { confirmSignOut = true } label: {
                    Text("Sign out").font(rowFont).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .listRowBackground(Palette.card)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Palette.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAsk) { AskView(store: store, prefs: prefs) }
            .sheet(isPresented: $showAppearance) { WardrobeView(store: store, prefs: prefs) }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.tint(Palette.gold)
                }
            }
            .confirmationDialog("Sign out on this phone?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("Sign out", role: .destructive) {
                    keys.clearAll(); prefs.name = "You"; prefs.providerID = "claude"; dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Removes agent keys and your name. Your proofs stay.")
            }
        }
    }

    private var agentsSummary: String {
        let n = Provider.allCases.filter { keys.canRun($0) }.count
        return n == 0 ? "None" : (keys.canRun(prefs.provider) ? prefs.provider.label : "\(n) set")
    }

    /// Bar is used-this-week against your best week so far; remaining is what's left to that mark.
    private var tokensRemaining: Int { max(0, agents.highWaterWeek - agents.weekTotal) }
    private var tokensFraction: CGFloat {
        let cap = max(agents.highWaterWeek, agents.weekTotal, 1)
        return CGFloat(agents.weekTotal) / CGFloat(cap)
    }
}

/// Agents: ONE key slot. Pick the provider, paste the key. Same shape for all. No Connect button.
struct AgentsView: View {
    @ObservedObject var prefs: Prefs
    @ObservedObject var keys: AgentKeys
    @State private var draft = ""

    private var p: Provider { prefs.provider }

    var body: some View {
        List {
            Section {
                Picker("Provider", selection: $prefs.providerID) {
                    ForEach(Provider.allCases) { p in Text(p.label).tag(p.rawValue) }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: 44)
                .listRowBackground(Palette.card)

                HStack(spacing: 10) {
                    if !p.needsKey {
                        Text(AgentKeys.appleAvailable ? "On this device. No key." : "Not available on this device.")
                            .font(.system(size: 14)).foregroundStyle(Palette.muted)
                        Spacer()
                    } else if keys.canRun(p) {
                        Text("Key added").font(.system(size: 14)).foregroundStyle(Palette.muted)
                        Spacer()
                        Button("Remove") { keys.clear(p) }
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(Palette.muted)
                            .buttonStyle(.plain)
                    } else {
                        SecureField("Paste \(p.label) key", text: $draft)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .font(.system(size: 14)).foregroundStyle(Palette.text)
                        Button("Add") { keys.set(draft, for: p); draft = "" }
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.bg)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Palette.gold, in: Capsule())
                            .buttonStyle(.plain)
                            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .frame(minHeight: 44)
                .listRowBackground(Palette.card)
            } header: {
                Text("Keys stay on this phone.")
            } footer: {
                Text("One job: a sentence about your week, from your receipts. Button on Week.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Palette.bg.ignoresSafeArea())
        .navigationTitle("Agents")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Onboarding (first launch)

/// Two steps (Hick): how he looks, then the 2-field profile a friend will see. Inviting comes after the first receipt.
// MARK: - One actor, four scenes. The face is never a costume surface.

enum ShipLevel {
    static func title(_ ships: Int) -> String {
        switch ships { case 0: "larping"; case 1..<3: "first proof"; case 3..<7: "repeat offender"; default: "real enough" }
    }
    static func next(_ ships: Int) -> Int { ships < 1 ? 1 : ships < 3 ? 3 : 7 }
}

enum SceneWardrobe {
    static func kit(for logs: [ProofLog], fallback: Kit = .bare) -> Kit {
        guard let latest = logs.first else { return fallback }
        if let saved = latest.costumeID, let kit = Kit(rawValue: saved) { return kit }
        if fallback != .bare { return fallback }
        return latest.quest == .work ? .hoodie : latest.quest == .body ? .tee : .rollneck
    }
    static func caption(_ kit: Kit, hungry: Bool) -> String {
        if hungry { return "WAITING FOR EVIDENCE" }
        switch kit {
        case .rollneck: return "THE WALK BEFORE THE LAUNCH"
        case .tee: return "DO THE BORING REPS"
        case .collar: return "PICK UP. CLOSE. REPEAT."
        case .hoodie: return "IT LEFT LOCALHOST"
        default: return "BECOME THE PERSON. PROVE IT."
        }
    }
}

struct LarpyCharacterView: View {
    let life: LifeState
    let base: LarpyBase
    var blush = true
    var kit: Kit = .bare
    var width: CGFloat = 220
    var showScene = true
    /// Overrides the look's own room. Today uses it so the lane you just fed picks the scene.
    var scene: MovieScene? = nil
    var sceneCorner: CGFloat = 26
    var interactive = false
    var hatched = true // compatibility: the actor now has a face from the very first open
    var fedTick = 0
    var fedLane = 0
    var level = 0
    var founderID: String? = nil
    var companion = false
    private var founder: FounderLook? { FounderLook.find(founderID) }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var fedAt = Date.distantPast
    @State private var touchedAt = Date.distantPast
    @State private var enteredAt = Date.now
    @State private var drag: CGSize = .zero

    private var hungry: Bool { life.face == .asleep }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !interactive || reduceMotion || scenePhase != .active)) { clock in
            stage(at: interactive && !reduceMotion ? clock.date : .distantPast)
        }
        .onChange(of: fedTick) { _, _ in fedAt = .now }
        .onChange(of: kit) { _, _ in enteredAt = .now }
        .onChange(of: reduceMotion) { _, _ in resetInteraction() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { resetInteraction() } }
        .onDisappear { resetInteraction() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Larpy. \(hungry ? "Hungry" : "Fed"). \(founder?.title ?? Costume.from(kit: kit).label). \(ShipLevel.title(level)).")
    }

    private func stage(at date: Date) -> some View {
        let moving = interactive && !reduceMotion && scenePhase == .active
        let t = moving ? date.timeIntervalSince(enteredAt) : 3.0
        let phase = max(0, t).truncatingRemainder(dividingBy: 12)
        let walking = kit == .rollneck && !hungry && phase < 2.4
        let walk = walking ? sin(phase / 2.4 * .pi) : 0
        let sinceFeed = date.timeIntervalSince(fedAt)
        let squash = moving && sinceFeed >= 0 && sinceFeed < 0.65 ? sin(sinceFeed / 0.65 * .pi) : 0
        let sincePoke = date.timeIntervalSince(touchedAt)
        let poke = moving && sincePoke >= 0 && sincePoke < 0.45 ? sin(sincePoke / 0.45 * .pi) : 0
        let breathe = moving ? sin(t * 1.7) * 0.012 : 0
        let sway = moving ? sin(t * 0.85) * (hungry ? 1.3 : 2) : 0
        let blink = moving && t > 1 && t.truncatingRemainder(dividingBy: 5.7) < 0.4
        let w = width
        return ZStack {
            if showScene {
                (scene ?? founder?.scene ?? MovieScene.forKit(kit)).panel(w: w, corner: sceneCorner)
                Ellipse().fill(Palette.ink.opacity(0.20))
                    .frame(width: w * 0.85, height: w * 0.075)
                    .blur(radius: w * 0.018).offset(y: w * 0.58)
            }
            actor(w: w, blink: blink, phase: phase, greeting: companion && (poke > 0 || squash > 0 || life.cleared))
                .scaleEffect(x: 1 + breathe + squash * 0.12 + poke * 0.045,
                             y: (hungry ? 0.91 : 1) + breathe - squash * 0.13 + poke * 0.045, anchor: .bottom)
                .rotationEffect(.degrees((hungry ? -4 : 0) + (life.posture == .upright ? 0 : sway) + (walking ? -3 * sin(phase * 10) : 0)), anchor: .bottom)
                .scaleEffect(life.growScale, anchor: .bottom)
                .offset(y: life.posture == .sofa ? w * 1.10 * 0.05 : 0)
                .offset(x: walk * w * 0.15 + (moving ? drag.width : 0), y: -abs(sin(phase * 8)) * (walking ? w * 0.025 : 0) + (moving ? drag.height : 0))
            if showScene && level >= 7 {
                Image(systemName: "sparkle").font(.system(size: w * 0.10, weight: .light))
                    .foregroundStyle(Palette.gold).offset(x: w * 0.52, y: -w * 0.35)
            }
            if showScene, let bubble = life.bubble, !(sinceFeed >= 0 && sinceFeed < 1.4 && moving) {
                Text(bubble)
                    .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(0.8)
                    .foregroundStyle(Palette.ink.opacity(0.8))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color(hex: 0xF5F0E6).opacity(0.9), in: Capsule())
                    .rotationEffect(.degrees(-3)).offset(x: w * 0.30, y: -w * 0.66)
            }
            if showScene && sinceFeed >= 0 && sinceFeed < 1.4 && moving {
                Text(fedLane == 3 ? "OUT IN THE WORLD." : fedLane == 1 ? "BODY OF EVIDENCE." : "LOADED. NOW USE IT.")
                    .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1)
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(fedLane == 3 ? Palette.gold : Color(hex: 0xF5F0E6), in: Capsule())
                    .rotationEffect(.degrees(-5)).offset(y: -w * 0.63)
                    .opacity(min(1, (1.4 - sinceFeed) * 4))
            }
        }
        // With a scene the stage is a panel and fills whatever frame the parent gives it.
        // Without one it keeps the tight avatar box the small call sites rely on.
        .frame(width: showScene ? nil : w * 1.5, height: showScene ? nil : w * 1.45)
        .frame(maxWidth: showScene ? .infinity : nil, maxHeight: showScene ? .infinity : nil)
        .contentShape(Rectangle())
        .onTapGesture {
            guard interactive else { return }
            touchedAt = .now
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
        .gesture(DragGesture(minimumDistance: 5).onChanged { value in
            guard interactive && !reduceMotion else { return }
            drag = CGSize(width: max(-24, min(24, value.translation.width * 0.3)), height: max(-18, min(18, value.translation.height * 0.3)))
        }.onEnded { _ in withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { drag = .zero } })
    }

    private func resetInteraction() {
        drag = .zero
        fedAt = .distantPast
        touchedAt = .distantPast
    }

    private func actor(w: CGFloat, blink: Bool, phase: Double, greeting: Bool) -> some View {
        let h = w * 1.10
        let clothed = kit == .hoodie || kit == .tee || kit == .rollneck || kit == .collar
        let cloth = founder?.color ?? (kit == .hoodie ? Color(hex: 0x666D69) : kit == .tee || kit == .collar ? Color(hex: 0xE4DED2) : Palette.ink)
        return ZStack {
            // Stubby limbs. Same silhouette for every character.
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule().fill(clothed ? cloth : Palette.creature)
                    .overlay(Capsule().stroke(Palette.ink.opacity(0.65), lineWidth: w * 0.009))
                    .frame(width: w * 0.14 * life.bodyTone, height: w * 0.29)
                    .rotationEffect(.degrees(side * (greeting ? -125 : hungry ? -12 : -28)))
                    .offset(x: side * w * 0.46, y: h * (greeting ? 0.04 : 0.20))
                Capsule().fill(clothed ? Color(hex: 0x393C39) : Palette.creature)
                    .overlay(Capsule().stroke(Palette.ink.opacity(0.65), lineWidth: w * 0.009))
                    .frame(width: w * 0.20, height: w * 0.13)
                    .rotationEffect(.degrees(side * (life.posture == .sofa ? 25 : 12)))
                    .offset(x: side * w * (life.posture == .upright ? 0.25 : 0.23), y: h * 0.48)
            }
            EggShape().fill(LinearGradient(colors: [Color(hex: 0xFFF1D8), Palette.creature, Color(hex: 0xEAD4B0)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(EggShape().stroke(Palette.ink.opacity(0.8), lineWidth: max(0.7, w * 0.009)))
                .frame(width: w, height: h)
                .shadow(color: Palette.ink.opacity(0.07), radius: w * 0.03, y: w * 0.025)
            if clothed {
                Rectangle().fill(LinearGradient(colors: [cloth, cloth.opacity(0.85), cloth], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w, height: h * 0.40)
                    .offset(y: h * 0.35)
                    .mask(EggShape().frame(width: w, height: h))
                CurveLine(bend: 0.15).stroke(Palette.ink.opacity(0.22), lineWidth: w * 0.007)
                    .frame(width: w * 0.64, height: w * 0.035).offset(y: h * 0.45)
                if kit == .rollneck {
                    Capsule().fill(cloth).frame(width: w * 0.64, height: w * 0.055).offset(y: h * 0.18)
                }
                if kit == .hoodie {
                    HStack(spacing: w * 0.20) {
                        Capsule().fill(Palette.creature).frame(width: w * 0.012, height: w * 0.09)
                        Capsule().fill(Palette.creature).frame(width: w * 0.012, height: w * 0.09)
                    }.offset(y: h * 0.23)
                    RoundedRectangle(cornerRadius: w * 0.04).stroke(Palette.ink.opacity(0.28), lineWidth: w * 0.008)
                        .frame(width: w * 0.33, height: h * 0.08).offset(y: h * 0.37)
                }
                if kit == .collar {
                    HStack(spacing: 0) {
                        Triangle().fill(Color.white).frame(width: w * 0.16, height: w * 0.11)
                        Triangle().fill(Color.white).frame(width: w * 0.16, height: w * 0.11)
                    }.offset(y: h * 0.19)
                }
            }
            if let founder {
                garmentDetail(founder.detail, w: w, h: h)
                if ["camera", "microphone", "dumbbell", "notebook"].contains(founder.prop) {
                    RewardProp(prop: founder.prop, width: w).offset(x: w * 0.36, y: h * 0.31)
                } else if !["walk", "board", "phone", "laptop"].contains(founder.prop) {
                    RoundedRectangle(cornerRadius: w * 0.025).fill(Color(hex: 0xE1C9A6))
                        .overlay(RoundedRectangle(cornerRadius: w * 0.025).stroke(Palette.ink.opacity(0.8), lineWidth: w * 0.008))
                        .overlay { Image(systemName: propSymbol(founder.prop)).font(.system(size: w * 0.10, weight: .regular)).foregroundStyle(Palette.ink) }
                        .frame(width: w * 0.27, height: w * 0.25)
                        .rotationEffect(.degrees(-8)).offset(x: w * 0.35, y: h * 0.32)
                }
                if founder.prop == "laptop" && kit != .hoodie {
                    RoundedRectangle(cornerRadius: w * 0.02).fill(Color(hex: 0xA8AAA4))
                        .overlay { Text(">_").font(.system(size: w * 0.06, weight: .bold, design: .monospaced)).foregroundStyle(Palette.ink) }
                        .frame(width: w * 0.42, height: w * 0.23).offset(x: w * 0.22, y: h * 0.36)
                }
            }
            // Face: cream from crown to chin. Blush stays even when hungry.
            HStack(spacing: w * 0.40) {
                Ellipse().fill(Palette.blush.opacity(hungry ? 0.46 : 0.72)).frame(width: w * 0.18, height: w * 0.105)
                Ellipse().fill(Palette.blush.opacity(hungry ? 0.46 : 0.72)).frame(width: w * 0.18, height: w * 0.105)
            }.offset(y: h * 0.035)
            HStack(spacing: w * 0.23) {
                if greeting {
                    ForEach(0..<2) { _ in
                        CurveLine(bend: -0.5).stroke(Palette.ink, style: StrokeStyle(lineWidth: w * 0.018, lineCap: .round))
                            .frame(width: w * 0.085, height: w * 0.06)
                    }
                } else {
                    eye(w, blink: blink); eye(w, blink: blink)
                }
            }.offset(x: kit == .rollneck && phase < 2.4 ? w * 0.02 : 0, y: -h * 0.065)
            CurveLine(bend: greeting ? 0.9 : hungry ? -0.10 : life.face == .stirring ? 0.12 : 0.72)
                .stroke(Palette.ink, style: StrokeStyle(lineWidth: max(1, w * 0.016), lineCap: .round))
                .frame(width: w * (companion ? 0.16 : 0.12), height: w * 0.06).offset(y: h * 0.11)
            if level >= 3 && clothed {
                Circle().fill(Palette.gold).frame(width: w * 0.035, height: w * 0.035).offset(x: -w * 0.24, y: h * 0.34)
            }
            if kit == .hoodie && (founder?.prop == "laptop" || (founder == nil && level > 0)) {
                RoundedRectangle(cornerRadius: w * 0.025).fill(Color(hex: 0xA8AAA4))
                    .overlay(RoundedRectangle(cornerRadius: w * 0.025).stroke(Palette.ink, lineWidth: w * 0.008))
                    .overlay { Text(">_").font(.system(size: w * 0.055, weight: .bold, design: .monospaced)).foregroundStyle(Palette.ink) }
                    .frame(width: w * 0.43, height: w * 0.24)
                    .rotationEffect(.degrees(-3)).offset(x: w * 0.18, y: h * 0.36)
            }
            if (kit == .collar && founder == nil) || founder?.prop == "phone" {
                Capsule().fill(Palette.ink).frame(width: w * 0.085, height: w * 0.25)
                    .rotationEffect(.degrees(-20 + sin(phase * 2) * 4))
                    .offset(x: w * 0.48, y: h * 0.08)
            }
        }.frame(width: w, height: h)
    }

    @ViewBuilder private func garmentDetail(_ detail: String, w: CGFloat, h: CGFloat) -> some View {
        switch detail {
        case "blazer":
            Path { p in
                p.move(to: CGPoint(x: w * 0.24, y: 0)); p.addLine(to: CGPoint(x: w * 0.43, y: w * 0.14)); p.addLine(to: CGPoint(x: w * 0.36, y: w * 0.03)); p.closeSubpath()
                p.move(to: CGPoint(x: w * 0.60, y: 0)); p.addLine(to: CGPoint(x: w * 0.44, y: w * 0.26)); p.addLine(to: CGPoint(x: w * 0.53, y: w * 0.03)); p.closeSubpath()
            }.fill(Color(hex: 0x233E54)).frame(width: w * 0.85, height: w * 0.27).offset(y: h * 0.29)
            RoundedRectangle(cornerRadius: w * 0.006).fill(Color(hex: 0xEEE7D8)).frame(width: w * 0.105, height: w * 0.025).rotationEffect(.degrees(-6)).offset(x: -w * 0.23, y: h * 0.28)
            Circle().fill(Color(hex: 0xC4A35A)).frame(width: w * 0.027).offset(x: -w * 0.02, y: h * 0.40)
        case "athletic":
            Capsule().fill(Color(hex: 0xF4EAD1)).frame(width: w * 0.68, height: w * 0.058).rotationEffect(.degrees(-4)).offset(y: -h * 0.29)
            Text("10").font(.system(size: w * 0.15, weight: .heavy, design: .rounded)).foregroundStyle(Color(hex: 0xF4EAD1)).offset(x: -w * 0.1, y: h * 0.30)
        case "photographer":
            Rectangle().fill(Color(hex: 0x3F3930)).frame(width: w * 0.035, height: h * 0.37).rotationEffect(.degrees(-36)).offset(x: w * 0.07, y: h * 0.31)
            RoundedRectangle(cornerRadius: w * 0.02).stroke(Color(hex: 0x704C3E), lineWidth: w * 0.008).frame(width: w * 0.14, height: w * 0.10).offset(x: -w * 0.23, y: h * 0.30)
        case "broadcast":
            Path { p in p.addArc(center: CGPoint(x: w * 0.5, y: w * 0.4), radius: w * 0.44, startAngle: .degrees(195), endAngle: .degrees(345), clockwise: false) }
                .stroke(Color(hex: 0x303B40), style: StrokeStyle(lineWidth: w * 0.055, lineCap: .round)).frame(width: w, height: w * 0.5).offset(y: -h * 0.21)
            HStack { Capsule().fill(Color(hex: 0x303B40)).frame(width: w * 0.09, height: w * 0.19); Spacer(); Capsule().fill(Color(hex: 0x303B40)).frame(width: w * 0.09, height: w * 0.19) }
                .frame(width: w * 0.99).offset(y: -h * 0.02)
        case "round-glasses":
            HStack(spacing: w * 0.14) {
                Circle().stroke(Palette.ink, lineWidth: w * 0.01).frame(width: w * 0.16, height: w * 0.16)
                Circle().stroke(Palette.ink, lineWidth: w * 0.01).frame(width: w * 0.16, height: w * 0.16)
            }.offset(y: -h * 0.065)
        case "stripe":
            HStack(spacing: w * 0.07) { ForEach(0..<5) { _ in Rectangle().fill(Palette.ink.opacity(0.25)).frame(width: w * 0.012, height: h * 0.13) } }.offset(y: h * 0.35)
        case "buttons":
            VStack(spacing: w * 0.03) { ForEach(0..<3) { _ in Circle().fill(Palette.ink.opacity(0.6)).frame(width: w * 0.015, height: w * 0.015) } }.offset(y: h * 0.36)
        case "pocket", "patch":
            RoundedRectangle(cornerRadius: 2).stroke(Palette.ink.opacity(0.45), lineWidth: w * 0.008).frame(width: w * 0.11, height: w * 0.09).offset(x: -w * 0.22, y: h * 0.34)
        case "chain":
            CurveLine(bend: 0.7).stroke(Palette.gold, lineWidth: w * 0.012).frame(width: w * 0.34, height: w * 0.08).offset(y: h * 0.28)
        case "v-neck":
            Triangle().stroke(Palette.ink.opacity(0.3), lineWidth: w * 0.009).frame(width: w * 0.17, height: w * 0.09).offset(y: h * 0.29)
        case "zip":
            Rectangle().fill(Palette.ink.opacity(0.45)).frame(width: w * 0.01, height: h * 0.17).offset(y: h * 0.37)
        default: EmptyView()
        }
    }
    private func propSymbol(_ prop: String) -> String {
        switch prop {
        case "chip": "cpu"; case "book": "book.closed"; case "notebook": "pencil.line"; case "phone": "phone";
        case "rocket": "paperplane"; case "parcel": "shippingbox"; case "shoe": "shoe"; case "gear": "gearshape";
        case "headphones": "headphones"; case "camera": "camera"; default: "book.closed"
        }
    }

    private func eye(_ w: CGFloat, blink: Bool) -> some View {
        Capsule().fill(Palette.ink).frame(width: w * 0.072, height: w * 0.105)
            .overlay(alignment: .topTrailing) {
                Circle().fill(Color(hex: 0xFFF9ED)).frame(width: w * 0.023, height: w * 0.023).offset(x: -w * 0.01, y: w * 0.014)
            }
            .scaleEffect(y: blink ? 0.13 : 1)
    }
}

struct CurveLine: Shape {
    var bend: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.height * 2 * bend)); return p
    }
}
struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: r.minX, y: r.minY)); p.addLine(to: CGPoint(x: r.midX, y: r.maxY)); p.addLine(to: CGPoint(x: r.maxX, y: r.minY)); p.closeSubpath(); return p
    }
}
private struct EggShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.height * 0.62), control1: CGPoint(x: r.width * 0.79, y: 0), control2: CGPoint(x: r.maxX, y: r.height * 0.34))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY), control1: CGPoint(x: r.maxX, y: r.height * 0.88), control2: CGPoint(x: r.width * 0.79, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.height * 0.62), control1: CGPoint(x: r.width * 0.21, y: r.maxY), control2: CGPoint(x: 0, y: r.height * 0.88))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY), control1: CGPoint(x: 0, y: r.height * 0.34), control2: CGPoint(x: r.width * 0.21, y: 0))
        return p
    }
}

// MARK: - Badge, notifications, once-a-day icon

/// Two rows in Settings. The system review prompt is never called; a person opens these.
enum Feedback {
    /// Empty until the app has an App Store ID. The row hides itself until then.
    static let appStoreID = ""
    /// Where 'Ask for something' goes. Set this before TestFlight.
    static let address = "hello@larpy.app"

    static func rate() {
        guard !appStoreID.isEmpty, let url = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review") else { return }
        UIApplication.shared.open(url)
    }

    @MainActor static func ask(store: ProofStore) {
        let s = LifeEngine.stats(store.logs)
        let build = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") + " (" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?") + ")"
        let firstDay = store.logs.map(\.createdAt).min().map { max(1, (LarpyTime.cal.dateComponents([.day], from: $0, to: .now).day ?? 0) + 1) } ?? 0
        let work = store.logs.filter { $0.quest == .work && $0.isEligible }.count
        let body = "\n\n\nv\(build) · iOS \(UIDevice.current.systemVersion) · \(firstDay) days used · \(work) Work · \(s.workN)/7 this week"
        var c = URLComponents(); c.scheme = "mailto"; c.path = address
        c.queryItems = [URLQueryItem(name: "subject", value: "Larpy"), URLQueryItem(name: "body", value: body)]
        if let url = c.url, UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
        else { UIPasteboard.general.string = address }
    }
}

enum LarpyReminders {
    private static let morningID = "larpy.1700"
    private static let eveningID = "larpy.2130"

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    @MainActor
    static func refresh(store: ProofStore, agents: AgentStore) {
        UNUserNotificationCenter.current().setBadgeCount(max(0, 3 - store.todayCount))
        scheduleReminders(store: store, agents: agents)
    }

    /// Automatic swaps, once a day max: Hungry when a day after an empty day is still empty;
    /// back to the user's pick once a receipt lands. The user's own choice always wins.
    @MainActor
    private static func updateIcon(store: ProofStore) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let chosen = UserDefaults.standard.string(forKey: "iconChoice") ?? ""
        let current = UIApplication.shared.alternateIconName
        let s = LifeEngine.stats(store.logs)
        let hungry = !store.logs.isEmpty && store.todayCount == 0 && s.emptyStreak >= 1

        if hungry, chosen != "LarpyHungry" {
            LarpyIcon.apply("LarpyHungry", userChosen: false)
        } else if !hungry, current == "LarpyHungry", chosen != "LarpyHungry" {
            LarpyIcon.apply(chosen, userChosen: false)
        } else if let c = current, !LarpyIcon.all.contains(where: { $0.id == c }) {
            LarpyIcon.apply(chosen, userChosen: true)          // icon from an older build — reset once
        }
    }

    /// Two pings only: 10:00 "Body?" if no Train yet, 18:00 "Ship?" if no Ship yet. Nothing else, ever.
    @MainActor
    private static func scheduleReminders(store: ProofStore, agents: AgentStore) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningID, eveningID, "larpy.1000", "larpy.1800"])

        let d = UserDefaults.standard
        let on = d.object(forKey: "notificationsOn") as? Bool ?? false
        guard on else { return }

        // Three unanswered days in a row and Larpy goes quiet. Turning the toggle back on resets him.
        let today = LarpyTime.dayKey()
        let yesterdayDate = LarpyTime.cal.date(byAdding: .day, value: -1, to: .now) ?? .now
        if d.string(forKey: "pingLastDay") == LarpyTime.dayKey(yesterdayDate) {
            let answered = LifeEngine.anyDone(store.logs, on: yesterdayDate)
            d.set(answered ? 0 : d.integer(forKey: "pingUnanswered") + 1, forKey: "pingUnanswered")
        }
        if store.todayCount > 0 { d.set(0, forKey: "pingUnanswered") }
        if d.integer(forKey: "pingUnanswered") >= 3 {
            d.set(true, forKey: "remindersQuiet"); d.set(false, forKey: "notificationsOn"); d.set(0, forKey: "pingUnanswered")
            return
        }
        d.set(today, forKey: "pingLastDay")

        let n = max(0, 3 - store.todayCount)
        if !store.doneToday(.body) { add(center, id: "larpy.1000", hour: 10, minute: 0, body: "Body?", badge: n) }
        if !store.doneToday(.work) { add(center, id: "larpy.1800", hour: 18, minute: 0, body: "Work?", badge: n) }
        print("[Larpy] 10:00 → \(store.doneToday(.body) ? "-" : "Body?") | 18:00 → \(store.doneToday(.work) ? "-" : "Ship?")")
    }

    private static func add(_ center: UNUserNotificationCenter, id: String, hour: Int, minute: Int, body: String, badge: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Larpy"
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: badge)

        var when = DateComponents()
        when.calendar = LarpyTime.cal
        when.timeZone = LarpyTime.cal.timeZone
        when.hour = hour
        when.minute = minute

        guard let today = LarpyTime.cal.date(bySettingHour: hour, minute: minute, second: 0, of: .now), today > .now else { return }
        when = LarpyTime.cal.dateComponents([.year, .month, .day, .hour, .minute], from: today)
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
