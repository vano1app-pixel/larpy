import SwiftUI
import Speech
import AVFoundation

@MainActor
final class VoiceNote: ObservableObject {
    @Published private(set) var listening = false
    @Published private(set) var requesting = false
    @Published private(set) var transcript = ""
    @Published private(set) var message: String?
    private let engine = AVAudioEngine()
    private var recognition: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var timeout: Task<Void, Never>?
    private var generation = UUID()
    private var tapInstalled = false

    func start() async {
        guard !listening, !requesting else { return }
        let token = UUID(); generation = token
        requesting = true; message = nil; transcript = ""
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard generation == token else { return }
        guard speech == .authorized else {
            requesting = false; message = "Speech access is off. You can type, or enable it in iPhone Settings."; return
        }
        let microphone = await AVAudioApplication.requestRecordPermission()
        guard generation == token else { return }
        requesting = false
        guard microphone else { message = "Microphone access is off. You can still type your note."; return }
        guard let recognizer = SFSpeechRecognizer(locale: .current), recognizer.isAvailable,
              recognizer.supportsOnDeviceRecognition else {
            message = "On-device dictation isn’t available for this language right now. Type your note instead."; return
        }
        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audio.setActive(true, options: .notifyOthersOnDeactivation)
            let bufferRequest = SFSpeechAudioBufferRecognitionRequest()
            bufferRequest.requiresOnDeviceRecognition = true
            bufferRequest.shouldReportPartialResults = true
            request = bufferRequest
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                stop(); message = "No microphone is available. Type your note instead."; return
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in bufferRequest.append(buffer) }
            tapInstalled = true
            listening = true
            recognition = recognizer.recognitionTask(with: bufferRequest) { [weak self] result, error in
                Task { @MainActor in
                    guard let self, self.generation == token else { return }
                    if let result { self.transcript = result.bestTranscription.formattedString }
                    if error != nil || result?.isFinal == true {
                        self.stop()
                        if error != nil && self.transcript.isEmpty { self.message = "Couldn’t hear that. Try again or type your note." }
                    }
                }
            }
            engine.prepare(); try engine.start()
            timeout = Task { [weak self] in
                try? await Task.sleep(for: .seconds(55))
                guard !Task.isCancelled else { return }
                self?.stop()
            }
        } catch {
            stop(); message = "The microphone couldn’t start. Try again or type your note."
        }
    }

    func stop() {
        generation = UUID(); requesting = false; listening = false
        timeout?.cancel(); timeout = nil
        engine.stop()
        if tapInstalled { engine.inputNode.removeTap(onBus: 0); tapInstalled = false }
        request?.endAudio(); recognition?.cancel(); recognition = nil; request = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

/// Dictation edits a draft. It never files evidence, awards progress or saves audio.
struct VoiceNoteButton: View {
    @Binding var text: String
    @StateObject private var voice = VoiceNote()
    @State private var original = ""
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button {
                if voice.listening || voice.requesting { voice.stop() }
                else {
                    original = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task { await voice.start() }
                }
            } label: {
                Label(voice.listening ? "Listening · tap to stop" : voice.requesting ? "Cancel dictation" : "Say it instead",
                      systemImage: voice.listening ? "stop.circle.fill" : "mic")
                    .font(.subheadline.weight(.medium)).frame(minHeight: 44)
            }.buttonStyle(.plain).foregroundStyle(Palette.text)
            if let message = voice.message { Text(message).font(.footnote).foregroundStyle(Palette.muted) }
            else if voice.listening { Text("On-device dictation. Review your words before saving.").font(.footnote).foregroundStyle(Palette.muted) }
        }
        .onChange(of: voice.transcript) { _, value in
            guard !value.isEmpty else { return }
            text = original.isEmpty ? value : original + " " + value
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || (phase == .inactive && voice.listening) { voice.stop() }
        }
        .onDisappear { voice.stop() }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in voice.stop() }
    }
}
