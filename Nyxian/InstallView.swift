import SwiftUI

struct InstallView: View {
    let onFinish: () -> Void

    @StateObject private var engine = InstallEngine()

    var body: some View {
        ZStack {
            NyxBackground()

            VStack(spacing: 20) {
                Text("Nyxian")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(LinearGradient.nyxAccent)
                    .padding(.top, 8)

                ProgressRing(percent: engine.percent)
                    .frame(width: 170, height: 170)

                VStack(spacing: 4) {
                    Text(engine.detail)
                        .font(.subheadline.weight(.medium))
                    if let downloaded = engine.downloadedMB {
                        Text(String(format: "%.1f из %.1f МБ", downloaded, InstallEngine.packageSizeMB))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 40)

                StageList(current: engine.stage, finished: engine.isFinished)

                LogConsole(lines: engine.log)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Экран не гаснет ни во время «установки», ни во время песни.
            UIApplication.shared.isIdleTimerDisabled = true
            engine.start(onFinish: onFinish)
        }
    }
}

private struct ProgressRing: View {
    let percent: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.nyxCard, lineWidth: 14)
            Circle()
                .trim(from: 0, to: percent / 100)
                .stroke(LinearGradient.nyxAccent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: percent)
            Text("\(Int(percent))%")
                .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
        }
    }
}

private struct StageList: View {
    let current: InstallEngine.Stage
    let finished: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(InstallEngine.Stage.allCases, id: \.rawValue) { stage in
                StageRow(number: stage.rawValue + 1, title: stage.title, phase: phase(of: stage))
            }
        }
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.nyxCard))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.nyxStroke))
    }

    private func phase(of stage: InstallEngine.Stage) -> StageRow.Phase {
        if stage.rawValue < current.rawValue { return .done }
        if stage == current { return finished ? .attention : .active }
        return .pending
    }
}

private struct StageRow: View {
    enum Phase {
        case pending, active, done, attention
    }

    let number: Int
    let title: String
    let phase: Phase

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 24, height: 24)
            Text("\(number). \(title)")
                .fontWeight(phase == .active ? .semibold : .regular)
                .foregroundColor(phase == .pending ? .secondary : .primary)
            Spacer()
            status
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var icon: some View {
        switch phase {
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .active:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .nyxAccent))
        case .attention:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
        case .pending:
            Image(systemName: "circle")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var status: some View {
        switch phase {
        case .done:
            Text("Готово")
                .font(.caption)
                .foregroundColor(.green)
        case .active:
            Text("Выполняется…")
                .font(.caption)
                .foregroundColor(.nyxAccent)
        case .attention:
            Text("Нужен патч")
                .font(.caption)
                .foregroundColor(.orange)
        case .pending:
            EmptyView()
        }
    }
}

private struct LogConsole: View {
    let lines: [InstallEngine.LogLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(lines.suffix(6)) { line in
                Text("\(line.kind.prefix) \(line.text)")
                    .foregroundColor(color(for: line.kind))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .font(.system(size: 11, design: .monospaced))
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black.opacity(0.35)))
    }

    private func color(for kind: InstallEngine.LogLine.Kind) -> Color {
        switch kind {
        case .info: return .secondary
        case .success: return .green
        case .warning: return .orange
        }
    }
}
