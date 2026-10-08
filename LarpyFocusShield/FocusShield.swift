import ManagedSettings
import ManagedSettingsUI
import UIKit

final class FocusShield: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration { makeShield() }
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration { makeShield() }
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration { makeShield() }
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration { makeShield() }

    private func makeShield() -> ShieldConfiguration {
        let paper = UIColor(red: 0.086, green: 0.078, blue: 0.071, alpha: 1)
        let ink = UIColor(red: 0.95, green: 0.93, blue: 0.89, alpha: 1)
        let defaults = FocusStorage.shared
        let session = defaults.flatMap { FocusStorage.read(FocusStorage.activeKey, from: $0) }
        let roast = defaults?.string(forKey: "focus.personality") == "roast"
        let title = roast ? "Nice try. We had a plan." : "Still with me?"
        let task = session?.task ?? "Your focus block"
        let end = session?.endsAt.formatted(date: .omitted, time: .shortened) ?? "the end of your block"
        let canOpen: Bool
        if #available(iOS 26.5, *) { canOpen = true } else { canOpen = false }
        return ShieldConfiguration(backgroundBlurStyle: nil, backgroundColor: paper, icon: portrait(),
            title: .init(text: title, color: ink),
            subtitle: .init(text: "\(task)\n\nBlocked until \(end). Need a short break? Give a reason and choose a time in Larpy.\(canOpen ? "" : " Return to your Home Screen and open Larpy to request it.")", color: ink.withAlphaComponent(0.8)),
            primaryButtonLabel: .init(text: "Back to focus", color: paper),
            primaryButtonBackgroundColor: UIColor(red: 0.76, green: 0.63, blue: 0.31, alpha: 1),
            secondaryButtonLabel: .init(text: canOpen ? "Ask Larpy for a break" : "I’ll open Larpy", color: ink))
    }

    /// Original Larpy art, rendered locally inside Apple's shield. No app names leave the extension.
    private func portrait() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 128, height: 142)).image { _ in
            let ink = UIColor(red: 0.18, green: 0.16, blue: 0.11, alpha: 1)
            let body = UIBezierPath()
            body.move(to: CGPoint(x: 64, y: 5))
            body.addCurve(to: CGPoint(x: 120, y: 91), controlPoint1: CGPoint(x: 96, y: 5), controlPoint2: CGPoint(x: 120, y: 61))
            body.addCurve(to: CGPoint(x: 64, y: 134), controlPoint1: CGPoint(x: 120, y: 124), controlPoint2: CGPoint(x: 97, y: 134))
            body.addCurve(to: CGPoint(x: 8, y: 91), controlPoint1: CGPoint(x: 31, y: 134), controlPoint2: CGPoint(x: 8, y: 124))
            body.addCurve(to: CGPoint(x: 64, y: 5), controlPoint1: CGPoint(x: 8, y: 61), controlPoint2: CGPoint(x: 32, y: 5))
            UIColor(red: 0.99, green: 0.91, blue: 0.76, alpha: 1).setFill(); body.fill()
            ink.setStroke(); body.lineWidth = 2; body.stroke()
            UIColor(red: 0.90, green: 0.59, blue: 0.49, alpha: 0.6).setFill()
            for x in [26.0, 82.0] { UIBezierPath(ovalIn: CGRect(x: x, y: 84, width: 20, height: 10)).fill() }
            ink.setFill()
            for x in [43.0, 77.0] { UIBezierPath(roundedRect: CGRect(x: x, y: 67, width: 8, height: 12), cornerRadius: 4).fill() }
            let brows = UIBezierPath(); brows.lineWidth = 3; brows.lineCapStyle = .round
            brows.move(to: CGPoint(x: 40, y: 55)); brows.addLine(to: CGPoint(x: 53, y: 60))
            brows.move(to: CGPoint(x: 75, y: 60)); brows.addLine(to: CGPoint(x: 88, y: 55)); brows.stroke()
            let mouth = UIBezierPath(); mouth.lineWidth = 3; mouth.lineCapStyle = .round
            mouth.move(to: CGPoint(x: 56, y: 102)); mouth.addQuadCurve(to: CGPoint(x: 72, y: 102), controlPoint: CGPoint(x: 64, y: 97)); mouth.stroke()
        }
    }
}
