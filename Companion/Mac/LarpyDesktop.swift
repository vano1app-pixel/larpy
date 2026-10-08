import AppKit
import SwiftUI
import UserNotifications

private let ink = Color(red: 0.16, green: 0.17, blue: 0.15)
private let paper = Color(red: 0.97, green: 0.95, blue: 0.89)
private let gold = Color(red: 0.89, green: 0.71, blue: 0.32)

@MainActor
final class DesktopModel: ObservableObject {
    @Published var line = ""
    @Published var occasionalRemarks = (UserDefaults.standard.object(forKey: "occasionalRemarks") as? Bool) ?? true {
        didSet {
            UserDefaults.standard.set(occasionalRemarks, forKey: "occasionalRemarks")
            dialogue.record(line, focusing: remaining > 0)
        }
    }
    @Published var remaining = 0
    @Published var focusMinutes = 25
    @Published var completed = UserDefaults.standard.integer(forKey: "focusBlocks")
    @Published var monitoring = false
    @Published var putAppsAway = false
    @Published private(set) var annoyed = false
    @Published private(set) var detours = 0
    @Published var paused = false
    @Published var personality = UserDefaults.standard.string(forKey: "personality") ?? "Buddy" {
        didSet {
            UserDefaults.standard.set(personality, forKey: "personality")
            speak(paused ? .paused : remaining > 0 ? .focusing : .tap)
        }
    }
    @Published var watched: [String: String] = UserDefaults.standard.dictionary(forKey: "watchedApps") as? [String: String] ?? [:]
    @Published var syncEnabled = false
    @Published var syncStatus = "Connect local Codex and Claude Code counters."
    @Published var totals: [String: Int] = [:]
    @Published var notificationStatus = "Notifications are optional."
    @Published var bounce = 0
    private var end: Date?
    private var timer: Timer?
    private var distractedApp: String?
    private var distractionStarted: Date?
    private var lastNudge = Date.distantPast
    private var lastInterception = Date.distantPast
    private var syncProcess: Process?
    private var syncTimer: Timer?
    private var folder: URL?
    private var syncStarted: Date?
    private var dialogue = DesktopDialogue(previous: UserDefaults.standard.string(forKey: "lastDesktopRemark"))

