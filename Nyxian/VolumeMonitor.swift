import AVFoundation
import Combine
import UIKit

/// Следит за системной громкостью — меняется кнопками громкости на телефоне.
final class VolumeMonitor: ObservableObject {
    @Published private(set) var level: Float

    private var observation: NSKeyValueObservation?
    private var tokens: [NSObjectProtocol] = []

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

        // После сворачивания, звонка, Siri или будильника iOS выключает сессию,
        // и кнопки громкости перестают отслеживаться — включаем её обратно.
        let center = NotificationCenter.default
        tokens = [
            center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                self?.reactivate()
            },
            center.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { [weak self] note in
                guard let rawType = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      AVAudioSession.InterruptionType(rawValue: rawType) == .ended else { return }
                self?.reactivate()
            },
        ]
    }

    deinit {
        for token in tokens {
            NotificationCenter.default.removeObserver(token)
        }
    }

    private func reactivate() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
        // Перечитываем: громкость могли прибавить, пока приложение было в фоне.
        // Присваивание публикуется даже без изменения значения — PatchView сразу его проверит.
        level = session.outputVolume
    }
}
