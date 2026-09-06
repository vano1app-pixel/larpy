import Combine
import Foundation
import UIKit

@MainActor
final class ProofStore: ObservableObject {
    @Published private(set) var logs: [ProofLog] = []
    @Published var errorMessage: String?
    private var storageUnreadable = false
    private let jsonURL: URL
    private let photosURL: URL

    init(fileManager: FileManager = .default, baseURL: URL? = nil) {
        let folder = baseURL ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Larpy", isDirectory: true)
        jsonURL = folder.appendingPathComponent("proofs.json")
        photosURL = folder.appendingPathComponent("ProofPhotos", isDirectory: true)
        do {
            try fileManager.createDirectory(at: photosURL, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: jsonURL.path) {
                var loaded = try JSONDecoder().decode([ProofLog].self, from: Data(contentsOf: jsonURL))
                    .sorted { $0.createdAt > $1.createdAt }
                // Old receipts carry look keys that were once a person's name. Rewrite them once.
                var migrated = false
                for i in loaded.indices {
                    if let c = FounderLook.canonicalID(loaded[i].founderID), c != loaded[i].founderID { loaded[i].founderID = c; migrated = true }
                }
                if migrated { try? JSONEncoder().encode(loaded).write(to: jsonURL, options: [.atomic]) }
                logs = loaded
            }
        } catch { storageUnreadable = true; errorMessage = "Your receipts couldn't be opened. Nothing has been overwritten." }
    }

    func latestLog(for quest: QuestKind) -> ProofLog? {
        logs.first { $0.quest == quest && $0.isEligible }
    }

    @discardableResult
    func logTextProof(quest: QuestKind, proofKind: ProofKind, value: String, annotation: String? = nil,
                      id: UUID = UUID(), createdAt: Date = .now) -> Bool {
        guard quest != .body else { errorMessage = "Body needs a photo or a completed timer."; return false }
        var value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return false }
        if proofKind == .link {
            guard let url = ReceiptRules.webURL(value) else { errorMessage = "Use a full web link to the thing."; return false }
            value = url.absoluteString
        }
        guard quest != .work || proofKind == .link else { errorMessage = "A sentence is Load. Ship needs a link or screenshot."; return false }
        return add(ProofLog(id: id, quest: quest, proofKind: proofKind, value: value,
                            founderID: nextLook.id, costumeID: nextLook.kit.rawValue, annotation: annotation, createdAt: createdAt))
    }

    @discardableResult
    func logTimer(start: Date, end: Date = .now, note: String = "") -> Bool {
        let seconds = Int(end.timeIntervalSince(start))
        guard seconds >= 60, end <= Date().addingTimeInterval(1), seconds <= 86_400 else {
            errorMessage = "Give it a real minute. Timer receipts need at least 60 seconds."; return false
        }
        return add(ProofLog(quest: .body, proofKind: .number, value: "\(seconds / 60)m",
                            founderID: nextLook.id, costumeID: nextLook.kit.rawValue, annotation: note, timerSeconds: seconds, createdAt: end))
    }

    func logPhotoProof(quest: QuestKind, imageData: Data) throws {
        try logPhoto(quest: quest, imageData: imageData, value: "photo")
    }
    func logPhoto(quest: QuestKind, imageData: Data, value: String) throws {
        guard let image = UIImage(data: imageData), let data = image.jpegData(compressionQuality: 0.82) else {
            throw NSError(domain: "Larpy", code: 1, userInfo: [NSLocalizedDescriptionKey: "That image couldn't be read. Pick it again."])
        }
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = photosURL.appendingPathComponent(filename)
        try data.write(to: fileURL, options: [.atomic])
        if !add(ProofLog(quest: quest, proofKind: .photo, value: value, photoFilename: filename, founderID: nextLook.id, costumeID: nextLook.kit.rawValue)) {
            try? FileManager.default.removeItem(at: fileURL)
            throw NSError(domain: "Larpy", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? "Receipt couldn't be saved."])
        }
    }
    func photoURL(for log: ProofLog) -> URL? {
        guard let filename = log.photoFilename, filename == (filename as NSString).lastPathComponent else { return nil }
        return photosURL.appendingPathComponent(filename)
    }
    /// The next look in order. When the wardrobe is paused after the free month the look holds where it is.
    private var nextLook: FounderLook {
        if !Larp.wardrobeOpen, let held = FounderLook.find(logs.first?.founderID) { return held }
        return FounderLook.next(ordinal: logs.filter { $0.isEligible }.count)
    }
    @discardableResult
    private func add(_ log: ProofLog) -> Bool {
        guard logs.contains(where: { $0.id == log.id }) == false else { return true }
        guard !storageUnreadable else { errorMessage = "Your receipts couldn't be opened. Nothing has been overwritten."; return false }
        // The same URL can be homework and output, but can't earn two Ships.
        if log.quest == .work, log.proofKind == .link,
           logs.contains(where: { $0.quest == .work && $0.proofKind == .link && $0.value.trimmingCharacters(in: CharacterSet(charactersIn: "/")) == log.value.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }) {
            errorMessage = "That Ship already has a receipt. Bring something new."; return false
        }
        var log = log
        let next = ([log] + logs).sorted { $0.createdAt > $1.createdAt }
        // Stamp the room this receipt puts Larpy in, so history can show it without re-deriving.
        if log.sceneID == nil {
            let todays = next.filter { LarpyTime.cal.isDate($0.createdAt, inSameDayAs: log.createdAt) }
            log.sceneID = MovieScene.forToday(todays, allLogs: next, workThisWeek: LifeEngine.stats(next).workN, fallbackKit: .bare, paused: !Larp.wardrobeOpen).rawValue
        }
        let stamped = ([log] + logs).sorted { $0.createdAt > $1.createdAt }
        do {
            try JSONEncoder().encode(stamped).write(to: jsonURL, options: [.atomic])
            errorMessage = nil
            logs = stamped
            return true
        } catch {
            errorMessage = "Couldn't save the receipt. Keep this open and try again."
            return false
        }
    }
}
