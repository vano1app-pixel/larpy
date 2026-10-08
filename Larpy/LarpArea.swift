import SwiftUI
import UniformTypeIdentifiers

struct LarpLevelBar: View {
    let progress: LarpProgress
    var disclosure = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Lv \(progress.level)").font(.headline).monospacedDigit()
                Text(progress.title).font(.subheadline).foregroundStyle(Palette.muted)
                Spacer(minLength: 0)
                if disclosure { Image(systemName: "arrow.up.right").font(.caption) }
            }
            ProgressView(value: Double(progress.intoLevel), total: 100).tint(Palette.gold)
            HStack {
                Text("\(progress.intoLevel)/100 XP")
                Spacer()
                Text("\(progress.remaining) to level \(progress.level + 1)")
            }.font(.caption).foregroundStyle(Palette.muted).monospacedDigit()
        }.foregroundStyle(Palette.text)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Level \(progress.level), \(progress.remaining) XP to level \(progress.level + 1)")
    }
}

/// A private, offline board. Only people whose files you import appear here.
struct LarpAreaView: View {
    @ObservedObject var store: ProofStore
    @ObservedObject var prefs: Prefs
    @AppStorage("larpyPeerID") private var peerID = ""
    @AppStorage("larpLeague.v1") private var saved = Data()
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var period = LarpLeague.Period.week
    @State private var importing = false
    @State private var showSharing = false
    @State private var exporting = false
    @State private var prepared: FriendSnapshotDocument?
    @State private var message: String?
    @State private var inspect: LarpSnapshot?
    @State private var now = Date.now
    @Environment(\.scenePhase) private var scenePhase
    private var ownID: UUID { UUID(uuidString: peerID) ?? Self.fallbackID }
    private static let fallbackID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    private var friends: [LarpSnapshot] { (try? JSONDecoder().decode([LarpSnapshot].self, from: saved)) ?? [] }
    private var mine: LarpSnapshot { LarpSnapshot.make(id: ownID, name: prefs.name, logs: store.logs, calendar: LarpyTime.cal, now: now) }
    private var rows: [LarpLeague.Standing] { LarpLeague.standings(mine: mine, friends: friends, period: period, now: now) }
    private var older: Int { friends.filter { $0.valid(now: now) && ($0.weekStart != mine.weekStart || $0.weekEnd != mine.weekEnd) }.count }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    levelHero
                    leaderboard
                    rules
                }.padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.background(Palette.bg.ignoresSafeArea()).foregroundStyle(Palette.text)
                .navigationTitle("Larp").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) {
                    Button { showSharing = true } label: { Image(systemName: "person.badge.plus") }
                        .accessibilityLabel("Share scores and add friends")
                } }
                .onAppear { refresh() }
                .onChange(of: store.logs) { _, _ in now = .now }
                .onChange(of: scenePhase) { _, phase in if phase == .active { refresh() } }
                .sheet(isPresented: $showSharing) {
                    NavigationStack {
                        ScrollView { sharing.padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity) }
                            .background(Palette.bg).foregroundStyle(Palette.text)
                            .navigationTitle("Swap scores").navigationBarTitleDisplayMode(.inline)
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSharing = false } } }
                            .fileExporter(isPresented: $exporting, document: prepared, contentType: .json, defaultFilename: "Larpy-level-and-week") { result in
                                switch result {
                                case .success: message = "Saved. Send that file to a friend; they can add it in Larp."
                                case .failure(let error): message = "Could not export: \(error.localizedDescription)"
                                }
                            }
                            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in importFile(result) }
                    }
                }
                .sheet(item: $inspect) { snapshot in details(snapshot) }
        }
    }
    private func refresh() {
        now = .now
        if UUID(uuidString: peerID) == nil { peerID = UUID().uuidString }
    }
    private var levelHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The work shows.").font(.system(.largeTitle, design: .serif))
            HStack(spacing: 20) {
                LarpyCharacterView(life: .neutral, base: .cream, kit: .hoodie, width: 110, showScene: false,
                                   founderID: CharacterStyle.lookID(logs: store.logs, selected: prefs.selectedLookID), companion: true)
                    .frame(width: 120, height: 155).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("LEVEL").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(Palette.muted)
                    Text("\(mine.progress.level)").font(.system(size: textSize.isAccessibilitySize ? 56 : 76, weight: .medium, design: .serif)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                    Text("\(mine.progress.xp) lifetime XP").font(.subheadline).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
            LarpLevelBar(progress: mine.progress)
            Text("Every day you show up becomes part of your Larpy. Rest days never take XP away.")
                .font(.subheadline).foregroundStyle(Palette.muted)
        }
    }
    private var leaderboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your circle").font(.system(.title2, design: .serif))
                Spacer()
                Text("Shared leaderboard").font(.caption).foregroundStyle(Palette.muted)
            }
            Picker("Leaderboard period", selection: $period) {
                ForEach(LarpLeague.Period.allCases) { item in Text(item.rawValue).tag(item) }
            }.pickerStyle(.segmented)
            Text(period == .week ? "\(mine.weekStart) — \(mine.weekEnd) · Mon–Sun" : "Lifetime XP · levels stay with you")
                .font(.caption).foregroundStyle(Palette.muted)
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    Button { inspect = row.snapshot } label: { standing(row) }.buttonStyle(.plain)
                    if row.id != rows.last?.id { Divider() }
                }
            }
            if friends.isEmpty {
                Text("A little rivalry starts with one friend.").font(.headline)
                Button("Add your first friend") { showSharing = true }.font(.subheadline.weight(.semibold)).frame(minHeight: 44).tint(Palette.text)
            } else {
                if let you = rows.first(where: { $0.id == ownID }), let next = rows.last(where: { $0.score > you.score }) {
                    Text("\(next.snapshot.name) is \(next.score - you.score) XP ahead of you\(period == .week ? " this week" : " overall").").font(.subheadline.weight(.medium))
                } else if rows.count > 1 {
                    Text("You’re \(rows.filter { $0.score == rows.first?.score }.count > 1 ? "tied at the top" : "leading this board")\(period == .week ? " this week" : " overall").").font(.subheadline.weight(.medium))
                }
                if period == .week && older > 0 {
                    Text("\(older) older \(older == 1 ? "snapshot needs" : "snapshots need") refreshing for this week. Find them in Levels.").font(.caption).foregroundStyle(Palette.muted)
                }
            }
            Text("Friends’ scores reflect their last export. Shared by them, not independently verified. This board measures consistency, not hours or quality of work.")
                .font(.caption).foregroundStyle(Palette.muted)
        }
    }
    private func standing(_ row: LarpLeague.Standing) -> some View {
        let layout = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 14))
        return layout {
            Text(row.id == ownID && rows.count == 1 ? "—" : "\(row.rank)")
                .font(.system(.title2, design: .serif)).monospacedDigit().frame(minWidth: 26)
            VStack(alignment: .leading, spacing: 4) {
                Text(row.id == ownID ? "You" : row.snapshot.name).font(.headline).lineLimit(2)
                Text(row.id == ownID ? "Lv \(row.snapshot.progress.level) · up to date" : "Lv \(row.snapshot.progress.level) · \(row.snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Text("\(row.score) XP").font(.subheadline.weight(.semibold)).monospacedDigit().fixedSize()
        }.padding(.vertical, 16).padding(.horizontal, 10)
            .background(row.id == ownID ? Palette.gold.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
    }
    private var sharing: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Name on your score").font(.subheadline.weight(.semibold))
            TextField("Your name or nickname", text: $prefs.name).textFieldStyle(.roundedBorder)
                .onChange(of: prefs.name) { _, value in prefs.name = String(value.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }.map(String.init).joined().prefix(60)) }
            Button {
                refresh()
                do { prepared = FriendSnapshotDocument(data: try JSONEncoder().encode(mine)); exporting = true; message = nil }
                catch { message = "Could not prepare your score. Try again." }
            } label: {
                Label("Export my score", systemImage: "square.and.arrow.up").font(.headline).frame(maxWidth: .infinity, minHeight: 52)
                    .background(Palette.gold, in: Capsule()).foregroundStyle(Palette.ink)
            }.buttonStyle(.plain)
            Button { importing = true; message = nil } label: {
                Label("Add a friend’s score", systemImage: "person.badge.plus").font(.headline).frame(maxWidth: .infinity, minHeight: 48)
            }.buttonStyle(.plain)
            if let message { Text(message).font(.subheadline).foregroundStyle(Palette.text).accessibilityLabel(message) }
            Text("Shares your nickname, a stable profile ID, time zone, export date and Body, Work and Learnt day totals. Your receipts, photos and notes stay private.")
                .font(.caption).foregroundStyle(Palette.muted)
        }
    }
    private var rules: some View {
        DisclosureGroup("How levels work") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach([QuestKind.work, .body, .learn]) { lane in
                    HStack { Text(lane.title); Spacer(); Text("+\(LarpProgress.award(lane)) XP / day").monospacedDigit() }.font(.subheadline)
                }
                Text("Work needs a finished result with a link or photo. Body needs a photo or at least 10 minutes of activity. Learnt needs a takeaway. Each lane earns XP once a day, up to 50 XP total.")
                Text("100 XP = one level. Existing qualifying receipts count. More logs on the same day, token spending, followers and purchases do not add XP. Removing proof can change your total.")
                Text("Weekly scores use each person’s saved local dates, Monday to Sunday. Equal XP shares a rank. Old weeks never enter the current weekly board.")
            }.font(.footnote).foregroundStyle(Palette.muted).padding(.top, 12)
        }.tint(Palette.text)
    }
    private func details(_ item: LarpSnapshot) -> some View {
        NavigationStack {
            List {
                Section(item.id == ownID ? "You · Lv \(item.progress.level)" : "\(item.name) · Lv \(item.progress.level)") {
                    ForEach([QuestKind.work, .body, .learn]) { lane in
                        LabeledContent(lane.title, value: "\(item.lifetimeDays[lane.rawValue] ?? 0) days · \((item.lifetimeDays[lane.rawValue] ?? 0) * LarpProgress.award(lane)) XP")
                    }
                }
                Section("Snapshot") {
                    Text("Saved \(item.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                    Text("Week: \(item.weekStart) to \(item.weekEnd)")
                    Text(item.timeZoneID)
                    Text(item.id == ownID ? "Calculated from your saved proof." : "Shared totals. Not an authenticated account or a live feed.")
                }
                if item.id != ownID {
                    Button("Remove from my board", role: .destructive) {
                        save(friends.filter { $0.id != item.id }); inspect = nil
                    }
                }
            }.navigationTitle("Score details").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { inspect = nil } } }
        }
    }
    private func save(_ items: [LarpSnapshot]) {
        do { saved = try JSONEncoder().encode(items) }
        catch { message = "Could not save the board. Try again." }
    }
    private func importFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let scoped = url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= 50_000 else { throw LarpLeague.ImportError.invalid }
            let data = try Data(contentsOf: url)
            guard data.count <= 50_000 else { throw LarpLeague.ImportError.invalid }
            let item = try JSONDecoder().decode(LarpSnapshot.self, from: data)
            refresh()
            let updated = try LarpLeague.merge(item, into: friends, ownID: ownID, now: now)
            saved = try JSONEncoder().encode(updated)
            message = "\(item.name)’s score is on your board."
        } catch let error as LarpLeague.ImportError { message = error.rawValue }
        catch { message = "Could not read that score. Choose a JSON file exported from Larpy’s Larp tab." }
    }
}
