import SwiftUI
import PhotosUI

/// Original costume interpretations, not downloaded portraits or endorsements.
/// Each receipt keeps its own look ID, so history never redresses itself.
struct FounderLook: Identifiable {
    let id: String
    let kit: Kit
    let colorHex: UInt
    let detail: String
    let prop: String
    var color: Color { Color(hex: colorHex) }

    /// No real person is named anywhere in the app. A look is its clothes and its scene.
    var scene: MovieScene { MovieScene.forLook(id) }
    var title: String { "\(kit.shortLabel) · \(scene.title)" }
    var label: String { scene.caption }

    static let all: [FounderLook] = [
        .init(id: "jobs", kit: .rollneck, colorHex: 0x282522, detail: "round-glasses", prop: "walk"),
        .init(id: "hormozi", kit: .tee, colorHex: 0xDDD6C8, detail: "stripe", prop: "board"),
        .init(id: "cursor", kit: .hoodie, colorHex: 0x6C756C, detail: "zip", prop: "laptop"),
        .init(id: "belfort", kit: .collar, colorHex: 0xDDD9CF, detail: "tie", prop: "phone"),
        .init(id: "zuck", kit: .tee, colorHex: 0x929591, detail: "chain", prop: "laptop"),
        .init(id: "jensen", kit: .hoodie, colorHex: 0x363A35, detail: "zip", prop: "chip"),
        .init(id: "sara", kit: .collar, colorHex: 0xB9816D, detail: "buttons", prop: "notebook"),
        .init(id: "sam", kit: .tee, colorHex: 0x73877D, detail: "pocket", prop: "laptop"),
        .init(id: "melanie", kit: .collar, colorHex: 0x95A69E, detail: "buttons", prop: "notebook"),
        .init(id: "patrick", kit: .collar, colorHex: 0xA4B3B4, detail: "pocket", prop: "notebook"),
        .init(id: "john", kit: .tee, colorHex: 0x7E8F9E, detail: "stripe", prop: "laptop"),
        .init(id: "brian", kit: .tee, colorHex: 0x454A47, detail: "pocket", prop: "notebook"),
        .init(id: "paul", kit: .collar, colorHex: 0xC5BB9E, detail: "round-glasses", prop: "notebook"),
        .init(id: "jessica", kit: .collar, colorHex: 0x7E9295, detail: "buttons", prop: "notebook"),
        .init(id: "naval", kit: .tee, colorHex: 0x8A9290, detail: "v-neck", prop: "book"),
        .init(id: "jack", kit: .hoodie, colorHex: 0x444C4B, detail: "zip", prop: "phone"),
        .init(id: "elon", kit: .tee, colorHex: 0x393F3C, detail: "patch", prop: "rocket"),
        .init(id: "jeff", kit: .collar, colorHex: 0xB7A78A, detail: "zip", prop: "parcel"),
        .init(id: "bill", kit: .rollneck, colorHex: 0x9A9A8C, detail: "round-glasses", prop: "book"),
        .init(id: "woz", kit: .tee, colorHex: 0x9DADAB, detail: "stripe", prop: "chip"),
        .init(id: "larry", kit: .collar, colorHex: 0xBEC4BA, detail: "pocket", prop: "notebook"),
        .init(id: "sergey", kit: .tee, colorHex: 0x708C87, detail: "v-neck", prop: "chip"),
        .init(id: "reid", kit: .collar, colorHex: 0xA5ABB0, detail: "pocket", prop: "phone"),
        .init(id: "peter", kit: .collar, colorHex: 0x747F84, detail: "tie", prop: "book"),
        .init(id: "marc", kit: .collar, colorHex: 0x8D9093, detail: "buttons", prop: "notebook"),
        .init(id: "ben", kit: .hoodie, colorHex: 0x858574, detail: "zip", prop: "book"),
        .init(id: "tobi", kit: .hoodie, colorHex: 0x6E8678, detail: "patch", prop: "laptop"),
        .init(id: "dylan", kit: .tee, colorHex: 0xAE8C70, detail: "pocket", prop: "notebook"),
        .init(id: "ivan", kit: .rollneck, colorHex: 0x555652, detail: "buttons", prop: "book"),
        .init(id: "guillermo", kit: .hoodie, colorHex: 0x484C4A, detail: "patch", prop: "laptop"),
        .init(id: "pieter", kit: .tee, colorHex: 0xB4A084, detail: "v-neck", prop: "laptop"),
        .init(id: "david", kit: .collar, colorHex: 0xB0B2A8, detail: "stripe", prop: "laptop"),
        .init(id: "jason", kit: .tee, colorHex: 0xA09D90, detail: "pocket", prop: "book"),
        .init(id: "drew", kit: .hoodie, colorHex: 0x8398A7, detail: "zip", prop: "laptop"),
        .init(id: "dustin", kit: .tee, colorHex: 0x8C9C90, detail: "pocket", prop: "notebook"),
        .init(id: "stewart", kit: .collar, colorHex: 0x998B78, detail: "round-glasses", prop: "phone"),
        .init(id: "aaron", kit: .collar, colorHex: 0x98A4AA, detail: "tie", prop: "parcel"),
        .init(id: "eric", kit: .collar, colorHex: 0xA7B4BA, detail: "buttons", prop: "phone"),
        .init(id: "whitney", kit: .collar, colorHex: 0xCAB47E, detail: "buttons", prop: "phone"),
        .init(id: "anne", kit: .collar, colorHex: 0x8CA89A, detail: "stripe", prop: "notebook"),
        .init(id: "reshma", kit: .collar, colorHex: 0xB88776, detail: "buttons", prop: "book"),
        .init(id: "leila", kit: .collar, colorHex: 0xB39880, detail: "v-neck", prop: "notebook"),
        .init(id: "tristan", kit: .hoodie, colorHex: 0x777F72, detail: "zip", prop: "parcel"),
        .init(id: "daymond", kit: .collar, colorHex: 0x646B6D, detail: "tie", prop: "notebook"),
        .init(id: "mark", kit: .tee, colorHex: 0x7C91A0, detail: "v-neck", prop: "phone"),
        .init(id: "richard", kit: .collar, colorHex: 0xD6D1C1, detail: "buttons", prop: "notebook"),
        .init(id: "phil", kit: .tee, colorHex: 0x8D9584, detail: "stripe", prop: "shoe"),
        .init(id: "yvon", kit: .hoodie, colorHex: 0x9B9E7E, detail: "zip", prop: "notebook"),
        .init(id: "james", kit: .collar, colorHex: 0xB3B6AD, detail: "round-glasses", prop: "gear"),
        .init(id: "reed", kit: .collar, colorHex: 0xA78C80, detail: "buttons", prop: "notebook"),
        .init(id: "daniel", kit: .tee, colorHex: 0x778E79, detail: "patch", prop: "headphones"),
        .init(id: "kevin", kit: .collar, colorHex: 0xAAB1A6, detail: "pocket", prop: "camera"),
        .init(id: "evan", kit: .tee, colorHex: 0xB9AD83, detail: "v-neck", prop: "camera"),
        .init(id: "mike", kit: .hoodie, colorHex: 0xA58C7A, detail: "zip", prop: "camera")
    ]
    static func find(_ id: String?) -> FounderLook? { all.first { $0.id == id } }
    static func next(ordinal: Int) -> FounderLook { all[max(0, ordinal) % all.count] }
}

