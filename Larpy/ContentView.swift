import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = ProofStore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                LarpyCharacterView(completedCount: completedTodayCount)

                VStack(spacing: 14) {
                    ForEach(QuestKind.allCases) { quest in
                        QuestCard(quest: quest, store: store)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, 36)
        }
        .background(GameColor.void.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MY DAY")
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .tracking(5)
                .foregroundStyle(GameColor.glow)

            Text("Keep Larpy alive.")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(GameColor.text)

            Text("Three quests. One proof each. Stored on this phone.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(GameColor.muted)
        }
    }

    private var completedTodayCount: Int {
        QuestKind.allCases.filter { quest in
            guard let latest = store.latestLog(for: quest) else { return false }
            return Calendar.current.isDateInToday(latest.createdAt)
        }.count
    }
}

private struct LarpyCharacterView: View {
    let completedCount: Int

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(GameColor.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(GameColor.line, lineWidth: 2)
                    )

                RadialGradient(
                    colors: [GameColor.glow.opacity(0.36), .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 150
                )
                .blur(radius: 4)

                VStack(spacing: 10) {
                    PixelLarpy()
                        .frame(width: 168, height: 142)

                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Capsule()
                                .fill(index < completedCount ? GameColor.glow : GameColor.line)
                                .frame(width: index < completedCount ? 44 : 26, height: 8)
                                .animation(.snappy(duration: 0.24), value: completedCount)
                        }
                    }

                    Text(statusCopy)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(GameColor.text)
                }
                .padding(24)
            }
            .frame(height: 260)

            Text("Larpy runs on proof, not vibes.")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(GameColor.muted)
        }
    }

    private var statusCopy: String {
        switch completedCount {
        case 0:
            "LOW BATTERY"
        case 1:
            "BOOTING"
        case 2:
            "ALMOST ALIVE"
        default:
            "DAY CLEARED"
        }
    }
}

private struct PixelLarpy: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(GameColor.creature)
                .frame(width: 118, height: 104)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(GameColor.glow, lineWidth: 5)
                        .padding(8)
                )
                .shadow(color: GameColor.glow.opacity(0.45), radius: 20, y: 10)

            HStack(spacing: 32) {
                Eye()
                Eye()
            }
            .offset(y: -14)

            RoundedRectangle(cornerRadius: 4)
                .fill(GameColor.void)
                .frame(width: 44, height: 8)
                .offset(y: 28)

            RoundedRectangle(cornerRadius: 8)
                .fill(GameColor.creature)
                .frame(width: 34, height: 46)
                .rotationEffect(.degrees(-18))
                .offset(x: -70, y: 6)

            RoundedRectangle(cornerRadius: 8)
                .fill(GameColor.creature)
                .frame(width: 34, height: 46)
                .rotationEffect(.degrees(18))
                .offset(x: 70, y: 6)

            Rectangle()
                .fill(GameColor.glow)
                .frame(width: 18, height: 18)
                .offset(x: -43, y: 54)

            Rectangle()
                .fill(GameColor.glow)
                .frame(width: 18, height: 18)
                .offset(x: 43, y: 54)
        }
    }
}

private struct Eye: View {
    var body: some View {
        Rectangle()
            .fill(GameColor.void)
            .frame(width: 18, height: 26)
            .overlay(alignment: .topTrailing) {
                Rectangle()
                    .fill(GameColor.glow)
                    .frame(width: 6, height: 6)
                    .padding(4)
            }
    }
}

private struct QuestCard: View {
    let quest: QuestKind
    @ObservedObject var store: ProofStore

