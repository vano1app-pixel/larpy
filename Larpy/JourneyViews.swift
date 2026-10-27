import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Small, original props with readable silhouettes at wardrobe size.
struct RewardProp: View {
    let prop: String
    let width: CGFloat
    var body: some View {
        let w = width
        Group {
            switch prop {
            case "camera":
                ZStack {
                    RoundedRectangle(cornerRadius: w * 0.035).fill(Color(hex: 0x3D403C)).frame(width: w * 0.34, height: w * 0.23)
                    RoundedRectangle(cornerRadius: w * 0.012).fill(Color(hex: 0x3D403C)).frame(width: w * 0.14, height: w * 0.06).offset(y: -w * 0.125)
                    Circle().fill(Color(hex: 0x858D87)).frame(width: w * 0.17)
                    Circle().fill(Color(hex: 0x242E31)).frame(width: w * 0.125)
                    Circle().fill(Color(hex: 0xB6C9C4)).frame(width: w * 0.035).offset(x: -w * 0.025, y: -w * 0.025)
                    Rectangle().fill(Color(hex: 0xE9DABF)).frame(width: w * 0.042, height: w * 0.02).offset(x: -w * 0.115, y: -w * 0.06)
                }
            case "dumbbell":
                ZStack {
                    Capsule().fill(Color(hex: 0xAAB0A7)).frame(width: w * 0.37, height: w * 0.045)
                    HStack(spacing: w * 0.17) {
                        RoundedRectangle(cornerRadius: w * 0.02).fill(Color(hex: 0x344C45)).frame(width: w * 0.085, height: w * 0.20)
                        RoundedRectangle(cornerRadius: w * 0.02).fill(Color(hex: 0x344C45)).frame(width: w * 0.085, height: w * 0.20)
                    }
                }.rotationEffect(.degrees(-13))
            case "microphone":
                ZStack {
                    Capsule().fill(Color(hex: 0x303B40)).frame(width: w * 0.055, height: w * 0.28).offset(y: w * 0.045)
                    Capsule().fill(Color(hex: 0xA9B6AC)).overlay(Capsule().stroke(Color(hex: 0x303B40), lineWidth: w * 0.009)).frame(width: w * 0.13, height: w * 0.18).offset(y: -w * 0.06)
                    VStack(spacing: w * 0.026) { ForEach(0..<3) { _ in Rectangle().fill(Color(hex: 0x65766E)).frame(width: w * 0.075, height: w * 0.008) } }.offset(y: -w * 0.06)
                }.rotationEffect(.degrees(15))
            default:
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: w * 0.015).fill(Color(hex: 0xEBDDC4)).frame(width: w * 0.23, height: w * 0.29)
                    Rectangle().fill(Color(hex: 0x314B62)).frame(width: w * 0.035, height: w * 0.29)
                    Rectangle().fill(Color(hex: 0xAF795A)).frame(width: w * 0.015, height: w * 0.29).offset(x: w * 0.17)
                }.rotationEffect(.degrees(-8))
            }
        }.frame(width: w * 0.4, height: w * 0.38)
    }
}

enum RewardLedger {
    static let audienceKey = "audienceRecords.v1"
    static var audience: [AudienceRecord] {
        guard let data = UserDefaults.standard.data(forKey: audienceKey) else { return [] }
        return (try? JSONDecoder().decode([AudienceRecord].self, from: data)) ?? []
    }
    static func migrate(_ logs: [ProofLog]) {
        let d = UserDefaults.standard
        if d.data(forKey: audienceKey) == nil, let data = d.data(forKey: "followerEvidence"),
           let old = try? JSONDecoder().decode(FollowerAchievement.self, from: data),
           old.photoFilename == (old.photoFilename as NSString).lastPathComponent {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Larpy", isDirectory: true)
            let folder = base.appendingPathComponent("Audience", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let name = "legacy-" + old.photoFilename
                let destination = folder.appendingPathComponent(name)
                if !FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.copyItem(at: base.appendingPathComponent("Achievements").appendingPathComponent(old.photoFilename), to: destination)
                }
                let record = AudienceRecord(platform: .linkedin, handle: "Previously logged LinkedIn account", count: old.count, photoFilename: name, recordedAt: old.at)
                if record.valid { d.set(try JSONEncoder().encode([record]), forKey: audienceKey) }
            } catch { /* Preserve the original record if its photo cannot migrate. */ }
        }
        guard !d.bool(forKey: "milestoneMigration.v1") else { return }
        // Preserve previously available clothes once. New receipts cannot bypass milestones.
        if !logs.isEmpty {
            // The historical trial check uses each receipt's actual date.
            let historical = logs.filter { log in log.isEligible && (Larp.unlocked || Larp.freeUntil.map { log.createdAt < $0 } ?? true) }
            let legacyIDs = Set(FounderLook.all.prefix(54).map(\.id))
            let legacy = Set(FounderLook.all.prefix(min(54, 4 + historical.count)).map(\.id))
                .union(historical.compactMap { FounderLook.canonicalID($0.founderID) }.filter { legacyIDs.contains($0) })
            d.set(Array(legacy), forKey: "earnedSkins.v1")
        }
        d.set(true, forKey: "milestoneMigration.v1")
    }
    static func unlocked(_ logs: [ProofLog]) -> Set<String> {
        let d = UserDefaults.standard
        let previous = Set(d.stringArray(forKey: "earnedSkins.v1") ?? []).subtracting(SeasonalShop.lookIDs)
        let earned = ProgressRules.earned(logs: logs, audience: audience, calendar: LarpyTime.cal)
        let all = previous.union(earned)
        if all != previous { d.set(Array(all).sorted(), forKey: "earnedSkins.v1") }
        return all
    }
}

struct WelcomeCompanionView: View {
    @ObservedObject var prefs: Prefs
    @ObservedObject var store: ProofStore
    @ObservedObject var loads: LoadLedger
    @AppStorage("companionName") private var companionName = "Larpy"
    @State private var choosing = false
    var body: some View {
        if choosing {
            JourneyProfileView(prefs: prefs, store: store, loads: loads, onboarding: true)
        } else {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("A little character.\nA lot of becoming.").font(.system(.largeTitle, design: .serif)).multilineTextAlignment(.center)
                        LarpyCharacterView(life: .clearedPreview, base: .cream, kit: .hoodie, width: 190, showScene: false,
                                           interactive: true, founderID: "look-03", companion: true).frame(height: 275)
                        Text("Move your body. Make something. Learn something. Your real progress levels up Larpy and earns new looks.")
                            .font(.body).multilineTextAlignment(.center).foregroundStyle(Palette.muted)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What should we call them?").font(.headline)
                            TextField("Larpy", text: $companionName).textFieldStyle(.roundedBorder).submitLabel(.done)
                                .onChange(of: companionName) { _, value in companionName = String(value.prefix(24)) }
                            Text("Optional. You can change it anytime.").font(.caption).foregroundStyle(Palette.muted)
                        }
                        Button {
                            companionName = companionName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if companionName.isEmpty { companionName = "Larpy" }
                            choosing = true
                        } label: {
                            Text("Meet my Larpy").font(.headline).foregroundStyle(Palette.ink)
                                .frame(maxWidth: .infinity, minHeight: 56).background(Palette.gold, in: Capsule())
                        }.buttonStyle(.plain)
                        Text("Start free. No account needed. Focus and app blocking are free. Optional Plus adds detailed weekly reviews.").font(.footnote).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    }.foregroundStyle(Palette.text).padding(24).frame(maxWidth: 520).frame(maxWidth: .infinity)
                }.background(Palette.bg).navigationTitle("Welcome").navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct JourneyProfileView: View {
    @ObservedObject var prefs: Prefs
    @ObservedObject var store: ProofStore
    @ObservedObject var loads: LoadLedger
    var onboarding = false
    @AppStorage("careerPath") private var career = CareerPath.exploring.rawValue
    @AppStorage("journeySetupDone") private var setupDone = false
    @Environment(\.dismiss) private var dismiss
    @State private var showConnections = false
    @State private var showAudience = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(onboarding ? "Who are you\nbecoming?" : "Your direction")
                        .font(.system(.largeTitle, design: .serif).weight(.medium)).foregroundStyle(Palette.text)
                    Text("Choose a path. Larpy will tailor your Work and Learnt prompts. You can change it anytime.")
                        .font(.body).foregroundStyle(Palette.muted)
                    VStack(spacing: 0) {
                        ForEach(CareerPath.allCases) { path in
                            Button { career = path.rawValue } label: {
                                HStack {
                                    Text(path.title).font(.body.weight(.medium))
                                    Spacer()
                                    Image(systemName: career == path.rawValue ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(career == path.rawValue ? Palette.gold : Palette.muted)
                                }.foregroundStyle(Palette.text).padding(.vertical, 14).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityAddTraits(career == path.rawValue ? .isSelected : [])
                            if path != CareerPath.allCases.last { Divider() }
                        }
                    }
                    Text("10 active days. Your first earned outfit.").font(.headline).foregroundStyle(Palette.text)
                    Text("Days do not need to be consecutive. Work and learning earn their own looks too.")
                        .foregroundStyle(Palette.muted)
                    DisclosureGroup("Connect trackers (optional)") {
                        Button { showConnections = true } label: { Label("Workouts & AI usage", systemImage: "link").frame(minHeight: 44) }
                        Button { showAudience = true } label: { Label("LinkedIn, Instagram & X", systemImage: "person.2").frame(minHeight: 44) }
                        Text("You can set these up later in Settings.").font(.footnote).foregroundStyle(Palette.muted)
                    }.foregroundStyle(Palette.text)
                    Button(onboarding ? "Start my journey" : "Save direction") { setupDone = true; dismiss() }
                        .buttonStyle(.borderedProminent).tint(Palette.gold).foregroundStyle(Palette.ink)
                        .controlSize(.large).frame(maxWidth: .infinity)
                    if onboarding {
                        Button("Decide later") { career = CareerPath.exploring.rawValue; setupDone = true; dismiss() }
                            .frame(maxWidth: .infinity, minHeight: 44).foregroundStyle(Palette.muted)
                    }
                }.padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.background(Palette.bg)
                .navigationTitle(onboarding ? "Welcome to Larpy" : "Your path").navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showConnections) { ConnectionsView(store: store, loads: loads) }
                .sheet(isPresented: $showAudience) { AudienceView(store: store) }
        }
    }
}

