import SwiftUI

/// «Нужно вручную сделать патч»: фейковая видеоинструкция и просьба прибавить звук.
struct PatchView: View {
    let onPlay: () -> Void

    @StateObject private var volume = VolumeMonitor()
    @State private var isLoadingVideo = false
    @State private var isTooQuietWarned = false

    private let requiredLevel: Float = 0.3

    private var isLoudEnough: Bool {
        volume.level >= requiredLevel
    }

    var body: some View {
        ZStack {
            NyxBackground()

            VStack(spacing: 24) {
                header
                videoPlayer
                volumeCard
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.orange)
            Text("Нужно вручную сделать патч")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("Автоматическая установка не смогла применить патч. Посмотрите короткую видеоинструкцию — это займёт пару минут.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var videoPlayer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(white: 0.14), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(spacing: 6) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 34))
                Text("Ручной патч Nyxian")
                    .font(.headline)
                Text("шаг 1 из 3")
                    .font(.caption)
            }
            .foregroundColor(.white.opacity(0.25))

            Group {
                if isLoadingVideo {
                    VStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                        Text("Загрузка видео…")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                        .offset(x: 2)
                        .frame(width: 68, height: 68)
                        .background(Circle().fill(Color.white.opacity(0.9)))
                }
            }

            VStack {
                HStack {
                    Text("Видеоинструкция")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                    Spacer()
                }
                Spacer()
                videoControls
            }
            .padding(12)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.nyxStroke))
        .contentShape(Rectangle())
        .onTapGesture(perform: play)
    }

    private var videoControls: some View {
        HStack(spacing: 10) {
            Image(systemName: "play.fill")
            Text("0:00")
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(height: 4)
            Text("2:47")
            Image(systemName: speakerIcon)
        }
        .font(.caption2.monospacedDigit())
        .foregroundColor(.white.opacity(0.85))
    }

    private var volumeCard: some View {
        HStack(alignment: .top, spacing: 14) {
            TimelineView(.animation) { context in
                // Пока тихо, динамик «пульсирует».
                let phase = context.date.timeIntervalSinceReferenceDate * 2 * .pi / 1.2
                let scale = isLoudEnough ? 1 : 1 + 0.12 * sin(phase)

                Image(systemName: speakerIcon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(isLoudEnough ? .green : .orange)
                    .scaleEffect(scale)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 8) {
                Text(isLoudEnough ? "Громкость в порядке" : "Прибавьте громкость")
                    .font(.subheadline.weight(.semibold))
                Text(volumeHint)
                    .font(.caption)
                    .foregroundColor(isTooQuietWarned && !isLoudEnough ? .orange : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
                volumeBar
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.nyxCard))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isTooQuietWarned && !isLoudEnough ? Color.orange : Color.nyxStroke)
        )
    }

    private var volumeBar: some View {
        HStack(spacing: 10) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(isLoudEnough ? Color.green : Color.orange)
                        .frame(width: proxy.size.width * CGFloat(volume.level))
                        .animation(.easeOut(duration: 0.2), value: volume.level)
                    // Отметка нужного уровня.
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 2, height: 12)
                        .offset(x: proxy.size.width * CGFloat(requiredLevel) - 1)
                }
            }
            .frame(height: 8)

            Text("\(Int((volume.level * 100).rounded()))%")
                .font(.caption.monospacedDigit().weight(.semibold))
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var volumeHint: String {
        if isLoudEnough {
            return "Можно смотреть видео."
        }
        if isTooQuietWarned {
            return "Слишком тихо! Прибавьте звук кнопками сбоку — без звука инструкцию не понять."
        }
        return "В видео голосовые инструкции — поставьте громкость не меньше \(Int((requiredLevel * 100).rounded()))%."
    }

    private var speakerIcon: String {
        switch volume.level {
        case ..<0.01: return "speaker.slash.fill"
        case ..<0.34: return "speaker.wave.1.fill"
        case ..<0.67: return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    private func play() {
        guard !isLoadingVideo else { return }
        // Первый раз при тихом звуке просим прибавить, со второго нажатия пускаем в любом случае.
        if !isLoudEnough && !isTooQuietWarned {
            isTooQuietWarned = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        isLoadingVideo = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            onPlay()
        }
    }
}
