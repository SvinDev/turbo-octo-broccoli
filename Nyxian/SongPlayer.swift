import AVFoundation

/// Играет первый аудиофайл из папки Music внутри приложения, по кругу.
final class SongPlayer {
    static let shared = SongPlayer()

    private var player: AVAudioPlayer?

    func play() {
        guard let url = Self.songURL() else {
            print("Nyxian: в папке Music нет аудиофайла")
            return
        }
        do {
            // .playback — звук играет даже при включённом беззвучном режиме.
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 1
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            print("Nyxian: не удалось включить песню: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private static func songURL() -> URL? {
        for ext in ["mp3", "m4a", "aac", "wav"] {
            if let url = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Music")?.first {
                return url
            }
        }
        return nil
    }
}