/// Character-first home. Receipt rules and storage remain shared with extensions.
struct CompanionHomeView: View {
    @ObservedObject var store: ProofStore
    @ObservedObject var prefs: Prefs
    @ObservedObject var loads: LoadLedger
    @ObservedObject var circle: CircleStore
    let onSettings: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize
    @EnvironmentObject private var connections: ConnectionsStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var focus = FocusModel.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var focusNote = ""
    @State private var focusProofPending = false
    @Binding var active: QuestKind?
    @Binding var showFocus: Bool
    let onCalendar: () -> Void
    let onLarp: () -> Void
    @AppStorage("companionName") private var companionName = "Larpy"
    @AppStorage(RewardLedger.audienceKey) private var audienceData = Data()
    @State private var previouslyEarned: Set<String> = []
    @State private var newSkin: FounderLook?
    @State private var showConnections = false
    @State private var calendar = false
    @State private var invite = false
    @State private var wardrobe = false
    @State private var hello = false
    @State private var fed = 0
    private var progress: LarpProgress { LarpProgress.earned(store.logs, calendar: LarpyTime.cal) }
    @State private var levelUp: Int?
    @State private var previousLevel = 1
    @AppStorage("careerPath") private var career = CareerPath.exploring.rawValue
    @State private var tomorrowDraft = ""
    @State private var editingTomorrow = false
    private var tomorrowKey: String { LarpyTime.dayKey(LarpyTime.cal.date(byAdding: .day, value: 1, to: .now)!) }
    private var todayIntent: String { prefs.tomorrowIntentFor == LarpyTime.dayKey() ? prefs.tomorrowIntent : "" }
    private var done: Int { QuestKind.allCases.filter { store.doneToday($0) }.count }
    private var look: FounderLook { FounderLook.find(CharacterStyle.lookID(logs: store.logs, selected: prefs.selectedLookID)) ?? FounderLook.all[0] }
    private var quickActivities: some View {
        let layout = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            ForEach([QuestKind.body, .work, .learn]) { lane in
                Button { focusNote = ""; active = lane } label: {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Image(systemName: store.doneToday(lane) ? "checkmark.circle.fill" : lane == .body ? "figure.run" : lane == .work ? "link" : "mic")
                            Spacer(minLength: 0)
                            if !store.doneToday(lane) { Image(systemName: "plus").font(.caption) }
                        }
                        Text(lane.title).font(.headline)
                        Text(store.doneToday(lane) ? "XP earned" : "+\(LarpProgress.award(lane)) XP").font(.caption.weight(.semibold))
                        Text(lane == .body ? "Photo or timer" : lane == .work ? "Link or photo" : "A takeaway")
                            .font(.caption).foregroundStyle(lane == .work ? Palette.ink.opacity(0.7) : Palette.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }.foregroundStyle(lane == .work ? Palette.ink : Palette.text).padding(13).frame(maxWidth: .infinity, alignment: .leading)
                        .background(lane == .work ? Palette.gold : Palette.card, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain)
                    .accessibilityLabel("\(lane.title), \(store.doneToday(lane) ? "logged today, add proof" : "add proof")")
            }
        }
    }
    private var focusEntry: some View {
        Button {
            focus.refresh()
            if focus.session == nil && focus.finished == nil && focus.readyToProtect {
                if !focus.quickStart(task: todayIntent) { showFocus = true }
            } else { showFocus = true }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: focus.session?.activeBreak() != nil ? "pause.circle" : focus.session?.blocksDistractions == false ? "timer" : "shield.lefthalf.filled").font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text(focus.session?.activeBreak() != nil ? "Break time · return early" : focus.session?.blocksDistractions == false ? "Focus timer · apps available" : focus.session != nil ? "Stay with your one thing" : focus.finished != nil ? "Time’s up. Bring the proof." : focus.readyToProtect ? "Focus for \(focus.quickMinutes) minutes" : "Set up protected focus").font(.subheadline.weight(.semibold))
                    Text(focus.session?.task ?? focus.finished?.task ?? (todayIntent.isEmpty ? (CareerPath(rawValue: career) ?? .exploring).work : todayIntent))
                        .font(.caption).foregroundStyle(Palette.muted).lineLimit(2)
                }
                Spacer(minLength: 8)
                if let session = focus.session {
                    let countdownEnd = session.activeBreak()?.endsAt ?? session.endsAt
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let seconds = max(0, Int(ceil(countdownEnd.timeIntervalSince(context.date))))
                        Text(String(format: "%02d:%02d", seconds / 60, seconds % 60)).font(.subheadline).monospacedDigit()
                            .onChange(of: seconds) { _, value in if value == 0 { focus.refresh() } }
                    }
                } else { Image(systemName: "arrow.up.right") }
            }.foregroundStyle(Palette.text).padding(14)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    private func checkRewards() {
        let current = RewardLedger.unlocked(store.logs)
        if let milestone = ProgressRules.skins.first(where: { current.contains($0.id) && !previouslyEarned.contains($0.id) }) {
            newSkin = FounderLook.find(milestone.id)
        }
        previouslyEarned = current
    }
    private func earnedMoment(_ item: FounderLook) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You earned a new look.").font(.headline)
                    Text(item.styleName).font(.system(.title2, design: .serif))
                }
                Spacer()
                Button { newSkin = nil } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Dismiss new skin")
            }
            Button {
                prefs.selectedLookID = item.id
                newSkin = nil; hello = true
            } label: {
                Label("Wear it", systemImage: "tshirt").font(.headline).frame(maxWidth: .infinity, minHeight: 48)
                    .background(Palette.gold, in: Capsule())
            }.buttonStyle(.plain)
        }.foregroundStyle(Palette.text).padding(18).background(Palette.gold.opacity(0.22), in: RoundedRectangle(cornerRadius: 22))
            .padding(.top, 12).accessibilityElement(children: .contain)
    }
    @AppStorage("companionPersonality") private var personality = CompanionPersonality.buddy.rawValue
    private var greeting: String {
        if focus.session != nil { return "Your one thing. I’m here." }
        if !hello, personality == CompanionPersonality.buddy.rawValue,
           let recognition = CompanionRecognition.greeting(logs: store.logs, calendar: LarpyTime.cal) { return recognition }
        return (CompanionPersonality(rawValue: personality) ?? .buddy).greeting(done: done, hello: hello)
    }
    private var companionLife: LifeState {
        var life = LifeState.neutral
        life.face = done == 0 ? .stirring : done == 3 ? .cleared : .fed
        life.posture = done == 3 || hello ? .upright : .normal
        life.cleared = done == 3 || hello
        return life
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                openHome
                if let levelUp {
                    Text("Level \(levelUp). You put in the work.").font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.text).padding(.vertical, 12)
                }
                if let newSkin { earnedMoment(newSkin) }
                focusEntry.padding(.top, 12)
                HStack {
                    Text("Add your proof").font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(done) of 3 today").font(.caption).foregroundStyle(Palette.muted)
                }.foregroundStyle(Palette.text).padding(.top, 16)
                quickActivities.padding(.top, 10)
                if store.doneToday(.work) { tomorrowNote.padding(.top, 12) }
                weekStrip.padding(.top, 24)
                NextSkinView(store: store) { wardrobe = true }.padding(.top, 12)
                Button { invite = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus").font(.title3)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Better with a friend").font(.subheadline.weight(.semibold))
                            Text("Share a little of your day.").font(.caption).foregroundStyle(Palette.muted)
                        }
                        Spacer(); Image(systemName: "chevron.right").font(.caption)
                    }.foregroundStyle(Palette.text).padding(.vertical, 16).contentShape(Rectangle())
                }.buttonStyle(.plain)
                Button { showConnections = true } label: {
                    HStack { Text("Connections"); Spacer(); Text("Health · AI · Calendar"); Image(systemName: "chevron.right") }
                        .font(.footnote).foregroundStyle(Palette.muted).frame(minHeight: 44)
                }.buttonStyle(.plain)
                Text("One small thing is enough to make today count.")
                    .font(.caption).foregroundStyle(Palette.muted).multilineTextAlignment(.center).padding(.top, 12)
            }.frame(maxWidth: 560).padding(.horizontal, 24).padding(.bottom, 24)
                .frame(maxWidth: .infinity)
        }.scrollIndicators(.hidden).background(Palette.bg.ignoresSafeArea())
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack {
                    Text("larpy").font(.system(.title2, design: .serif).weight(.bold)).tracking(-1)
                    Spacer()
                    Button { invite = true } label: { Image(systemName: "person.badge.plus").font(.system(size: 20)).frame(width: 44, height: 44) }.accessibilityLabel("Invite a friend")
                    Button(action: onSettings) { Image(systemName: "gearshape").font(.system(size: 20)).frame(width: 44, height: 44) }.accessibilityLabel("Settings")
                }.foregroundStyle(Palette.text).padding(.horizontal, 24).background(Palette.bg)
            }
            .sheet(isPresented: $showFocus, onDismiss: {
                if focusProofPending { focusProofPending = false; active = .work }
            }) {
                FocusModeView(model: focus, initialTask: todayIntent) { title in focusNote = title; focusProofPending = true }
            }
            .sheet(item: $active, onDismiss: { focusNote = "" }) { lane in LogSheet(quest: lane, store: store, loads: loads, prefillNote: lane == .work ? focusNote : "") }
            .sheet(isPresented: $calendar) { ActivityCalendarView(store: store) }
            .sheet(isPresented: $invite) { TogetherView(store: store, circle: circle, prefs: prefs) }
            .sheet(isPresented: $showConnections) { ConnectionsView(store: store, loads: loads) }
            .sheet(isPresented: $wardrobe) { WardrobeView(store: store, prefs: prefs) }
            .onChange(of: store.logs.first?.id) { _, _ in
                fed += 1; hello = false
                if store.logs.first?.quest == .work { focus.dismissFinished() }
                checkRewards()
                if progress.level > previousLevel { levelUp = progress.level }
                previousLevel = progress.level
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            .onChange(of: audienceData) { _, _ in checkRewards() }
            .onAppear {
                previouslyEarned = RewardLedger.unlocked(store.logs); focus.refresh(); previousLevel = progress.level
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-openFocus") { showFocus = true }
                if ProcessInfo.processInfo.arguments.contains("-openLearn") { active = .learn }
                #endif
            }
            .onChange(of: scenePhase) { _, phase in if phase == .active { focus.refresh() } }
            .task(id: hello) {
                guard hello else { return }
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { hello = false }
            }
    }
    private var tomorrowNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Leave tomorrow a little easier.").font(.system(.title3, design: .serif))
            if !editingTomorrow && prefs.tomorrowIntentFor == tomorrowKey && !prefs.tomorrowIntent.isEmpty {
                HStack(alignment: .top) {
                    Text(prefs.tomorrowIntent).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button("Edit") { tomorrowDraft = prefs.tomorrowIntent; editingTomorrow = true }.frame(minHeight: 44)
                }
                Text("I’ll keep this here for you tomorrow.").font(.caption).foregroundStyle(Palette.muted)
            } else {
                Text("One small next step. I’ll remember it.").font(.subheadline).foregroundStyle(Palette.muted)
                TextField("Tomorrow, I’ll…", text: $tomorrowDraft, axis: .vertical)
                    .textFieldStyle(.roundedBorder).lineLimit(1...3).submitLabel(.done)
                    .onChange(of: tomorrowDraft) { _, value in tomorrowDraft = String(value.prefix(120)) }
                if editingTomorrow {
                    Button("Cancel edit") { editingTomorrow = false; tomorrowDraft = "" }.font(.subheadline).frame(minHeight: 44)
                }
                if !tomorrowDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button("Keep it for tomorrow") {
                        prefs.tomorrowIntent = tomorrowDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        prefs.tomorrowIntentFor = tomorrowKey; tomorrowDraft = ""; editingTomorrow = false
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }.font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }
            }
        }.foregroundStyle(Palette.text).tint(Palette.text).padding(.vertical, 14)
    }
    private var openHome: some View {
        VStack(spacing: 0) {
            Text(greeting).font(.system(.title2, design: .serif).weight(.medium))
                .multilineTextAlignment(.center).foregroundStyle(Palette.text).padding(.top, 12)
            if !connections.usageConnected {
                companionStage(width: textSize.isAccessibilitySize ? 170 : 185).frame(height: 250).frame(maxWidth: .infinity)
            } else if textSize.isAccessibilitySize {
                companionStage(width: 180).frame(height: 230)
                weeklyTokenCounter.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 12)
            } else {
                GeometryReader { geometry in
                    HStack(spacing: 12) {
                        // The animated character reserves a stage 1.5x its body width.
                        companionStage(width: min(190, max(90, (geometry.size.width - 120) / 1.5)))
                            .frame(width: max(135, geometry.size.width - 120))
                        weeklyTokenCounter.frame(width: 108, alignment: .leading)
                    }.frame(width: geometry.size.width, height: geometry.size.height)
                }.frame(height: 260)
            }
            Button(action: onLarp) { LarpLevelBar(progress: progress, disclosure: true).padding(.vertical, 12).contentShape(Rectangle()) }
                .buttonStyle(.plain).accessibilityHint("Open levels and the friends leaderboard")
            HStack {
                Text(companionName.isEmpty ? "Larpy" : companionName).font(.headline).foregroundStyle(Palette.text)
                Spacer()
                Button { wardrobe = true } label: {
                    Label("Change look", systemImage: "tshirt").font(.subheadline).foregroundStyle(Palette.muted).frame(minHeight: 44)
                }.buttonStyle(.plain)
            }
        }
    }
    private func companionStage(width: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            Ellipse().fill(Palette.line.opacity(0.6)).frame(width: width * 0.8, height: 12).padding(.bottom, 16)
            character(width: width, scene: false)
        }
    }
    private var weeklyTokenCounter: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let week = connections.weeklyUsage(now: context.date)
            Button { showConnections = true } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Tokens").font(.caption).foregroundStyle(Palette.muted)
                    Text(week?.compact ?? "—")
                        .font(.system(.largeTitle, design: .rounded).weight(.semibold)).monospacedDigit()
                        .contentTransition(.numericText()).foregroundStyle(Palette.text)
                        .lineLimit(1).minimumScaleFactor(0.6)
                }.frame(minHeight: 80, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityLabel(week.map { "\($0.total.formatted()) AI tokens this week, \($0.sourceLabel), \($0.freshness(now: context.date))" } ?? "Weekly AI tokens, \(connections.usageConnected ? "waiting for your Mac" : "not connected")")
                .accessibilityHint("Open usage details and connections")
                .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: week?.total)
        }
    }
    private func character(width: CGFloat, scene: Bool) -> some View {
        LarpyCharacterView(life: companionLife, base: .cream, kit: look.kit, width: width,
                           showScene: scene, interactive: true, fedTick: fed, founderID: look.id, companion: true)
            .simultaneousGesture(TapGesture().onEnded {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { hello.toggle() }
            })
            .accessibilityLabel("Your Larpy, \(done == 0 ? "ready for today" : "happy you showed up")")
            .accessibilityHint("Double tap to say hello")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { hello.toggle() }
    }
    private var weekStrip: some View {
        Button(action: onCalendar) {
            VStack(spacing: 12) {
                HStack { Text("Your days").font(.subheadline.weight(.semibold)); Spacer(); Image(systemName: "calendar"); Image(systemName: "chevron.right").font(.caption) }
                HStack {
                    let cal = LarpyTime.cal
                    let start = cal.dateInterval(of: .weekOfYear, for: .now)!.start
                    ForEach(0..<7) { offset in
                        let day = cal.date(byAdding: .day, value: offset, to: start)!
                        VStack(spacing: 7) {
                            Text(day.formatted(.dateTime.weekday(.narrow))).font(.caption2)
                            CalendarMark(status: ActivityCalendarRules.status(on: day, logs: store.logs, calendar: cal), today: cal.isDateInToday(day))
                                .frame(width: 30, height: 30)
                        }.frame(maxWidth: .infinity)
                    }
                }
            }.foregroundStyle(Palette.text).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel("Your days. Open activity calendar")
    }
}

