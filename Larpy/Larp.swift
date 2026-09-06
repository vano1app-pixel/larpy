import Foundation
import StoreKit
import SwiftUI

/// The one thing for sale. After the free month the wardrobe pauses: no new looks, no new rooms.
/// Everything else is free forever: logging, history, the week, the widget, the share card, the friend.
/// Nothing here is ever shown automatically. The ask is reached from the paused wardrobe card and Settings.
enum Larp {
    static let productID = "com.larpy.app.larp"
    static let freeDays = 30
    /// Shown until StoreKit has answered. Small on purpose: an impulse, not a contract.
    static let fallbackPrice = "€2.99"

    static var unlocked: Bool {
        get { UserDefaults.standard.bool(forKey: "larpUnlocked") }
        set { UserDefaults.standard.set(newValue, forKey: "larpUnlocked") }
    }
    static var firstReceiptAt: Date? {
        let t = UserDefaults.standard.double(forKey: "firstReceiptAt")
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }
    static var freeUntil: Date? {
        guard let first = firstReceiptAt else { return nil }
        return LarpyTime.cal.date(byAdding: .day, value: freeDays, to: first)
    }
    /// Days of free wardrobe left. nil before the first receipt.
    static var daysLeft: Int? {
        guard let until = freeUntil else { return nil }
        return max(0, LarpyTime.cal.dateComponents([.day], from: LarpyTime.cal.startOfDay(for: .now), to: LarpyTime.cal.startOfDay(for: until)).day ?? 0)
    }
    /// True while looks and rooms still change with receipts.
    static var wardrobeOpen: Bool {
        if unlocked { return true }
        guard let until = freeUntil else { return true }
        return Date() < until
    }
    static func wardrobeOpen(prefs: Prefs) -> Bool { wardrobeOpen }
    static var untilLine: String? {
        guard let until = freeUntil, !unlocked else { return nil }
        let f = DateFormatter(); f.calendar = LarpyTime.cal; f.dateFormat = "d MMM"
        return "WARDROBE OPEN UNTIL \(f.string(from: until).uppercased())"
    }
}

/// StoreKit 2. One non-consumable. Loads the price, buys, restores, and listens for transactions.
@MainActor
final class LarpStore: ObservableObject {
    @Published var product: Product?
    @Published var busy = false
    @Published var message: String?
    private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, case .verified(let t) = result else { continue }
                if t.productID == Larp.productID, t.revocationDate == nil { Larp.unlocked = true }
                await t.finish()
                self.objectWillChange.send()
            }
        }
    }
    deinit { updates?.cancel() }

    var priceLine: String { product?.displayPrice ?? Larp.fallbackPrice }

    func load() async {
        guard product == nil else { return }
        do {
            product = try await Product.products(for: [Larp.productID]).first
            await refreshEntitlement()
        } catch { message = nil }   // no store yet: the fallback price shows, the button waits
    }

    func refreshEntitlement() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Larp.productID, t.revocationDate == nil { Larp.unlocked = true }
        }
        objectWillChange.send()
    }

    func buy() async {
        guard let product else { message = "Not on sale yet."; return }
        busy = true; defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let t) = verification { Larp.unlocked = true; await t.finish(); message = nil }
                else { message = "That purchase couldn't be verified." }
            case .userCancelled: message = nil
            case .pending: message = "Waiting on approval."
            @unknown default: message = nil
            }
        } catch { message = "The App Store didn't answer. Try again." }
        objectWillChange.send()
    }

    func restore() async {
        busy = true; defer { busy = false }
        try? await AppStore.sync()
        await refreshEntitlement()
        message = Larp.unlocked ? "Restored." : "Nothing to restore on this Apple ID."
    }
}

/// The ask. Half a screen. The user's own receipts, one number, one button, one honest way out.
struct AskView: View {
    @ObservedObject var store: ProofStore
    @ObservedObject var prefs: Prefs
    @StateObject private var shop = LarpStore()
    @Environment(\.dismiss) private var dismiss

