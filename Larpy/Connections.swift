import SwiftUI
import HealthKit
import EventKit
import EventKitUI
import UniformTypeIdentifiers

@MainActor
final class ConnectionsStore: ObservableObject {
    private let defaults = UserDefaults.standard
    private let health = HKHealthStore()
    private var observer: HKObserverQuery?
    private var timer: Timer?
    private var readingUsage = false
    @Published var healthEnabled = UserDefaults.standard.bool(forKey: "healthEnabled")
    @Published var healthStatus = "Connect workouts from Apple Health."
    @Published var usageConnected = UserDefaults.standard.data(forKey: "usageFolderBookmark") != nil
    @Published var usageStatus = "Sync Codex and Claude Code from your Mac."
    @Published var lastUsageSync: Date?
    @Published var sourceTotals: [String: Int] = [:]
    @Published private(set) var usageSnapshot: UsageSnapshot? = {
        guard let data = UserDefaults.standard.data(forKey: "usageSnapshotCache.v1") else { return nil }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(UsageSnapshot.self, from: data)
    }()
    @Published private(set) var usageReadFailed = false
    @Published var busy = false

    func weeklyUsage(now: Date = .now) -> WeeklyUsageSummary? {
        guard usageConnected, let usageSnapshot else { return nil }
        return WeeklyUsageSummary.from(usageSnapshot, now: now)
    }

    var summary: String {
        healthEnabled || usageConnected ? "Connections & automatic activity" : "Log less. Connect your tools"
    }