private struct CalendarMark: View {
    let status: ActivityCalendarRules.Status
    var today = false
    var body: some View {
        ZStack {
            Circle().fill(isActive ? Palette.gold : today ? Palette.card : Color.clear)
            Circle().stroke(Palette.line, style: StrokeStyle(lineWidth: 1, dash: status == .missed ? [2, 3] : []))
            if isActive { Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(Palette.ink) }
            else if status == .missed { Text("−").foregroundStyle(Palette.muted) }
            else if today { Circle().fill(Palette.text).frame(width: 5, height: 5) }
        }.opacity(status == .future || status == .beforeStart ? 0.4 : 1)
    }
    private var isActive: Bool { if case .active = status { return true }; return false }
}

struct ActivityCalendarView: View {
    @ObservedObject var store: ProofStore
    var embedded = false
    var onToday: (() -> Void)? = nil
    @State private var weekOffset = 0
    @State private var month = LarpyTime.cal.dateInterval(of: .month, for: .now)!.start
    @State private var selected = Date.now
    @State private var showDetail = false
    @State private var showReview = false
    @State private var refreshDate = Date.now
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    private var cal: Calendar { LarpyTime.cal }
    private func makeSummary() -> ActivityProgressSummary {
        ActivityProgressSummary(logs: store.logs,
            weekContaining: cal.date(byAdding: .weekOfYear, value: weekOffset, to: refreshDate)!,
            calendar: cal, now: refreshDate)
    }
    private func focusMinutes(_ summary: ActivityProgressSummary) -> Int? {
        // The existing focus store retains 32 days, not lifetime timer history.
        guard summary.weekStart >= cal.date(byAdding: .day, value: -31, to: cal.startOfDay(for: refreshDate))!,
              let defaults = FocusStorage.shared else { return nil }
        return FocusStorage.recordedSeconds(in: DateInterval(start: summary.weekStart, end: summary.weekEnd),
                                            from: defaults, now: refreshDate) / 60
    }
    private var days: [Date] {
        (cal.range(of: .day, in: .month, for: month) ?? 1..<2).compactMap { cal.date(byAdding: .day, value: $0 - 1, to: month) }
    }
    private var weekTitle: String { weekOffset == 0 ? "This week" : weekOffset == -1 ? "Last week" : "Your week" }
    private func weekRange(_ summary: ActivityProgressSummary) -> String {
        let last = cal.date(byAdding: .day, value: -1, to: summary.weekEnd)!
        return "\(summary.weekStart.formatted(.dateTime.day().month(.abbreviated))) – \(last.formatted(.dateTime.day().month(.abbreviated).year()))"
    }

