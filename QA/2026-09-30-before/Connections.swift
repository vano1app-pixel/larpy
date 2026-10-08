import SwiftUI
import HealthKit
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
    @Published var busy = false

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
            let recorded = workouts.filter { $0.duration >= 60 && ($0.metadata?[HKMetadataKeyWasUserEntered] as? Bool) != true }
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
    @State private var pickFolder = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Do your thing.\nLarpy keeps up.").font(.largeTitle.weight(.semibold)).tracking(-1)
                    Text("Connect once. Let your activity come to you.").font(.body).foregroundStyle(Palette.muted)
                    section("YouTube & links", icon: "play.rectangle") {
                        Text("In YouTube, tap Share → More → Larpy. Tap Save to Learnt and carry on watching.")
                        Text("Your link joins today's learning when you next open Larpy.").font(.footnote).foregroundStyle(Palette.muted)
                    }
                    section("AI agents", icon: "terminal") {
                        Text(connections.usageStatus)
                        ForEach(["codex", "claude-code"], id: \.self) { source in
                            ViewThatFits(in: .horizontal) {
                                HStack {
                                    Text(source == "codex" ? "Codex" : "Claude Code")
                                    Spacer()
                                    usageTotal(source)
                                }.fixedSize(horizontal: true, vertical: false)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(source == "codex" ? "Codex" : "Claude Code")
                                    usageTotal(source)
                                }
                            }.font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityElement(children: .combine)
                        }
                        Text("Open Larpy Sync on your Mac. Then choose its Larpy folder in iCloud Drive here. Only daily token totals sync.")
                            .font(.footnote).foregroundStyle(Palette.muted)
                        Button(connections.usageConnected ? "Choose sync folder" : "Connect my Mac") { pickFolder = true }
                            .buttonStyle(.borderedProminent).tint(Palette.gold).foregroundStyle(Palette.ink)
                        if connections.usageConnected {
                            Button("Disconnect Mac") { connections.disconnectUsage() }.font(.subheadline).frame(minHeight: 44)
                        }
                    }
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
                }.padding(24).foregroundStyle(Palette.text)
            }.background(Palette.bg)
                .navigationTitle("Connections").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .fileImporter(isPresented: $pickFolder, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { connections.connectUsage(folder: url, store: store, loads: loads) }
        }
    }

    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon).font(.title3.weight(.semibold))
            content().font(.body)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func usageTotal(_ source: String) -> some View {
        Text(connections.sourceTotals[source].map { "\(fmtTokens($0)) today" } ?? "Waiting for usage")
            .foregroundStyle(Palette.muted).monospacedDigit()
    }
}
