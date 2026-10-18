import SwiftUI

/// «Нужно вручную сделать патч»: консоль ждёт, пока громкость поднимут до нужного уровня,
/// и сама запускает финал — без кнопок.
struct PatchView: View {
    let onConfirmed: () -> Void

    @StateObject private var volume = VolumeMonitor()
    @State private var lines: [InstallEngine.LogLine] = []
    @State private var isWaiting = false
    @State private var isConfirmed = false

    private let requiredLevel: Float = 0.5

    private static let intro: [(delay: Double, kind: InstallEngine.LogLine.Kind, text: String)] = [
        (0.4, .warning, "Автопатч не применён (код 0x1F)"),
        (0.8, .info, "Переход в режим ручного патча…"),
        (0.8, .info, "Подтверждение кнопками громкости"),
        (0.8, .warning, "Ожидание патча от пользователя…"),
    ]

    private var isLoudEnough: Bool {
        isLoud(volume.level)
    }

    private var volumePercent: Int {
        Int((volume.level * 100).rounded())
    }

    private var requiredPercent: Int {
        Int((requiredLevel * 100).rounded())
    }

    var body: some View {
        ZStack {
            NyxBackground()

            VStack(spacing: 24) {
                header
                console
                volumeCard
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
        }
        .task { await playIntro() }
        // Значение берём из события: @Published шлёт его до записи, и volume.level там ещё старый.
        .onReceive(volume.$level) { level in confirmIfReady(level) }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.orange)
            Text("Нужно вручную сделать патч")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("Автопатч не смог применить изменения. Подтвердите патч вручную — прибавьте громкость кнопками сбоку, дальше всё произойдёт автоматически.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var console: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                ForEach([Color.red, .yellow, .green], id: \.self) { color in
                    Circle()
                        .fill(color.opacity(0.8))
                        .frame(width: 9, height: 9)
                }
                Spacer()
                Text(verbatim: "nyxian — manual patch")
                    .foregroundColor(.secondary)
                Spacer()
                Color.clear.frame(width: 39, height: 9)
            }
            .font(.system(size: 11, design: .monospaced))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines) { line in
                    Text("\(line.kind.prefix) \(line.text)")
                        .foregroundColor(line.kind.color)
                }
                if isWaiting && !isConfirmed {
                    TimelineView(.periodic(from: .now, by: 0.5)) { context in
                        let isCursorOn = Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0

                        Text(verbatim: "> громкость \(volumePercent)% / \(requiredPercent)%" + (isCursorOn ? " ▌" : ""))
                            .foregroundColor(.white)
                    }
                }
            }
            .font(.system(size: 12, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .padding(12)
        }
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black.opacity(0.55)))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.nyxStroke))
        // Скрытый запасной выход, если громкость не меняется (например, в симуляторе).
        .onLongPressGesture(minimumDuration: 2) { confirm() }
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
                Text(isConfirmed ? "Патч подтверждён" : "Прибавьте громкость")
                    .font(.subheadline.weight(.semibold))
                Text(verbatim: isConfirmed
                    ? "Применяем патч…"
                    : "Нажимайте кнопку громкости вверх до отметки \(requiredPercent)% — патч применится сам.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                volumeBar
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.nyxCard))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isLoudEnough ? Color.green.opacity(0.6) : Color.nyxStroke)
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

            Text(verbatim: "\(volumePercent)%")
                .font(.caption.monospacedDigit().weight(.semibold))
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var speakerIcon: String {
        switch volume.level {
        case ..<0.01: return "speaker.slash.fill"
        case ..<0.34: return "speaker.wave.1.fill"
        case ..<0.67: return "speaker.wave.2.fill"
        default: return "speaker.wave.3.fill"
        }
    }

    private func playIntro() async {
        confirmIfReady(volume.level)
        guard lines.isEmpty else { return }
        for entry in Self.intro {
            try? await Task.sleep(nanoseconds: UInt64(entry.delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            append(entry.kind, entry.text)
        }
        isWaiting = true
    }

    /// Финал запускается в тот же миг, когда громкость дошла до нужной, — даже посреди вступления.
    private func confirmIfReady(_ level: Float) {
        guard isLoud(level) else { return }
        confirm()
    }

    private func isLoud(_ level: Float) -> Bool {
        // Небольшой допуск: 8 шагов из 16 система может вернуть как 0.4999….
        level >= requiredLevel - 0.01
    }

    private func confirm() {
        guard !isConfirmed else { return }
        isConfirmed = true
        // Песня стартует сразу, не дожидаясь смены экрана.
        SongPlayer.shared.play()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onConfirmed()
    }

    private func append(_ kind: InstallEngine.LogLine.Kind, _ text: String) {
        lines.append(InstallEngine.LogLine(id: lines.count, kind: kind, text: text))
    }
}
