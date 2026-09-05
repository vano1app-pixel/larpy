import SwiftUI
import PhotosUI

/// Original costume interpretations, not downloaded portraits or endorsements.
/// Each receipt keeps its own look ID, so history never redresses itself.
struct FounderLook: Identifiable {
    let id: String
    let name: String
    let kit: Kit
    let colorHex: UInt
    let detail: String
    let prop: String
    var color: Color { Color(hex: colorHex) }
    var label: String { "\(name) mode" }

    static let all: [FounderLook] = [
        .init(id: "jobs", name: "Steve Jobs", kit: .rollneck, colorHex: 0x282522, detail: "round-glasses", prop: "walk"),
        .init(id: "hormozi", name: "Alex Hormozi", kit: .tee, colorHex: 0xDDD6C8, detail: "stripe", prop: "board"),
        .init(id: "cursor", name: "Cursor kid", kit: .hoodie, colorHex: 0x6C756C, detail: "zip", prop: "laptop"),
        .init(id: "belfort", name: "Jordan Belfort", kit: .collar, colorHex: 0xDDD9CF, detail: "tie", prop: "phone"),
        .init(id: "zuck", name: "Mark Zuckerberg", kit: .tee, colorHex: 0x929591, detail: "chain", prop: "laptop"),
        .init(id: "jensen", name: "Jensen Huang", kit: .hoodie, colorHex: 0x363A35, detail: "zip", prop: "chip"),
        .init(id: "sara", name: "Sara Blakely", kit: .collar, colorHex: 0xB9816D, detail: "buttons", prop: "notebook"),
        .init(id: "sam", name: "Sam Altman", kit: .tee, colorHex: 0x73877D, detail: "pocket", prop: "laptop"),
        .init(id: "melanie", name: "Melanie Perkins", kit: .collar, colorHex: 0x95A69E, detail: "buttons", prop: "notebook"),
        .init(id: "patrick", name: "Patrick Collison", kit: .collar, colorHex: 0xA4B3B4, detail: "pocket", prop: "notebook"),
        .init(id: "john", name: "John Collison", kit: .tee, colorHex: 0x7E8F9E, detail: "stripe", prop: "laptop"),
        .init(id: "brian", name: "Brian Chesky", kit: .tee, colorHex: 0x454A47, detail: "pocket", prop: "notebook"),
        .init(id: "paul", name: "Paul Graham", kit: .collar, colorHex: 0xC5BB9E, detail: "round-glasses", prop: "notebook"),
        .init(id: "jessica", name: "Jessica Livingston", kit: .collar, colorHex: 0x7E9295, detail: "buttons", prop: "notebook"),
        .init(id: "naval", name: "Naval Ravikant", kit: .tee, colorHex: 0x8A9290, detail: "v-neck", prop: "book"),
        .init(id: "jack", name: "Jack Dorsey", kit: .hoodie, colorHex: 0x444C4B, detail: "zip", prop: "phone"),
        .init(id: "elon", name: "Elon Musk", kit: .tee, colorHex: 0x393F3C, detail: "patch", prop: "rocket"),
        .init(id: "jeff", name: "Jeff Bezos", kit: .collar, colorHex: 0xB7A78A, detail: "zip", prop: "parcel"),
        .init(id: "bill", name: "Bill Gates", kit: .rollneck, colorHex: 0x9A9A8C, detail: "round-glasses", prop: "book"),
        .init(id: "woz", name: "Steve Wozniak", kit: .tee, colorHex: 0x9DADAB, detail: "stripe", prop: "chip"),
        .init(id: "larry", name: "Larry Page", kit: .collar, colorHex: 0xBEC4BA, detail: "pocket", prop: "notebook"),
        .init(id: "sergey", name: "Sergey Brin", kit: .tee, colorHex: 0x708C87, detail: "v-neck", prop: "chip"),
        .init(id: "reid", name: "Reid Hoffman", kit: .collar, colorHex: 0xA5ABB0, detail: "pocket", prop: "phone"),
        .init(id: "peter", name: "Peter Thiel", kit: .collar, colorHex: 0x747F84, detail: "tie", prop: "book"),
        .init(id: "marc", name: "Marc Andreessen", kit: .collar, colorHex: 0x8D9093, detail: "buttons", prop: "notebook"),
        .init(id: "ben", name: "Ben Horowitz", kit: .hoodie, colorHex: 0x858574, detail: "zip", prop: "book"),
        .init(id: "tobi", name: "Tobias Lütke", kit: .hoodie, colorHex: 0x6E8678, detail: "patch", prop: "laptop"),
        .init(id: "dylan", name: "Dylan Field", kit: .tee, colorHex: 0xAE8C70, detail: "pocket", prop: "notebook"),
        .init(id: "ivan", name: "Ivan Zhao", kit: .rollneck, colorHex: 0x555652, detail: "buttons", prop: "book"),
        .init(id: "guillermo", name: "Guillermo Rauch", kit: .hoodie, colorHex: 0x484C4A, detail: "patch", prop: "laptop"),
        .init(id: "pieter", name: "Pieter Levels", kit: .tee, colorHex: 0xB4A084, detail: "v-neck", prop: "laptop"),
        .init(id: "david", name: "David Heinemeier Hansson", kit: .collar, colorHex: 0xB0B2A8, detail: "stripe", prop: "laptop"),
        .init(id: "jason", name: "Jason Fried", kit: .tee, colorHex: 0xA09D90, detail: "pocket", prop: "book"),
        .init(id: "drew", name: "Drew Houston", kit: .hoodie, colorHex: 0x8398A7, detail: "zip", prop: "laptop"),
        .init(id: "dustin", name: "Dustin Moskovitz", kit: .tee, colorHex: 0x8C9C90, detail: "pocket", prop: "notebook"),
        .init(id: "stewart", name: "Stewart Butterfield", kit: .collar, colorHex: 0x998B78, detail: "round-glasses", prop: "phone"),
        .init(id: "aaron", name: "Aaron Levie", kit: .collar, colorHex: 0x98A4AA, detail: "tie", prop: "parcel"),
        .init(id: "eric", name: "Eric Yuan", kit: .collar, colorHex: 0xA7B4BA, detail: "buttons", prop: "phone"),
        .init(id: "whitney", name: "Whitney Wolfe Herd", kit: .collar, colorHex: 0xCAB47E, detail: "buttons", prop: "phone"),
        .init(id: "anne", name: "Anne Wojcicki", kit: .collar, colorHex: 0x8CA89A, detail: "stripe", prop: "notebook"),
        .init(id: "reshma", name: "Reshma Saujani", kit: .collar, colorHex: 0xB88776, detail: "buttons", prop: "book"),
        .init(id: "leila", name: "Leila Janah", kit: .collar, colorHex: 0xB39880, detail: "v-neck", prop: "notebook"),
        .init(id: "tristan", name: "Tristan Walker", kit: .hoodie, colorHex: 0x777F72, detail: "zip", prop: "parcel"),
        .init(id: "daymond", name: "Daymond John", kit: .collar, colorHex: 0x646B6D, detail: "tie", prop: "notebook"),
        .init(id: "mark", name: "Mark Cuban", kit: .tee, colorHex: 0x7C91A0, detail: "v-neck", prop: "phone"),
        .init(id: "richard", name: "Richard Branson", kit: .collar, colorHex: 0xD6D1C1, detail: "buttons", prop: "notebook"),
        .init(id: "phil", name: "Phil Knight", kit: .tee, colorHex: 0x8D9584, detail: "stripe", prop: "shoe"),
        .init(id: "yvon", name: "Yvon Chouinard", kit: .hoodie, colorHex: 0x9B9E7E, detail: "zip", prop: "notebook"),
        .init(id: "james", name: "James Dyson", kit: .collar, colorHex: 0xB3B6AD, detail: "round-glasses", prop: "gear"),
        .init(id: "reed", name: "Reed Hastings", kit: .collar, colorHex: 0xA78C80, detail: "buttons", prop: "notebook"),
        .init(id: "daniel", name: "Daniel Ek", kit: .tee, colorHex: 0x778E79, detail: "patch", prop: "headphones"),
        .init(id: "kevin", name: "Kevin Systrom", kit: .collar, colorHex: 0xAAB1A6, detail: "pocket", prop: "camera"),
        .init(id: "evan", name: "Evan Spiegel", kit: .tee, colorHex: 0xB9AD83, detail: "v-neck", prop: "camera"),
        .init(id: "mike", name: "Mike Krieger", kit: .hoodie, colorHex: 0xA58C7A, detail: "zip", prop: "camera")
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
                    Text("\(unlocked.count) of \(FounderLook.all.count) looks earned. Every receipt changes the character. Only Work changes the level.")
                        .font(.system(size: 15)).foregroundStyle(Palette.muted)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(FounderLook.all) { look in
                            Button { selected = look } label: {
                                VStack(spacing: 8) {
                                    LarpyCharacterView(life: .neutral, base: .cream, kit: look.kit, width: 82, showScene: false, level: 1, founderID: look.id)
                                        .frame(height: 125)
                                    Text(look.name).font(.system(size: 15, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                                    Text(unlocked.contains(look.id) ? "Earned" : "Preview look")
                                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                                }.foregroundStyle(Palette.text).frame(maxWidth: .infinity).padding(.vertical, 15)
                                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                            }.buttonStyle(.plain)
                        }
                    }
                    Text("Original founder-inspired costumes. No affiliation or endorsement.").font(.system(size: 12)).foregroundStyle(Palette.muted)
                }.padding(24)
            }.background(Palette.bg).navigationTitle("Your characters").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .sheet(item: $selected) { look in
            VStack(spacing: 18) {
                LarpyCharacterView(life: .neutral, base: .cream, kit: look.kit, width: 190, interactive: true, level: 3, founderID: look.id).frame(height: 280)
                Text(look.label).font(.system(size: 30, weight: .medium, design: .serif)).foregroundStyle(Palette.text)
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