struct WardrobeView: View {
    @ObservedObject var store: ProofStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected: FounderLook?
    private var unlocked: Set<String> { Set(store.logs.compactMap(\.founderID)) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Become someone.\nThen bring receipts.").font(.system(size: 29, weight: .medium, design: .serif)).foregroundStyle(Palette.text)
                    Text("\(unlocked.count) of \(FounderLook.all.count) looks earned. Every receipt changes the clothes and the scene. Only Work changes the level.")
                        .font(.system(size: 15)).foregroundStyle(Palette.muted)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(FounderLook.all) { look in
                            Button { selected = look } label: {
                                VStack(spacing: 8) {
                                    LarpyCharacterView(life: .neutral, base: .cream, kit: look.kit, width: 82, showScene: false, level: 1, founderID: look.id)
                                        .frame(height: 125)
                                    Text(look.kit.shortLabel).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                                    Text(look.scene.title).font(.system(size: 12)).foregroundStyle(Palette.muted).lineLimit(1).minimumScaleFactor(0.8)
                                    Text(unlocked.contains(look.id) ? "Earned" : "Locked")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(unlocked.contains(look.id) ? Palette.gold : Palette.muted.opacity(0.7))
                                }.foregroundStyle(Palette.text).frame(maxWidth: .infinity).padding(.vertical, 15)
                                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                            }.buttonStyle(.plain)
                        }
                    }
                    Text("Original costumes and original scenes, drawn for this app. Nobody real is named or depicted, and no film is reproduced.").font(.system(size: 12)).foregroundStyle(Palette.muted)
                }.padding(24)
            }.background(Palette.bg).navigationTitle("Your characters").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .sheet(item: $selected) { look in
            VStack(spacing: 18) {
                LarpyCharacterView(life: .neutral, base: .cream, kit: look.kit, width: 190, interactive: true, level: 3, founderID: look.id).frame(height: 280)
                VStack(spacing: 6) {
                    Text(look.kit.shortLabel).font(.system(size: 30, weight: .medium, design: .serif)).foregroundStyle(Palette.text)
                    Text(look.scene.caption).font(.system(size: 11, weight: .medium, design: .monospaced)).tracking(1.6).foregroundStyle(Palette.muted)
                }
                Text(unlocked.contains(look.id) ? "You earned this look with a receipt." : "Keep logging. The next look comes with the next receipt.")
                    .font(.system(size: 16)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
            }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity).background(Palette.bg).presentationDetents([.large])
        }
    }
}

