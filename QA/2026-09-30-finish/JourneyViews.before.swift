import SwiftUI
import PhotosUI

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
            let legacy = Set(FounderLook.all.prefix(4 + historical.count).map(\.id))
                .union(historical.compactMap { FounderLook.canonicalID($0.founderID) })
            d.set(Array(legacy), forKey: "earnedSkins.v1")
        }
        d.set(true, forKey: "milestoneMigration.v1")
    }
    static func unlocked(_ logs: [ProofLog]) -> Set<String> {
        let d = UserDefaults.standard
        let previous = Set(d.stringArray(forKey: "earnedSkins.v1") ?? [])
        let earned = ProgressRules.earned(logs: logs, audience: audience, calendar: LarpyTime.cal)
        let all = previous.union(earned)
        if all != previous { d.set(Array(all).sorted(), forKey: "earnedSkins.v1") }
        return all
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
                    Text("Do the activity. Earn the skin.").font(.headline).foregroundStyle(Palette.text)
                    Text("10 active days earns Training club. Days do not need to be consecutive. Follower milestones earn platform-inspired skins too.")
                        .foregroundStyle(Palette.muted)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Optional trackers").font(.headline)
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
                }.padding(24)
            }.background(Palette.bg)
                .navigationTitle(onboarding ? "Welcome to Larpy" : "Your path").navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showConnections) { ConnectionsView(store: store, loads: loads) }
                .sheet(isPresented: $showAudience) { AudienceView(store: store) }
        }
    }
}

