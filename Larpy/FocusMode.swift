import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity
import WidgetKit

@MainActor
final class FocusModel: ObservableObject {
    static let shared = FocusModel()
    @Published private(set) var session: FocusSession?
    @Published private(set) var finished: FocusSession?
    @Published private(set) var authorized = false
    @Published private(set) var breakRequested = false
    @Published var message: String?
    @Published var selection = FamilyActivitySelection() {
        didSet {
            if let data = try? JSONEncoder().encode(selection) { defaults.set(data, forKey: FocusStorage.selectionKey) }
        }
    }
    private let defaults = FocusStorage.shared ?? .standard
    private let settings = ManagedSettingsStore(named: .init(FocusStorage.storeName))
    private let center = DeviceActivityCenter()
    var selectionCount: Int { selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count }
    var readyToProtect: Bool { authorized && selectionCount > 0 }
    var quickMinutes: Int { let value = defaults.integer(forKey: "focus.minutes"); return [15, 25, 50].contains(value) ? value : 25 }
    func quickStart(task: String) -> Bool { start(task: task.isEmpty ? "Make progress on my next step" : task, minutes: quickMinutes, blocking: true) }

    private init() {
        if let data = defaults.data(forKey: FocusStorage.selectionKey), let value = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) { selection = value }
        refresh()
    }

    func authorize() async {
        message = nil
        #if targetEnvironment(simulator)
        message = "App blocking needs a physical iPhone with Screen Time enabled. You can use the focus timer here."
        #else
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorized = AuthorizationCenter.shared.authorizationStatus == .approved
            if !authorized { message = "Screen Time wasn’t enabled. You can still use the timer." }
        } catch { message = "Screen Time couldn’t be enabled. This build needs Apple’s Family Controls capability and your permission. The timer still works." }
        #endif
    }

    @discardableResult
    func start(task: String, minutes: Int, blocking: Bool) -> Bool {
        message = nil; refresh()
        guard session == nil else { message = "End your current focus block first."; return false }
        let title = task.trimmingCharacters(in: .whitespacesAndNewlines)
        let next = FocusSession(task: title, startedAt: .now, endsAt: Date.now.addingTimeInterval(Double(minutes * 60)), blocksDistractions: blocking)
        guard next.valid else { message = "Name one thing to finish and choose 15–60 minutes."; return false }
        if blocking {
            guard authorized, selectionCount > 0 else { message = "Enable Screen Time and choose your distractions first."; return false }
            guard FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: FocusStorage.group) != nil else {
                message = "Blocking is unavailable in this build. The shared Screen Time container needs signing. Use the timer for now."; return false
            }
            let cal = Calendar.current
            let parts: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
            let schedule = DeviceActivitySchedule(intervalStart: cal.dateComponents(parts, from: next.startedAt), intervalEnd: cal.dateComponents(parts, from: next.endsAt), repeats: false)
            do { try center.startMonitoring(.init(next.activityName), during: schedule) }
            catch { message = "Couldn’t schedule app blocking. Nothing was blocked. Try again or turn off blocking."; return false }
        }
        defaults.set(UserDefaults.standard.string(forKey: "companionPersonality") ?? "buddy", forKey: "focus.personality")
        defaults.set(UserDefaults.standard.string(forKey: "companionName") ?? "Larpy", forKey: "focus.name")
        defaults.set(minutes, forKey: "focus.minutes")
        defaults.removeObject(forKey: FocusStorage.breakRequestKey); breakRequested = false
        FocusStorage.write(next, key: FocusStorage.activeKey, to: defaults)
        defaults.removeObject(forKey: FocusStorage.finishedKey); finished = nil
        if blocking { applyShield() }
        session = next
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }

    func refresh() {
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        // Apple invalidates opaque app tokens when authorization is revoked.
        if !authorized && selectionCount > 0 { selection = FamilyActivitySelection() }
        session = FocusStorage.read(FocusStorage.activeKey, from: defaults)
        finished = FocusStorage.read(FocusStorage.finishedKey, from: defaults)
        breakRequested = session.map { $0.id.uuidString == defaults.string(forKey: FocusStorage.breakRequestKey) } ?? false
        if let current = session {
            if current.remaining() == 0 {
                FocusStorage.complete(current, to: defaults)
                end(); finished = current
            } else if current.blocksDistractions && (!authorized || selectionCount == 0) {
                end(); message = "Screen Time setup changed. Choose your apps again. The focus block ended; no work was logged."
            } else if current.blocksDistractions {
                if current.activeBreak() == nil { applyShield() }
                else { settings.clearAllSettings() }
            }
        } else {
            // Recover from missing/corrupt session data without stranding a shield.
            settings.clearAllSettings()
        }
    }

    private func applyShield() {
        settings.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        settings.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        settings.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        settings.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
    }

    @discardableResult
    func takeBreak(reason: String, minutes: Int) -> Bool {
        refresh(); message = nil
        guard let current = session, authorized,
              let next = current.takingBreak(reason: reason, minutes: minutes), let pause = next.activeBreak() else {
            message = "Add a short reason and choose 5, 10 or 15 minutes during protected focus."; return false
        }
        let cal = Calendar.current, parts: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(intervalStart: cal.dateComponents(parts, from: pause.startedAt),
            intervalEnd: cal.dateComponents(parts, from: pause.monitorEnd), repeats: false,
            warningTime: pause.warningSeconds > 0 ? DateComponents(second: pause.warningSeconds) : nil)
        // Register the background re-block before allowing any access. Failure stays blocked.
        do { try center.startMonitoring(.init(pause.activityName), during: schedule) }
        catch { message = "Couldn’t schedule this break safely. Your apps are still blocked. Try again."; return false }
        FocusStorage.write(next, key: FocusStorage.activeKey, to: defaults)
        defaults.removeObject(forKey: FocusStorage.breakRequestKey); breakRequested = false
        session = next
        settings.clearAllSettings()
        WidgetCenter.shared.reloadAllTimelines()
        return true
    }

    func resumeFocus() {
        guard let current = session, let pause = current.activeBreak() else { refresh(); return }
        let resumed = current.resuming()
        FocusStorage.write(resumed, key: FocusStorage.activeKey, to: defaults)
        session = resumed; applyShield()
        center.stopMonitoring([.init(pause.activityName)])
        WidgetCenter.shared.reloadAllTimelines()
    }

    func dismissBreakRequest() { defaults.removeObject(forKey: FocusStorage.breakRequestKey); breakRequested = false }

    func end() {
        let current = session
        // Remove before stopping monitoring so a late extension callback cannot finish a cancelled block.
        defaults.removeObject(forKey: FocusStorage.activeKey)
        defaults.removeObject(forKey: FocusStorage.breakRequestKey); breakRequested = false
        session = nil
        settings.clearAllSettings()
        if let current, current.blocksDistractions {
            center.stopMonitoring([.init(current.activityName)] + (current.breaks ?? []).map { .init($0.activityName) })
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    func dismissFinished() { finished = nil; defaults.removeObject(forKey: FocusStorage.finishedKey) }
}

struct FocusModeView: View {
    @ObservedObject var model: FocusModel
    var initialTask = ""
    let logWork: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var task = ""
    @State private var minutes = 25
    @State private var picker = false
    @State private var permissionPending = false
    @State private var requestingBreak = false
    @State private var reason = ""
    @State private var breakMinutes = 5
    @State private var endConfirmation = false
    private var plannedTask: String {
        let trimmed = task.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Make progress on my next step" : trimmed
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let current = model.session { active(current) }
                    else if let finished = model.finished {
                        Text("Time’s up. What did you finish?").font(.system(.largeTitle, design: .serif))
                        Text(finished.task).foregroundStyle(Palette.muted)
                        Button("Attach your Work proof") { logWork(finished.task); dismiss() }.buttonStyle(FocusPrimaryStyle())
                        Button("Nothing to log yet") { model.dismissFinished() }.frame(minHeight: 44)
                        Text("No activity is awarded until you add proof.").font(.footnote).foregroundStyle(Palette.muted)
                    } else { setup }
                    if let message = model.message { Text(message).font(.subheadline).foregroundStyle(Palette.muted).accessibilityLabel("Focus status: \(message)") }
                }.foregroundStyle(Palette.text).padding(24).frame(maxWidth: 560).frame(maxWidth: .infinity)
            }.background(Palette.bg).navigationTitle("Focus with Larpy").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }.familyActivityPicker(isPresented: $picker, selection: $model.selection)
            .onAppear {
                model.refresh(); minutes = model.quickMinutes
                if task.isEmpty { task = initialTask }
                requestingBreak = model.breakRequested
            }
            .onChange(of: model.breakRequested) { _, requested in if requested { requestingBreak = true } }
            .onChange(of: scenePhase) { _, phase in if phase == .active { model.refresh() } }
            .confirmationDialog("End this focus session?", isPresented: $endConfirmation, titleVisibility: .visible) {
                Button("End focus and unblock apps", role: .destructive) { model.end(); requestingBreak = false }
                Button("Keep focusing", role: .cancel) { }
            } message: { Text("This cancels the timer and any break. No Work progress is awarded.") }
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(model.readyToProtect ? "One tap. A little more focus." : "Let me guard your attention.")
                .font(.system(.largeTitle, design: .serif))
            Text(model.readyToProtect ? "Your distractions are saved. Start here, or use the Focus button on Today." : "Choose TikTok, Instagram and Snapchat once. I’ll remember them for every focus session.")
                .foregroundStyle(Palette.muted)
            if !model.authorized {
                Button(permissionPending ? "Waiting for Apple…" : "Set up app blocking") {
                    permissionPending = true
                    Task { await model.authorize(); permissionPending = false; if model.authorized { picker = true } }
                }.buttonStyle(FocusPrimaryStyle()).disabled(permissionPending)
                Text("Apple will ask for Screen Time permission, then you choose the apps. Larpy can’t select them for you.")
                    .font(.footnote).foregroundStyle(Palette.muted)
            } else {
                Button { picker = true } label: {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                        Text(model.selectionCount == 0 ? "Choose TikTok, Instagram & Snapchat" : "\(model.selectionCount) selected · change apps")
                        Spacer(); Image(systemName: "chevron.right")
                    }.frame(minHeight: 48)
                }.buttonStyle(.plain)
            }
            Picker("Focus duration", selection: $minutes) {
                Text("15 min").tag(15); Text("25 min").tag(25); Text("50 min").tag(50)
            }.pickerStyle(.segmented)
            DisclosureGroup("Name your next step (optional)") {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Finish the edit, send the proposal…", text: $task, axis: .vertical)
                        .textFieldStyle(.roundedBorder).lineLimit(1...3)
                        .onChange(of: task) { _, value in task = String(value.prefix(140)) }
                    VoiceNoteButton(text: $task)
                }.padding(.top, 12)
            }
            if !task.isEmpty { Text(task).font(.subheadline).foregroundStyle(Palette.muted) }
            if model.readyToProtect {
                Button("Start \(minutes)-minute protected focus") {
                    if model.start(task: plannedTask, minutes: minutes, blocking: true) { dismiss() }
                }.buttonStyle(FocusPrimaryStyle())
            }
            Text("App blocking and timed breaks are free. No subscription is required.").font(.footnote).foregroundStyle(Palette.muted)
            Text("Blocked apps show Larpy. To take a timed break, return here, give a reason and choose how long. Breaks don’t count as focus time.")
                .font(.footnote).foregroundStyle(Palette.muted)
            VStack(alignment: .leading, spacing: 6) {
                Button("Start free timer · \(minutes) min") {
                    if model.start(task: plannedTask, minutes: minutes, blocking: false) { dismiss() }
                }.frame(minHeight: 48)
                Text("Apps stay available. This does not enable protection.").font(.footnote).foregroundStyle(Palette.muted)
            }.tint(Palette.text)
        }
    }

    @ViewBuilder private func active(_ current: FocusSession) -> some View {
        if let pause = current.activeBreak() {
            Text("A little break. Then back to it.").font(.system(.largeTitle, design: .serif))
            countdown(to: pause.endsAt)
            Text(pause.reason).font(.title3)
            Text("Your selected apps are temporarily available. Blocking resumes when this break ends, while focus is still running.")
                .foregroundStyle(Palette.muted)
            Text("Break ends at \(pause.endsAt.formatted(date: .omitted, time: .shortened)). Your focus session still ends at \(current.endsAt.formatted(date: .omitted, time: .shortened)).")
                .font(.footnote).foregroundStyle(Palette.muted)
            Button("I’m back · block apps now") { model.resumeFocus(); requestingBreak = false }.buttonStyle(FocusPrimaryStyle())
        } else if requestingBreak && current.blocksDistractions {
            Text("What do you need a moment for?").font(.system(.largeTitle, design: .serif))
            Text("One reason. A clear finish time. Then we get back to your next step.").foregroundStyle(Palette.muted)
            TextField("Reply to a friend, post my finished video…", text: $reason, axis: .vertical)
                .textFieldStyle(.roundedBorder).lineLimit(2...4)
                .onChange(of: reason) { _, value in reason = String(value.prefix(140)) }
                .accessibilityLabel("Reason for the break")
            Picker("Break duration", selection: $breakMinutes) {
                Text("5 min").tag(5); Text("10 min").tag(10); Text("15 min").tag(15)
            }.pickerStyle(.segmented)
            Text("This allows all your selected distractions for up to \(breakMinutes) minutes, or until your focus session ends. The clock starts immediately. Your reason stays on this device.")
                .font(.footnote).foregroundStyle(Palette.muted)
            Button("Allow a \(breakMinutes)-minute break") {
                if model.takeBreak(reason: reason, minutes: breakMinutes) { reason = ""; requestingBreak = false }
            }.buttonStyle(FocusPrimaryStyle()).disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
            Button("Actually, back to focus") { requestingBreak = false; model.dismissBreakRequest() }.frame(minHeight: 44)
        } else {
            Text("I’m keeping your place.").font(.system(.largeTitle, design: .serif))
            Text(current.task).font(.title3)
            countdown(to: current.endsAt)
            Label(current.blocksDistractions ? "Your distractions are blocked" : "Timer only · apps are available", systemImage: current.blocksDistractions ? "shield.lefthalf.filled" : "timer")
                .font(.subheadline)
            if current.blocksDistractions {
                Button("Request a short break") { requestingBreak = true }.buttonStyle(FocusPrimaryStyle())
            }
            Button("Add my Work proof") { logWork(current.task); dismiss() }.frame(minHeight: 48)
            Text("Time alone doesn’t earn XP. Attach what you made when you’re done.").font(.footnote).foregroundStyle(Palette.muted)
        }
        Button("End focus session") { endConfirmation = true }.font(.footnote).foregroundStyle(Palette.muted).frame(minHeight: 44)
    }

    private func countdown(to end: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(ceil(end.timeIntervalSince(context.date))))
            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                .font(.system(size: 60, weight: .medium, design: .rounded)).monospacedDigit()
                .onChange(of: remaining) { _, value in if value == 0 { model.refresh() } }
        }
    }
}

struct FocusPrimaryStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, minHeight: 54).padding(.horizontal, 14)
            .background(Palette.gold.opacity(enabled ? 1 : 0.3), in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