// MARK: - Milestones are receipts, never extra Work XP.

struct AchievementSection: View {
    @ObservedObject var store: ProofStore
    @AppStorage("followerEvidence") private var evidence = Data()
    @State private var showFollowers = false
    private var follower: FollowerAchievement? { try? JSONDecoder().decode(FollowerAchievement.self, from: evidence) }
    private var outputs: Int { store.logs.filter { $0.quest == .work && $0.isEligible }.count }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements").font(.system(size: 24, weight: .semibold)).foregroundStyle(Palette.text)
            Text("Receipts turn into things worth keeping.").font(.system(size: 15)).foregroundStyle(Palette.muted)
            VStack(spacing: 0) {
                milestone("First proof", detail: "One real receipt.", earned: store.logs.contains { $0.isEligible }, symbol: "checkmark.seal")
                Divider().overlay(Palette.line)
                milestone("Out in the world", detail: "Your first completed Work receipt.", earned: outputs >= 1, symbol: "arrow.up.right")
                Divider().overlay(Palette.line)
                milestone("Repeat offender", detail: "Seven completed Work receipts.", earned: outputs >= 7, symbol: "seal")
            }.padding(.horizontal, 16).background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
            Button { showFollowers = true } label: {
                HStack(spacing: 14) {
                    Text("in").font(.system(size: 20, weight: .bold)).foregroundStyle(Palette.load)
                        .frame(width: 44, height: 44).background(Palette.load.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(follower.map { $0.threshold > 0 ? "\(fmtTokens($0.threshold)) on LinkedIn" : "Your audience is growing" } ?? "An audience to build in front of")
                            .font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.text)
                        Text(follower == nil ? "1k · 10k · 100k. Attach your proof." : "Screenshot attached · self-reported")
                            .font(.system(size: 13)).foregroundStyle(Palette.muted)
                    }
                    Spacer(minLength: 0); Image(systemName: "plus").foregroundStyle(Palette.muted)
                }.padding(.vertical, 10).contentShape(Rectangle())
            }.buttonStyle(.plain)
        }.sheet(isPresented: $showFollowers) { FollowerEvidenceSheet(evidence: $evidence) }
    }
    private func milestone(_ title: String, detail: String, earned: Bool, symbol: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 24, weight: .light)).foregroundStyle(earned ? Palette.gold : Palette.muted.opacity(0.5)).frame(width: 34)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.text)
                Text(detail).font(.system(size: 13)).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 2)
            if earned { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.gold) }
        }.frame(minHeight: 78)
    }
}

