import AVFoundation
import Combine

/// Следит за системной громкостью — меняется кнопками громкости на телефоне.
final class VolumeMonitor: ObservableObject {
    @Published private(set) var level: Float

    private var observation: NSKeyValueObservation?

    init() {
        let session = AVAudioSession.sharedInstance()
        // Без активной сессии outputVolume не обновляется.
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
        level = session.outputVolume
        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let value = change.newValue else { return }
            DispatchQueue.main.async {
                self?.level = value
            }
        }
    }
}
