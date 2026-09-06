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
        .init(id: "zuck", kit: .tee, colorHex: 0x6F7F8C, detail: "chain", prop: "laptop"),
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
        .init(id: "bill", kit: .rollneck, colorHex: 0xB5A27C, detail: "round-glasses", prop: "book"),
        .init(id: "woz", kit: .tee, colorHex: 0x9DADAB, detail: "stripe", prop: "chip"),
        .init(id: "larry", kit: .collar, colorHex: 0xBEC4BA, detail: "pocket", prop: "notebook"),
        .init(id: "sergey", kit: .tee, colorHex: 0x708C87, detail: "v-neck", prop: "chip"),
        .init(id: "reid", kit: .collar, colorHex: 0xA5ABB0, detail: "pocket", prop: "phone"),
        .init(id: "peter", kit: .collar, colorHex: 0x747F84, detail: "tie", prop: "book"),
        .init(id: "marc", kit: .collar, colorHex: 0x5E6B72, detail: "buttons", prop: "notebook"),
        .init(id: "ben", kit: .hoodie, colorHex: 0x858574, detail: "zip", prop: "book"),
        .init(id: "tobi", kit: .hoodie, colorHex: 0x6E8678, detail: "patch", prop: "laptop"),
        .init(id: "dylan", kit: .tee, colorHex: 0xAE8C70, detail: "pocket", prop: "notebook"),
        .init(id: "ivan", kit: .rollneck, colorHex: 0x555652, detail: "buttons", prop: "book"),
        .init(id: "guillermo", kit: .hoodie, colorHex: 0x484C4A, detail: "patch", prop: "laptop"),
        .init(id: "pieter", kit: .tee, colorHex: 0xB4A084, detail: "v-neck", prop: "laptop"),
        .init(id: "david", kit: .collar, colorHex: 0xB0B2A8, detail: "stripe", prop: "laptop"),
        .init(id: "jason", kit: .tee, colorHex: 0xC2A98E, detail: "pocket", prop: "book"),
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
    @ObservedObject var prefs: Prefs
    @Environment(\.dismiss) private var dismiss
    @State private var selected: FounderLook?
    @State private var showAsk = false
    private var unlocked: Set<String> { Set(store.logs.compactMap(\.founderID)) }
    private var workDone: Int { store.logs.filter { $0.quest == .work && $0.isEligible }.count }
    private var rewardEarned: Bool { workDone >= MovieScene.rewardAt }
    private var nextID: String { FounderLook.next(ordinal: store.logs.filter(\.isEligible).count).id }
    private var paused: Bool { !Larp.wardrobeOpen }
    private let columns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(unlocked.count)").font(.system(size: 72, weight: .medium, design: .serif)).tracking(-3).foregroundStyle(Palette.text)
                        Text("OF \(FounderLook.all.count) LOOKS").font(.system(size: 11, weight: .semibold, design: .monospaced)).tracking(2).foregroundStyle(Palette.muted)
                    }
                    Text(paused ? "\(unlocked.count) of \(FounderLook.all.count) looks earned. Wardrobe paused." : "One look per receipt, in order. Only Work changes the level.")
                        .font(.system(size: 15)).foregroundStyle(Palette.muted)

                    if paused { pausedCard }
                    else if let line = Larp.untilLine, let days = Larp.daysLeft, days <= 7 {
                        Text(line).font(.system(size: 11, weight: .medium, design: .monospaced)).tracking(1.4).foregroundStyle(Palette.muted)
                    }

                    // The one room no costume carries. Visible from the first day, locked until seven.
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack {
                            // No actor stands here, so the scale is set for the empty room.
                            MovieScene.reward.panel(w: 78, corner: 20)
                                .frame(height: 152)
                                .saturation(rewardEarned ? 1 : 0.15)
                                .opacity(rewardEarned ? 1 : 0.5)
                            if !rewardEarned {
                                VStack(spacing: 7) {
                                    Image(systemName: "lock.fill").font(.system(size: 17, weight: .semibold))
                                    Text("\(workDone) / \(MovieScene.rewardAt) completed Work")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced)).tracking(0.6)
                                }.foregroundStyle(Palette.text.opacity(0.85))
                            }
                        }
                        HStack(alignment: .firstTextBaseline) {
                            Text(MovieScene.reward.title).font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.text)
                            Spacer()
                            Text(rewardEarned ? "EARNED" : "LOCKED")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced)).tracking(1)
                                .foregroundStyle(rewardEarned ? Palette.gold : Palette.muted)
                        }
                        Text(rewardEarned
                             ? "Yours. Log Work again and Larpy stands in it."
                             : "No costume comes with this room. Seven completed Work receipts is the only way in.")
                            .font(.system(size: 13)).foregroundStyle(Palette.muted)
                    }
                    .padding(.bottom, 4)

                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(FounderLook.all) { look in
                            let earned = unlocked.contains(look.id)
                            let isNext = !paused && look.id == nextID && !earned
                            Button { selected = look } label: {
                                ZStack(alignment: .bottom) {
                                    Rectangle().fill(look.color.opacity(earned ? 0.9 : 0.35)).frame(height: 4)
                                    LarpyCharacterView(life: .neutral, base: .cream, kit: look.kit, width: 60, showScene: false, level: earned ? 1 : 0, founderID: look.id)
                                        .frame(height: 96).offset(y: -4)
                                        .opacity(earned ? 1 : 0.26)
                                    if isNext {
                                        Text("NEXT").font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.2)
                                            .foregroundStyle(Palette.gold).offset(y: -84)
                                    }
                                }
                                .frame(maxWidth: .infinity).frame(height: 108)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Palette.gold, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                                    .opacity(isNext ? 1 : 0))
                                .contentShape(Rectangle())
                            }.buttonStyle(.plain)
                                .accessibilityLabel("\(look.title). \(earned ? "Earned" : isNext ? "Next" : "Locked").")
                        }
                    }
                    Text("Original costumes and original scenes, drawn for this app. Nobody real is named or depicted, and no film is reproduced.").font(.system(size: 12)).foregroundStyle(Palette.muted)
                }.padding(24)
            }.background(Palette.bg).navigationTitle("Looks").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .sheet(item: $selected) { look in
            VStack(spacing: 18) {
                LarpyCharacterView(life: .neutral, base: .cream, kit: look.kit, width: 150, scene: look.scene, interactive: true, level: 3, founderID: look.id).frame(height: 250)
                VStack(spacing: 6) {
                    Text(look.kit.shortLabel).font(.system(size: 30, weight: .medium, design: .serif)).foregroundStyle(Palette.text)
                    Text(look.scene.caption).font(.system(size: 11, weight: .medium, design: .monospaced)).tracking(1.6).foregroundStyle(Palette.muted)
                }
                Text(unlocked.contains(look.id) ? "You earned this look with a receipt." : "Keep logging. The next look comes with the next receipt.")
                    .font(.system(size: 16)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
            }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity).background(Palette.bg).presentationDetents([.large])
        }
        .sheet(isPresented: $showAsk) { AskView(store: store, prefs: prefs) }
    }

    /// The free month is over. The next look waits. One tap opens the ask; nothing opens it for you.
    private var pausedCard: some View {
        Button { showAsk = true } label: {
            HStack(spacing: 14) {
                LarpyCharacterView(life: .neutral, base: .cream, kit: FounderLook.find(nextID)?.kit ?? .bare, width: 44, showScene: false, founderID: nextID)
                    .frame(width: 56, height: 64).opacity(0.5)
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT LOOK · \(Larp.fallbackPrice.uppercased()) ONCE").font(.system(size: 11, weight: .semibold, design: .monospaced)).tracking(1.4).foregroundStyle(Palette.gold)
                    Text("Receipts still count. The costume is waiting.").font(.system(size: 13)).foregroundStyle(Palette.muted)
                }
                Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(Palette.muted)
            }
            .padding(16).background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }.buttonStyle(.plain)
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
            HStack(alignment: .top, spacing: 12) {
                pin("FIRST PROOF", earned: store.logs.contains { $0.isEligible })
                pin("OUT THERE", earned: outputs >= 1)
                pin("REPEAT OFFENDER", earned: outputs >= 7)
            }.frame(maxWidth: .infinity)
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
    /// The gold level pin from the character, at 28pt. Solid when earned, a line when not.
    private func pin(_ title: String, earned: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Palette.gold).opacity(earned ? 1 : 0)
                Circle().stroke(Palette.gold.opacity(earned ? 0 : 0.6), lineWidth: 1)
                if earned { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundStyle(Palette.ink) }
            }.frame(width: 28, height: 28)
            Text(title).font(.system(size: 11, weight: .semibold, design: .monospaced)).tracking(1)
                .foregroundStyle(earned ? Palette.text : Palette.muted).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity)
            .accessibilityLabel("\(title). \(earned ? "Earned" : "Not yet").")
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
                    TextField("1,000", text: $count).font(.system(size: 42, weight: .medium, design: .serif)).keyboardType(.numberPad).foregroundStyle(Palette.text)
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
    case pool, pitch, stairwell, bridge, lamp, whiteboard, hum, dock, table, launch
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
        case .pool:      "Pool at six"
        case .pitch:     "The pitch under lights"
        case .stairwell: "Stairwell, floor nine"
        case .bridge:    "Bridge at dawn"
        case .lamp:      "Lamp on the shelf"
        case .whiteboard: "Tape on the whiteboard"
        case .hum:       "Server hum at 2am"
        case .dock:      "Loading dock"
        case .table:     "The demo table"
        case .launch:    "Launch pad, wind up"
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
        case .pool:      (0xDCEBEA, 0xF1E9D6)
        case .pitch:     (0x2F3546, 0x4A4B55)
        case .stairwell: (0xF1E4D2, 0xE6CDB0)
        case .bridge:    (0xF4DDC3, 0xE9B48F)
        case .lamp:      (0xEFE6D3, 0xE5D6BC)
        case .whiteboard: (0xF3EFE6, 0xEAE3D5)
        case .hum:       (0x1E2426, 0x283033)
        case .dock:      (0xF5DEBB, 0xE8BF93)
        case .table:     (0xF4EEE3, 0xEADFCD)
        case .launch:    (0x2B2F45, 0x4C405A)
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
        case .pool: 0xE6DCC6
        case .pitch: 0x4E8A5C
        case .stairwell: 0xB9977A
        case .bridge: 0x8F7A6A
        case .lamp: 0xA6845E
        case .whiteboard: 0xC9C1B3
        case .hum: 0x1A1F21
        case .dock: 0x9A7B62
        case .table: 0xC8B49A
        case .launch: 0x514B4A
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
        case .pool: 0x35A8B5
        case .pitch: 0xF2E6A0
        case .stairwell: 0xE0603A
        case .bridge: 0xE76F3C
        case .lamp: 0x3F8F6B
        case .whiteboard: 0xE04B4B
        case .hum: 0x7ED957
        case .dock: 0xE2582F
        case .table: 0xC4A35A
        case .launch: 0xF0A03C
        }
    }

    /// Drawn as a full-bleed panel behind the actor. `w` is the actor width and sets the scale;
    /// the panel takes whatever frame its parent gives it. The ground line is derived from the
    /// actor's feet so the character always stands on it, at any panel size.
    func panel(w: CGFloat, corner: CGFloat = 26) -> some View {
        GeometryReader { g in
            let h = g.size.height
            let d = w * 1.85                       // scale unit for the furniture
            let hz = h / 2 + w * 0.58              // ground line, measured from the panel top
            ZStack {
                LinearGradient(colors: [Color(hex: sky.0), Color(hex: sky.1)], startPoint: .top, endPoint: .bottom)
                elements(d: d, hz: hz, h: h, pw: g.size.width)
            }
            .frame(width: g.size.width, height: h)
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).fill(MovieScene.daypartTint))
        .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Color.black.opacity(Theme.isDark ? 0.22 : 0)))
        .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(Palette.ink.opacity(Theme.isDark ? 0.32 : 0.09), lineWidth: 1))
    }

    /// One tint by time of day over every room. Dawn, dusk, night. Nothing else changes.
    static var daypartTint: Color {
        let hour = LarpyTime.cal.component(.hour, from: .now)
        switch hour {
        case 5..<8: return Color(hex: 0xF0A46A).opacity(0.16)
        case 18..<21: return Color(hex: 0xC4593A).opacity(0.20)
        case 21..<24, 0..<5: return Color(hex: 0x101828).opacity(Theme.isDark ? 0.22 : 0.42)
        default: return .clear
        }
    }

    /// Ground line as an offset from the panel centre. Everything that stands on the floor uses it.
    private func gy(_ hz: CGFloat, _ h: CGFloat) -> CGFloat { hz - h / 2 }

    private func ground(_ h: CGFloat, _ hz: CGFloat) -> some View {
        Rectangle().fill(Color(hex: land))
            .frame(height: max(0, h - hz))
            .offset(y: hz / 2)
    }

    /// `d` scales the furniture, `pw` places it. The actor stands in the middle ~45% of the
    /// panel, so everything that must stay visible sits outside that band or above the head.
    @ViewBuilder private func elements(d: CGFloat, hz: CGFloat, h: CGFloat, pw: CGFloat) -> some View {
        switch self {
        case .road: road(d, hz, h, pw)
        case .neon: neon(d, hz, h, pw)
        case .diner: diner(d, hz, h, pw)
        case .rooftop: rooftop(d, hz, h, pw)
        case .field: field(d, hz, h, pw)
        case .gym: gym(d, hz, h, pw)
        case .floor: floor(d, hz, h, pw)
        case .racks: racks(d, hz, h, pw)
        case .orbit: orbit(d, hz, h, pw)
        case .summit: summit(d, hz, h, pw)
        case .spotlight: spotlight(d, hz, h, pw)
        case .platform: platform(d, hz, h, pw)
        case .cabin: cabin(d, hz, h, pw)
        case .sea: sea(d, hz, h, pw)
        case .pool: pool(d, hz, h, pw)
        case .pitch: pitch(d, hz, h, pw)
        case .stairwell: stairwell(d, hz, h, pw)
        case .bridge: bridge(d, hz, h, pw)
        case .lamp: lamp(d, hz, h, pw)
        case .whiteboard: whiteboard(d, hz, h, pw)
        case .hum: hum(d, hz, h, pw)
        case .dock: dock(d, hz, h, pw)
        case .table: table(d, hz, h, pw)
        case .launch: launch(d, hz, h, pw)
        }
    }

    private func pool(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            Circle().fill(Color(hex: 0xF2C97E).opacity(0.55))
                .frame(width: d * 0.20, height: d * 0.20)
                .offset(x: -pw * 0.34, y: g - d * 0.60)
            ground(h, hz)
            RoundedRectangle(cornerRadius: d * 0.02).fill(Color(hex: accent).opacity(0.55))
                .frame(width: pw * 0.92, height: h - hz - d * 0.05)
                .offset(y: hz / 2 + d * 0.025)
            ForEach(0..<5, id: \.self) { i in
                Rectangle().fill(Color(hex: 0xF3E3C6).opacity(0.35))
                    .frame(width: d * 0.006, height: h - hz - d * 0.06)
                    .offset(x: pw * (CGFloat(i) * 0.19 - 0.38), y: hz / 2 + d * 0.03)
            }
        }
    }

    private func pitch(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<2, id: \.self) { side in
                Rectangle().fill(Color(hex: land).opacity(0.6))
                    .frame(width: d * 0.012, height: d * 0.62)
                    .offset(x: pw * (side == 0 ? -0.40 : 0.40), y: g - d * 0.31)
                Circle().fill(Color(hex: accent).opacity(0.9))
                    .frame(width: d * 0.09, height: d * 0.09)
                    .offset(x: pw * (side == 0 ? -0.40 : 0.40), y: g - d * 0.64)
                    .blur(radius: d * 0.008)
            }
            ground(h, hz)
            Rectangle().fill(Color(hex: 0xF3E3C6).opacity(0.35))
                .frame(height: d * 0.010).offset(y: g + d * 0.10)
        }
    }

    private func stairwell(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<5, id: \.self) { i in
                Rectangle().fill(Color(hex: land).opacity(0.75))
                    .frame(width: pw * 0.16, height: d * 0.05)
                    .offset(x: pw * (0.44 - CGFloat(i) * 0.05), y: g - d * (0.06 + CGFloat(i) * 0.10))
            }
            Rectangle().fill(Color(hex: accent).opacity(0.7))
                .frame(width: d * 0.012, height: d * 0.55)
                .offset(x: pw * 0.28, y: g - d * 0.33)
            RoundedRectangle(cornerRadius: d * 0.01).fill(Color(hex: accent).opacity(0.85))
                .frame(width: d * 0.16, height: d * 0.06)
                .offset(x: -pw * 0.36, y: g - d * 0.58)
            ground(h, hz)
        }
    }

    private func bridge(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            Circle().fill(Color(hex: accent).opacity(0.8))
                .frame(width: d * 0.26, height: d * 0.26)
                .offset(x: pw * 0.30, y: g - d * 0.52)
            ForEach(0..<2, id: \.self) { side in
                Rectangle().fill(Color(hex: land).opacity(0.85))
                    .frame(width: d * 0.06, height: d * 0.70)
                    .offset(x: pw * (side == 0 ? -0.36 : 0.36), y: g - d * 0.35)
            }
            CurveLine(bend: 0.45).stroke(Color(hex: land).opacity(0.7), lineWidth: max(1, d * 0.008))
                .frame(width: pw * 0.72, height: d * 0.30)
                .offset(y: g - d * 0.60)
            ground(h, hz)
        }
    }

    private func lamp(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            Rectangle().fill(Color(hex: land).opacity(0.7))
                .frame(width: pw * 0.30, height: d * 0.022)
                .offset(x: -pw * 0.34, y: g - d * 0.44)
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1).fill(Color(hex: land).opacity(0.5 + Double(i % 2) * 0.25))
                    .frame(width: d * 0.035, height: d * (0.12 + CGFloat(i % 3) * 0.02))
                    .offset(x: -pw * (0.44 - CGFloat(i) * 0.05), y: g - d * 0.52)
            }
            Triangle().fill(Color(hex: accent).opacity(0.22))
                .frame(width: pw * 0.34, height: d * 0.42)
                .offset(x: pw * 0.34, y: g - d * 0.21)
                .blur(radius: d * 0.02)
            Capsule().fill(Color(hex: accent).opacity(0.85))
                .frame(width: d * 0.10, height: d * 0.055)
                .offset(x: pw * 0.34, y: g - d * 0.46)
            Rectangle().fill(Color(hex: 0x2A241C).opacity(0.5))
                .frame(width: d * 0.006, height: d * 0.44)
                .offset(x: pw * 0.34, y: g - d * 0.22)
            ground(h, hz)
        }
    }

    private func whiteboard(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            RoundedRectangle(cornerRadius: d * 0.015).fill(Color.white.opacity(0.55))
                .frame(width: pw * 0.80, height: d * 0.46)
                .offset(y: g - d * 0.40)
            ForEach(0..<3, id: \.self) { i in
                Rectangle().fill(Color(hex: accent).opacity(0.75))
                    .frame(width: d * 0.10, height: d * 0.016)
                    .rotationEffect(.degrees(Double(i) * 30 - 30))
                    .offset(x: pw * (CGFloat(i) * 0.30 - 0.30), y: g - d * 0.60)
            }
            ground(h, hz)
        }
    }

    private func hum(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<2, id: \.self) { side in
                VStack(spacing: d * 0.018) {
                    ForEach(0..<8, id: \.self) { i in
                        HStack(spacing: d * 0.01) {
                            Circle().fill(Color(hex: accent).opacity(i % 3 == 0 ? 0.9 : 0.3)).frame(width: d * 0.010, height: d * 0.010)
                            RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0x3B4548)).frame(width: d * 0.09, height: d * 0.012)
                        }
                    }
                }
                .padding(d * 0.02)
                .background(RoundedRectangle(cornerRadius: d * 0.015).fill(Color(hex: land)))
                .offset(x: pw * (side == 0 ? -0.36 : 0.36), y: g - d * 0.26)
            }
            ground(h, hz)
        }
    }

    private func dock(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            RoundedRectangle(cornerRadius: d * 0.01).fill(Color(hex: land).opacity(0.30))
                .frame(width: pw * 0.34, height: d * 0.50)
                .overlay(
                    VStack(spacing: d * 0.035) { ForEach(0..<5, id: \.self) { _ in Rectangle().fill(Color(hex: land).opacity(0.35)).frame(height: d * 0.008) } }
                )
                .offset(x: -pw * 0.34, y: g - d * 0.25)
            ForEach(0..<2, id: \.self) { i in
                RoundedRectangle(cornerRadius: d * 0.01).fill(Color(hex: accent).opacity(0.7 - Double(i) * 0.2))
                    .frame(width: d * 0.18, height: d * 0.14)
                    .offset(x: pw * (0.30 + CGFloat(i) * 0.12), y: g - d * (0.07 + CGFloat(i) * 0.14))
            }
            ground(h, hz)
        }
    }

    private func table(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ground(h, hz)
            RoundedRectangle(cornerRadius: d * 0.01).fill(Color(hex: land))
                .frame(width: pw * 0.30, height: d * 0.03)
                .offset(x: pw * 0.34, y: g - d * 0.20)
            Rectangle().fill(Color(hex: land).opacity(0.8))
                .frame(width: d * 0.02, height: d * 0.20)
                .offset(x: pw * 0.34, y: g - d * 0.10)
            RoundedRectangle(cornerRadius: d * 0.015).fill(Color(hex: accent).opacity(0.9))
                .frame(width: d * 0.14, height: d * 0.09)
                .offset(x: pw * 0.34, y: g - d * 0.27)
            Circle().fill(Color(hex: accent).opacity(0.25))
                .frame(width: d * 0.30, height: d * 0.30)
                .offset(x: -pw * 0.34, y: g - d * 0.46)
                .blur(radius: d * 0.03)
        }
    }

    private func launch(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<10, id: \.self) { i in
                Circle().fill(Color.white.opacity(0.5))
                    .frame(width: d * 0.012, height: d * 0.012)
                    .offset(x: pw * (CGFloat(i) * 0.10 - 0.45), y: g - d * (0.40 + CGFloat((i * 7) % 4) * 0.12))
            }
            Rectangle().fill(Color(hex: land).opacity(0.9))
                .frame(width: d * 0.05, height: d * 0.72)
                .offset(x: pw * 0.36, y: g - d * 0.36)
            ForEach(0..<6, id: \.self) { i in
                Rectangle().fill(Color(hex: land).opacity(0.7))
                    .frame(width: d * 0.12, height: d * 0.008)
                    .offset(x: pw * 0.36, y: g - d * (0.10 + CGFloat(i) * 0.12))
            }
            Capsule().fill(Color(hex: accent).opacity(0.85))
                .frame(width: d * 0.06, height: d * 0.16)
                .offset(x: pw * 0.29, y: g - d * 0.26)
            Ellipse().fill(Color(hex: accent).opacity(0.25))
                .frame(width: pw * 0.40, height: d * 0.12)
                .offset(x: pw * 0.30, y: g + d * 0.02)
                .blur(radius: d * 0.03)
            ground(h, hz)
        }
    }

    private func road(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            Circle().fill(Color(hex: accent).opacity(0.72))
                .frame(width: d * 0.24, height: d * 0.24)
                .offset(x: -pw * 0.36, y: g - d * 0.36)
            ground(h, hz)
            Triangle().fill(Color(hex: 0xF3E3C6).opacity(0.8))
                .frame(width: pw * 0.78, height: d * 0.34)
                .rotationEffect(.degrees(180))
                .offset(y: g + d * 0.17)
            ForEach(0..<2, id: \.self) { i in
                Capsule().fill(Color(hex: land).opacity(0.6))
                    .frame(width: pw * 0.16, height: d * 0.030)
                    .offset(x: pw * (i == 0 ? -0.36 : 0.36), y: g - d * 0.015)
            }
        }
    }

    private func neon(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<4, id: \.self) { i in
                let tall: CGFloat = d * (0.34 - CGFloat(i % 2) * 0.12)
                let x: CGFloat = pw * (CGFloat(i) * 0.27 - 0.405)
                RoundedRectangle(cornerRadius: d * 0.012)
                    .fill(Color(hex: accent).opacity(0.75 - Double(i % 3) * 0.15))
                    .frame(width: d * 0.05, height: tall)
                    .offset(x: x, y: g - tall / 2 - d * 0.14)
            }
            ground(h, hz)
            ForEach(0..<4, id: \.self) { i in
                Rectangle().fill(Color(hex: accent).opacity(0.20))
                    .frame(width: d * 0.05, height: d * 0.18)
                    .offset(x: pw * (CGFloat(i) * 0.27 - 0.405), y: g + d * 0.10)
                    .blur(radius: d * 0.025)
            }
        }
    }

    private func diner(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<2, id: \.self) { i in
                RoundedRectangle(cornerRadius: d * 0.03).fill(Color(hex: accent).opacity(0.26))
                    .frame(width: pw * 0.30, height: d * 0.44)
                    .overlay(RoundedRectangle(cornerRadius: d * 0.03).stroke(Color(hex: accent).opacity(0.55), lineWidth: d * 0.007))
                    .offset(x: pw * (i == 0 ? -0.32 : 0.32), y: g - d * 0.36)
            }
            ground(h, hz)
            ForEach(0..<2, id: \.self) { i in
                Capsule().fill(Color(hex: land).opacity(0.9))
                    .frame(width: d * 0.09, height: d * 0.22)
                    .offset(x: pw * (i == 0 ? -0.40 : 0.40), y: g + d * 0.07)
            }
        }
    }

    private func rooftop(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            Circle().fill(Color(hex: accent).opacity(0.85))
                .frame(width: d * 0.24, height: d * 0.24)
                .offset(x: pw * 0.33, y: g - d * 0.60)
            ForEach(0..<7, id: \.self) { i in
                let tall: CGFloat = d * (0.20 + CGFloat((i * 5) % 3) * 0.13)
                Rectangle().fill(Color(hex: land).opacity(0.75))
                    .frame(width: pw * 0.10, height: tall)
                    .offset(x: pw * (CGFloat(i) * 0.15 - 0.45), y: g - tall / 2)
            }
            ground(h, hz)
        }
    }

    private func field(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            Circle().fill(Color(hex: accent).opacity(0.28))
                .frame(width: d * 0.24, height: d * 0.24)
                .offset(x: -pw * 0.34, y: g - d * 0.58)
            ground(h, hz)
            ForEach(0..<13, id: \.self) { i in
                Capsule().fill(Color(hex: 0x8B6F30).opacity(0.42))
                    .frame(width: d * 0.014, height: d * 0.19)
                    .offset(x: pw * (CGFloat(i) * 0.083 - 0.50), y: g + d * 0.07)
            }
        }
    }

    private func gym(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            Rectangle().fill(Color(hex: accent).opacity(0.20))
                .frame(width: pw * 0.24, height: d * 0.50)
                .rotationEffect(.degrees(12))
                .offset(x: -pw * 0.33, y: g - d * 0.52)
                .blur(radius: d * 0.02)
            Rectangle().fill(Color(hex: 0x2A241C).opacity(0.45))
                .frame(width: d * 0.006, height: d * 0.22)
                .offset(x: pw * 0.34, y: g - d * 0.62)
            Capsule().fill(Color(hex: land))
                .frame(width: d * 0.13, height: d * 0.32)
                .offset(x: pw * 0.34, y: g - d * 0.35)
            ground(h, hz)
        }
    }

    private func floor(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<8, id: \.self) { i in
                let col = CGFloat(i % 4)
                let row = CGFloat(i / 4)
                RoundedRectangle(cornerRadius: d * 0.012)
                    .fill(Color(hex: accent).opacity(0.48 - Double(i % 4) * 0.08))
                    .frame(width: pw * 0.16, height: d * 0.10)
                    .offset(x: pw * (col * 0.28 - 0.42), y: g - d * (row * 0.19 + 0.24))
            }
            ground(h, hz)
        }
    }

    private func racks(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<4, id: \.self) { i in
                let far = i == 0 || i == 3
                rack(d, tall: far ? 0.30 : 0.38)
                    .offset(x: pw * (CGFloat(i) * 0.26 - 0.39), y: g - d * (far ? 0.20 : 0.25))
            }
            ground(h, hz)
        }
    }
    private func rack(_ d: CGFloat, tall: CGFloat) -> some View {
        VStack(spacing: d * 0.02) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: d * 0.006)
                    .fill(Color(hex: accent).opacity(0.5))
                    .frame(width: d * 0.05, height: d * 0.014)
            }
        }
        .padding(d * 0.03)
        .frame(height: d * tall)
        .background(RoundedRectangle(cornerRadius: d * 0.02).fill(Color(hex: land)))
    }

    private func orbit(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<14, id: \.self) { i in
                Circle().fill(Color.white.opacity(0.55))
                    .frame(width: d * 0.013, height: d * 0.013)
                    .offset(x: pw * (CGFloat(i) * 0.077 - 0.46), y: g - d * (0.28 + CGFloat((i * 7) % 5) * 0.11))
            }
            Circle().fill(Color(hex: accent).opacity(0.9))
                .frame(width: d * 0.13, height: d * 0.13)
                .offset(x: pw * 0.35, y: g - d * 0.66)
            Circle().stroke(Color(hex: accent).opacity(0.28), lineWidth: d * 0.006)
                .frame(width: pw * 1.5, height: pw * 1.5)
                .offset(y: g + pw * 0.75)
            ground(h, hz)
        }
    }

    private func summit(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            Circle().fill(Color(hex: accent).opacity(0.75))
                .frame(width: d * 0.22, height: d * 0.22)
                .offset(x: -pw * 0.30, y: g - d * 0.60)
            Triangle().fill(Color(hex: land).opacity(0.60))
                .frame(width: pw * 0.46, height: d * 0.44)
                .rotationEffect(.degrees(180))
                .offset(x: -pw * 0.30, y: g - d * 0.22)
            Triangle().fill(Color(hex: land))
                .frame(width: pw * 0.52, height: d * 0.54)
                .rotationEffect(.degrees(180))
                .offset(x: pw * 0.31, y: g - d * 0.27)
            ground(h, hz)
        }
    }

    private func spotlight(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<2, id: \.self) { side in
                Rectangle().fill(Color(hex: land).opacity(0.92))
                    .frame(width: pw * 0.16, height: h)
                    .offset(x: pw * (side == 0 ? -0.42 : 0.42), y: g - h * 0.42)
            }
            Triangle().fill(Color(hex: accent).opacity(0.26))
                .frame(width: pw * 0.52, height: h * 0.82)
                .offset(y: g - h * 0.41)
                .blur(radius: d * 0.03)
            ground(h, hz)
            Ellipse().fill(Color(hex: accent).opacity(0.30))
                .frame(width: pw * 0.46, height: d * 0.10)
                .offset(y: g + d * 0.04)
        }
    }

    private func platform(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            ForEach(0..<12, id: \.self) { i in
                let col = CGFloat(i % 6)
                let row = CGFloat(i / 6)
                Rectangle().stroke(Color(hex: 0xF3E3C6).opacity(0.15), lineWidth: 1)
                    .frame(width: pw * 0.16, height: d * 0.16)
                    .offset(x: pw * (col * 0.17 - 0.425), y: g - d * (row * 0.18 + 0.26))
            }
            Circle().fill(Color(hex: accent).opacity(0.7))
                .frame(width: d * 0.11, height: d * 0.11)
                .offset(x: pw * 0.36, y: g - d * 0.40)
                .blur(radius: d * 0.008)
            ground(h, hz)
            Rectangle().fill(Color(hex: 0xF3E3C6).opacity(0.18))
                .frame(height: d * 0.014)
                .offset(y: g + d * 0.12)
        }
    }

    private func cabin(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            RoundedRectangle(cornerRadius: d * 0.02).fill(Color(hex: accent).opacity(0.30))
                .frame(width: pw * 0.22, height: d * 0.26)
                .offset(x: pw * 0.34, y: g - d * 0.38)
            ForEach(0..<16, id: \.self) { i in
                Circle().fill(Color.white.opacity(0.7))
                    .frame(width: d * 0.020, height: d * 0.020)
                    .offset(x: pw * (CGFloat(i) * 0.066 - 0.47), y: g - d * (0.16 + CGFloat((i * 5) % 6) * 0.11))
            }
            ground(h, hz)
        }
    }

    private func sea(_ d: CGFloat, _ hz: CGFloat, _ h: CGFloat, _ pw: CGFloat) -> some View {
        let g = gy(hz, h)
        return ZStack {
            Circle().fill(Color(hex: accent).opacity(0.26))
                .frame(width: d * 0.22, height: d * 0.22)
                .offset(x: pw * 0.33, y: g - d * 0.58)
            ground(h, hz)
            ForEach(0..<5, id: \.self) { i in
                Capsule().fill(Color(hex: 0xF3E3C6).opacity(0.26))
                    .frame(width: pw * (0.22 - CGFloat(i) * 0.03), height: d * 0.014)
                    .offset(x: pw * (CGFloat(i) * 0.21 - 0.40), y: g + d * (0.08 + CGFloat(i % 3) * 0.06))
            }
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
    /// `.orbit` is deliberately absent: it is the reward scene, not a look you can dress into.
    private static let rotation: [MovieScene] = [
        .road, .rooftop, .field, .platform, .diner, .summit, .neon,
        .sea, .cabin, .gym, .racks, .floor, .spotlight
    ]

    /// The one scene no look carries. It arrives with the seventh completed Work receipt.
    static let reward: MovieScene = .orbit
    static let rewardAt = 7

    /// The room Today and the share image are both showing. One place, so they never disagree.
    /// The seed is how many completed receipts that lane has this week, so the rooms rotate with use.
    static func forToday(_ todayLogs: [ProofLog], allLogs: [ProofLog], workThisWeek: Int, fallbackKit: Kit, paused: Bool = false) -> MovieScene {
        guard let latest = todayLogs.first else { return forKit(fallbackKit) }
        if paused { return forKit(Kit(rawValue: latest.costumeID ?? "") ?? fallbackKit) }
        if workThisWeek >= rewardAt && latest.quest == .work { return reward }
        let cal = LarpyTime.cal
        let monday = cal.dateInterval(of: .weekOfYear, for: cal.startOfDay(for: latest.createdAt))?.start ?? latest.createdAt
        let laneCount = allLogs.filter { $0.quest == latest.quest && $0.isEligible && $0.createdAt >= monday && $0.createdAt <= latest.createdAt }.count
        return forLane(latest.quest, seed: max(0, laneCount - 1))
    }

    /// What you did last decides the room. Body earns the outdoors and the gym, Learnt the rooms
    /// full of other people's work, Work the rooms with an audience. The seed keeps two looks in
    /// the same lane from landing in the same room.
    static func forLane(_ lane: QuestKind, seed: Int) -> MovieScene {
        let set: [MovieScene]
        switch lane {
        case .body:  set = [.summit, .road, .field, .gym, .pool, .bridge, .stairwell, .pitch]
        case .learn: set = [.cabin, .racks, .platform, .diner, .lamp, .whiteboard, .hum]
        case .work:  set = [.rooftop, .sea, .spotlight, .floor, .neon, .dock, .table, .launch]
        }
        return set[abs(seed) % set.count]
    }

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
