import UIKit
import UniformTypeIdentifiers

/// Tap Larpy in YouTube's share sheet, then File Load. No app-opening responder hack.
/// Committed inputs wait durably in the App Group until Larpy imports them.
final class ShareViewController: UIViewController {
    private let suite = "group.com.vano.larpy"
    private var incomingURL: String?
    private var incomingText: String?
    private var incomingImage: Data?
    private let subtitle = UILabel()
    private let use = UITextField()
    private let saveButton = UIButton(type: .system)
    private var ready = false
    private var failed = false
    private var receiving = 0
    private struct Input: Codable { var id: UUID; var url: String?; var text: String?; var use: String; var at: Date }
    private struct Draft: Codable { var url: String?; var text: String?; var imageFile: String?; var at: Date }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.961, green: 0.941, blue: 0.902, alpha: 1)
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 22; stack.translatesAutoresizingMaskIntoConstraints = false
        let eyebrow = UILabel(); eyebrow.text = "Larpy · Learnt"; eyebrow.font = .preferredFont(forTextStyle: .headline)
        eyebrow.textColor = .darkGray
        let title = UILabel(); title.text = "Keep what you learnt."; title.font = .preferredFont(forTextStyle: .title1); title.numberOfLines = 0
        subtitle.text = "Reading your link…"; subtitle.numberOfLines = 3; subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.textColor = .darkGray
        use.placeholder = "What are you using this for? (optional)"; use.font = .systemFont(ofSize: 16)
        use.borderStyle = .roundedRect; use.returnKeyType = .done
        saveButton.setTitle("Save to Learnt", for: .normal); saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.setTitleColor(.black, for: .normal); saveButton.backgroundColor = UIColor(red: 0.769, green: 0.639, blue: 0.353, alpha: 1)
        saveButton.layer.cornerRadius = 16; saveButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside); saveButton.isEnabled = false; saveButton.alpha = 0.4
        let note = UILabel(); note.text = "Saved here. Added to your day when you next open Larpy."; note.numberOfLines = 0; note.font = .preferredFont(forTextStyle: .footnote); note.textColor = .darkGray
        let cancel = UIButton(type: .system); cancel.setTitle("Cancel", for: .normal); cancel.addTarget(self, action: #selector(close), for: .touchUpInside)
        [eyebrow, title, subtitle, use, saveButton, note, cancel].forEach { stack.addArrangedSubview($0) }
        view.addSubview(stack)
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24), stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24), stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30)])
        collect()
    }
    private func collect() {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? []).flatMap { $0.attachments ?? [] }
        for p in providers.prefix(5) {
            let type = p.hasItemConformingToTypeIdentifier(UTType.url.identifier) ? UTType.url.identifier
                : p.hasItemConformingToTypeIdentifier(UTType.image.identifier) ? UTType.image.identifier : UTType.plainText.identifier
            guard p.hasItemConformingToTypeIdentifier(type) else { continue }
            receiving += 1
            p.loadItem(forTypeIdentifier: type) { [weak self] item, error in
                var url: String?; var text: String?; var image: Data?
                if type == UTType.url.identifier { url = (item as? URL)?.absoluteString ?? (item as? String) }
                else if type == UTType.image.identifier {
                    let raw = (item as? Data) ?? (item as? URL).flatMap { try? Data(contentsOf: $0) }
                    image = (item as? UIImage)?.jpegData(compressionQuality: 0.82) ?? raw.flatMap { UIImage(data: $0)?.jpegData(compressionQuality: 0.82) }
                } else { text = (item as? String) ?? (item as? Data).flatMap { String(data: $0, encoding: .utf8) } }
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let url { self.incomingURL = url }
                    if let text { self.incomingText = text }
                    if let image { self.incomingImage = image }
                    self.receiving -= 1
                    if self.receiving == 0 { self.prepare() }
                }
            }
        }
        if receiving == 0 { prepare() }
    }
    private func prepare() {
        if incomingURL == nil, let text = incomingText,
           let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let match = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)), let url = match.url,
           ["http", "https"].contains(url.scheme?.lowercased() ?? "") { incomingURL = url.absoluteString }
        ready = incomingURL != nil || incomingText != nil || incomingImage != nil
        subtitle.text = incomingURL ?? incomingText ?? (incomingImage != nil ? "Image attached. Choose its lane in Larpy." : "No readable receipt. Try sharing a link or screenshot.")
        if incomingImage != nil { saveButton.setTitle("Keep draft for Larpy", for: .normal) }
        saveButton.isEnabled = ready; saveButton.alpha = ready ? 1 : 0.4
    }
    @objc private func save() {
        guard ready, let defaults = UserDefaults(suiteName: suite),
              let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suite) else {
            subtitle.text = "Larpy's shared storage isn't available. Open Larpy once, then try again."; return
        }
        do {
            if let image = incomingImage {
                let dir = container.appendingPathComponent("ShareInbox", isDirectory: true)
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let name = "\(UUID().uuidString).jpg"
                try image.write(to: dir.appendingPathComponent(name), options: .atomic)
                let draft = Draft(url: incomingURL, text: use.text, imageFile: name, at: .now)
                defaults.set(try JSONEncoder().encode(draft), forKey: "shareDraft")
            } else {
                let input = Input(id: UUID(), url: incomingURL, text: incomingText, use: use.text ?? "", at: .now)
                let dir = container.appendingPathComponent("LearningInbox", isDirectory: true)
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                try JSONEncoder().encode(input).write(to: dir.appendingPathComponent("\(input.id.uuidString).json"), options: .atomic)
            }
            saveButton.isEnabled = false
            saveButton.setTitle(incomingImage == nil ? "Saved to Learnt" : "Draft ready. Open Larpy.", for: .normal)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { self.close() }
        } catch { subtitle.text = "Couldn't keep the receipt. Try again." }
    }
    @objc private func close() { extensionContext?.completeRequest(returningItems: nil) }
}