    func start(store: ProofStore, loads: LoadLedger) {
        if healthEnabled { observeWorkouts(store: store) }
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self, weak store, weak loads] _ in
                Task { @MainActor in
                    guard let self, let store, let loads else { return }
                    self.refresh(store: store, loads: loads)
                }
            }
        }
        refresh(store: store, loads: loads)
    }

    func refresh(store: ProofStore, loads: LoadLedger) {
        if healthEnabled { Task { await syncWorkouts(store: store) } }
        if usageConnected { syncUsage(store: store, loads: loads) }
    }

    func connectHealth(store: ProofStore) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthStatus = "Apple Health isn't available on this device."; return
        }
        busy = true
        defer { busy = false }
        do {
            try await health.requestAuthorization(toShare: [], read: [HKObjectType.workoutType()])
            // Successful permission UI is not proof of read access; Apple keeps denials private.
            healthEnabled = true
            defaults.set(true, forKey: "healthEnabled")
            if defaults.double(forKey: "healthConnectedAt") == 0 {
                defaults.set(LarpyTime.startOfToday().timeIntervalSince1970, forKey: "healthConnectedAt")
            }
            observeWorkouts(store: store)
            await syncWorkouts(store: store)
        } catch { healthStatus = "Couldn't request workouts. Try again." }
    }

    func disconnectHealth() {
        healthEnabled = false
        defaults.set(false, forKey: "healthEnabled")
        if let observer { health.stop(observer) }
        observer = nil
        health.disableBackgroundDelivery(for: HKObjectType.workoutType()) { _, _ in }
        healthStatus = "Disconnected. Existing activities stay saved."
    }

    private func observeWorkouts(store: ProofStore) {
        guard observer == nil, HKHealthStore.isHealthDataAvailable() else { return }
        let query = HKObserverQuery(sampleType: HKObjectType.workoutType(), predicate: nil) { [weak self, weak store] _, completion, error in
            Task { @MainActor in
                defer { completion() }
                guard error == nil, let self, let store, self.healthEnabled else { return }
                await self.syncWorkouts(store: store)
            }
        }
        observer = query
        health.execute(query)
        health.enableBackgroundDelivery(for: HKObjectType.workoutType(), frequency: .immediate) { _, _ in }
    }

    private func syncWorkouts(store: ProofStore) async {
        guard healthEnabled, HKHealthStore.isHealthDataAvailable() else { return }
        let connected = defaults.double(forKey: "healthConnectedAt")
        let since = max(connected, Date().addingTimeInterval(-7 * 86_400).timeIntervalSince1970)
        let predicate = HKQuery.predicateForSamples(withStart: Date(timeIntervalSince1970: since), end: .now, options: .strictEndDate)
        do {
            let workouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit,
                                          sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { _, samples, error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: samples as? [HKWorkout] ?? []) }
                }
                health.execute(query)
            }
            guard healthEnabled else { return }
            let recorded = workouts.filter { $0.duration >= 600 && ($0.metadata?[HKMetadataKeyWasUserEntered] as? Bool) != true }
            var saved = true
            for workout in recorded {
                if !store.importWorkout(id: workout.uuid, start: workout.startDate, end: workout.endDate,
                                        seconds: Int(workout.duration), source: workout.sourceRevision.source.name) { saved = false }
            }
            healthStatus = !saved ? "A workout couldn't save. We'll retry."
                : recorded.isEmpty ? "No workouts available yet. Allow Workouts in Health and record an activity."
                : "Workouts synced. Gym & movement updates automatically."
        } catch { healthStatus = "Couldn't read workouts. Check Health access and try again." }
    }

    func connectUsage(folder: URL, store: ProofStore, loads: LoadLedger) {
        let access = folder.startAccessingSecurityScopedResource()
        defer { if access { folder.stopAccessingSecurityScopedResource() } }
        do {
            let bookmark = try folder.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            usageSnapshot = nil
            defaults.removeObject(forKey: "usageSnapshotCache.v1")
            usageReadFailed = false
            defaults.set(bookmark, forKey: "usageFolderBookmark")
            if defaults.double(forKey: "usageConnectedAt") == 0 {
                defaults.set(LarpyTime.startOfToday().timeIntervalSince1970, forKey: "usageConnectedAt")
            }
            usageConnected = true
            syncUsage(store: store, loads: loads)
        } catch { usageStatus = "Couldn't connect this folder. Choose the Larpy folder in iCloud Drive." }
    }

    func disconnectUsage() {
        defaults.removeObject(forKey: "usageFolderBookmark")
        usageConnected = false
        sourceTotals = [:]
        lastUsageSync = nil
        usageSnapshot = nil
        defaults.removeObject(forKey: "usageSnapshotCache.v1")
        usageReadFailed = false
        usageStatus = "Disconnected. Existing usage stays saved."
    }

    func syncUsage(store: ProofStore, loads: LoadLedger) {
        guard usageConnected, !readingUsage, let bookmark = defaults.data(forKey: "usageFolderBookmark") else { return }
        readingUsage = true
        Task {
            defer { readingUsage = false }
            do {
                let data = try await Task.detached(priority: .utility) {
                    var stale = false
                    let folder = try URL(resolvingBookmarkData: bookmark, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
                    let access = folder.startAccessingSecurityScopedResource()
                    defer { if access { folder.stopAccessingSecurityScopedResource() } }
                    let file = folder.appendingPathComponent("usage.json")
                    var coordinationError: NSError?
                    var result: Result<Data, Error> = .failure(CocoaError(.fileReadUnknown))
                    NSFileCoordinator().coordinate(readingItemAt: file, options: [], error: &coordinationError) { url in
                        result = Result {
                            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                            guard size <= 2_000_000 else { throw CocoaError(.fileReadTooLarge) }
                            return try Data(contentsOf: url)
                        }
                    }
                    if let coordinationError { throw coordinationError }
                    return try result.get()
                }.value
                guard usageConnected, defaults.data(forKey: "usageFolderBookmark") == bookmark else { return }
                let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .secondsSince1970
                let snapshot = try decoder.decode(UsageSnapshot.self, from: data)
                guard snapshot.version == 1, snapshot.days.count <= 200,
                      snapshot.generatedAt <= Date().addingTimeInterval(300) else { throw CocoaError(.coderReadCorrupt) }
                // iCloud can briefly present an older version. Never roll the display back to it.
                if let previous = usageSnapshot, snapshot.generatedAt < previous.generatedAt { return }
                usageSnapshot = snapshot
                defaults.set(data, forKey: "usageSnapshotCache.v1")
                usageReadFailed = false
                let connectedAt = defaults.double(forKey: "usageConnectedAt")
                let valid = snapshot.days.filter { $0.valid() && $0.at.timeIntervalSince1970 >= connectedAt }
                var saved = true
                for day in valid {
                    if store.importUsage(day) { loads.syncUsage(day) } else { saved = false }
                }
                sourceTotals = Dictionary(grouping: valid.filter { LarpyTime.cal.isDateInToday($0.at) }, by: \.source)
                    .mapValues { $0.map(\.tokens).reduce(0, +) }
                lastUsageSync = snapshot.generatedAt
                usageStatus = !saved ? "Some usage couldn't save. We'll retry."
                    : Date().timeIntervalSince(snapshot.generatedAt) > 15 * 60 ? "Waiting for your Mac. Last synced totals are saved."
                    : valid.isEmpty ? "Mac file connected. Waiting for today's agent usage."
                    : "Usage synced. Updates when Larpy is open."
            } catch {
                guard usageConnected else { return }
                usageReadFailed = true
                usageStatus = "Can't read usage yet. Run Larpy Sync on your Mac and choose its iCloud folder."
            }
        }
    }
}