    var body: some View {
        // Reuse one snapshot across the overview, streak and history in this render.
        let summary = makeSummary()
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    weeklyOverview(summary)
                    Button { showReview = true } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Your weekly review").font(.headline)
                                Text("Compare, reflect, choose your next step · Plus").font(.caption).foregroundStyle(Palette.muted)
                            }
                            Spacer(); Image(systemName: "arrow.up.right")
                        }.padding(.vertical, 10).frame(minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    streak(summary)
                    history(summary)
                    DisclosureGroup("Month view") { monthView.padding(.top, 12) }
                        .font(.subheadline.weight(.medium))
                    DisclosureGroup("What counts?") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("An activity day has at least one saved Body, Work or Learnt entry that meets its requirement. Extra entries on the same day don't add days.")
                            Text("Body: a photo or at least 10 minutes of movement. Work: a link or screenshot of a finished result. Learnt: a takeaway with a source or saved note. AI token usage alone doesn't count.")
                            Text("The activity streak counts consecutive dates, across any of those three activities. It stays open through today if you logged something yesterday. A gap starts a new streak; earned outfits and XP stay yours.")
                            Text("Focus is time in completed Larpy timer blocks, with breaks removed—not proof of finished work. Only the last 32 days of timer history are retained. Older weeks show a dash, not a guessed zero.")
                        }.font(.footnote).foregroundStyle(Palette.muted).padding(.top, 12)
                    }.font(.subheadline.weight(.medium))
                }.foregroundStyle(Palette.text).padding(22).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }.background(Palette.bg).navigationTitle("Progress").navigationBarTitleDisplayMode(.inline)
                .toolbar { if !embedded { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } } }
                .sheet(isPresented: $showDetail) {
                    NavigationStack {
                        DayDetail(day: selected, store: store)
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showDetail = false } } }
                    }
                }
                .sheet(isPresented: $showReview) { WeeklyReviewView(store: store, week: summary.weekStart) }
        }
        .onAppear { refreshDate = .now }
        .onChange(of: scenePhase) { _, phase in if phase == .active { refreshDate = .now } }
    }

    private func weeklyOverview(_ summary: ActivityProgressSummary) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(weekTitle).font(.system(.largeTitle, design: .serif))
                    Text(weekRange(summary)).font(.subheadline).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 4)
                Button { weekOffset -= 1 } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Previous week")
                Button { weekOffset = min(0, weekOffset + 1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .accessibilityLabel("Next week").disabled(weekOffset == 0)
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(summary.activeDays)").font(.system(size: 64, weight: .regular, design: .serif)).monospacedDigit()
                    Text(summary.activeDays == 1 ? "active day" : "active days").font(.title3).foregroundStyle(Palette.muted)
                    Spacer()
                }
                Text("\(summary.activeDays) active days").font(.title)
            }.accessibilityElement(children: .combine)
            VStack(spacing: 14) {
                measure("Recorded focus", value: focusMinutes(summary).map { "\($0) min" } ?? "—", icon: "timer")
                measure("Work days", value: "\(summary.workDays)", icon: "hammer")
                measure("Movement days", value: "\(summary.bodyDays)", icon: "figure.walk")
                measure("Learning days", value: "\(summary.learningDays)", icon: "book.closed")
            }
            Text(summary.activeDays > 0
                 ? "You saved progress on \(summary.activeDays) of 7 days\(weekOffset == 0 ? " so far" : ""). Your notes and proof are below."
                 : weekOffset == 0 ? "One small thing is enough to start. Log Body, Work or Learnt from Today."
                 : "No activity days recorded in this week.")
                .font(.subheadline).foregroundStyle(Palette.muted).fixedSize(horizontal: false, vertical: true)
            if weekOffset < 0 {
                Button("Back to this week") { weekOffset = 0 }.font(.subheadline).frame(minHeight: 44)
            } else if summary.activeDays == 0 {
                Button { if let onToday { onToday() } else { dismiss() } } label: {
                    Label("Go to Today", systemImage: "arrow.right").font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                }
            }
        }
    }

    private func measure(_ title: String, value: String, icon: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon).frame(width: 22).foregroundStyle(Palette.muted)
            Text(title).font(.body)
            Spacer(minLength: 8)
            Text(value).font(.body.weight(.semibold)).monospacedDigit().fixedSize()
        }.accessibilityElement(children: .combine)
    }

    private func streak(_ summary: ActivityProgressSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Activity streak").font(.headline)
                    Spacer(minLength: 12)
                    Text("\(summary.currentStreak) \(summary.currentStreak == 1 ? "day" : "days")").font(.title2).monospacedDigit()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Activity streak").font(.headline)
                    Text("\(summary.currentStreak) days").font(.title2).monospacedDigit()
                }
            }
            Text("Best: \(summary.bestStreak) \(summary.bestStreak == 1 ? "day" : "days") · One activity a day keeps it going.")
                .font(.subheadline).foregroundStyle(Palette.muted)
            Divider()
        }
    }

    private func history(_ summary: ActivityProgressSummary) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("What you did").font(.system(.title2, design: .serif))
            if summary.history.isEmpty {
                Text("Your saved notes, links and photos will appear here, newest first.")
                    .font(.subheadline).foregroundStyle(Palette.muted)
            }
            ForEach(summary.history) { day in
                Button { selected = day.date; showDetail = true } label: {
                    HStack(alignment: .top, spacing: 14) {
                        VStack(spacing: 3) {
                            Text(day.date.formatted(.dateTime.day())).font(.system(.title, design: .serif))
                            Text(day.date.formatted(.dateTime.weekday(.abbreviated))).font(.caption).foregroundStyle(Palette.muted)
                        }.frame(minWidth: 42).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(cal.isDateInToday(day.date) ? "Today" : day.date.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.headline)
                            Text(day.lanes.isEmpty ? "Saved records · no activity day" : day.lanes.map(\.title).joined(separator: " · "))
                                .font(.subheadline).foregroundStyle(day.lanes.isEmpty ? Palette.muted : Palette.gold)
                            Text(preview(day)).font(.subheadline).foregroundStyle(Palette.muted)
                                .lineLimit(textSize.isAccessibilitySize ? nil : 2)
                            Text("View \(day.logs.count) saved \(day.logs.count == 1 ? "entry" : "entries")")
                                .font(.caption).foregroundStyle(Palette.muted)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption).padding(.top, 5)
                    }.foregroundStyle(Palette.text).frame(maxWidth: .infinity, minHeight: 64, alignment: .leading).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityHint("Opens saved notes and proof for this day.")
                if day.id != summary.history.last?.id { Divider() }
            }
        }
    }

    private func preview(_ day: ActivityProgressSummary.Day) -> String {
        let log = day.logs.first { ProgressRules.countsForDay($0, now: refreshDate) } ?? day.logs[0]
        if let note = log.annotation, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return note }
        if log.proofKind == .photo { return "\(log.quest.title) photo saved" }
        return log.value.replacingOccurrences(of: "note: ", with: "")
    }

    private var monthView: some View {
        VStack(spacing: 12) {
            HStack {
                Button { moveMonth(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel("Previous month")
                Spacer(minLength: 0)
                Text(month.formatted(.dateTime.month(.wide).year())).font(.headline)
                Spacer(minLength: 0)
                Button { moveMonth(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }.accessibilityLabel("Next month")
                    .disabled(cal.isDate(month, equalTo: refreshDate, toGranularity: .month))
            }
            if textSize.isAccessibilitySize {
                ForEach(days.filter { !store.logsOn($0).isEmpty }, id: \.self) { day in
                    Button { selected = day; showDetail = true } label: {
                        Text(day.formatted(date: .abbreviated, time: .omitted)).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    }
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                    ForEach(0..<7) { index in Text(["M", "T", "W", "T", "F", "S", "S"][index]).font(.caption).foregroundStyle(Palette.muted) }
                    ForEach(0..<((cal.component(.weekday, from: month) + 5) % 7), id: \.self) { _ in Color.clear.frame(height: 44) }
                    ForEach(days, id: \.self) { day in
                        let active: Bool = { if case .active = ActivityCalendarRules.status(on: day, logs: store.logs, calendar: cal, now: refreshDate) { return true }; return false }()
                        let hasRecords = !store.logsOn(day).isEmpty && day <= refreshDate
                        Button { selected = day; showDetail = true } label: {
                            Text("\(cal.component(.day, from: day))").font(.subheadline.weight(active ? .semibold : .regular))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(active ? Palette.gold.opacity(0.18) : .clear, in: Circle())
                                .overlay(Circle().stroke(cal.isDateInToday(day) ? Palette.gold : .clear))
                        }.buttonStyle(.plain).disabled(!hasRecords).opacity(day > refreshDate ? 0.35 : 1)
                            .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)). \(active ? "Activity logged" : hasRecords ? "Saved records" : "No activity recorded")")
                    }
                }
            }
            Text("Gold marks an activity day. Tap a saved day to read it.").font(.footnote).foregroundStyle(Palette.muted)
        }
    }

    private func moveMonth(_ direction: Int) {
        if let next = cal.date(byAdding: .month, value: direction, to: month) { month = next }
    }
}

