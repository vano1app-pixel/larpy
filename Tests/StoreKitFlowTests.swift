import XCTest
import StoreKitTest
@testable import LarpyPaymentQA

/// Calls the shipping purchase/restore implementation using Xcode's StoreKit service.
/// This does not establish that Apple's remote Sandbox or the physical phone works.
@MainActor
final class StoreKitFlowTests: XCTestCase {
    private func session() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "LarpyPlus")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        // Fail clearly if Xcode cannot configure its test service. Otherwise a
        // failed disableDialogs call can leave CI waiting on Apple's UI forever.
        return try XCTUnwrap(session.disableDialogs ? session : nil,
            "Xcode StoreKit test service did not accept configuration; purchase tests cannot run safely without dialog control")
    }

    func testMonthlyTrialPurchaseRestoreAndExpiry() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let store = LarpyPlusStore()
        await store.load()
        let product = try XCTUnwrap(store.product)
        XCTAssertFalse(product.displayPrice.isEmpty)
        XCTAssertEqual(store.billingLength, "1 month")
        XCTAssertEqual(store.trialLength, "1 week")
        XCTAssertFalse(store.active)
        await store.purchase()
        XCTAssertTrue(store.active, store.message ?? "Purchase did not activate Plus")
        XCTAssertNotNil(store.accessUntil)
        let fresh = LarpyPlusStore()
        await fresh.restore()
        XCTAssertTrue(fresh.active, fresh.message ?? "Restore did not activate Plus")
        try session.expireSubscription(productIdentifier: LarpyPlusStore.productID)
        await fresh.refresh()
        XCTAssertFalse(fresh.active)
    }

    func testRefundRemovesAccess() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let store = LarpyPlusStore()
        await store.load()
        _ = try XCTUnwrap(store.product)
        await store.purchase()
        XCTAssertTrue(store.active)
        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.refundTransaction(identifier: transaction.identifier)
        await store.refresh()
        XCTAssertFalse(store.active)
        XCTAssertNil(store.trialLength, "A used introductory trial must not be offered again after refund")
    }

    func testRestoreWithoutPurchaseStaysFree() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let store = LarpyPlusStore()
        await store.load()
        _ = try XCTUnwrap(store.product, "A working local StoreKit session is required before invoking restore")
        await store.restore()
        XCTAssertFalse(store.active)
        XCTAssertTrue(store.message?.contains("No active") == true)
    }

    func testPendingPurchaseDoesNotActivateAccess() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        session.askToBuyEnabled = true
        let store = LarpyPlusStore()
        await store.load()
        _ = try XCTUnwrap(store.product)
        await store.purchase()
        XCTAssertFalse(store.active)
        XCTAssertTrue(store.message?.contains("Waiting") == true)
    }
}
