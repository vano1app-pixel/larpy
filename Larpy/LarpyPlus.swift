import StoreKit
import SwiftUI

enum LarpyLinks {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://vano1app-pixel.github.io/larpy-support/privacy.html")!
    static let support = URL(string: "https://vano1app-pixel.github.io/larpy-support/")!
    static let subscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
}

/// Access is derived from verified StoreKit transactions, never a local trial clock.
@MainActor
final class LarpyPlusStore: ObservableObject {
    static let shared = LarpyPlusStore()
    nonisolated static let productID = "com.vano.larpy.plus.monthly"
    // Keep verified legacy access while only offering the current monthly plan.
    nonisolated static let entitlementProductIDs: Set<String> = [productID, "com.vano.larpy.plus.weekly"]
    @Published private(set) var product: Product?
    @Published private(set) var active = false
    @Published private(set) var accessUntil: Date?
    @Published private(set) var eligibleForTrial = false
    @Published private(set) var loading = false
    @Published private(set) var busy = false
    @Published private(set) var message: String?
    private var updates: Task<Void, Never>?
    private var expiry: Task<Void, Never>?
    private var refreshGeneration = 0

    init() {
        updates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self, case .verified(let transaction) = result,
                      Self.entitlementProductIDs.contains(transaction.productID) else { continue }
                self.apply(transaction)
                await self.refresh()
                await transaction.finish()
            }
        }
    }
    deinit { updates?.cancel(); expiry?.cancel() }

    func load() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        await refresh()
        do {
            product = try await Product.products(for: [Self.productID]).first { $0.type == .autoRenewable }
            if product?.subscription != nil {
                await refresh()
                message = nil
            } else {
                eligibleForTrial = false
                message = "The App Store hasn’t loaded Larpy Plus. You can keep using the free features and try again."
            }
        } catch {
            product = nil; eligibleForTrial = false
            message = "The App Store couldn’t be reached. Check your connection and try again."
        }
    }

    func refresh() async {
        refreshGeneration += 1
        let generation = refreshGeneration
        var until: Date?
        var trialEligible = false
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  Self.entitlementProductIDs.contains(transaction.productID),
                  transaction.revocationDate == nil, !transaction.isUpgraded,
                  let date = transaction.expirationDate, date > .now else { continue }
            until = max(until ?? date, date)
        }
        // A verified billing grace period also grants service if enabled in Apple.
        if let subscription = product?.subscription {
            trialEligible = await subscription.isEligibleForIntroOffer
            for status in (try? await subscription.status) ?? [] where status.state == .inGracePeriod {
                guard case .verified(let transaction) = status.transaction,
                      Self.entitlementProductIDs.contains(transaction.productID), transaction.revocationDate == nil,
                      case .verified(let renewal) = status.renewalInfo,
                      let date = renewal.gracePeriodExpirationDate, date > .now else { continue }
                until = max(until ?? date, date)
            }
        }
        guard generation == refreshGeneration else { return }
        eligibleForTrial = trialEligible
        setAccess(until)
    }

    private func apply(_ transaction: StoreKit.Transaction) {
        refreshGeneration += 1
        guard Self.entitlementProductIDs.contains(transaction.productID) else { return }
        setAccess(transaction.revocationDate == nil && !transaction.isUpgraded ? transaction.expirationDate : nil)
    }

    private func setAccess(_ date: Date?) {
        accessUntil = date.flatMap { $0 > .now ? $0 : nil }
        active = accessUntil != nil
        expiry?.cancel()
        if let accessUntil {
            expiry = Task { [weak self] in
                try? await Task.sleep(for: .seconds(max(1, accessUntil.timeIntervalSinceNow + 1)))
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    var trialLength: String? {
        guard eligibleForTrial, let offer = product?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return Self.length(offer.period, count: offer.periodCount)
    }
    var billingLength: String? { product?.subscription.map { Self.length($0.subscriptionPeriod) } }
    static func length(_ period: Product.SubscriptionPeriod, count: Int = 1) -> String {
        let amount = period.value * count
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        @unknown default: unit = "period"
        }
        return "\(amount) \(unit)\(amount == 1 ? "" : "s")"
    }

    func purchase() async {
        guard !busy, !active, let product else { return }
        busy = true; message = nil
        defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified(let transaction) = result, transaction.productID == Self.productID else {
                    message = "Apple’s purchase couldn’t be verified. No access was changed. Try Restore purchases."
                    return
                }
                apply(transaction)
                await transaction.finish()
                await refresh()
                message = active ? "Larpy Plus is active. Your detailed weekly review is ready." : "Apple confirmed the purchase, but access is not active. Try Restore purchases."
            case .pending: message = "Waiting for Apple’s purchase approval. Plus will activate when it is approved."
            case .userCancelled: break
            @unknown default: message = "The purchase did not finish. Please try again."
            }
        } catch { message = "The purchase did not finish. Check your connection and try again." }
    }

    func restore() async {
        guard !busy else { return }
        busy = true; message = nil
        defer { busy = false }
        do {
            try await AppStore.sync()
            await refresh()
            message = active ? "Larpy Plus restored." : "No active Larpy Plus subscription was found for this Apple Account."
        } catch { message = "Restore did not finish. Check your connection and try again." }
    }
}

