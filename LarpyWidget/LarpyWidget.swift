import SwiftUI
import WidgetKit

// Larpy on the Home Screen. Reads ONE snapshot the app writes: mood, today's three pips,
// ships this week, the last receipt. No Screen Time, no usage, nothing else is read.

struct WidgetSnapshot: Codable {
    var mood: String        // "fed" | "hungry"
    var pips: [Bool]        // Train, Load, Ship today
    var ships: Int          // this week
    var lastReceipt: String
    var name: String
    var updatedAt: Date

    static let empty = WidgetSnapshot(mood: "hungry", pips: [false, false, false], ships: 0, lastReceipt: "", name: "", updatedAt: .distantPast)
    static let sample = WidgetSnapshot(mood: "fed", pips: [true, true, false], ships: 2, lastReceipt: "Load · 184k tok", name: "You", updatedAt: .now)
    var fed: Bool { mood == "fed" && Calendar.current.isDateInToday(updatedAt) }
    func current(at date: Date) -> WidgetSnapshot {
        var result = self
        if !Calendar.current.isDate(updatedAt, inSameDayAs: date) {
            result.mood = "hungry"; result.pips = [false, false, false]; result.lastReceipt = "New day. New evidence."
        }
        var calendar = Calendar.current; calendar.firstWeekday = 2
        if calendar.dateInterval(of: .weekOfYear, for: date)?.start != calendar.dateInterval(of: .weekOfYear, for: updatedAt)?.start { result.ships = 0 }
        return result
    }
}

struct LarpyEntry: TimelineEntry {
    let date: Date
    let snap: WidgetSnapshot
}

struct LarpyProvider: TimelineProvider {
    static let suite = "group.com.larpy.app"

    func placeholder(in context: Context) -> LarpyEntry { LarpyEntry(date: .now, snap: .sample) }

    func getSnapshot(in context: Context, completion: @escaping (LarpyEntry) -> Void) {
        completion(LarpyEntry(date: .now, snap: context.isPreview ? .sample : load().current(at: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LarpyEntry>) -> Void) {
        let now = Date.now
        let snapshot = load()
        let entries = (0...24).compactMap { hour -> LarpyEntry? in
            guard let date = Calendar.current.date(byAdding: .hour, value: hour, to: Calendar.current.startOfDay(for: now)), date >= now else { return nil }
            return LarpyEntry(date: date, snap: snapshot.current(at: date))
        }
        let first = LarpyEntry(date: now, snap: snapshot.current(at: now))
        completion(Timeline(entries: [first] + entries, policy: .atEnd))
    }

    private func load() -> WidgetSnapshot {
        guard let data = UserDefaults(suiteName: Self.suite)?.data(forKey: "snapshot"),
              let snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return .empty }
        return snap
    }
}

// MARK: - Palette (mirrors the app; cream paper, ink, gold, three lane colours)

enum WPalette {
    static let paper = Color(red: 0.961, green: 0.941, blue: 0.902)     // #F5F0E6
    static let ink = Color(red: 0.102, green: 0.090, blue: 0.078)       // #1A1714
    static let muted = Color(red: 0.478, green: 0.420, blue: 0.345)     // #7A6B58
    static let line = Color(red: 0.882, green: 0.847, blue: 0.776)      // #E1D8C6
    static let creature = Color(red: 0.957, green: 0.894, blue: 0.784)  // #F4E4C8
    static let blush = Color(red: 0.910, green: 0.608, blue: 0.541)     // #E89B8A
    static let gold = Color(red: 0.769, green: 0.639, blue: 0.353)      // #C4A35A
    static let lanes: [Color] = [
        Color(red: 1.0, green: 0.353, blue: 0.239),                     // Train #FF5A3D
        Color(red: 0.357, green: 0.549, blue: 1.0),                     // Load  #5B8CFF
        Color(red: 0.769, green: 0.639, blue: 0.353)                    // Ship  #F5C542
    ]
}

/// The same body, drawn small: cream egg, TWO open eyes, blush when fed, flat mouth when hungry. Never a wink.
struct LarpyFace: View {
    let fed: Bool
    var size: CGFloat = 64

