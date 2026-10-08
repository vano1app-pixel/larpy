import Foundation
import StoreKit
import SwiftUI

/// Compatibility for older receipts and paid wardrobe entitlements.
/// Current progression skins are always earned; optional purchases live in the
/// separate seasonal collection.
enum Larp {
    static var unlocked: Bool {
        get { UserDefaults.standard.bool(forKey: "larpUnlocked") }
        set { UserDefaults.standard.set(newValue, forKey: "larpUnlocked") }
    }

    static var firstReceiptAt: Date? {
        let timestamp = UserDefaults.standard.double(forKey: "firstReceiptAt")
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }

    /// Used only by the one-time migration that preserves older earned looks.
    static var freeUntil: Date? {
        guard let firstReceiptAt else { return nil }
        return LarpyTime.cal.date(byAdding: .day, value: 30, to: firstReceiptAt)
    }

    static var wardrobeOpen: Bool { true }
    static func wardrobeOpen(prefs: Prefs) -> Bool { true }
}

/// The seasonal collection is the only optional purchase. Progression outfits
/// remain separate and can never be bought to skip their requirements.
@MainActor
final class SeasonalShop: ObservableObject {
    static let shared = SeasonalShop()
    nonisolated static let productID = "com.vano.larpy.afterdark2026"
    nonisolated static let lookIDs: Set<String> = ["season-pumpkin", "season-vampire", "season-wizard"]
    nonisolated static let titles = ["season-pumpkin": "Pumpkin shift", "season-vampire": "Night shift", "season-wizard": "Spell check"]
    nonisolated static var cachedLooks: Set<String> {
        UserDefaults.standard.bool(forKey: "seasonAfterDarkOwned") ? lookIDs : []
    }

    @Published private(set) var owned = false
    @Published private(set) var product: Product?
    @Published private(set) var busy = false
    @Published private(set) var message: String?
    private var watcher: Task<Void, Never>?

    init() {
        watcher = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, case .verified(let transaction) = result,
                      transaction.productID == Self.productID else { continue }
                await refresh()
                await transaction.finish()
            }
        }
    }

    deinit { watcher?.cancel() }

    func load() async {
        await refresh()
        do {
            product = try await Product.products(for: [Self.productID]).first
            if product == nil { message = "Preview collection. This pack isn’t available from the App Store yet." }
        } catch {
            message = "The App Store couldn’t load this collection. Try again later."
        }
    }

    func refresh() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.productID,
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded,
                  transaction.expirationDate == nil || transaction.expirationDate! > .now else { continue }
            entitled = true
        }
        owned = entitled
        UserDefaults.standard.set(entitled, forKey: "seasonAfterDarkOwned")
    }

    func buy() async {
        guard !busy, let product else { return }
        busy = true
        defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    message = "Purchase couldn’t be verified. No outfit has been unlocked."
                    return
                }
                await refresh()
                await transaction.finish()
                message = owned ? "The collection is yours." : "Waiting for your purchase to appear. Try Restore purchases."
            case .pending:
                message = "Waiting for purchase approval."
            case .userCancelled:
                message = nil
            @unknown default:
                message = "Purchase didn’t complete. Try again."
            }
        } catch {
            message = "Purchase didn’t complete. Try again."
        }
    }

    func restore() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            try await AppStore.sync()
            await refresh()
            message = owned ? "Collection restored." : "No purchase of this collection on this Apple ID."
        } catch {
            message = "Restore couldn’t finish. Check your connection and try again."
        }
    }
}

struct SeasonalCollectionView: View {
    @ObservedObject var prefs: Prefs
    @ObservedObject private var shop = SeasonalShop.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selection = "season-pumpkin"
    private var look: FounderLook { FounderLook.find(selection)! }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("After dark.").font(.system(.largeTitle, design: .serif))
                    Text("Same little menace. A different disguise.").font(.subheadline).foregroundStyle(Palette.muted)
                    LarpyCharacterView(life: .neutral, base: .cream, kit: look.kit, width: 185, showScene: false, interactive: true, founderID: look.id, companion: true)
                        .frame(height: 305)
                    Text(look.styleName).font(.title2.weight(.semibold))
                    HStack(spacing: 10) {
                        ForEach(["season-pumpkin", "season-vampire", "season-wizard"], id: \.self) { id in
                            let item = FounderLook.find(id)!
                            Button { selection = id } label: {
                                LarpyCharacterView(life: .neutral, base: .cream, kit: item.kit, width: 48, showScene: false, founderID: id)
                                    .frame(maxWidth: .infinity).frame(height: 86)
                                    .background(selection == id ? Palette.gold.opacity(0.25) : Palette.card, in: RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.styleName)
                            .accessibilityAddTraits(selection == id ? .isSelected : [])
                        }
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Link("Terms of Use (EULA)", destination: LarpyLinks.terms).frame(minHeight: 44)
                        Link("Privacy policy", destination: LarpyLinks.privacy).frame(minHeight: 44)
                    }.font(.subheadline).tint(Palette.text)
                    if shop.owned {
                        Button("Wear \(look.styleName)") { prefs.selectedLookID = selection; dismiss() }
                            .buttonStyle(.borderedProminent).tint(Palette.gold).foregroundStyle(Palette.ink)
                    } else if let product = shop.product {
                        Text(product.displayName).font(.headline)
                        Button("All 3 outfits · \(product.displayPrice)") { Task { await shop.buy() } }
                            .buttonStyle(.borderedProminent).tint(Palette.gold).foregroundStyle(Palette.ink).disabled(shop.busy)
                        Text("One purchase. No subscription.").font(.caption)
                    }
                    if let message = shop.message {
                        Text(message).font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    }
                    Text("Optional costumes only. Your progress, daily activities and achievement skins stay free. These outfits never count as achievements.")
                        .font(.footnote).foregroundStyle(Palette.muted).multilineTextAlignment(.center)
                    Button("Restore purchases") { Task { await shop.restore() } }
                        .frame(minHeight: 44).disabled(shop.busy)
                    if shop.busy { ProgressView() }
                }
                .padding(24).frame(maxWidth: 480).frame(maxWidth: .infinity)
            }
            .background(Palette.bg).foregroundStyle(Palette.text)
            .navigationTitle("Seasonal collection").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { await shop.load() }
        }
    }
}