struct TogetherView: View {
    @State private var comparison = false
    @ObservedObject var store: ProofStore
    @ObservedObject var circle: CircleStore
    @ObservedObject var prefs: Prefs
    @Environment(\.dismiss) private var dismiss
    @State private var card: UIImage?
    private var completed: Int { QuestKind.allCases.filter { store.doneToday($0) }.count }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    if completed == 0 { HStack(spacing: -12) {
                        LarpyCharacterView(life: .neutral, base: .cream, kit: .hoodie, width: 106, showScene: false, companion: true).rotationEffect(.degrees(-7))
                        LarpyCharacterView(life: .clearedPreview, base: .cream, kit: .tee, width: 106, showScene: false, companion: true).rotationEffect(.degrees(7))
                    }.accessibilityHidden(true) }
                    Text(completed > 0 ? "Your day,\nworth sharing." : "A little company\ngoes a long way.").font(.system(.largeTitle, design: .serif)).multilineTextAlignment(.center)
                    Text(completed > 0 ? "Send a small win to someone you like." : "Invite a friend to try Larpy with you.").foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    if let friend = circle.friend {
                        Text("Saved friend · \(friend.name)").font(.headline)
                    }
                    if let card, completed > 0 {
                        Image(uiImage: card).resizable().scaledToFit().frame(maxWidth: 230)
                            .clipShape(RoundedRectangle(cornerRadius: 20)).accessibilityLabel("Preview of today's progress card")
                        ShareLink(item: Image(uiImage: card), preview: SharePreview("A little progress with Larpy", image: Image(uiImage: card))) {
                            Label("Share today’s card", systemImage: "square.and.arrow.up").font(.headline)
                                .foregroundStyle(Palette.ink).frame(maxWidth: .infinity, minHeight: 56)
                                .background(Palette.gold, in: Capsule())
                        }
                        Text("Only your outfit and completed activity labels are shared. Your photos, links and follower counts stay private.")
                            .font(.footnote).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    }
                    ShareLink(item: "Try Larpy with me. Let's make time for one small thing each day.\n\(circle.inviteLink(name: prefs.name, shipping: prefs.shipping).absoluteString)") {
                        Label("Share invitation", systemImage: "person.badge.plus").font(.headline).foregroundStyle(Palette.text)
                            .frame(maxWidth: .infinity, minHeight: 56).background(Palette.card, in: Capsule())
                    }
                    Text("For this test build, your friend needs Larpy installed. The invite saves a friend on their phone; activity sharing between phones is not connected yet.")
                        .font(.footnote).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    Button { comparison = true } label: {
                        Label("Compare with a friend", systemImage: "person.2.fill").font(.headline).frame(minHeight: 52)
                    }
                    Text("Free to use. No subscription needed.").font(.caption).foregroundStyle(Palette.muted)
                }.padding(24).frame(maxWidth: 480).frame(maxWidth: .infinity)
            }.background(Palette.bg).foregroundStyle(Palette.text).navigationTitle("Together").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .sheet(isPresented: $comparison) { FriendComparisonView(store: store, name: prefs.name) }
                .task(id: "\(store.logs.first?.id.uuidString ?? "")-\(prefs.selectedLookID)-\(prefs.selectedSceneID)") {
                    let renderer = ImageRenderer(content: CompanionProgressCard(store: store, prefs: prefs))
                    renderer.scale = 3
                    card = renderer.uiImage
                }
        }
    }
}

private struct CompanionProgressCard: View {
    let store: ProofStore
    let prefs: Prefs
    private var look: FounderLook? { FounderLook.find(CharacterStyle.lookID(logs: store.logs, selected: prefs.selectedLookID)) }
    var body: some View {
        VStack(spacing: 16) {
            HStack { Text("larpy").font(.system(size: 24, weight: .bold, design: .serif)); Spacer(); Text(Date.now.formatted(.dateTime.day().month())).font(.system(size: 13)) }
            Text("A little progress.").font(.system(size: 32, design: .serif))
            LarpyCharacterView(life: .clearedPreview, base: .cream, kit: look?.kit ?? .hoodie, width: 160,
                               showScene: !prefs.selectedSceneID.isEmpty,
                               scene: CharacterStyle.scene(logs: store.logs, selected: prefs.selectedSceneID, kit: look?.kit ?? .hoodie),
                               founderID: look?.id, companion: true).frame(height: 225)
            VStack(spacing: 10) {
                ForEach([QuestKind.body, .work, .learn].filter { store.doneToday($0) }) { lane in
                    Label(lane.title, systemImage: "checkmark.circle.fill").font(.system(size: 18, weight: .medium))
                }
            }
            Text("One small thing at a time.").font(.system(size: 14)).padding(.top, 8)
        }.foregroundStyle(Palette.ink).padding(28).frame(width: 360)
            .background(Color(hex: 0xF5F0E6)).environment(\.dynamicTypeSize, .large)
    }
}

struct NextSkinView: View {
    @ObservedObject var store: ProofStore
    @AppStorage(RewardLedger.audienceKey) private var audienceData = Data()
    @AppStorage("pinnedSkinID") private var pinnedSkinID = ""
    let action: () -> Void
    private var next: SkinMilestone? {
        let unlocked = RewardLedger.unlocked(store.logs)
        if let pinned = ProgressRules.skins.first(where: { $0.id == pinnedSkinID && !unlocked.contains($0.id) }) { return pinned }
        return ProgressRules.skins.filter { $0.lane != nil && !unlocked.contains($0.id) }.sorted {
            Double($0.progress(logs: store.logs, audience: [], calendar: LarpyTime.cal)) / Double($0.target) >
            Double($1.progress(logs: store.logs, audience: [], calendar: LarpyTime.cal)) / Double($1.target)
        }.first
    }
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(next.map { "Working toward · \($0.title)" } ?? "Your skin collection").font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }.foregroundStyle(Palette.text)
                if let next {
                    let n = next.progress(logs: store.logs, audience: RewardLedger.audience, calendar: LarpyTime.cal)
                    ProgressView(value: Double(min(n, next.target)), total: Double(next.target)).tint(Palette.gold)
                    Text(next.platform != nil ? "\(n.formatted()) / \(next.target.formatted()) \(next.platform!.title) followers" : "\(n)/\(next.target) \(next.lane == .body ? "active" : next.lane == .work ? "Work" : "learning") days · \(max(0, next.target - n)) to go")
                        .font(.caption).foregroundStyle(Palette.muted)
                } else { Text("Earned through your progress.").font(.caption).foregroundStyle(Palette.muted) }
            }.padding(.vertical, 12).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

