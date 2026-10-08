import SwiftUI
import WidgetKit

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
                WidgetArc(bend: 0.7).stroke(WPalette.ink, style: StrokeStyle(lineWidth: max(1.5, w * 0.03), lineCap: .round))
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

struct WidgetArc: Shape {
    var bend: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.minY + r.height * 2 * bend))
        return p
    }
}

// MARK: - Views

struct LarpySmallWidgetView: View {
    let snap: WidgetSnapshot
    var body: some View {
        VStack(spacing: 7) {
            LarpyFace(fed: snap.done > 0, size: 54).padding(.top, 2)
            Text(snap.reminder).font(.system(size: 13, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.85)
            if let end = snap.breakEnd ?? snap.focusEnd {
                Text(timerInterval: min(Date.now, end)...end, countsDown: true).font(.caption.monospacedDigit())
            } else { Text("Lv \(snap.level) · \(snap.done) of 3 today").font(.system(size: 10)).foregroundStyle(WPalette.muted) }
        }.foregroundStyle(WPalette.ink).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LarpyMediumWidgetView: View {
    let snap: WidgetSnapshot
    var body: some View {
        HStack(spacing: 18) {
            VStack(spacing: 9) {
                LarpyFace(fed: snap.done > 0, size: 65)
                Text("Lv \(snap.level)").font(.system(size: 12, weight: .semibold)).monospacedDigit()
            }
            VStack(alignment: .leading, spacing: 9) {
                Text(snap.reminder).font(.system(size: 15, weight: .semibold, design: .rounded)).lineLimit(2)
                HStack(spacing: 8) {
                    ForEach([0, 2, 1], id: \.self) { i in
                        Link(destination: URL(string: "larpy://log/" + ["body", "learn", "work"][i])!) {
                            HStack(spacing: 3) {
                                Image(systemName: snap.has(i) ? "checkmark.circle.fill" : "plus.circle")
                                Text(["Body", "Learnt", "Work"][i])
                            }.font(.system(size: 11, weight: .medium)).fixedSize(horizontal: true, vertical: false)
                        }.accessibilityLabel("\(["Body", "Learnt", "Work"][i]), \(snap.has(i) ? "logged" : "add proof")")
                    }
                }
                if let end = snap.breakEnd ?? snap.focusEnd {
                    HStack(spacing: 4) { Image(systemName: "timer"); Text(timerInterval: min(Date.now, end)...end, countsDown: true); Text("left") }.font(.caption).monospacedDigit()
                } else { Text(snap.focusLine).font(.system(size: 11)).foregroundStyle(WPalette.muted).lineLimit(2) }
            }
        }.foregroundStyle(WPalette.ink).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A monochrome drawing that stays legible in the Lock Screen's tinted rendering.
struct LarpyLockScreenMark: View {
    var body: some View {
        ZStack {
            WidgetEgg().stroke(.primary, lineWidth: 1.8)
            HStack(spacing: 7) { Capsule().frame(width: 2.5, height: 4); Capsule().frame(width: 2.5, height: 4) }.offset(y: -2)
            WidgetArc(bend: 0.5).stroke(.primary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round)).frame(width: 8, height: 4).offset(y: 6)
        }.frame(width: 29, height: 34).accessibilityHidden(true)
    }
}

struct LarpyRectangularWidgetView: View {
    let snap: WidgetSnapshot
    var body: some View {
        HStack(spacing: 8) {
            LarpyLockScreenMark()
            VStack(alignment: .leading, spacing: 2) {
                Text(snap.reminder).font(.headline).lineLimit(2)
                if let end = snap.breakEnd ?? snap.focusEnd { Text(timerInterval: min(Date.now, end)...end, countsDown: true).font(.caption).monospacedDigit() }
                else { Text("Lv \(snap.level) · \(snap.done)/3 · \(snap.focusMinutes ?? 0)m focus").font(.caption) }
            }
        }
    }
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
