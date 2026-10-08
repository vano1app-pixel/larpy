import SwiftUI
import WidgetKit

// Home and Lock Screen companion. Receipts and local focus timers only; no passive work claims.

struct LarpyEntry: TimelineEntry {
    let date: Date
    let snap: WidgetSnapshot
}

struct LarpyProvider: TimelineProvider {
    static let suite = "group.com.vano.larpy"

    func placeholder(in context: Context) -> LarpyEntry { LarpyEntry(date: .now, snap: .sample) }

    func getSnapshot(in context: Context, completion: @escaping (LarpyEntry) -> Void) {
        completion(LarpyEntry(date: .now, snap: context.isPreview ? .sample : load().current(at: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LarpyEntry>) -> Void) {
        let now = Date.now
        let snapshot = load()
        var entries = (0...24).compactMap { hour -> LarpyEntry? in
            guard let date = Calendar.current.date(byAdding: .hour, value: hour, to: Calendar.current.startOfDay(for: now)), date >= now else { return nil }
            return LarpyEntry(date: date, snap: snapshot.current(at: date))
        }
        if let defaults = FocusStorage.shared, let session = FocusStorage.read(FocusStorage.activeKey, from: defaults), session.endsAt > now {
            entries.append(LarpyEntry(date: session.endsAt, snap: snapshot.current(at: session.endsAt)))
            if let pause = session.activeBreak(at: now) {
                entries.append(LarpyEntry(date: pause.endsAt, snap: snapshot.current(at: pause.endsAt)))
            }
        }
        entries.sort { $0.date < $1.date }
        let first = LarpyEntry(date: now, snap: snapshot.current(at: now))
        completion(Timeline(entries: [first] + entries, policy: .atEnd))
    }

    private func load() -> WidgetSnapshot {
        guard let data = UserDefaults(suiteName: Self.suite)?.data(forKey: "snapshot"),
              let snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return .empty }
        return snap
    }
}

struct LarpyWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LarpyEntry
    var body: some View {
        Group {
            switch family {
            case .systemMedium: LarpyMediumWidgetView(snap: entry.snap)
            case .accessoryRectangular:
                LarpyRectangularWidgetView(snap: entry.snap)
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 1) { LarpyLockScreenMark(); Text("\(entry.snap.done)/3").font(.system(size: 10, weight: .bold)) }
                }.accessibilityLabel("Larpy. \(entry.snap.done) of three activities logged. \(entry.snap.reminder)")
            case .accessoryInline:
                Label(entry.snap.reminder, systemImage: "face.smiling")
            default: LarpySmallWidgetView(snap: entry.snap)
            }
        }
        .containerBackground(for: .widget) { WPalette.paper }
        .widgetURL(entry.snap.link)
    }
}

struct LarpyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LarpyWidget", provider: LarpyProvider()) { entry in LarpyWidgetEntryView(entry: entry) }
            .configurationDisplayName("Larpy · your little nudge")
            .description("Your companion, today’s proof and recorded focus time. Tap to add what’s missing.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct LarpyWidgetBundle: WidgetBundle {
    var body: some Widget { LarpyWidget() }
}