    init() {
        speak(.welcome)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }
    func hello() {
        bounce += 1
        speak(paused ? .paused : remaining > 0 ? .focusing : .tap)
    }
    private func speak(_ moment: DesktopDialogue.Moment) {
        line = dialogue.next(moment, personality: personality, focusing: remaining > 0)
        UserDefaults.standard.set(line, forKey: "lastDesktopRemark")
    }
    private func say(_ message: String) {
        line = message
        dialogue.record(message, focusing: remaining > 0)
        UserDefaults.standard.set(message, forKey: "lastDesktopRemark")
    }
    func focus() {
        detours = 0; annoyed = false; lastInterception = .distantPast
        end = Date.now.addingTimeInterval(Double(focusMinutes * 60)); remaining = focusMinutes * 60
        speak(.started)
    }
    func stopFocus() { end = nil; remaining = 0; annoyed = false; speak(.stopped) }
    func tick() {
        if annoyed && Date.now.timeIntervalSince(lastInterception) > 12 { annoyed = false }
        guard !paused else { distractionStarted = nil; return }
        if let end {
            remaining = max(0, Int(ceil(end.timeIntervalSinceNow)))
            if remaining == 0 {
                self.end = nil; completed += 1
                UserDefaults.standard.set(completed, forKey: "focusBlocks")
                speak(.finished)
                bounce += 1; notify(line)
            }
        }
        if !annoyed && dialogue.isDue(enabled: occasionalRemarks, paused: paused) {
            speak(remaining > 0 ? .focusing : .idle)
        }
        // Deliberately no browser URLs, window titles, keyboard logging or screenshots.
        guard (monitoring || putAppsAway), end != nil,
              let app = NSWorkspace.shared.frontmostApplication,
              let bundle = app.bundleIdentifier, watched[bundle] != nil else {
            distractedApp = nil; distractionStarted = nil; return
        }
        if bundle != distractedApp { distractedApp = bundle; distractionStarted = .now }
        if putAppsAway, let since = distractionStarted, Date.now.timeIntervalSince(since) >= 3,
           Date.now.timeIntervalSince(lastInterception) >= 8 {
            lastInterception = .now
            if app.hide() {
                detours += 1; annoyed = true
                let name = watched[bundle] ?? "That app"
                say(personality == "Little menace" ? "\(name)? Nice try. We had a plan." : "Put \(name) away. Your one thing is waiting.")
            } else { say("Couldn’t hide that app. Close it yourself, then back to your one thing.") }
            return
        }
        guard monitoring else { return }
        guard let since = distractionStarted, Date.now.timeIntervalSince(since) >= 60,
              Date.now.timeIntervalSince(lastNudge) >= 15 * 60 else { return }
        lastNudge = .now
        let name = watched[bundle] ?? "that app"
        say(personality == "Little menace" ? "A minute in \(name). Research, or side quest?" : personality == "Coach" ? "Your focus block is running. Back to your one thing?" : "Tiny detour? Your focus block is still here.")
        notify(line)
    }
    func togglePause() {
        paused.toggle()
        if paused { stopFocus(); speak(.paused) }
        else { speak(.welcome) }
    }
    func chooseApp() {
        let panel = NSOpenPanel(); panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true; panel.canChooseDirectories = false
        panel.message = "Choose apps Larpy may nudge you about during a focus block. Browsers can also be work: choose carefully."
        if panel.runModal() == .OK {
            for url in panel.urls {
                guard let bundle = Bundle(url: url), let id = bundle.bundleIdentifier, id != Bundle.main.bundleIdentifier else { continue }
                guard !["com.apple.finder", "com.apple.systempreferences", "com.apple.loginwindow"].contains(id) else { continue }
                watched[id] = (bundle.infoDictionary?["CFBundleDisplayName"] as? String) ?? url.deletingPathExtension().lastPathComponent
            }
            UserDefaults.standard.set(watched, forKey: "watchedApps")
        }
    }
    func removeApp(_ id: String) { watched.removeValue(forKey: id); UserDefaults.standard.set(watched, forKey: "watchedApps") }
    func allowNotifications() {
        Task {
            do {
                let allowed = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                notificationStatus = allowed ? "Notifications allowed. At most one distraction nudge every 15 minutes." : "Notifications are off in System Settings. The pet still speaks on screen."
            } catch { notificationStatus = "Notifications unavailable. The pet still speaks on screen." }
        }
    }
    private func notify(_ message: String) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent(); content.title = "Larpy"; content.body = message
            try? await center.add(UNNotificationRequest(identifier: "larpy-latest-nudge", content: content, trigger: nil))
        }
    }
    func chooseSync() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false
        panel.canCreateDirectories = true; panel.prompt = "Use this folder"
        panel.message = "Choose a Larpy folder in iCloud Drive. Only daily token totals will be written here. Choose the same folder on your iPhone."
        let cloud = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
        if FileManager.default.fileExists(atPath: cloud.path) { panel.directoryURL = cloud }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        stopSync(); folder = url; syncEnabled = true
        scan()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in Task { @MainActor in self?.scan() } }
    }
    func stopSync() {
        syncTimer?.invalidate(); syncTimer = nil
        syncProcess?.terminate(); syncProcess = nil
        syncEnabled = false; totals = [:]; folder = nil
        syncStatus = "Sync stopped. Existing daily totals remain in your chosen folder."
    }
    func scan() {
        guard syncEnabled, let folder else { return }
        if let process = syncProcess, process.isRunning {
            if let started = syncStarted, Date.now.timeIntervalSince(started) > 55 {
                process.terminate(); syncProcess = nil; syncStatus = "Scan took too long. Will retry next minute."
            }
            return
        }
        guard let script = Bundle.main.url(forResource: "larpy_sync", withExtension: "py") else { syncStatus = "Usage reader missing from this build."; return }
        let process = Process(); process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python3", script.path, "--output", folder.appendingPathComponent("usage.json").path]
        process.standardOutput = FileHandle.nullDevice; process.standardError = FileHandle.nullDevice
        process.terminationHandler = { [weak self] finished in
            Task { @MainActor in
                guard let self, self.syncEnabled, self.folder == folder, self.syncProcess === finished else { return }
                self.syncProcess = nil
                guard finished.terminationStatus == 0 else {
                    self.syncStatus = "Couldn’t read local usage. Python 3 and readable Codex or Claude Code logs are required. Previous totals are preserved."; return
                }
                do {
                    let data = try Data(contentsOf: folder.appendingPathComponent("usage.json"))
                    let snapshot = try JSONDecoder().decode(UsageSnapshot.self, from: data)
                    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "Europe/Dublin")!
                    self.totals = Dictionary(grouping: snapshot.days.filter { cal.isDateInToday(Date(timeIntervalSince1970: $0.at)) }, by: \.source).mapValues { $0.reduce(0) { $0 + $1.tokens } }
                    self.syncStatus = "Updated \(Date.now.formatted(date: .omitted, time: .shortened)). Daily totals only; no conversations or keys."
                } catch { self.syncStatus = "The usage file couldn’t be read. Try syncing again." }
            }
        }
        do { syncProcess = process; syncStarted = .now; try process.run() }
        catch { syncProcess = nil; syncStatus = "Couldn’t start the usage reader. Python 3 is required for this local build." }
    }
    func shutdown() { timer?.invalidate(); stopSync() }
}
private struct UsageSnapshot: Decodable {
    struct Day: Decodable { let source: String; let at: Double; let tokens: Int }
    let days: [Day]
}

