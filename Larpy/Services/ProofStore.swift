import Combine
import Foundation

@MainActor
final class ProofStore: ObservableObject {
    @Published private(set) var logs: [ProofLog] = []

    private let folderURL: URL
    private let jsonURL: URL
    private let photosURL: URL

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Larpy", isDirectory: true)

        folderURL = baseURL
        jsonURL = baseURL.appendingPathComponent("proofs.json")
        photosURL = baseURL.appendingPathComponent("ProofPhotos", isDirectory: true)

        createFolders(fileManager: fileManager)
        load()
    }

    func latestLog(for quest: QuestKind) -> ProofLog? {
        logs
            .filter { $0.quest == quest }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func logTextProof(quest: QuestKind, proofKind: ProofKind, value: String) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return }

        add(ProofLog(quest: quest, proofKind: proofKind, value: trimmedValue))
    }

    func logPhotoProof(quest: QuestKind, imageData: Data) throws {
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = photosURL.appendingPathComponent(filename)
        try imageData.write(to: fileURL, options: [.atomic])

        add(
            ProofLog(
                quest: quest,
                proofKind: .photo,
                value: "Photo saved",
                photoFilename: filename
            )
        )
    }

    func photoURL(for log: ProofLog) -> URL? {
        guard let filename = log.photoFilename else { return nil }
        return photosURL.appendingPathComponent(filename)
    }

    private func add(_ log: ProofLog) {
        logs.insert(log, at: 0)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: jsonURL) else { return }

        do {
            logs = try JSONDecoder().decode([ProofLog].self, from: data)
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            logs = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(logs)
            try data.write(to: jsonURL, options: [.atomic])
        } catch {
            assertionFailure("Could not save proof logs: \(error.localizedDescription)")
        }
    }

    private func createFolders(fileManager: FileManager) {
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: photosURL, withIntermediateDirectories: true)
        } catch {
            assertionFailure("Could not create Larpy storage folders: \(error.localizedDescription)")
        }
    }
}