#if DEBUG
/// Two native compositions for review. Production Today is unchanged until a direction is chosen.
struct CompanionDesignPreview: View {
    @ObservedObject var store: ProofStore
    @ObservedObject var prefs: Prefs
    @ObservedObject var loads: LoadLedger
    @ObservedObject var circle: CircleStore
    let onSettings: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var chooser = false
    @State private var active: QuestKind?
    @State private var calendar = false
    @State private var invite = false
    @State private var wardrobe = false
    @State private var hello = false
    @State private var fed = 0
    private var room: Bool { ProcessInfo.processInfo.arguments.contains("-roomPreview") }
    private var done: Int { QuestKind.allCases.filter { store.doneToday($0) }.count }
    private var look: FounderLook { FounderLook.find(CharacterStyle.lookID(logs: store.logs, selected: prefs.selectedLookID)) ?? FounderLook.all[0] }
    private var greeting: String {
        if hello { return "Hey. I'm glad it's you." }
        if done == 3 { return "Look at us go." }
        if done > 0 { return "A little more you, every day." }
        if LifeEngine.stats(store.logs).emptyStreak > 0 { return "Glad you're back." }
        return "What will we do today?"
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
                if room { roomHome } else { openHome }
                Button { chooser = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus").font(.system(size: 20, weight: .semibold))
                        Text(done == 3 ? "Add another moment" : "Log activity").multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    }.font(.headline).foregroundStyle(Palette.ink)
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Palette.gold, in: Capsule())
                }.buttonStyle(.plain).padding(.top, 16)
                Text(done == 0 ? "Move. Make something. Learn something." : "\(done) of 3 activities logged today")
                    .font(.footnote).foregroundStyle(Palette.muted).padding(.top, 10)
                    .fixedSize(horizontal: false, vertical: true)
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
                Text("Design preview · \(room ? "B / Larpy's room" : "A / Your companion")")
                    .font(.caption2).foregroundStyle(Palette.muted).padding(.top, 12)
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
            .sheet(isPresented: $chooser) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("One small thing counts.").font(.system(.title2, design: .serif))
                            ForEach(QuestKind.allCases) { lane in
                                Button {
                                    chooser = false
                                    // Present the receipt form after the chooser has dismissed.
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { active = lane }
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: lane == .body ? "figure.run" : lane == .work ? "hammer" : "book").font(.system(size: 22)).frame(width: 28)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(lane == .body ? "Body" : lane.title).font(.headline)
                                            Text(lane == .body ? "A workout or a photo" : lane == .work ? "A link or photo of finished work" : "A useful idea in your own words").font(.subheadline).foregroundStyle(Palette.muted)
                                        }
                                        Spacer(); Image(systemName: store.doneToday(lane) ? "checkmark.circle.fill" : "plus").font(.system(size: 20))
                                    }.foregroundStyle(Palette.text).padding(.vertical, 18).contentShape(Rectangle())
                                }.buttonStyle(.plain)
                                Divider()
                            }
                        }.padding(24)
                    }.background(Palette.bg).navigationTitle("Log activity").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { chooser = false } } }
                }.presentationDetents(textSize.isAccessibilitySize ? [.large] : [.medium, .large])
            }
            .sheet(item: $active) { lane in LogSheet(quest: lane, store: store, loads: loads) }
            .sheet(isPresented: $calendar) { CompanionCalendarPreview(store: store) }
            .sheet(isPresented: $invite) { CompanionInvitePreview(circle: circle, prefs: prefs) }
            .sheet(isPresented: $wardrobe) { WardrobeView(store: store, prefs: prefs) }
            .onChange(of: store.logs.first?.id) { _, _ in fed += 1; hello = false }
            .onAppear {
                if ProcessInfo.processInfo.arguments.contains("-previewCalendar") { calendar = true }
            }
    }
    private var openHome: some View {
        VStack(spacing: 0) {
            Text(greeting).font(.system(.title2, design: .serif).weight(.medium))
                .multilineTextAlignment(.center).foregroundStyle(Palette.text).padding(.top, 12)
            ZStack(alignment: .bottom) {
                Ellipse().fill(Palette.line.opacity(0.6)).frame(width: 170, height: 16).padding(.bottom, 20)
                character(width: textSize.isAccessibilitySize ? 180 : 214, scene: false)
            }.frame(height: textSize.isAccessibilitySize ? 270 : 300)
            Button { wardrobe = true } label: {
                Label(look.styleName, systemImage: "tshirt").font(.subheadline).foregroundStyle(Palette.muted).frame(minHeight: 44)
            }.buttonStyle(.plain)
        }
    }
    private var roomHome: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(greeting).font(.system(.title2, design: .serif).weight(.medium)).foregroundStyle(Palette.text)
            ZStack(alignment: .bottomLeading) {
                character(width: 200, scene: true)
                Button { wardrobe = true } label: {
                    Label("Change look", systemImage: "tshirt").font(.subheadline.weight(.medium))
                        .foregroundStyle(Palette.ink).padding(12).background(Color(hex: 0xF5F0E6), in: Capsule())
                }.buttonStyle(.plain).padding(16)
            }.frame(height: 348)
        }.padding(.top, 12)
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
        Button { calendar = true } label: {
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

struct CompanionCalendarPreview: View {
    @ObservedObject var store: ProofStore
    @State private var month = LarpyTime.cal.dateInterval(of: .month, for: .now)!.start
    @State private var selected = Date.now
    @Environment(\.dismiss) private var dismiss
    private var cal: Calendar { LarpyTime.cal }
    private var days: [Date] {
        (cal.range(of: .day, in: .month, for: month) ?? 1..<2).compactMap { cal.date(byAdding: .day, value: $0 - 1, to: month) }
    }
    private var missed: Int { days.filter { status($0) == .missed }.count }
    private var active: Int { days.filter { if case .active = status($0) { return true }; return false }.count }
    private func status(_ day: Date) -> ActivityCalendarRules.Status { ActivityCalendarRules.status(on: day, logs: store.logs, calendar: cal) }
    private func description(_ day: Date) -> String {
        switch status(day) {
        case .beforeStart: "Before your first logged activity"
        case .future: "Still to come"
        case .open: "Today is still open"
        case .missed: "No activity logged"
        case .active(let count): "\(count) of 3 activities logged"
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Every return counts.").font(.system(.largeTitle, design: .serif))
                    Text("\(active) active · \(missed) missed").font(.title3.weight(.semibold)).monospacedDigit()
                    HStack {
                        Button { move(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel("Previous month")
                        Spacer(); Text(month.formatted(.dateTime.month(.wide).year())).font(.headline); Spacer()
                        Button { move(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }.accessibilityLabel("Next month")
                            .disabled(cal.isDate(month, equalTo: .now, toGranularity: .month))
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 12) {
                        ForEach(0..<7) { index in Text(cal.veryShortStandaloneWeekdaySymbols[(index + cal.firstWeekday - 1) % 7]).font(.caption).foregroundStyle(Palette.muted) }
                        let offset = (cal.component(.weekday, from: month) - cal.firstWeekday + 7) % 7
                        ForEach(0..<offset, id: \.self) { _ in Color.clear.frame(height: 44) }
                        ForEach(days, id: \.self) { day in
                            Button { selected = day } label: {
                                VStack(spacing: 5) {
                                    Text("\(cal.component(.day, from: day))").font(.subheadline).foregroundStyle(Palette.text)
                                    CalendarMark(status: status(day), today: cal.isDateInToday(day)).frame(width: 26, height: 26)
                                }.frame(maxWidth: .infinity, minHeight: 56)
                                    .background(cal.isDate(day, inSameDayAs: selected) ? Palette.card : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                            }.buttonStyle(.plain)
                                .accessibilityLabel("\(day.formatted(date: .complete, time: .omitted)). \(description(day))")
                                .accessibilityAddTraits(cal.isDate(day, inSameDayAs: selected) ? .isSelected : [])
                        }
                    }
                    HStack(spacing: 8) {
                        CalendarMark(status: .active(1)).frame(width: 22, height: 22); Text("Active")
                        Spacer(); CalendarMark(status: .missed).frame(width: 22, height: 22); Text("Missed")
                        Spacer(); CalendarMark(status: .open, today: true).frame(width: 22, height: 22); Text("Today")
                    }.font(.caption).foregroundStyle(Palette.muted)
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selected.formatted(date: .abbreviated, time: .omitted)).font(.headline)
                        Text(description(selected)).foregroundStyle(Palette.muted)
                        if case .active = status(selected) {
                            ForEach(QuestKind.allCases.filter { LifeEngine.laneDone(store.logs, $0, on: selected) }) { lane in
                                Label(lane == .body ? "Body" : lane.title, systemImage: "checkmark").font(.subheadline)
                            }
                        }
                    }
                    Text("Missed means no qualifying activity was logged after your first active day. Today and future days never count as missed. Your earned skins stay yours.")
                        .font(.footnote).foregroundStyle(Palette.muted)
                }.foregroundStyle(Palette.text).padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.background(Palette.bg).navigationTitle("Your calendar").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
    private func move(_ direction: Int) {
        if let next = cal.date(byAdding: .month, value: direction, to: month) { month = next; selected = next }
    }
}

private struct CompanionInvitePreview: View {
    @ObservedObject var circle: CircleStore
    @ObservedObject var prefs: Prefs
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    HStack(spacing: -12) {
                        LarpyCharacterView(life: .neutral, base: .cream, kit: .hoodie, width: 106, showScene: false, companion: true).rotationEffect(.degrees(-7))
                        LarpyCharacterView(life: .clearedPreview, base: .cream, kit: .tee, width: 106, showScene: false, companion: true).rotationEffect(.degrees(7))
                    }.accessibilityHidden(true)
                    Text("A little company\ngoes a long way.").font(.system(.largeTitle, design: .serif)).multilineTextAlignment(.center)
                    Text("Invite a friend to try Larpy with you.").foregroundStyle(Palette.muted)
                    ShareLink(item: "Try Larpy with me. Let's make time for one small thing each day.\n\(circle.inviteLink(name: prefs.name, shipping: prefs.shipping).absoluteString)") {
                        Label("Invite a friend", systemImage: "square.and.arrow.up").font(.headline).foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity, minHeight: 56).background(Palette.gold, in: Capsule())
                    }
                    Text("For this test build, your friend needs Larpy installed. The invite saves a friend on their phone; activity sharing between phones is not connected yet.")
                        .font(.footnote).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    Text("Free to use. No subscription needed.").font(.caption).foregroundStyle(Palette.muted)
                }.padding(24).frame(maxWidth: 480).frame(maxWidth: .infinity)
            }.background(Palette.bg).foregroundStyle(Palette.text).navigationTitle("Together").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
#endif

struct NextSkinView: View {
    @ObservedObject var store: ProofStore
    @AppStorage(RewardLedger.audienceKey) private var audienceData = Data()
    let action: () -> Void
    private var next: SkinMilestone? {
        let unlocked = RewardLedger.unlocked(store.logs)
        return ProgressRules.skins.filter { $0.lane != nil && !unlocked.contains($0.id) }.sorted {
            Double($0.progress(logs: store.logs, audience: [], calendar: LarpyTime.cal)) / Double($0.target) >
            Double($1.progress(logs: store.logs, audience: [], calendar: LarpyTime.cal)) / Double($1.target)
        }.first
    }
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(next.map { "Next skin · \($0.title)" } ?? "Your skin collection").font(.subheadline.weight(.semibold))
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }.foregroundStyle(Palette.text)
                if let next {
                    let n = next.progress(logs: store.logs, audience: [], calendar: LarpyTime.cal)
                    ProgressView(value: Double(min(n, next.target)), total: Double(next.target)).tint(Palette.gold)
                    Text("\(n)/\(next.target) \(next.lane == .body ? "active" : next.lane == .work ? "Work" : "learning") days · no streak required")
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
    @ObservedObject var store: ProofStore
    @ObservedObject var prefs: Prefs
    @ObservedObject var loads: LoadLedger
    @ObservedObject var agents: AgentStore
    @AppStorage("careerPath") private var career = CareerPath.exploring.rawValue
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Your journey") {
                    NavigationLink { JourneyProfileView(prefs: prefs, store: store, loads: loads) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your path")
                            Text((CareerPath(rawValue: career) ?? .exploring).title).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink("Followers & platform skins") { AudienceView(store: store) }
                    NavigationLink("Workouts & AI usage") { ConnectionsView(store: store, loads: loads) }
                }
                Section("Preferences") {
                    Toggle("Dark appearance", isOn: $prefs.isDark)
                    Toggle("Activity reminders", isOn: $prefs.notificationsOn)
                        .onChange(of: prefs.notificationsOn) {
                            if prefs.notificationsOn { LarpyReminders.requestAuthorization() }
                            LarpyReminders.refresh(store: store, agents: agents)
                        }
                    TextField("Your name (optional)", text: $prefs.name)
                        .onChange(of: prefs.name) { _, value in prefs.name = String(value.prefix(60)) }
                }
                Section("About your data") {
                    NavigationLink("Privacy policy") { LarpyPrivacyView() }
                    Text("Activities and screenshots stay on this phone. The optional Mac companion shares daily token totals through your iCloud Drive. Health access reads workouts only.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Follower screenshots are self-reported. Larpy cannot authenticate an audience or verify that a photo proves an activity.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Disconnect Health or the Mac in Workouts & AI usage. Remove follower counts and screenshots from Followers & platform skins.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Text("Original Larpy outfits. No affiliation with or endorsement by LinkedIn, Instagram, X or their founders.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }.navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .tint(Palette.gold)
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
            Section("Optional AI usage") {
                Text("The Mac companion reads local Codex and Claude Code usage counters and writes daily totals into an iCloud Drive folder you choose. It does not export conversations, prompts, code or provider keys. This is not a connection to your ChatGPT or Claude web account. You can disconnect the folder in Settings. Manual and imported totals can overlap and are labelled separately on Today.")
            }
            Section("Follower evidence") {
                Text("Follower tracking currently uses a profile name, a count you enter and a screenshot you select. These are self-reported and are not authenticated by a social platform. Larpy does not request social passwords or automatically read your accounts in this version. Removing a tracker removes its current count and screenshot. Earned skins remain.")
            }
            Section("Sharing and support") {
                Text("Larpy does not include advertising or analytics SDKs. If you choose to share a card, Apple presents a share sheet and you choose its destination. Only send information you want that recipient to see. For privacy questions, use the developer contact listed on Larpy's App Store page when available.")
            }
        }.navigationTitle("Privacy policy").navigationBarTitleDisplayMode(.inline)
    }
}