struct FollowerEvidenceSheet: View {
    @Binding var evidence: Data
    @Environment(\.dismiss) private var dismiss
    @State private var count = ""
    @State private var photo: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var loading = false
    @State private var error = ""
    private var number: Int { Int(count.replacingOccurrences(of: ",", with: "")) ?? 0 }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Your audience.\nYour receipt.").font(.system(size: 32, weight: .medium, design: .serif)).foregroundStyle(Palette.text)
                    Text("LinkedIn followers").font(.system(size: 16, weight: .semibold)).foregroundStyle(Palette.text)
                    TextField("1,000", text: $count).font(.system(size: 42, weight: .medium, design: .rounded)).keyboardType(.numberPad).foregroundStyle(Palette.text)
                    PhotosPicker(selection: $photo, matching: .images) {
                        VStack(spacing: 12) {
                            if let data = imageData, let image = UIImage(data: data) {
                                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 220).clipShape(RoundedRectangle(cornerRadius: 14))
                            } else { Image(systemName: "photo.badge.plus").font(.system(size: 28, weight: .light)) }
                            Text(loading ? "Reading screenshot…" : imageData == nil ? "Attach a screenshot of the count" : "Change screenshot").font(.system(size: 16, weight: .medium))
                        }.foregroundStyle(Palette.text).padding(24).frame(maxWidth: .infinity).background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    }
                    Text("1k, 10k and 100k unlock a milestone. This is self-reported with a screenshot, not verified by LinkedIn. It doesn't add Work XP.")
                        .font(.system(size: 14)).foregroundStyle(Palette.muted)
                    Button { save() } label: {
                        Text("Keep this achievement").font(.system(size: 18, weight: .semibold)).foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity, minHeight: 56).background(Palette.gold, in: RoundedRectangle(cornerRadius: 16))
                    }.disabled(imageData == nil || number < 1_000 || number > 1_000_000_000 || loading)
                        .opacity(imageData != nil && number >= 1_000 && !loading ? 1 : 0.4)
                    if !error.isEmpty { Text(error).font(.system(size: 14)).foregroundStyle(Palette.train) }
                }.padding(26)
            }.background(Palette.bg).navigationTitle("LinkedIn milestone").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
        .task(id: photo) {
            guard let photo else { return }; loading = true
            defer { loading = false }
            do {
                guard let data = try await photo.loadTransferable(type: Data.self), let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.8) else { error = "Pick a readable screenshot."; return }
                imageData = jpeg
            } catch { self.error = "That image couldn't be opened. Try another screenshot." }
        }
        .onAppear {
            guard let saved = try? JSONDecoder().decode(FollowerAchievement.self, from: evidence) else { return }
            count = "\(saved.count)"
            imageData = try? Data(contentsOf: Self.folder.appendingPathComponent(saved.photoFilename))
        }
    }
    private static var folder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Larpy/Achievements", isDirectory: true)
    }
    private func save() {
        guard let imageData, number >= 1_000, number <= 1_000_000_000 else { return }
        do {
            try FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
            let name = "\(UUID().uuidString).jpg"
            try imageData.write(to: Self.folder.appendingPathComponent(name), options: .atomic)
            evidence = try JSONEncoder().encode(FollowerAchievement(count: number, photoFilename: name, at: .now))
            UINotificationFeedbackGenerator().notificationOccurred(.success); dismiss()
        } catch { self.error = "Couldn't keep the screenshot. Try again." }
    }
}

// MARK: - Scenes

/// Backdrops behind Larpy. Archetypes, drawn from scratch in the app's own flat style —
/// no film is named, no still is reproduced, no character is depicted.
/// One warm ground, one saturated accent per scene, so the set still reads as one system.
enum MovieScene: String, CaseIterable, Identifiable {
    case road, neon, diner, rooftop, field, gym, floor, racks, orbit, summit, spotlight, platform, cabin, sea
    var id: String { rawValue }

    /// Sentence case for the wardrobe grid.
    var title: String {
        switch self {
        case .road:      "The long drive"
        case .neon:      "Rain on the signs"
        case .diner:     "The 3am booth"
        case .rooftop:   "Above the noise"
        case .field:     "Rows and sky"
        case .gym:       "The early rounds"
        case .floor:     "The open floor"
        case .racks:     "Down in the racks"
        case .orbit:     "Somebody else's orbit"
        case .summit:    "First light up top"
        case .spotlight: "One spot, one take"
        case .platform:  "Waiting on the train"
        case .cabin:     "Snow on the glass"
        case .sea:       "Out past the shelf"
        }
    }

    /// Monospaced caption under the actor.
    var caption: String { title.uppercased() }

