import DeviceActivity
import ManagedSettings
import FamilyControls
import WidgetKit

final class FocusMonitor: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        if activity.rawValue.hasPrefix("larpy.break.") { restoreAfterBreak(activity); return }
        guard let defaults = FocusStorage.shared,
              let session = FocusStorage.read(FocusStorage.activeKey, from: defaults),
              activity.rawValue == session.activityName else { return }
        ManagedSettingsStore(named: .init(FocusStorage.storeName)).clearAllSettings()
        if session.remaining() <= 1 { FocusStorage.complete(session, to: defaults, now: max(.now, session.endsAt)) }
        defaults.removeObject(forKey: FocusStorage.activeKey)
        defaults.removeObject(forKey: FocusStorage.breakRequestKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        restoreAfterBreak(activity)
    }

    private func restoreAfterBreak(_ activity: DeviceActivityName) {
        guard let defaults = FocusStorage.shared,
              let session = FocusStorage.read(FocusStorage.activeKey, from: defaults), session.blocksDistractions,
              let pause = session.breaks?.last, activity.rawValue == pause.activityName,
              // Calendar schedules resolve to whole seconds, so allow sub-second rounding.
              pause.endsAt <= Date.now.addingTimeInterval(1) else { return }
        let settings = ManagedSettingsStore(named: .init(FocusStorage.storeName))
        guard session.remaining() > 0 else {
            settings.clearAllSettings(); FocusStorage.complete(session, to: defaults)
            defaults.removeObject(forKey: FocusStorage.activeKey)
            defaults.removeObject(forKey: FocusStorage.breakRequestKey)
            WidgetCenter.shared.reloadAllTimelines(); return
        }
        guard let data = defaults.data(forKey: FocusStorage.selectionKey),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else { return }
        settings.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        settings.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        settings.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        settings.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