struct ConnectionsView: View {
    @ObservedObject var store: ProofStore
    @ObservedObject var loads: LoadLedger
    @EnvironmentObject private var connections: ConnectionsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var calendar = CalendarConnection.shared
    @State private var pickFolder = false
    @State private var showAudience = false
    @State private var selected: String?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    connector("Codex", action: connections.usageConnected ? "Manage" : "Connect") { connectAgent("Codex") }
                    connector("Claude Code", action: connections.usageConnected ? "Manage" : "Connect") { connectAgent("Claude Code") }
                    if !connections.usageConnected {
                        Text("Turn on Mac token sync, then choose the Larpy folder once for both.")
                            .font(.caption).foregroundStyle(Palette.muted)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 12)
                    } else if connections.usageReadFailed {
                        Button("Sync needs attention →") { selected = "Codex" }
                            .font(.caption).foregroundStyle(Palette.gold).frame(minHeight: 44)
                    }
                    connector("Apple Health", action: connections.busy ? "Opening…" : connections.healthEnabled ? "Manage" : "Authorize") {
                        if connections.healthEnabled { selected = "Apple Health" }
                        else { Task { await connections.connectHealth(store: store); selected = "Apple Health" } }
                    }
                    connector("Apple Calendar", action: calendar.busy ? "Opening…" : calendar.enabled ? "Manage" : "Authorize") {
                        if calendar.enabled { selected = "Apple Calendar" }
                        else { Task { await calendar.connect(); if !calendar.enabled { selected = "Apple Calendar" } } }
                    }
                    connector("YouTube", action: "Open") { openURL(URL(string: "https://www.youtube.com/")!) }
                    connector("Social accounts", action: "Track") { showAudience = true }
                    connector("TradingView", action: "Open") { openURL(URL(string: "https://www.tradingview.com/chart/")!) }
                    DisclosureGroup("Need help?") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mac tokens: in Larpy Desktop, enable token sync and choose a Larpy folder in iCloud Drive. Connect either agent here and choose that same folder. Both use this one connection.")
                            Text("YouTube: Share → Larpy saves a link to Learnt. TradingView: add your journal screenshot or link to Work. These don't connect your accounts.")
                            Text("Social counts are tracked with screenshots, not automatic account access.")
                        }.font(.footnote).foregroundStyle(Palette.muted).padding(.top, 12)
                    }.font(.subheadline).foregroundStyle(Palette.muted).tint(Palette.muted).padding(.top, 24)
                }.padding(.horizontal, 24).padding(.top, 12)
            }.background(Palette.bg)
                .navigationTitle("Connections").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .navigationDestination(item: $selected) { name in
                    ScrollView {
                        connectionDetails(name).padding(24).foregroundStyle(Palette.text)
                    }.background(Palette.bg).navigationTitle(name).navigationBarTitleDisplayMode(.inline)
                }
        }
        .fileImporter(isPresented: $pickFolder, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { connections.connectUsage(folder: url, store: store, loads: loads) }
        }
        .sheet(isPresented: $showAudience) { AudienceView(store: store) }
        .onAppear { calendar.refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { calendar.refresh() } }
    }

    private func connectAgent(_ name: String) {
        if connections.usageConnected { selected = name }
        else { pickFolder = true }
    }

    private func connector(_ name: String, action: String, perform: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            Button(action: perform) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) {
                        Text(name).font(.body.weight(.medium)).foregroundStyle(Palette.text).fixedSize()
                        Spacer(minLength: 12)
                        Text(action).font(.subheadline.weight(.medium)).foregroundStyle(Palette.gold).fixedSize()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(name).font(.body.weight(.medium)).foregroundStyle(Palette.text)
                        Text(action).font(.subheadline.weight(.medium)).foregroundStyle(Palette.gold)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.padding(.vertical, 20).frame(minHeight: 64).contentShape(Rectangle())
            }.buttonStyle(.plain)
                .disabled((connections.busy && name == "Apple Health") || (calendar.busy && name == "Apple Calendar"))
            Divider().overlay(Palette.line)
        }
    }

    @ViewBuilder private func connectionDetails(_ name: String) -> some View {
                VStack(alignment: .leading, spacing: 24) {
                    if name == "Apple Calendar" { CalendarPlanView() }
                    if name == "YouTube" {
                    section("YouTube & links", icon: "play.rectangle") {
                        Text("In YouTube, tap Share → More → Larpy. Tap Save to Learnt and carry on watching.")
                        Text("Your link joins today's learning when you next open Larpy.").font(.footnote).foregroundStyle(Palette.muted)
                    }
                    }
                    if name == "Codex" || name == "Claude Code" {
                        Text("Enable token sync in Larpy Desktop, then choose its Larpy folder in iCloud Drive.")
                            .font(.footnote).foregroundStyle(Palette.muted)
                        Button("Choose iCloud folder") { pickFolder = true }
                            .buttonStyle(.borderedProminent).tint(Palette.gold).foregroundStyle(Palette.ink)
                        if connections.usageConnected { Text(connections.usageStatus).font(.footnote).foregroundStyle(Palette.muted) }
                        DisclosureGroup("Usage details") {
                            VStack(alignment: .leading, spacing: 12) {
                                if let week = connections.weeklyUsage() {
                                    Text("\(week.total.formatted()) tokens this week").font(.headline)
                                    Text("Monday–Sunday, Europe/Dublin. \(week.freshness()).")
                                    ForEach(week.bySource.keys.sorted(), id: \.self) { source in
                                        Text("\(source == "codex" ? "Codex" : "Claude Code"): \(week.bySource[source, default: 0].formatted())")
                                    }
                                }
                                Text("Codex and Claude Code share one Mac connection. Only daily counts sync, never prompts or code. Updates roughly every minute while both apps are open, plus iCloud delivery time. Web chats are not included; usage is not a remaining allowance or proof of work.")
                            }.font(.footnote).foregroundStyle(Palette.muted).padding(.top, 12)
                        }.tint(Palette.muted)
                        if connections.usageConnected {
                            Button("Disconnect Mac") { connections.disconnectUsage() }.font(.subheadline).frame(minHeight: 44)
                        }
                    }
                    if name == "TradingView" {
                    section("TradingView", icon: "chart.xyaxis.line") {
                        Text("Bring your trading journal or paper-trade review into Work. A screenshot or link counts towards Work-day skins.")
                        Text("TradingView does not offer this build a personal account connection. Profit and trading volume do not unlock rewards.").font(.footnote).foregroundStyle(Palette.muted)
                        Link("Open TradingView", destination: URL(string: "https://www.tradingview.com/chart/")!).frame(minHeight: 44)
                    }
                    }
                    if name == "Apple Health" {
                    section("Gym & workouts", icon: "figure.run") {
                        Text(connections.healthStatus)
                        Text("Apple Watch and workout apps that save to Apple Health can fill Gym & movement. Larpy reads workouts only.")
                            .font(.footnote).foregroundStyle(Palette.muted)
                        Button(connections.healthEnabled ? "Check Health access" : "Connect Apple Health") {
                            Task { await connections.connectHealth(store: store) }
                        }.buttonStyle(.borderedProminent).tint(Palette.gold).foregroundStyle(Palette.ink).disabled(connections.busy)
                        if connections.healthEnabled {
                            Button("Disconnect Health") { connections.disconnectHealth() }.font(.subheadline).frame(minHeight: 44)
                        }
                        Text("Gym entry scans need support from your gym's app. Opening its QR code alone isn't a confirmed visit.")
                            .font(.footnote).foregroundStyle(Palette.muted)
                    }
                    }
                }
    }

    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon).font(.title3.weight(.semibold))
            content().font(.body)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

}