    private var sky: (UInt, UInt) {
        switch self {
        case .road:      (0xF6D9A8, 0xE9A87C)
        case .neon:      (0x2C3350, 0x3E3352)
        case .diner:     (0x24262E, 0x33333A)
        case .rooftop:   (0xF7DCB0, 0xE3A98A)
        case .field:     (0xCFE0E6, 0xEFE7CE)
        case .gym:       (0x3A3630, 0x53483C)
        case .floor:     (0x2B2F36, 0x3B3C40)
        case .racks:     (0x22282B, 0x2C3438)
        case .orbit:     (0x11131C, 0x1B1E2C)
        case .summit:    (0xF2D6C0, 0xE8B9A6)
        case .spotlight: (0x2A2320, 0x3A2F29)
        case .platform:  (0x2E3231, 0x40423E)
        case .cabin:     (0xBFCCD4, 0xE2E2DE)
        case .sea:       (0xD9E4E4, 0xF0E6D2)
        }
    }
    private var land: UInt {
        switch self {
        case .road: 0xC98F63
        case .neon: 0x232839
        case .diner: 0x4A3B30
        case .rooftop: 0x8C6D5C
        case .field: 0xC9A85F
        case .gym: 0x6B5340
        case .floor: 0x4A4741
        case .racks: 0x1B2124
        case .orbit: 0x2B2E3D
        case .summit: 0xB08575
        case .spotlight: 0x4C3B31
        case .platform: 0x53544F
        case .cabin: 0xE9E9E6
        case .sea: 0x8FA9AC
        }
    }
    /// The one saturated note per scene.
    private var accent: UInt {
        switch self {
        case .road: 0xE4622F
        case .neon: 0xFF4D7A
        case .diner: 0xE9C468
        case .rooftop: 0xE8672F
        case .field: 0x6FA0C4
        case .gym: 0xE8A03C
        case .floor: 0x53D08A
        case .racks: 0x3FC7D6
        case .orbit: 0xE6A94B
        case .summit: 0xE8843F
        case .spotlight: 0xF0D38A
        case .platform: 0xE8B33C
        case .cabin: 0xE2954F
        case .sea: 0x3F86B0
        }
    }

    /// Drawn inside the circular stage. `w` is the actor width, `ratio` how much wider the
    /// stage is than the actor. The ground line is derived so it always meets the feet.
    func backdrop(w: CGFloat, ratio: CGFloat) -> some View {
        let d = w * ratio
        let hz = d / 2 + w * 0.58
        return ZStack {
            LinearGradient(colors: [Color(hex: sky.0), Color(hex: sky.1)], startPoint: .top, endPoint: .bottom)
            elements(d: d, hz: hz)
        }
        .frame(width: d, height: d)
        .clipShape(Circle())
        .overlay(Circle().fill(Color.black.opacity(Theme.isDark ? 0.30 : 0)))
        .overlay(Circle().stroke(Palette.ink.opacity(Theme.isDark ? 0.30 : 0.08), lineWidth: 1))
    }

    private func ground(_ d: CGFloat, _ hz: CGFloat) -> some View {
        Rectangle().fill(Color(hex: land))
            .frame(height: max(0, d - hz))
            .offset(y: hz / 2)
    }

    @ViewBuilder private func elements(d: CGFloat, hz: CGFloat) -> some View {
        switch self {
        case .road: road(d, hz)
        case .neon: neon(d, hz)
        case .diner: diner(d, hz)
        case .rooftop: rooftop(d, hz)
        case .field: field(d, hz)
        case .gym: gym(d, hz)
        case .floor: floor(d, hz)
        case .racks: racks(d, hz)
        case .orbit: orbit(d, hz)
        case .summit: summit(d, hz)
        case .spotlight: spotlight(d, hz)
        case .platform: platform(d, hz)
        case .cabin: cabin(d, hz)
        case .sea: sea(d, hz)
        }
    }