struct LarpyPlusView: View {
    @ObservedObject private var plus = LarpyPlusStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .center, spacing: 16) {
                        LarpyCharacterView(life: .neutral, base: .cream, kit: .hoodie, width: 70, showScene: false, companion: true)
                            .frame(width: 105, height: 115).accessibilityHidden(true)
                        Text(plus.active ? "Your week.\nA little clearer." : "See what your\nweek adds up to.")
                            .font(.system(.title, design: .serif)).fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        benefit("Compare your weeks", "See your Body, Work and Learnt activity side by side with the same weekdays last week.", icon: "chart.bar.xaxis")
                        benefit("Choose your next step", "Get a weekly summary and a suggestion based on your saved activity days. Reviews update as you log.", icon: "arrow.up.right")
                    }
                    if plus.active {
                        Label("Larpy Plus is active", systemImage: "checkmark.seal.fill").font(.headline)
                            .foregroundStyle(Palette.gold).accessibilityIdentifier("plus.active")
                        if let date = plus.accessUntil {
                            Text("Current access through \(date.formatted(date: .abbreviated, time: .shortened)). Renewal and cancellation details are in Apple’s subscription settings.")
                                .font(.footnote).foregroundStyle(Palette.muted)
                        }
                    } else if let product = plus.product, let period = plus.billingLength {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(product.displayName).font(.headline)
                            if let trial = plus.trialLength {
                                Text("\(trial) free, then \(product.displayPrice) every \(period)").font(.title3.weight(.semibold))
                                Text("Free trial for eligible new subscribers. Apple confirms eligibility before you subscribe.").font(.footnote).foregroundStyle(Palette.muted)
                            } else {
                                Text("\(product.displayPrice) every \(period)").font(.title3.weight(.semibold))
                            }
                            Text("Auto-renews until cancelled. Cancel in Settings at least 24 hours before the trial or current period ends to avoid the next charge.")
                                .font(.footnote).foregroundStyle(Palette.muted)
                        }.accessibilityIdentifier("plus.offer")
                    } else if plus.loading { ProgressView("Loading Apple’s offer…") }
                    // Legal links precede the action that opens Apple's purchase sheet.
                    VStack(alignment: .leading, spacing: 0) {
                        Link("Terms of Use (EULA)", destination: LarpyLinks.terms).frame(minHeight: 44)
                        Link("Privacy policy", destination: LarpyLinks.privacy).frame(minHeight: 44)
                    }.font(.subheadline).tint(Palette.text)
                    if plus.active {
                        Button("Continue with Plus") { dismiss() }.buttonStyle(FocusPrimaryStyle())
                        Link("Manage or cancel subscription", destination: LarpyLinks.subscriptions).frame(minHeight: 44)
                    } else if plus.product != nil {
                        Button(plus.busy ? "Waiting for Apple…" : plus.trialLength.map { "Start \($0) free trial" } ?? "Subscribe to Larpy Plus") {
                            Task { await plus.purchase() }
                        }.buttonStyle(FocusPrimaryStyle()).disabled(plus.busy || plus.loading).accessibilityIdentifier("plus.purchase")
                    } else if !plus.loading {
                        Button("Reload Apple’s offer") { Task { await plus.load() } }.buttonStyle(FocusPrimaryStyle())
                    }
                    if let message = plus.message {
                        Text(message).font(.subheadline).foregroundStyle(Palette.muted).accessibilityIdentifier("plus.message")
                    }
                    Button("Restore purchases") { Task { await plus.restore() } }
                        .frame(minHeight: 44).disabled(plus.busy).accessibilityIdentifier("plus.restore")
                    Text("Activity logging, saved history, reflections, earned outfits, app blocking and timed breaks stay free. No account or device permission is needed for Plus reviews.")
                        .font(.footnote).foregroundStyle(Palette.muted)
                }.foregroundStyle(Palette.text).padding(24).frame(maxWidth: 540).frame(maxWidth: .infinity)
            }.background(Palette.bg).navigationTitle("Larpy Plus").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }.task { await plus.load() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await plus.refresh() } } }
    }
    private func benefit(_ title: String, _ detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(Palette.gold).frame(width: 25)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(Palette.muted)
            }
        }
    }
}