// EventKit access stays on-device. Plans never count as completed activities.
@MainActor
final class CalendarConnection: ObservableObject {
    static let shared = CalendarConnection()
    let eventStore = EKEventStore()
    @Published var enabled = UserDefaults.standard.bool(forKey: "calendarConnected")
    @Published var events: [EKEvent] = []
    @Published var status = "Make room for the person you’re becoming."
    @Published var busy = false
    private var observer: NSObjectProtocol?
    init() {
        observer = NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh()
    }
    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
    func connect() async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            enabled = granted
            UserDefaults.standard.set(granted, forKey: "calendarConnected")
            if granted { refresh() }
            else { events = []; status = "Calendar access is off. You can allow it in iPhone Settings, or just add a focus block." }
        } catch { status = "Calendar access couldn’t be requested. Try again." }
    }
    func refresh() {
        guard enabled else { events = []; return }
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            enabled = false; UserDefaults.standard.set(false, forKey: "calendarConnected"); events = []; status = "Calendar access changed. Reconnect to show your plans."; return
        }
        let now = Date.now
        let end = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        events = Array(eventStore.events(matching: eventStore.predicateForEvents(withStart: now, end: end, calendars: nil))
            .filter { $0.endDate > now }.sorted { $0.startDate < $1.startDate }.prefix(8))
        status = events.isEmpty ? "Connected. No upcoming events in the next 7 days." : "Your next 7 days. Plans aren’t completed activities."
    }
    func disconnect() {
        enabled = false; events = []; UserDefaults.standard.set(false, forKey: "calendarConnected")
        status = "Calendar disconnected. Your events haven’t been changed."
    }
}

