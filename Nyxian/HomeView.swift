import SwiftUI

struct HomeView: View {
    let onLaunch: () -> Void

    private let needsLocalPatch = DeviceInfo.needsLocalPatch
    private let isUnsupported = DeviceInfo.isUnsupported

    @State private var exploit = Exploit.recommended

    var body: some View {
        ZStack {
            NyxBackground()

            GeometryReader { proxy in
                // На низких экранах (SE, mini) всё компактнее, чтобы влезло без прокрутки.
                let isCompact = proxy.size.height < 760

                VStack(spacing: isCompact ? 14 : 24) {
                    Spacer(minLength: 0)
                    header(isCompact: isCompact)
                    infoCard
                    exploitCard
                    Spacer(minLength: 0)
                    launchButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func header(isCompact: Bool) -> some View {
        VStack(spacing: 10) {
            if !isCompact {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(LinearGradient.nyxAccent)
            }
            Text("Nyxian")
                .font(.system(size: isCompact ? 44 : 52, weight: .heavy, design: .rounded))
                .foregroundStyle(LinearGradient.nyxAccent)
            VStack(spacing: 4) {
                Text(verbatim: "@pablofsky1 x @Chekush671")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.nyxAccent)
                Text(verbatim: "internal mod menu for “standoff2” for iOS \(DeviceInfo.minSupported)-\(DeviceInfo.maxSupported)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            InfoRow(icon: "iphone", title: "Устройство", value: DeviceInfo.modelName)
            Divider().overlay(Color.nyxStroke)
            InfoRow(icon: "gearshape.fill", title: "Версия iOS", value: "iOS \(DeviceInfo.systemVersion)")
            Divider().overlay(Color.nyxStroke)
            InfoRow(icon: "checkmark.shield.fill", title: "Поддерживаемые iOS", value: DeviceInfo.supportedRange)
            Divider().overlay(Color.nyxStroke)
            InfoRow(
                icon: isUnsupported ? "xmark.octagon.fill" : "checkmark.circle.fill",
                title: "Статус",
                value: isUnsupported ? "Не поддерживается" : needsLocalPatch ? "Совместимо · локальный патч" : "Совместимо",
                valueColor: isUnsupported ? .red : .green
            )
        }
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.nyxCard))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.nyxStroke))
    }

    private var exploitCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ЭКСПЛОИТ")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.nyxAccent)
                    .frame(width: 24)
                Menu {
                    Picker("Эксплоит", selection: $exploit) {
                        ForEach(Exploit.allCases) { exploit in
                            Text(exploit.name).tag(exploit)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(exploit.name)
                            .font(.title3.weight(.semibold))
                            .contentTransition(.identity)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.nyxAccent)
                    // Метка на всю ширину и прижата влево — иначе меню центрирует название,
                    // и оно ездит влево-вправо при смене эксплоита (названия разной длины).
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
            }
            // Две строки фиксированной высоты — при смене эксплоита блок не меняет размер и экран не прыгает.
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: isExploitSupported
                    ? "✓ Поддерживается на iOS \(DeviceInfo.systemVersion)"
                    : "✕ Не поддерживается на iOS \(DeviceInfo.systemVersion)")
                    .foregroundColor(isExploitSupported ? .green : .red)
                Text(verbatim: exploit.supportedRange)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .transaction { $0.animation = nil }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.nyxCard))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.nyxStroke))
    }

    /// Зависит и от выбранного эксплоита, и от версии iOS.
    private var isExploitSupported: Bool {
        exploit.supports(DeviceInfo.version)
    }

    private var launchButton: some View {
        // С неподдерживаемым эксплоитом запуск недоступен.
        Button(action: onLaunch) {
            Text("Запуск")
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(LinearGradient.nyxAccent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .opacity(isExploitSupported ? 1 : 0.35)
                .shadow(color: .nyxAccent.opacity(isExploitSupported ? 0.5 : 0), radius: 16, y: 6)
        }
        .disabled(!isExploitSupported)
        .transaction { $0.animation = nil }
    }
}

private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.nyxAccent)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
