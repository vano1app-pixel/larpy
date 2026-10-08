import SwiftUI
import WidgetKit

struct WidgetGuideView: View {
    @State private var installed: Int?
    @State private var snapshot = WidgetSnapshot.empty
    var body: some View {
        List {
            Section {
                Text("A little nudge, before the scroll.").font(.system(.title2, design: .serif))
                Text("Larpy shows what you’ve logged, what’s missing and your recorded focus time. Tap his widget to add proof or return to an active focus block.")
                if let installed { Text(installed == 0 ? "No Larpy widget is installed yet." : "\(installed) Larpy widget\(installed == 1 ? "" : "s") installed.").font(.footnote).foregroundStyle(.secondary) }
            }
            Section("Home Screen or Today View") {
                LarpyMediumWidgetView(snap: snapshot).padding(16).frame(height: 156)
                    .background(WPalette.paper, in: RoundedRectangle(cornerRadius: 24))
                    .allowsHitTesting(false).accessibilityElement(children: .ignore)
                    .accessibilityLabel("Preview of your Home Screen widget. \(snapshot.reminder)")
                Text("1. Touch and hold an empty part of your Home Screen.")
                Text("2. Tap Edit, then Add Widget. Search for Larpy.")
                Text("3. Pick the small companion or the wider three-activity widget, then tap Add Widget.")
                Text("The wider widget takes you straight to Body, Work or Learnt. You can also add Larpy in Today View, to the left of your Home Screen.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Lock Screen") {
                LarpyRectangularWidgetView(snap: snapshot)
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                    .environment(\.colorScheme, .dark)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Preview of your Lock Screen widget. \(snapshot.reminder)")
                Text("1. Touch and hold your Lock Screen, then tap Customize and choose Lock Screen.")
                Text("2. Tap the widget area below the clock and choose Larpy.")
                Text("3. Choose his little face or the wider reminder. Tap Done.")
                Text("The inline reminder also fits above the clock. These widgets show activity status on your Lock Screen.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("What he knows") {
                Text("“No movement logged” means no qualifying Body activity has been saved. “50m focus recorded” means completed Larpy timers, not proof that you worked for 50 minutes.")
                Text("Apple controls widget refresh timing. Larpy requests an update after a saved activity or focus change; a widget may briefly show an earlier state.").font(.footnote).foregroundStyle(.secondary)
            }
        }.navigationTitle("Larpy on your screen").navigationBarTitleDisplayMode(.inline)
            .task {
                if let data = UserDefaults(suiteName: WidgetBridge.suite)?.data(forKey: "snapshot"),
                   let saved = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) { snapshot = saved.current(at: .now) }
                WidgetCenter.shared.getCurrentConfigurations { result in
                    if case .success(let configurations) = result {
                        Task { @MainActor in installed = configurations.filter { $0.kind == "LarpyWidget" }.count }
                    }
                }
            }
    }
}