    @State private var proofKind: ProofKind = .photo
    @State private var proofValue = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var saveMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: quest.glyph)
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(GameColor.void)
                    .frame(width: 42, height: 42)
                    .background(GameColor.glow, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.rawValue)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(GameColor.text)

                    Text(quest.prompt)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(GameColor.muted)
                }

                Spacer()

                if completedToday {
                    Text("DONE")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(GameColor.void)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(GameColor.gold, in: Capsule())
                }
            }

            Picker("Proof type", selection: $proofKind) {
                ForEach(ProofKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            proofInput

            if let latestLog {
                LatestProofView(log: latestLog, photoURL: store.photoURL(for: latestLog))
            }

            if !saveMessage.isEmpty {
                Text(saveMessage)
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundStyle(GameColor.glow)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(GameColor.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(completedToday ? GameColor.glow.opacity(0.7) : GameColor.line, lineWidth: 1.5)
                )
        )
        .task(id: selectedPhoto) {
            await saveSelectedPhoto()
        }
    }

    @ViewBuilder
    private var proofInput: some View {
        switch proofKind {
        case .photo:
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Attach Photo Proof", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GameButtonStyle())

        case .link:
            HStack(spacing: 10) {
                TextField("Paste proof link", text: $proofValue)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(GameTextFieldStyle())

                Button("Save") {
                    store.logTextProof(quest: quest, proofKind: .link, value: proofValue)
                    proofValue = ""
                    saveMessage = "LINK PROOF SAVED"
                }
                .buttonStyle(GameSmallButtonStyle())
                .disabled(proofValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

        case .number:
            HStack(spacing: 10) {
                TextField("Number", text: $proofValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(GameTextFieldStyle())

                Button("Save") {
                    store.logTextProof(quest: quest, proofKind: .number, value: proofValue)
                    proofValue = ""
                    saveMessage = "NUMBER PROOF SAVED"
                }
                .buttonStyle(GameSmallButtonStyle())
                .disabled(proofValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var latestLog: ProofLog? {
        store.latestLog(for: quest)
    }

    private var completedToday: Bool {
        guard let latestLog else { return false }
        return Calendar.current.isDateInToday(latestLog.createdAt)
    }

    private func saveSelectedPhoto() async {
        guard let selectedPhoto else { return }

        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else {
                saveMessage = "PHOTO COULD NOT LOAD"
                return
            }

            try store.logPhotoProof(quest: quest, imageData: data)
            saveMessage = "PHOTO PROOF SAVED"
            self.selectedPhoto = nil
        } catch {
            saveMessage = "PHOTO SAVE FAILED"
        }
    }
}

private struct LatestProofView: View {
    let log: ProofLog
    let photoURL: URL?

    var body: some View {
        HStack(spacing: 12) {
            preview

            VStack(alignment: .leading, spacing: 4) {
                Text("LAST PROOF")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(GameColor.glow)

                Text(summary)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(GameColor.text)
                    .lineLimit(1)

                Text(log.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(GameColor.muted)
            }

            Spacer()
        }
        .padding(12)
        .background(GameColor.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var preview: some View {
        if let image = localImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(GameColor.glow)
                .frame(width: 52, height: 52)
                .background(GameColor.void, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var localImage: UIImage? {
        guard let photoURL, let data = try? Data(contentsOf: photoURL) else { return nil }
        return UIImage(data: data)
    }

    private var icon: String {
        switch log.proofKind {
        case .photo:
            "photo.fill"
        case .link:
            "link"
        case .number:
            "number"
        }
    }

    private var summary: String {
        switch log.proofKind {
        case .photo:
            "Photo saved locally"
        case .link, .number:
            log.value
        }
    }
}

private struct GameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black, design: .rounded))
            .foregroundStyle(GameColor.void)
            .padding(.vertical, 14)
            .background(GameColor.glow, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

private struct GameSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(GameColor.void)
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(GameColor.gold, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

private struct GameTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(GameColor.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(GameColor.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(GameColor.line, lineWidth: 1)
            )
    }
}

private enum GameColor {
    static let void = Color(red: 0.03, green: 0.04, blue: 0.06)
    static let panel = Color(red: 0.07, green: 0.09, blue: 0.12)
    static let card = Color(red: 0.10, green: 0.13, blue: 0.17)
    static let line = Color(red: 0.24, green: 0.31, blue: 0.34)
    static let creature = Color(red: 0.17, green: 0.28, blue: 0.24)
    static let glow = Color(red: 0.55, green: 1.00, blue: 0.55)
    static let gold = Color(red: 0.98, green: 0.74, blue: 0.23)
    static let text = Color(red: 0.91, green: 0.97, blue: 0.88)
    static let muted = Color(red: 0.55, green: 0.63, blue: 0.58)
}