    private func road(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color(hex: accent).opacity(0.9))
                .frame(width: d * 0.30, height: d * 0.30)
                .offset(y: -d * 0.10)
            ground(d, hz)
            Triangle().fill(Color(hex: 0xF3E3C6).opacity(0.85))
                .frame(width: d * 0.46, height: d * 0.22)
                .rotationEffect(.degrees(180))
                .offset(y: hz - d / 2 + d * 0.11)
        }
    }

    private func neon(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                let h: CGFloat = d * (0.24 - CGFloat(i) * 0.05)
                RoundedRectangle(cornerRadius: d * 0.012)
                    .fill(Color(hex: accent).opacity(0.8 - Double(i) * 0.18))
                    .frame(width: d * 0.045, height: h)
                    .offset(x: d * (CGFloat(i) * 0.24 - 0.34), y: -d * (0.16 - CGFloat(i) * 0.03))
            }
            ground(d, hz)
            Rectangle().fill(Color(hex: accent).opacity(0.28))
                .frame(width: d * 0.05, height: d * 0.18)
                .offset(x: -d * 0.34, y: hz / 2 - d * 0.04)
                .blur(radius: d * 0.02)
        }
    }

    private func diner(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: d * 0.03).fill(Color(hex: accent).opacity(0.30))
                .frame(width: d * 0.62, height: d * 0.40)
                .offset(y: -d * 0.10)
            RoundedRectangle(cornerRadius: d * 0.03).stroke(Color(hex: accent).opacity(0.65), lineWidth: d * 0.008)
                .frame(width: d * 0.62, height: d * 0.40)
                .offset(y: -d * 0.10)
            ground(d, hz)
        }
    }

    private func rooftop(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color(hex: accent).opacity(0.85))
                .frame(width: d * 0.22, height: d * 0.22)
                .offset(x: d * 0.20, y: -d * 0.16)
            ForEach(0..<4, id: \.self) { i in
                let tall: CGFloat = d * (0.16 + CGFloat(i % 2) * 0.10)
                Rectangle().fill(Color(hex: land).opacity(0.85))
                    .frame(width: d * 0.13, height: tall)
                    .offset(x: d * (CGFloat(i) * 0.17 - 0.30), y: d * (0.14 - CGFloat(i % 2) * 0.05))
            }
            ground(d, hz)
        }
    }

    private func field(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            ground(d, hz)
            ForEach(0..<5, id: \.self) { i in
                Capsule().fill(Color(hex: 0x9A7C3A).opacity(0.5))
                    .frame(width: d * 0.012, height: d * 0.14)
                    .offset(x: d * (CGFloat(i) * 0.16 - 0.32), y: hz / 2 - d * 0.04)
            }
            Circle().fill(Color(hex: accent).opacity(0.35))
                .frame(width: d * 0.16, height: d * 0.16)
                .offset(x: -d * 0.24, y: -d * 0.22)
        }
    }

    private func gym(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(Color(hex: accent).opacity(0.22))
                .frame(width: d * 0.30, height: d * 0.34)
                .rotationEffect(.degrees(12))
                .offset(x: -d * 0.22, y: -d * 0.14)
                .blur(radius: d * 0.02)
            Capsule().fill(Color(hex: land))
                .frame(width: d * 0.10, height: d * 0.26)
                .offset(x: d * 0.30, y: -d * 0.10)
            Rectangle().fill(Color(hex: 0x2A241C).opacity(0.5))
                .frame(width: d * 0.006, height: d * 0.12)
                .offset(x: d * 0.30, y: -d * 0.28)
            ground(d, hz)
        }
    }

    private func floor(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: d * 0.01)
                    .fill(Color(hex: accent).opacity(0.55 - Double(i % 3) * 0.12))
                    .frame(width: d * 0.10, height: d * 0.07)
                    .offset(x: d * (CGFloat(i % 3) * 0.20 - 0.22), y: d * (CGFloat(i / 3) * 0.13 - 0.20))
            }
            ground(d, hz)
        }
    }

    private func racks(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            ForEach(0..<2, id: \.self) { side in
                rack(d).offset(x: d * (side == 0 ? -0.30 : 0.30), y: -d * 0.06)
            }
            ground(d, hz)
        }
    }
    private func rack(_ d: CGFloat) -> some View {
        VStack(spacing: d * 0.02) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: d * 0.006)
                    .fill(Color(hex: accent).opacity(0.5))
                    .frame(width: d * 0.03, height: d * 0.012)
            }
        }
        .padding(d * 0.03)
        .background(RoundedRectangle(cornerRadius: d * 0.02).fill(Color(hex: land)))
    }

    private func orbit(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color(hex: accent).opacity(0.9))
                .frame(width: d * 0.10, height: d * 0.10)
                .offset(x: d * 0.26, y: -d * 0.26)
            Circle().fill(Color(hex: land))
                .frame(width: d * 1.10, height: d * 1.10)
                .offset(y: d * 0.74)
            Circle().stroke(Color(hex: accent).opacity(0.35), lineWidth: d * 0.005)
                .frame(width: d * 1.24, height: d * 1.24)
                .offset(y: d * 0.74)
        }
    }

    private func summit(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color(hex: accent).opacity(0.8))
                .frame(width: d * 0.20, height: d * 0.20)
                .offset(x: -d * 0.18, y: -d * 0.18)
            Triangle().fill(Color(hex: land).opacity(0.7))
                .frame(width: d * 0.52, height: d * 0.34)
                .rotationEffect(.degrees(180))
                .offset(x: -d * 0.18, y: d * 0.14)
            Triangle().fill(Color(hex: land))
                .frame(width: d * 0.60, height: d * 0.42)
                .rotationEffect(.degrees(180))
                .offset(x: d * 0.16, y: d * 0.10)
            ground(d, hz)
        }
    }

    private func spotlight(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            Triangle().fill(Color(hex: accent).opacity(0.30))
                .frame(width: d * 0.72, height: d * 0.62)
                .offset(y: -d * 0.04)
                .blur(radius: d * 0.02)
            ground(d, hz)
            Ellipse().fill(Color(hex: accent).opacity(0.35))
                .frame(width: d * 0.50, height: d * 0.08)
                .offset(y: hz / 2 - d * 0.02)
        }
    }

    private func platform(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Rectangle().stroke(Color(hex: 0xF3E3C6).opacity(0.18), lineWidth: 1)
                    .frame(width: d * 0.18, height: d * 0.13)
                    .offset(x: d * (CGFloat(i % 2) * 0.20 - 0.30), y: d * (CGFloat(i / 2) * 0.15 - 0.22))
            }
            Circle().fill(Color(hex: accent).opacity(0.75))
                .frame(width: d * 0.09, height: d * 0.09)
                .offset(x: d * 0.26, y: -d * 0.14)
                .blur(radius: d * 0.006)
            ground(d, hz)
        }
    }

    private func cabin(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            ForEach(0..<7, id: \.self) { i in
                Circle().fill(Color.white.opacity(0.75))
                    .frame(width: d * 0.018, height: d * 0.018)
                    .offset(x: d * (CGFloat(i) * 0.11 - 0.34), y: d * (CGFloat(i % 3) * 0.12 - 0.26))
            }
            RoundedRectangle(cornerRadius: d * 0.02).fill(Color(hex: accent).opacity(0.35))
                .frame(width: d * 0.26, height: d * 0.20)
                .offset(x: d * 0.26, y: -d * 0.06)
            ground(d, hz)
        }
    }

    private func sea(_ d: CGFloat, _ hz: CGFloat) -> some View {
        ZStack {
            ground(d, hz)
            ForEach(0..<3, id: \.self) { i in
                let wide: CGFloat = d * (0.20 - CGFloat(i) * 0.04)
                Capsule().fill(Color(hex: 0xF3E3C6).opacity(0.30))
                    .frame(width: wide, height: d * 0.012)
                    .offset(x: d * (CGFloat(i) * 0.22 - 0.24), y: hz / 2 + d * 0.05 + d * CGFloat(i) * 0.04)
            }
            Circle().fill(Color(hex: accent).opacity(0.30))
                .frame(width: d * 0.14, height: d * 0.14)
                .offset(x: d * 0.24, y: -d * 0.24)
        }
    }

    /// Clothes decide the room. Everything else rotates so all 54 looks stay distinct.
    static func forLook(_ id: String) -> MovieScene {
        if let forced = overrides[id] { return forced }
        let index = FounderLook.all.firstIndex { $0.id == id } ?? 0
        return rotation[index % rotation.count]
    }
    private static let overrides: [String: MovieScene] = [
        "jobs": .spotlight, "hormozi": .gym, "cursor": .racks, "belfort": .floor
    ]
    private static let rotation: [MovieScene] = [
        .road, .rooftop, .field, .platform, .diner, .summit, .neon,
        .sea, .orbit, .cabin, .gym, .racks, .floor, .spotlight
    ]

    /// When no look has been earned yet, the clothes alone pick the room.
    static func forKit(_ kit: Kit) -> MovieScene {
        switch kit {
        case .hoodie: .racks
        case .tee: .gym
        case .rollneck: .spotlight
        case .collar: .floor
        case .cans: .diner
        case .cap: .field
        case .glasses: .platform
        case .bare: .road
        }
    }
}