struct DesktopEgg: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.height * 0.68), control1: CGPoint(x: r.width * 0.78, y: 0), control2: CGPoint(x: r.maxX, y: r.height * 0.34))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY), control1: CGPoint(x: r.maxX, y: r.maxY), control2: CGPoint(x: r.width * 0.68, y: r.maxY))
        p.addCurve(to: CGPoint(x: 0, y: r.height * 0.68), control1: CGPoint(x: r.width * 0.32, y: r.maxY), control2: CGPoint(x: 0, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX, y: 0), control1: CGPoint(x: 0, y: r.height * 0.34), control2: CGPoint(x: r.width * 0.22, y: 0)); return p
    }
}
struct DesktopPet: View {
    @ObservedObject var model: DesktopModel
    var controls: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var touched = Date.distantPast
    var body: some View {
        VStack(spacing: 0) {
            Button { model.hello() } label: {
                Text(model.line).font(.system(size: 13, weight: .medium)).multilineTextAlignment(.center)
                    .foregroundStyle(ink).padding(12).frame(width: 210, height: 68)
                    .background(paper, in: RoundedRectangle(cornerRadius: 18))
            }.buttonStyle(.plain).help("Another little thought")
                .accessibilityLabel(model.line).accessibilityHint("Say something else")
                .padding(.top, 6)
            TimelineView(.animation(minimumInterval: 1 / 24, paused: reduceMotion || model.paused)) { context in
                let t = reduceMotion || model.paused ? 6 : context.date.timeIntervalSinceReferenceDate
                let phase = t.truncatingRemainder(dividingBy: 12)
                let walk = phase < 4 && !reduceMotion && !model.paused
                let wave = phase > 8 || context.date.timeIntervalSince(touched) < 1
                ZStack {
                    Ellipse().fill(.black.opacity(0.12)).frame(width: 115, height: 12).offset(y: 68)
                    actor(t: t, wave: wave)
                        .rotationEffect(.degrees(walk ? sin(t * 10) * 5 : sin(t) * 2), anchor: .bottom)
                        .offset(x: walk ? sin(phase / 4 * .pi * 2) * 21 : 0, y: walk ? -abs(sin(t * 8)) * 5 : 0)
                }.frame(width: 220, height: 165)
            }.onTapGesture { touched = .now; model.hello() }
                .accessibilityLabel("Larpy desktop companion").accessibilityAddTraits(.isButton)
                .accessibilityAction { touched = .now; model.hello() }
            Button(action: controls) {
                Label(model.remaining > 0 ? "\(model.remaining / 60):\(String(format: "%02d", model.remaining % 60)) · Focus" : "Let’s focus", systemImage: model.remaining > 0 ? "timer" : "play.fill")
                    .font(.system(size: 12, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 8)
                    .background(gold, in: Capsule()).foregroundStyle(ink)
            }.buttonStyle(.plain)
        }.frame(width: 240, height: 285)
            .contextMenu {
                Button("Open controls", action: controls)
                Button(model.paused ? "Resume" : "Pause") { model.togglePause() }
                Button("Quit Larpy") { NSApp.terminate(nil) }
            }
    }
    private func actor(t: Double, wave: Bool) -> some View {
        ZStack {
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule().fill(Color(red: 0.40, green: 0.46, blue: 0.40)).overlay(Capsule().stroke(ink, lineWidth: 1))
                    .frame(width: 17, height: 36).rotationEffect(.degrees(side * (wave ? -125 + sin(t * 12) * 12 : -25)))
                    .offset(x: side * 55, y: wave ? 8 : 30)
                Capsule().fill(ink).frame(width: 25, height: 15).offset(x: side * 28, y: 63)
            }
            DesktopEgg().fill(LinearGradient(colors: [Color(red: 1, green: 0.96, blue: 0.84), Color(red: 0.94, green: 0.84, blue: 0.67)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(DesktopEgg().stroke(ink, lineWidth: 1.3)).frame(width: 122, height: 138)
            Rectangle().fill(Color(red: 0.40, green: 0.46, blue: 0.40)).frame(width: 122, height: 52).offset(y: 49)
                .mask(DesktopEgg().frame(width: 122, height: 138))
            RoundedRectangle(cornerRadius: 5).stroke(ink.opacity(0.5), lineWidth: 1).frame(width: 35, height: 13).offset(y: 50)
            HStack(spacing: 45) { ForEach(0..<2) { _ in Ellipse().fill(Color(red: 0.9, green: 0.6, blue: 0.5).opacity(0.65)).frame(width: 22, height: 12) } }.offset(y: 9)
            HStack(spacing: 29) { ForEach(0..<2) { _ in
                Capsule().fill(ink).frame(width: 7, height: t.truncatingRemainder(dividingBy: 5) < 0.25 ? 2 : 11)
            } }.offset(y: -4)
            if model.annoyed {
                HStack(spacing: 18) {
                    Capsule().fill(ink).frame(width: 17, height: 2.5).rotationEffect(.degrees(18))
                    Capsule().fill(ink).frame(width: 17, height: 2.5).rotationEffect(.degrees(-18))
                }.offset(y: -18)
            }
            Path { p in p.move(to: CGPoint(x: 0, y: 0)); p.addQuadCurve(to: CGPoint(x: 18, y: 0), control: CGPoint(x: 9, y: model.annoyed ? -4 : 12)) }
                .stroke(ink, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 18, height: 10).offset(y: 24)
        }
    }
}

struct DesktopControls: View {
    @ObservedObject var model: DesktopModel
    var showPet: () -> Void
    var hidePet: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack { Text("A little company.\nA little more done.").font(.system(size: 30, weight: .medium, design: .serif)); Spacer() }
                Picker("Personality", selection: $model.personality) { ForEach(["Buddy", "Coach", "Little menace"], id: \.self) { Text($0) } }
                Text(model.personality == "Little menace" ? "Playful roasting is on. No invented friend stats. No attacks on your worth." : "Your companion’s tone. You can change it anytime.").font(.caption).foregroundStyle(.secondary)
                Toggle("Occasional little remarks", isOn: $model.occasionalRemarks)
                Text("A new bubble about every 75 seconds, or 3 minutes during focus. No sounds or extra notifications. Tap Larpy or his bubble for another line; Pause stops automatic remarks.").font(.caption).foregroundStyle(.secondary)
                Divider()
                Text("One thing, finished.").font(.title2.weight(.semibold))
                if model.remaining > 0 {
                    Text("\(model.remaining / 60):\(String(format: "%02d", model.remaining % 60))").font(.system(size: 46, design: .monospaced))
                    Button("End focus block") { model.stopFocus() }
                } else {
                    Picker("Minutes", selection: $model.focusMinutes) { Text("10").tag(10); Text("25").tag(25); Text("50").tag(50) }.pickerStyle(.segmented)
                    Button("Start focus block") { model.focus(); showPet() }.buttonStyle(.borderedProminent).tint(gold).disabled(model.paused)
                }
                Text("\(model.completed) timer blocks finished on this Mac. A timer isn’t proof of work; log what you made on your phone.").font(.caption).foregroundStyle(.secondary)
                Divider()
                Toggle("Nudge me in apps I choose", isOn: $model.monitoring)
                Toggle("Put distracting apps away", isOn: $model.putAppsAway)
                Text("During a focus block, hides chosen apps after 3 seconds and gives Larpy a little side-eye. Apps keep running and documents stay open. This isn’t an unbreakable lock; you can stop anytime. Off when Larpy reopens.").font(.caption).foregroundStyle(.secondary)
                if model.remaining > 0 { Text("\(model.detours) detour\(model.detours == 1 ? "" : "s") put away this block.").font(.caption) }
                Text("Only during a focus block, after 60 seconds in a chosen app. At most once every 15 minutes. App names stay on this Mac; Larpy never reads screen contents, websites or keystrokes. Off each time you reopen Larpy.").font(.caption).foregroundStyle(.secondary)
                ForEach(model.watched.keys.sorted(), id: \.self) { key in
                    HStack { Text(model.watched[key] ?? key); Spacer(); Button("Remove") { model.removeApp(key) } }
                }
                Button("Choose distracting apps…") { model.chooseApp() }
                Button("Allow notifications") { model.allowNotifications() }
                Text(model.notificationStatus).font(.caption).foregroundStyle(.secondary)
                Divider()
                Text("Your agents, counted.").font(.title2.weight(.semibold))
                Text("Codex + Claude Code").font(.headline)
                Text(model.syncStatus).font(.caption).foregroundStyle(.secondary)
                ForEach(model.totals.keys.sorted(), id: \.self) { source in
                    HStack { Text(source == "codex" ? "Codex" : "Claude Code"); Spacer(); Text("\((model.totals[source] ?? 0).formatted()) today").monospacedDigit() }
                }
                Text("Reads local usage records only after you enable it. Tokens measure usage, not effort or quality. ChatGPT website chats aren’t included. Day boundary: Europe/Dublin, matching phone sync.").font(.caption).foregroundStyle(.secondary)
                Button(model.syncEnabled ? "Choose another sync folder…" : "Enable token sync…") { model.chooseSync() }
                if model.syncEnabled { Button("Stop token sync") { model.stopSync() } }
                Divider()
                HStack { Button("Show pet", action: showPet); Button("Hide pet", action: hidePet); Spacer(); Button(model.paused ? "Resume nudges" : "Pause nudges") { model.togglePause() } }
                Text("Drag the pet to move it. Right-click for controls. This local Mac build is not yet signed for distribution.").font(.caption).foregroundStyle(.secondary)
            }.padding(28)
        }.frame(width: 490, height: 690).background(paper).foregroundStyle(ink).preferredColorScheme(.light)
    }
}

