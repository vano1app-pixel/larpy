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
    var createdAt: Date

    init(
        id: UUID = UUID(),
        quest: QuestKind,
        proofKind: ProofKind,
        value: String,
        photoFilename: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.quest = quest
        self.proofKind = proofKind
        self.value = value
        self.photoFilename = photoFilename
        self.createdAt = createdAt
    }
}