    private var receipts: Int { store.logs.filter(\.isEligible).count }
    private var work: Int { store.logs.filter { $0.quest == .work && $0.isEligible }.count }
    private var levelLine: String {
        switch work {
        case 0: "Ship one thing. Then we'll talk about costumes."
        case 1..<3: "First proof. That's rarer than you think."
        case 3..<7: "Repeat offender. Keep going."
        default: "Real enough. Dress the part."
        }
    }
    private var days: Int {
        guard let first = Larp.firstReceiptAt else { return 0 }
        return max(1, (LarpyTime.cal.dateComponents([.day], from: first, to: .now).day ?? 0) + 1)
    }

    var body: some View {
        VStack(spacing: 14) {
            Capsule().fill(Palette.line).frame(width: 36, height: 4).padding(.top, 8)
            HStack(spacing: 14) {
                LarpyCharacterView(life: LifeEngine.life(store.logs), base: .cream,
                                   kit: SceneWardrobe.kit(for: store.logsOn(.now), fallback: prefs.kit),
                                   width: 64, showScene: false, level: work, founderID: store.logs.first?.founderID)
                    .frame(width: 84, height: 96)
                VStack(alignment: .leading, spacing: 4) {
                    Text(Larp.unlocked ? "The wardrobe is yours." : "\(days) days. \(receipts) receipts.")
                        .font(.system(size: 26, weight: .medium, design: .serif)).tracking(-0.6).foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(levelLine).font(.system(size: 15, design: .serif)).foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 0)
            }
            receiptStrip
            Text("Logging, history, the week, the widget, the share card. Free, forever. The costume doesn't stay free.")
                .font(.system(size: 13)).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if Larp.unlocked {
                Text("One payment. It never renews. Looks and rooms keep changing.")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Palette.text)
                Button("Done") { dismiss() }.font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.muted).buttonStyle(.plain)
            } else if work == 0 {
                Text("No price until the first Work receipt.").font(.system(size: 12, weight: .medium, design: .monospaced)).foregroundStyle(Palette.muted)
                Button("Restore purchase") { Task { await shop.restore() } }.font(.system(size: 13)).foregroundStyle(Palette.muted).buttonStyle(.plain)
            } else {
                Button { Task { await shop.buy(); if Larp.unlocked { dismiss() } } } label: {
                    HStack(spacing: 8) {
                        if shop.busy { ProgressView().tint(Palette.ink) }
                        Text("Keep the wardrobe · \(shop.priceLine) once")
                    }
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: 54).background(Palette.gold, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }.buttonStyle(.plain).disabled(shop.busy || shop.product == nil).opacity(shop.product == nil ? 0.55 : 1)
                Text(shop.product == nil ? "Not on sale yet. Nothing is paused until it is." : "One payment. It never renews.")
                    .font(.system(size: 12)).foregroundStyle(Palette.muted)
                Button("Not now. Receipts still count.") { dismiss() }
                    .font(.system(size: 14, weight: .medium)).foregroundStyle(Palette.text).buttonStyle(.plain).padding(.top, 2)
                Button("Restore purchase") { Task { await shop.restore() } }
                    .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(1).foregroundStyle(Palette.muted).buttonStyle(.plain)
                    .frame(minHeight: 44)
            }
            if let m = shop.message { Text(m).font(.system(size: 12)).foregroundStyle(Palette.muted) }
        }
        .padding(.horizontal, 24).padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(Palette.bg.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .task { await shop.load() }
    }

    /// The person's own receipts, most recent first. Not stat tiles.
    private var receiptStrip: some View {
        let recent = Array(store.logs.filter(\.isEligible).prefix(14))
        return HStack(spacing: 4) {
            ForEach(recent) { log in
                RoundedRectangle(cornerRadius: 2).fill(log.quest == .work ? Palette.gold : log.quest.tint.opacity(0.55))
                    .frame(width: 14, height: 6)
            }
            if recent.isEmpty { Rectangle().fill(Palette.line).frame(height: 1) }
            Spacer(minLength: 0)
        }.frame(height: 8).accessibilityLabel("\(recent.count) recent receipts")
    }
}