final class PetPanel: NSPanel { override var canBecomeKey: Bool { false } }
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let model = DesktopModel()
    var panel: PetPanel!
    var window: NSWindow!
    var status: NSStatusItem!
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = self
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1000, height: 700)
        panel = PetPanel(contentRect: NSRect(x: screen.maxX - 275, y: screen.minY + 30, width: 240, height: 285), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.level = .floating; panel.hidesOnDeactivate = false; panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: DesktopPet(model: model) { [weak self] in self?.openControls() })
        panel.orderFrontRegardless()
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 490, height: 690), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Larpy Desktop"; window.isReleasedWhenClosed = false; window.center()
        window.contentView = NSHostingView(rootView: DesktopControls(model: model, showPet: { [weak self] in self?.panel.orderFrontRegardless() }, hidePet: { [weak self] in self?.panel.orderOut(nil) }))
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Larpy")
        let menu = NSMenu()
        for (title, selector) in [("Open Larpy", #selector(openControls)), ("Show pet", #selector(showPet)), ("Hide pet", #selector(hidePet)), ("Pause / resume", #selector(pause)), ("Quit Larpy", #selector(quit))] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: ""); item.target = self; menu.addItem(item)
        }
        status.menu = menu
        openControls()
        // Local QA captures the real hosting views after they have appeared.
        if let index = CommandLine.arguments.firstIndex(of: "--qa-capture"), CommandLine.arguments.indices.contains(index + 1) {
            let directory = URL(fileURLWithPath: CommandLine.arguments[index + 1])
            for delay in [1.0, 2.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self else { return }
                    for (name, view) in [("pet", self.panel.contentView), ("controls", self.window.contentView)] {
                        guard let view, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { continue }
                        view.cacheDisplay(in: view.bounds, to: rep)
                        try? rep.representation(using: .png, properties: [:])?.write(to: directory.appendingPathComponent("mac-\(name)-\(Int(delay)).png"))
                    }
                }
            }
        }
    }
    @objc func openControls() { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    @objc func showPet() { panel.orderFrontRegardless() }
    @objc func hidePet() { panel.orderOut(nil) }
    @objc func pause() { model.togglePause() }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { model.shutdown() }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions { [.banner] }
}
@main
struct LarpyDesktopApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate(); app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