struct CalendarPlanView: View {
    @ObservedObject private var calendar = CalendarConnection.shared
    @Environment(\.scenePhase) private var phase
    @State private var edit = false
    @State private var result: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Image(systemName: "calendar.badge.clock"); Text("Make time for it.").font(.system(.title2, design: .serif)) }
            Text(calendar.status).font(.subheadline).foregroundStyle(Palette.muted)
            if calendar.enabled {
                ForEach(Array(calendar.events.enumerated()), id: \.offset) { _, event in
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 2).fill(Palette.gold).frame(width: 3)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title ?? "Untitled event").font(.subheadline.weight(.medium))
                            Text(event.isAllDay ? event.startDate.formatted(date: .abbreviated, time: .omitted) + " · all day" : event.startDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundStyle(Palette.muted)
                        }
                    }.fixedSize(horizontal: false, vertical: true).accessibilityElement(children: .combine)
                }
                Button("Disconnect calendar") { calendar.disconnect() }.font(.subheadline).frame(minHeight: 44)
            } else {
                Text("Show upcoming events from calendars on this iPhone. Apple asks for full calendar access; Larpy only reads events here and never uploads them.")
                    .font(.footnote).foregroundStyle(Palette.muted)
                Button("Connect my calendar") { Task { await calendar.connect() } }
                    .buttonStyle(.bordered).disabled(calendar.busy)
            }
            Button { edit = true } label: { Label("Plan 25 minutes", systemImage: "plus").frame(minHeight: 44) }
            Text(result ?? "You choose the time and calendar, then confirm Save. No access needed to add a block.")
                .font(.footnote).foregroundStyle(Palette.muted)
        }.foregroundStyle(Palette.text)
            .sheet(isPresented: $edit) {
                FocusEventEditor(eventStore: calendar.eventStore) { saved in
                    edit = false
                    result = saved ? "Focus block added. Log what you finish afterwards." : nil
                    calendar.refresh()
                }.ignoresSafeArea()
            }
            .onAppear { calendar.refresh() }
            .onChange(of: phase) { _, phase in if phase == .active { calendar.refresh() } }
    }
}

struct FocusEventEditor: UIViewControllerRepresentable {
    let eventStore: EKEventStore
    let completed: (Bool) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completed: completed) }
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        controller.eventStore = eventStore
        let event = EKEvent(eventStore: eventStore)
        event.title = "Larpy · one thing, finished"
        event.startDate = Date.now.addingTimeInterval(3600)
        event.endDate = event.startDate.addingTimeInterval(25 * 60)
        event.notes = "A little time for what matters. Log your finished activity in Larpy afterwards."
        controller.event = event; controller.editViewDelegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}
    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let completed: (Bool) -> Void
        init(completed: @escaping (Bool) -> Void) { self.completed = completed }
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) { completed(action == .saved) }
    }
}
