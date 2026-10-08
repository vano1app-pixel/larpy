import Foundation

enum QuestKind: String, CaseIterable, Codable, Identifiable {
    case body = "Body"
    case learn = "Learn"
    case work = "Work"

    var id: String { rawValue }

    var prompt: String {
        switch self {
        case .body:
            "Move the meat suit."
        case .learn:
            "Feed the tiny brain."
        case .work:
            "Ship one real thing."
        }
    }

    /// The three moves. Raw values stay Body/Learn/Work so stored JSON keeps loading.
    var title: String {
        switch self {
        case .body: "Body"
        case .learn: "Learnt"
        case .work: "Work"
        }
    }

    var actionTitle: String {
        switch self {
        case .body: "Body"
        case .work: "Work"
        case .learn: "Learnt"
        }
    }

    /// Receipt placeholder in the lane's sheet.
    var receiptPlaceholder: String {
        switch self {
        case .body: "pic of the work or what you did"
        case .learn: "tokens / title of the lesson"
        case .work: "what left the building"
        }
    }

    /// Empty-row subtitle on Today.
    var emptyHint: String {
        switch self {
        case .body: "Add a photo or start a timer"
        case .learn: "Log AI tokens, a book or a lesson"
        case .work: "Add a link or screenshot"
        }
    }

    var glyph: String {
        switch self {
        case .body:
            "figure.run"
        case .learn:
            "book.closed.fill"
        case .work:
            "hammer.fill"
        }
    }
}

enum ProofKind: String, CaseIterable, Codable, Identifiable {
    case photo = "Photo"
    case link = "Link"
    case number = "Number"

    var id: String { rawValue }
}

struct ProofLog: Identifiable, Codable, Equatable {
    var id: UUID
    var quest: QuestKind
    var proofKind: ProofKind
    var value: String
    var photoFilename: String?
    var founderID: String?
    var costumeID: String?
    var annotation: String?
    var timerSeconds: Int?
    /// The room Larpy stood in when this landed. Old receipts have none and fall back to the lane's first room.
    var sceneID: String?
    var source: String?
    /// Local date when recorded. Travelling later must not split or merge earned days.
    var progressDay: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        quest: QuestKind,
        proofKind: ProofKind,
        value: String,
        photoFilename: String? = nil,
        founderID: String? = nil,
        costumeID: String? = nil,
        annotation: String? = nil,
        timerSeconds: Int? = nil,
        sceneID: String? = nil,
        source: String? = nil,
        progressDay: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.quest = quest
        self.proofKind = proofKind
        self.value = value
        self.photoFilename = photoFilename
        self.founderID = founderID
        self.costumeID = costumeID
        self.annotation = annotation
        self.timerSeconds = timerSeconds
        self.sceneID = sceneID
        self.source = source
        self.progressDay = progressDay
        self.createdAt = createdAt
    }
}

/// A cumulative daily total. Re-importing the same id replaces the total, never adds it twice.
struct UsageDay: Codable {
    let id: UUID
    let source: String
    let at: Date
    let tokens: Int
    var sourceLabel: String { source == "codex" ? "Codex" : "Claude Code" }
    func valid(now: Date = .now) -> Bool {
        ["codex", "claude-code"].contains(source) && tokens > 0 && tokens <= 10_000_000_000
            && at <= now.addingTimeInterval(300) && at > now.addingTimeInterval(-32 * 86_400)
    }
}

struct UsageSnapshot: Codable {
    let version: Int
    let generatedAt: Date
    let sources: [String]
    let days: [UsageDay]
}

/// Display-only usage. Reading historical totals must never award historical XP.
struct WeeklyUsageSummary {
    let total: Int
    let bySource: [String: Int]
    let generatedAt: Date
    let weekStart: Date
    var sourceLabel: String {
        if bySource.count == 2 { return "Codex + Claude Code" }
        return bySource["codex"] != nil ? "Codex" : "Claude Code"
    }
    var compact: String {
        if total >= 1_000_000_000 { return String(format: "%.1fB", Double(total) / 1_000_000_000).replacingOccurrences(of: ".0B", with: "B") }
        if total >= 1_000_000 { return String(format: "%.1fM", Double(total) / 1_000_000).replacingOccurrences(of: ".0M", with: "M") }
        if total >= 1_000 { return String(format: "%.1fk", Double(total) / 1_000).replacingOccurrences(of: ".0k", with: "k") }
        return String(total)
    }
    func freshness(now: Date = .now) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(generatedAt) / 60))
        if minutes < 1 { return "Updated just now" }
        if minutes < 15 { return "Updated \(minutes)m ago" }
        if minutes < 60 { return "Saved · \(minutes)m ago" }
        if minutes < 1440 { return "Saved · \(minutes / 60)h ago" }
        return "Saved · \(minutes / 1440)d ago"
    }
    static func from(_ snapshot: UsageSnapshot, now: Date = .now) -> WeeklyUsageSummary? {
        // Exporter groups by Dublin day. Keep that same boundary while travelling.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Dublin")!
        calendar.firstWeekday = 2; calendar.minimumDaysInFirstWeek = 4
        guard snapshot.version == 1, snapshot.days.count <= 200,
              snapshot.generatedAt <= now.addingTimeInterval(300),
              let week = calendar.dateInterval(of: .weekOfYear, for: now),
              snapshot.generatedAt >= week.start else { return nil }
        let sources = Set(snapshot.sources).intersection(["codex", "claude-code"])
        guard !sources.isEmpty else { return nil }
        var daily: [String: UsageDay] = [:]
        for day in snapshot.days where sources.contains(day.source) && day.valid(now: now)
            && day.at >= week.start && day.at < week.end {
            // One Mac snapshot has one cumulative value per source/day. Do not sum duplicates.
            let key = "\(day.source):\(calendar.startOfDay(for: day.at).timeIntervalSince1970)"
            if day.tokens > (daily[key]?.tokens ?? -1) { daily[key] = day }
        }
        var totals = Dictionary(uniqueKeysWithValues: sources.map { ($0, 0) })
        for day in daily.values { totals[day.source, default: 0] += day.tokens }
        return WeeklyUsageSummary(total: totals.values.reduce(0, +), bySource: totals,
                                  generatedAt: snapshot.generatedAt, weekStart: week.start)
    }
}

/// The receipt gate is shared by manual logging and the Share inbox.
/// We validate a receipt's format, never claim to verify a photograph or a deal.
enum ReceiptRules {
    static func webURL(_ value: String) -> URL? {
        let raw = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, !raw.contains(where: { $0.isWhitespace }),
              !raw.contains("@"), !raw.contains("\\") else { return nil }
        let text = raw.contains("://") ? raw : "https://" + raw
        guard let c = URLComponents(string: text),
              let scheme = c.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = c.host?.lowercased(), host != "localhost", !host.hasSuffix(".local"),
              host.range(of: #"^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,63}$"#, options: .regularExpression) != nil,
              c.user == nil, c.password == nil else { return nil }
        return c.url
    }
}

extension ProofLog {
    var isEligible: Bool {
        switch quest {
        case .learn: return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .work: return proofKind == .photo ? photoFilename != nil : proofKind == .link && ReceiptRules.webURL(value) != nil
        case .body: return proofKind == .photo ? photoFilename != nil : (timerSeconds ?? 0) >= 60
        }
    }
}

struct FollowerAchievement: Codable {
    var count: Int
    var photoFilename: String
    var at: Date
    var threshold: Int { count >= 100_000 ? 100_000 : count >= 10_000 ? 10_000 : count >= 1_000 ? 1_000 : 0 }
}