struct WeeklyReviewView: View {
    @ObservedObject var store: ProofStore
    let week: Date
    @ObservedObject private var plus = LarpyPlusStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var showPlus = false
    @State private var reflection = ""
    private var summary: WeeklyReviewSummary { WeeklyReviewSummary(logs: store.logs, weekContaining: week, calendar: LarpyTime.cal) }
    private var noteKey: String { "weeklyReflection." + ActivityCalendarRules.key(week, calendar: LarpyTime.cal) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("\(summary.start.formatted(.dateTime.day().month(.abbreviated))) – \(summary.through.formatted(.dateTime.day().month(.abbreviated)))")
                        .font(.subheadline).foregroundStyle(Palette.muted)
                    if plus.active {
                        Text(summary.headline).font(.system(.largeTitle, design: .serif))
                        Text("Comparing the same \(summary.daysIncluded) weekdays in each week. Today is still in progress when viewing the current week.")
                            .font(.footnote).foregroundStyle(Palette.muted)
                        ForEach(summary.lanes) { lane in
                            let layout = textSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout())
                            layout {
                                Text(lane.kind.title).font(.headline)
                                if !textSize.isAccessibilitySize { Spacer() }
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(lane.current) \(lane.current == 1 ? "day" : "days")").font(.title3.weight(.semibold)).monospacedDigit()
                                    Text(summary.hasEarlierActivity ? "\(lane.previous) last week" : "Building your first comparison")
                                        .font(.caption).foregroundStyle(Palette.muted)
                                }
                            }.accessibilityElement(children: .combine)
                            Divider()
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("One idea for next week").font(.headline)
                            Text(summary.nextStep).font(.body)
                            Text("A suggestion from your saved activity days. It is not a measure of effort or work quality.")
                                .font(.caption).foregroundStyle(Palette.muted)
                        }
                    } else {
                        Text("A little perspective\non your week.").font(.system(.largeTitle, design: .serif))
                        Text("Plus compares your Body, Work and Learnt days with the same days last week, then suggests one area to make time for. Your saved activities remain available in Progress.")
                            .foregroundStyle(Palette.muted)
                        Button("See Larpy Plus") { showPlus = true }.buttonStyle(FocusPrimaryStyle())
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What worked? What’s next?").font(.headline)
                        TextField("One thing to keep doing next week…", text: $reflection, axis: .vertical)
                            .lineLimit(3...8).padding(14).background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
                            .onChange(of: reflection) { _, text in
                                let limited = String(text.prefix(1000))
                                if limited != text { reflection = limited }
                                UserDefaults.standard.set(limited, forKey: noteKey)
                            }
                        Text("Saved on this device. Your reflection stays accessible without Plus and does not earn activity credit.")
                            .font(.footnote).foregroundStyle(Palette.muted)
                    }
                }.foregroundStyle(Palette.text).padding(24).frame(maxWidth: 540).frame(maxWidth: .infinity)
            }.background(Palette.bg).navigationTitle("Weekly review").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .sheet(isPresented: $showPlus) { LarpyPlusView() }
        }.onAppear { reflection = UserDefaults.standard.string(forKey: noteKey) ?? "" }
    }
}