    var body: some View {
        let w = size
        let h = fed ? size * 1.10 : size * 0.97     // hungry = slump
        ZStack {
            ForEach([-1.0, 1.0], id: \.self) { side in
                Capsule().fill(WPalette.creature).frame(width: w * 0.16, height: w * 0.25)
                    .rotationEffect(.degrees(side * -25)).offset(x: side * w * 0.47, y: h * 0.20)
                Capsule().fill(WPalette.creature).frame(width: w * 0.20, height: w * 0.12)
                    .offset(x: side * w * 0.22, y: h * 0.48)
            }
            WidgetEgg().fill(WPalette.creature)
                .frame(width: w, height: h)
                .shadow(color: WPalette.ink.opacity(0.10), radius: 3, y: 2)
            if true {
                HStack(spacing: w * 0.36) {
                    Circle().fill(WPalette.blush.opacity(0.7)).frame(width: w * 0.16, height: w * 0.16)
                    Circle().fill(WPalette.blush.opacity(0.7)).frame(width: w * 0.16, height: w * 0.16)
                }
                .offset(y: h * 0.02)
            }
            HStack(spacing: w * 0.22) {
                eye(w); eye(w)
            }
            .offset(y: -h * 0.08)
            if fed {
                Arc(bend: 0.7).stroke(WPalette.ink, style: StrokeStyle(lineWidth: max(1.5, w * 0.03), lineCap: .round))
                    .frame(width: w * 0.18, height: w * 0.08)
                    .offset(y: h * 0.14)
            } else {
                Capsule().fill(WPalette.ink).frame(width: w * 0.14, height: max(1.5, w * 0.03))
                    .offset(y: h * 0.14)
            }
        }
        .frame(width: w, height: size)
    }

    private func eye(_ w: CGFloat) -> some View {
        Ellipse().fill(WPalette.ink).frame(width: w * 0.072, height: w * 0.105)
            .overlay(alignment: .topTrailing) {
                Circle().fill(WPalette.creature).frame(width: w * 0.03, height: w * 0.03).offset(x: -w * 0.012, y: w * 0.012)
            }
    }
}

struct Arc: Shape {
    var bend: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.minY + r.height * 2 * bend))
        return p
    }
}

// MARK: - Views

struct SmallView: View {
    let snap: WidgetSnapshot
    var body: some View {
        VStack(spacing: 6) {
            LarpyFace(fed: snap.fed, size: 62)
            Text("\(snap.ships)")
                .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(WPalette.ink)
                .monospacedDigit()
            Text(snap.ships == 1 ? "ship this week" : "ships this week")
                .font(.system(size: 10, weight: .semibold)).foregroundStyle(WPalette.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MediumView: View {
    let snap: WidgetSnapshot
    var body: some View {
        HStack(spacing: 16) {
            LarpyFace(fed: snap.fed, size: 76)
            VStack(alignment: .leading, spacing: 8) {
                Text(snap.fed ? "Evidence attached." : "I don’t see a ship.")
                    .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(WPalette.ink)
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        HStack(spacing: 4) {
                            Circle().fill(snap.pips.indices.contains(i) && snap.pips[i] ? WPalette.lanes[i] : WPalette.line)
                                .frame(width: 8, height: 8)
                            Text(["Body", "Learnt", "Work"][i])
                                .font(.system(size: 11, weight: .semibold)).foregroundStyle(WPalette.muted)
                        }
                    }
                }
                Text(snap.lastReceipt.isEmpty ? "No receipts." : snap.lastReceipt)
                    .font(.system(size: 12)).foregroundStyle(WPalette.muted).lineLimit(1)
                Text("\(snap.ships) ship\(snap.ships == 1 ? "" : "s") this week")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(WPalette.gold)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LarpyWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LarpyEntry
    var body: some View {
        Group {
            switch family {
            case .systemMedium: MediumView(snap: entry.snap)
            default: SmallView(snap: entry.snap)
            }
        }
        .containerBackground(for: .widget) { WPalette.paper }
        .widgetURL(URL(string: "larpy://log/work"))
    }
}

struct LarpyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LarpyWidget", provider: LarpyProvider()) { entry in
            LarpyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Larpy")
        .description("His face and your ships this week. From receipts only.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct LarpyWidgetBundle: WidgetBundle {
    var body: some Widget { LarpyWidget() }
}

struct WidgetEgg: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: r.midX, y: 0))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.height * 0.62), control1: CGPoint(x: r.width * 0.79, y: 0), control2: CGPoint(x: r.maxX, y: r.height * 0.34))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY), control1: CGPoint(x: r.maxX, y: r.height * 0.88), control2: CGPoint(x: r.width * 0.79, y: r.maxY))
        p.addCurve(to: CGPoint(x: 0, y: r.height * 0.62), control1: CGPoint(x: r.width * 0.21, y: r.maxY), control2: CGPoint(x: 0, y: r.height * 0.88))
        p.addCurve(to: CGPoint(x: r.midX, y: 0), control1: CGPoint(x: 0, y: r.height * 0.34), control2: CGPoint(x: r.width * 0.21, y: 0)); return p
    }
}