struct AudienceView: View {
    @ObservedObject var store: ProofStore
    @AppStorage(RewardLedger.audienceKey) private var audienceData = Data()
    @State private var selected: AudiencePlatform?
    @State private var removing: AudiencePlatform?
    @State private var error = ""
    @Environment(\.dismiss) private var dismiss
    private var records: [AudienceRecord] { (try? JSONDecoder().decode([AudienceRecord].self, from: audienceData)) ?? [] }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("An audience.\nA new look.").font(.system(.largeTitle, design: .serif).weight(.medium)).foregroundStyle(Palette.text)
                    Text("Reach 10,000 followers on a platform to earn its founder-inspired skin. Each platform counts separately.")
                        .foregroundStyle(Palette.muted)
                    ForEach(AudiencePlatform.allCases) { platform in
                        let record = records.first { $0.platform == platform }
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(platform.title).font(.title3.weight(.semibold))
                                    Text(record?.handle ?? "No account added").font(.subheadline).foregroundStyle(Palette.muted)
                                }
                                Spacer()
                                Text(record.map { $0.count.formatted() } ?? "—").font(.title2.weight(.medium)).monospacedDigit()
                            }.foregroundStyle(Palette.text)
                            ProgressView(value: Double(min(record?.count ?? 0, 10_000)), total: 10_000).tint(Palette.gold)
                                .accessibilityLabel("\(platform.title) skin progress")
                                .accessibilityValue("\(record?.count ?? 0) of 10,000 followers")
                            let skin = ProgressRules.skins.first { $0.platform == platform }!
                        Text("\(skin.title) · 10,000 followers").font(.subheadline).foregroundStyle(Palette.text)
                            if let record {
                                Text("Self-reported · updated \(record.recordedAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption).foregroundStyle(Palette.muted)
                                if Date().timeIntervalSince(record.recordedAt) > 7 * 86_400 {
                                    Text("This count is over a week old. Add a current screenshot to update it.").font(.caption).foregroundStyle(Palette.muted)
                                }
                            }
                            HStack {
                                Button(record == nil ? "Add follower count" : "Update count") { selected = platform }.frame(minHeight: 44)
                                Spacer()
                                if record != nil { Button("Remove", role: .destructive) { removing = platform }.frame(minHeight: 44) }
                            }.font(.subheadline.weight(.medium)).tint(Palette.text)
                        }
                        Divider()
                    }
                    Text("Manual tracking in this build").font(.headline).foregroundStyle(Palette.text)
                    Text("Add your own account and a screenshot of its follower count. Larpy does not verify screenshots. Automatic account connections are not available yet; adding a handle does not connect an account.")
                        .font(.footnote).foregroundStyle(Palette.muted)
                    Text("Your screenshots stay on this device. Removing a tracker deletes its saved count and screenshot. Earned skins stay yours.")
                        .font(.footnote).foregroundStyle(Palette.muted)
                    if !error.isEmpty { Text(error).font(.footnote).foregroundStyle(.red) }
                }.padding(24)
            }.background(Palette.bg).navigationTitle("Followers").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .sheet(item: $selected) { platform in AudienceEntryView(platform: platform, store: store) }
                .confirmationDialog("Remove this follower tracker?", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })) {
                    Button("Remove tracker", role: .destructive) { remove() }
                    Button("Cancel", role: .cancel) { removing = nil }
                } message: { Text("The count and screenshot will be deleted. Earned skins stay yours.") }
        }
    }
    private func remove() {
        guard let platform = removing else { return }
        do {
            let old = records.first { $0.platform == platform }
            let remaining = records.filter { $0.platform != platform }
            let data = try JSONEncoder().encode(remaining)
            if let old {
                let file = AudienceEntryView.folder.appendingPathComponent(old.photoFilename)
                if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
            }
            audienceData = data; removing = nil
        } catch { self.error = "Couldn't remove the tracker. Try again." }
    }
}

struct AudienceEntryView: View {
    let platform: AudiencePlatform
    @ObservedObject var store: ProofStore
    @AppStorage(RewardLedger.audienceKey) private var audienceData = Data()
    @State private var handle = ""
    @State private var count = ""
    @State private var photo: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var loading = false
    @State private var ownsAccount = false
    @State private var error = ""
    @Environment(\.dismiss) private var dismiss
    private var number: Int? { count.allSatisfy(\.isNumber) && !count.isEmpty ? Int(count) : nil }
    private var valid: Bool { number.map { $0 >= 0 && $0 <= 1_000_000_000 } == true && !handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && imageData != nil && ownsAccount && !loading }
    static var folder: URL { FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Larpy/Audience", isDirectory: true) }
    var body: some View {
        NavigationStack {
            Form {
                Section("Your \(platform.title) account") {
                    TextField("Username or profile name", text: $handle).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .onChange(of: handle) { _, v in handle = String(v.prefix(100)) }
                    TextField("Follower count", text: $count).keyboardType(.numberPad)
                        .onChange(of: count) { _, v in count = String(v.prefix(10)) }
                }
                Section {
                    PhotosPicker(selection: $photo, matching: .images) { Label(loading ? "Reading screenshot…" : imageData == nil ? "Attach screenshot" : "Replace screenshot", systemImage: "photo") }.disabled(loading)
                    if let imageData, let image = UIImage(data: imageData) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 180).accessibilityLabel("Follower count screenshot")
                    }
                    Toggle("This is my account and current count", isOn: $ownsAccount)
                } footer: {
                    Text("Include your profile name and follower count. This is self-reported evidence, not a verified connection. Larpy stores the screenshot on this phone.")
                }
                Section {
                    Button("Save follower count", action: save).disabled(!valid || loading).frame(minHeight: 44)
                    if !error.isEmpty { Text(error).foregroundStyle(.red) }
                }
            }.navigationTitle(platform.title).navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .onAppear { handle = RewardLedger.audience.first { $0.platform == platform }?.handle ?? "" }
        .task(id: photo) {
            guard let photo else { return }; imageData = nil; loading = true; error = ""
            defer { loading = false }
            do {
                guard let data = try await photo.loadTransferable(type: Data.self), !Task.isCancelled,
                      let original = UIImage(data: data) else { return }
                let ratio = min(1, 1600 / max(original.size.width, original.size.height))
                let size = CGSize(width: original.size.width * ratio, height: original.size.height * ratio)
                let renderer = UIGraphicsImageRenderer(size: size)
                let resized = renderer.image { _ in original.draw(in: CGRect(origin: .zero, size: size)) }
                imageData = resized.jpegData(compressionQuality: 0.8)
            } catch { self.error = "Couldn't read that screenshot. Pick another." }
        }
    }
    private func save() {
        guard valid, let number, let imageData else { return }
        let name = UUID().uuidString + ".jpg"
        do {
            try FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
            let record = AudienceRecord(platform: platform, handle: handle.trimmingCharacters(in: .whitespacesAndNewlines), count: number, photoFilename: name, recordedAt: .now)
            let existing: [AudienceRecord]
            if let saved = UserDefaults.standard.data(forKey: RewardLedger.audienceKey) {
                existing = try JSONDecoder().decode([AudienceRecord].self, from: saved)
            } else { existing = [] }
            let updated = existing.filter { $0.platform != platform } + [record]
            let encoded = try JSONEncoder().encode(updated)
            try imageData.write(to: Self.folder.appendingPathComponent(name), options: [.atomic])
            audienceData = encoded
            _ = RewardLedger.unlocked(store.logs)
            if let old = existing.first(where: { $0.platform == platform }) { try? FileManager.default.removeItem(at: Self.folder.appendingPathComponent(old.photoFilename)) }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch { self.error = "Couldn't save. Your previous count is unchanged." }
    }
}

struct JourneyProgressView: View {
    @Environment(\.dynamicTypeSize) private var textSize
    @ObservedObject var store: ProofStore
    @ObservedObject var prefs: Prefs
    @ObservedObject var keys: AgentKeys
    @ObservedObject var agents: AgentStore
    @ObservedObject var loads: LoadLedger
    @State private var showHistory = false
    @State private var showAudience = false
    @AppStorage(RewardLedger.audienceKey) private var audienceData = Data()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Every day adds up.").font(.system(.largeTitle, design: .serif).weight(.medium)).foregroundStyle(Palette.text)
                    Text("Your lifetime progress. Rest days never reset it.").foregroundStyle(Palette.muted)
                    ForEach(QuestKind.allCases) { lane in
                        let days = ProgressRules.days(lane, logs: store.logs, calendar: LarpyTime.cal)
                        let layout = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout())
                        layout {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(lane == .body ? "Body" : lane.title).font(.headline)
                                Text(lane == .body ? "Workout timer of 10+ minutes, Health workout or photo" : lane == .work ? "Finished work with a link or image" : "A lesson with your own takeaway")
                                    .font(.caption).foregroundStyle(Palette.muted)
                            }
                            if !textSize.isAccessibilitySize { Spacer() }
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(days)").font(.system(.largeTitle, design: .serif)).monospacedDigit()
                                Text("days").font(.caption).foregroundStyle(Palette.muted)
                            }
                        }.foregroundStyle(Palette.text)
                        Divider()
                    }
                    Button { showAudience = true } label: {
                        HStack { Label("Followers & platform skins", systemImage: "person.2"); Spacer(); Image(systemName: "chevron.right") }.frame(minHeight: 44)
                    }.foregroundStyle(Palette.text)
                    Button { showHistory = true } label: {
                        HStack { Label("View activity history", systemImage: "calendar"); Spacer(); Image(systemName: "chevron.right") }.frame(minHeight: 44)
                    }.foregroundStyle(Palette.text)
                    Text("Each lane counts once per date. Photos and manual follower counts are self-reported. Token usage is tracked separately and does not earn learning days.")
                        .font(.footnote).foregroundStyle(Palette.muted)
                }.padding(24)
            }.background(Palette.bg).navigationTitle("Progress").navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showAudience) { AudienceView(store: store) }
                .sheet(isPresented: $showHistory) {
                    NavigationStack {
                        WeekView(store: store, prefs: prefs, keys: keys, agents: agents, loads: loads, onSettings: {})
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showHistory = false } } }
                    }
                }
        }
    }
}

