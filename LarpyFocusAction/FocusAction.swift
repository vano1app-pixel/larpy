import ManagedSettings
import Foundation

final class FocusAction: ShieldActionDelegate {
    private func respond(_ action: ShieldAction, _ completion: (ShieldActionResponse) -> Void) {
        if case .secondaryButtonPressed = action,
           let defaults = FocusStorage.shared, let session = FocusStorage.read(FocusStorage.activeKey, from: defaults),
           session.blocksDistractions, session.remaining() > 0 {
            defaults.set(session.id.uuidString, forKey: FocusStorage.breakRequestKey)
            if #available(iOS 26.5, *) { completion(.openParentalControlsApp); return }
        }
        // The shield never grants access. Only the timed-break flow in Larpy can do that.
        completion(.close)
    }
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) { respond(action, completionHandler) }
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) { respond(action, completionHandler) }
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) { respond(action, completionHandler) }
}
