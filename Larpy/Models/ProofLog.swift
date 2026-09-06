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
        case .body: "Photo, or a 60-second timer."
        case .learn: "Token count, or a link and what it's for."
        case .work: "A live link or a screenshot."
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
        self.createdAt = createdAt
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