struct SimpleSettingsView: View {
    @ObservedObject private var plus = LarpyPlusStore.shared
    @State private var showPlus = false
    @AppStorage("companionPersonality") private var personality = CompanionPersonality.buddy.rawValue
    @ObservedObject var store: ProofStore
    @ObservedObject var prefs: Prefs
    @ObservedObject var loads: LoadLedger
    @ObservedObject var agents: AgentStore
    @AppStorage("careerPath") private var career = CareerPath.exploring.rawValue
    @AppStorage("companionName") private var companionName = "Larpy"
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Larpy Plus") {
                    Button { showPlus = true } label: {
                        HStack {
                            Text(plus.active ? "Plus is active" : "Explore Larpy Plus")
                            Spacer(); Image(systemName: plus.active ? "checkmark.seal.fill" : "chevron.right")
                        }.frame(minHeight: 44)
                    }
                    Button("Restore purchases") { Task { await plus.restore() } }.disabled(plus.busy)
                    if plus.active { Link("Manage or cancel subscription", destination: LarpyLinks.subscriptions) }
                    if let message = plus.message { Text(message).font(.footnote).foregroundStyle(.secondary) }
                }
                Section("Your journey") {
                    NavigationLink { JourneyProfileView(prefs: prefs, store: store, loads: loads) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your path")
                            Text((CareerPath(rawValue: career) ?? .exploring).title).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink("Followers & platform skins") { AudienceView(store: store) }
                    NavigationLink("Connections") { ConnectionsView(store: store, loads: loads) }
                    NavigationLink("Larpy on your Home & Lock Screen") { WidgetGuideView() }
                }
                Section("Larpy’s personality") {
                    Picker("Personality", selection: $personality) {
                        ForEach(CompanionPersonality.allCases) { item in Text(item.title).tag(item.rawValue) }
                    }
                    Text((CompanionPersonality(rawValue: personality) ?? .buddy).detail).font(.footnote).foregroundStyle(.secondary)
                }
                Section("Preferences") {
                    TextField("Your companion’s name", text: $companionName)
                        .onChange(of: companionName) { _, value in companionName = String(value.prefix(24)) }
                    Toggle("Dark appearance", isOn: $prefs.isDark)
                    Toggle("Activity reminders", isOn: $prefs.notificationsOn)
                        .onChange(of: prefs.notificationsOn) {
                            if prefs.notificationsOn { UserDefaults.standard.set(0, forKey: "pingUnanswered"); LarpyReminders.requestAuthorization() }
                            LarpyReminders.refresh(store: store, agents: agents)
                        }
                    TextField("Your name (optional)", text: $prefs.name)
                        .onChange(of: prefs.name) { _, value in prefs.name = String(value.prefix(60)) }
                }
                Section("About your data") {
                    NavigationLink("Privacy policy") { LarpyPrivacyView() }
                    Link("Privacy policy on the web", destination: LarpyLinks.privacy)
                    Link("Terms of Use (EULA)", destination: LarpyLinks.terms)
                    Link("Help & support", destination: LarpyLinks.support)
                    Text("Activities and screenshots stay on this phone. The optional Mac companion shares daily token totals through your iCloud Drive. Health access reads workouts only.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Follower screenshots are self-reported. Larpy cannot authenticate an audience or verify that a photo proves an activity.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Disconnect Health, calendar or the Mac in Connections. Remove follower counts and screenshots from Followers & platform skins.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Text("Logging, focus, app blocking, timed breaks, saved history and earned outfits stay free. Plus adds detailed weekly reviews. Optional seasonal outfits are separate purchases.").font(.footnote)
                    Text("Original Larpy outfits. No affiliation with or endorsement by LinkedIn, Instagram, X or their founders.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .tint(Palette.gold)
                .sheet(isPresented: $showPlus) { LarpyPlusView() }
        }
    }
}

struct LarpyPrivacyView: View {
    var body: some View {
        List {
            Section("Stored on your device") {
                Text("Larpy stores your chosen path, optional name, activity history, outfit choices and any photos you choose. The activity and screenshot folder is excluded from iCloud backup because it may contain workout information. Deleting the app removes this local activity folder; Larpy does not provide account recovery or cloud history sync.")
            }
            Section("Optional workout access") {
                Text("With your permission, Larpy reads completed workouts from Apple Health to count active days. It stores workout identifiers, dates, durations and their source on this device. It does not request heart rate or medical records, write workouts, or use Health data for advertising. Disconnect Health in Workouts & AI usage, or revoke access in Apple's Health settings. Disconnecting stops future imports; existing receipts remain in your history.")
            }
            Section("Optional calendar access") {
                Text("Connected calendar event titles and times appear on this device only. Larpy does not upload events or treat plans as completed activity. Disconnect in Connections to stop reading. Apple’s event editor lets you confirm a new focus block without granting full access.")
            }
            Section("Voice notes") {
                Text("When you tap Say it instead, Larpy asks for microphone and speech permission. It requires on-device speech recognition, never saves audio, and puts the transcription into an editable draft. If local recognition is unavailable, you can type instead. Your saved note follows the same evidence rules as typed text.")
            }
            Section("Focus and Screen Time") {
                Text("You can choose apps and websites to shield during a focus block. Apple keeps these selections as private tokens. Larpy uses them only for the block you start, then clears its shield at the end. You can stop early in Larpy or revoke Screen Time access in iPhone Settings. Larpy does not read messages, screen contents or browsing history. Its shield shows your chosen task, so avoid sensitive details if others can see your phone.")
                Text("A timed break needs a reason and a 5-, 10- or 15-minute limit. It temporarily allows all your selected distractions, not just one app. The clock starts immediately. Break reasons and times are saved locally with the focus session and are not sent to friends. Break time is excluded from recorded focus minutes. Apple’s Screen Time service schedules blocking to resume; you can also return early in Larpy.")
                Text("Completed focus timers are stored on this device. Widgets show today's recorded focus time, not verified work time, alongside your activity checkmarks. Timer completion does not earn a Work day. Remove a widget if you do not want your activity status visible on your Lock Screen.")
            }
            Section("Optional AI usage") {
                Text("The Mac companion reads local Codex and Claude Code usage counters and writes daily totals into an iCloud Drive folder you choose. It does not export conversations, prompts, code or provider keys. This is not a connection to your ChatGPT or Claude web account. You can disconnect the folder in Settings. Manual and imported totals can overlap and are labelled separately on Today.")
            }
            Section("Follower evidence") {
                Text("Follower tracking currently uses a profile name, a count you enter and a screenshot you select. These are self-reported and are not authenticated by a social platform. Larpy does not request social passwords or automatically read your accounts in this version. Removing a tracker removes its current count and screenshot. Earned skins remain.")
            }
            Section("Sharing and support") {
                Text("Larpy does not include advertising or analytics SDKs. If you choose to share a card, Apple presents a share sheet and you choose its destination. Only send information you want that recipient to see. For privacy questions, use the developer contact listed on Larpy's App Store page when available.")
                Link("Contact Larpy support", destination: LarpyLinks.support)
            }
            Section("Purchases and weekly reflections") {
                Text("Apple processes purchases. Larpy uses verified transaction and expiry information to provide Plus; it does not receive payment card details. Weekly reflections stay on this device, remain accessible without Plus and do not earn activity credit.")
                Link("Read the full privacy policy", destination: LarpyLinks.privacy)
            }
        }.navigationTitle("Privacy policy").navigationBarTitleDisplayMode(.inline)
    }
}

struct FriendSnapshotDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct FriendComparisonView: View {
    @Environment(\.dynamicTypeSize) private var textSize
    @ObservedObject var store: ProofStore
    let name: String
    @AppStorage("larpyPeerID") private var peerID = ""
    @AppStorage("friendSnapshot") private var friendData = Data()
    @State private var exporting = false
    @State private var importing = false
    @State private var prepared: FriendSnapshotDocument?
    @State private var message: String?
    @State private var includeFollowers = false
    @State private var includeTokens = false
    @Environment(\.dismiss) private var dismiss
    private var friend: FriendSnapshot? { guard let item = try? JSONDecoder().decode(FriendSnapshot.self, from: friendData), item.valid() else { return nil }; return item }
    private func snapshot() -> FriendSnapshot {
        let cal = LarpyTime.cal
        let end = cal.startOfDay(for: .now)
        let start = cal.date(byAdding: .day, value: -7, to: end)!
        let startKey = ActivityCalendarRules.key(start, calendar: cal)
        let endKey = ActivityCalendarRules.key(cal.date(byAdding: .day, value: -1, to: end)!, calendar: cal)
        let week = store.logs.filter {
            let key = $0.progressDay ?? ActivityCalendarRules.key($0.createdAt, calendar: cal)
            return key >= startKey && key <= endKey
        }
        var counts: [String: Int] = [:]
        for lane in QuestKind.allCases { counts[lane.rawValue] = ProgressRules.days(lane, logs: week, calendar: cal) }
        var tokens: [String: Int] = [:]
        if includeTokens {
            for source in ["codex", "claude-code"] {
                let matching = week.filter { $0.source == source && $0.proofKind == .number }
                if !matching.isEmpty { tokens[source] = matching.compactMap { Int($0.value.split(separator: " ").first ?? "") }.reduce(0, +) }
            }
        }
        let audience = includeFollowers ? RewardLedger.audience.filter { $0.valid && $0.recordedAt <= Date.now } : []
        return FriendSnapshot(id: UUID(uuidString: peerID) ?? UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Larpy" : String(name.prefix(60)), generatedAt: .now,
                              weekStart: startKey, weekEnd: endKey, days: counts,
                              followers: Dictionary(uniqueKeysWithValues: audience.map { ($0.platform.rawValue, $0.count) }),
                              followerDates: Dictionary(uniqueKeysWithValues: audience.map { ($0.platform.rawValue, $0.recordedAt) }), tokens: tokens)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("A little friendly\ncompetition.").font(.system(.largeTitle, design: .serif))
                    Text("Swap snapshots with a friend. Real saved counts, with their date attached. No public ranking.").foregroundStyle(Palette.muted)
                    if let friend {
                        comparison(friend)
                        Button("Remove friend snapshot", role: .destructive) { friendData = Data() }.frame(minHeight: 44)
                    } else {
                        Text("No snapshot from a friend yet.").font(.headline)
                        Text("Import the JSON file they export from this screen. A missing number stays unknown, never zero.").font(.subheadline).foregroundStyle(Palette.muted)
                    }
                    Button { importing = true } label: { Label("Import friend’s snapshot", systemImage: "square.and.arrow.down").frame(minHeight: 44) }
                    Divider()
                    Text("Choose what you share.").font(.title2.weight(.semibold))
                    Text("Activity-day totals for the last 7 completed days are included. Photos, links, calendar events and activity notes are never included.").font(.footnote).foregroundStyle(Palette.muted)
                    Toggle("Include follower counts", isOn: $includeFollowers)
                    Toggle("Include synced AI token totals", isOn: $includeTokens)
                    let mine = snapshot()
                    Text("Preview · \(mine.weekStart) to \(mine.weekEnd) · Europe/Dublin").font(.caption).foregroundStyle(Palette.muted)
                    ForEach(QuestKind.allCases) { lane in row(lane.title + " days", mine.days[lane.rawValue], nil, paired: false) }
                    if includeFollowers {
                        ForEach(AudiencePlatform.allCases) { platform in row(platform.title + " followers", mine.followers[platform.rawValue], nil, paired: false) }
                    }
                    if includeTokens {
                        ForEach(["codex", "claude-code"], id: \.self) { source in row(source == "codex" ? "Codex tokens" : "Claude Code tokens", mine.tokens[source], nil, paired: false) }
                    }
                    Button {
                        do { prepared = FriendSnapshotDocument(data: try JSONEncoder().encode(mine)); exporting = true }
                        catch { message = "Couldn’t prepare a snapshot. Try again." }
                    } label: { Label("Export my snapshot", systemImage: "square.and.arrow.up").font(.headline).frame(maxWidth: .infinity, minHeight: 52) }
                        .buttonStyle(.borderedProminent).tint(Palette.gold).foregroundStyle(Palette.ink)
                    Text("Save the file, then share it with your friend. Snapshots are self-reported and can be edited; they don’t verify identity or unlock skins. Token use is not a measure of quality or effort.")
                        .font(.footnote).foregroundStyle(Palette.muted)
                    if let message { Text(message).font(.subheadline) }
                }.padding(24).frame(maxWidth: 550).frame(maxWidth: .infinity)
            }.background(Palette.bg).foregroundStyle(Palette.text).navigationTitle("With a friend").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .onAppear {
            if UUID(uuidString: peerID) == nil { peerID = UUID().uuidString }
            if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                try? FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
            }
        }
        .fileExporter(isPresented: $exporting, document: prepared, contentType: .json, defaultFilename: "Larpy-snapshot") { result in
            if case .success = result { message = "Snapshot saved. Share only with someone you choose." }
            else { message = "Snapshot wasn’t exported." }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get(); let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? Int.max) < 100_000 else { message = "That file is too large for a Larpy snapshot."; return }
                let data = try Data(contentsOf: url)
                let item = try JSONDecoder().decode(FriendSnapshot.self, from: data)
                guard item.valid(), item.id.uuidString != peerID else { message = "Choose a valid snapshot from someone else."; return }
                friendData = data; message = "Imported a snapshot. It doesn’t update automatically."
            } catch { message = "Couldn’t import that snapshot. Ask your friend to export it again." }
        }
    }
    @ViewBuilder private func comparison(_ other: FriendSnapshot) -> some View {
        let mine = snapshot()
        VStack(alignment: .leading, spacing: 14) {
            Text(other.name).font(.title2.weight(.semibold))
            Text("Shared snapshot · \(other.generatedAt.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(Palette.muted)
            Text("\(other.weekStart) to \(other.weekEnd) · Europe/Dublin").font(.caption)
            HStack { Text("Saved totals"); Spacer(); Text("You / Friend") }.font(.caption.weight(.semibold))
            if mine.weekStart == other.weekStart && mine.weekEnd == other.weekEnd {
                ForEach(QuestKind.allCases) { lane in row(lane.title + " days", mine.days[lane.rawValue], other.days[lane.rawValue]) }
                if includeTokens {
                    ForEach(["codex", "claude-code"], id: \.self) { source in row(source == "codex" ? "Codex tokens" : "Claude Code tokens", mine.tokens[source], other.tokens[source]) }
                }
            } else { Text("Different weeks. Import a new snapshot to compare activity and token totals fairly.").font(.subheadline).foregroundStyle(Palette.muted) }
            if includeFollowers {
                ForEach(AudiencePlatform.allCases) { platform in
                    row(platform.title + " followers", mine.followers[platform.rawValue], other.followers[platform.rawValue])
                    if let date = other.followerDates[platform.rawValue] { Text("Friend’s count entered \(date.formatted(date: .abbreviated, time: .omitted))").font(.caption2).foregroundStyle(Palette.muted) }
                }
            }
            Text("— means not shared. Follower counts are separate snapshots, not live account readings.").font(.caption).foregroundStyle(Palette.muted)
        }.padding(18).background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
    }
    private func row(_ title: String, _ mine: Int?, _ theirs: Int?, paired: Bool = true) -> some View {
        Group {
            if textSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title).font(.headline)
                    if paired {
                        Text("You").font(.caption).foregroundStyle(Palette.muted)
                        Text(mine?.formatted() ?? "—").font(.subheadline.weight(.semibold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                        Text("Friend").font(.caption).foregroundStyle(Palette.muted)
                        Text(theirs?.formatted() ?? "—").font(.subheadline.weight(.semibold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                    } else {
                        Text(mine?.formatted() ?? "—").font(.subheadline.weight(.semibold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).font(.subheadline)
                    Spacer(minLength: 12)
                    Text(paired ? "\(mine?.formatted() ?? "—") / \(theirs?.formatted() ?? "—")" : mine?.formatted() ?? "—")
                        .font(.subheadline.weight(.semibold)).monospacedDigit().multilineTextAlignment(.trailing)
                }
            }
        }.accessibilityElement(children: .combine)
    }
}
