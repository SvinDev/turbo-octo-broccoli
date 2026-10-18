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
                // На низких экранах (iPhone SE) шапка компактнее, чтобы всё влезло без прокрутки.
                let isCompact = proxy.size.height < 700

                VStack(spacing: 24) {
                    Spacer()
                    header(isCompact: isCompact)
                    infoCard
                    exploitCard
                    Spacer()
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
                Text(verbatim: "@pablofskyyy x @Chekush671")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.nyxAccent)
                Text(verbatim: "external mod menu for “standoff2” for iOS 17.0-26.0.1")
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
                Picker("Эксплоит", selection: $exploit) {
                    ForEach(Exploit.available) { exploit in
                        Text(exploit.name).tag(exploit)
                    }
                }
                .pickerStyle(.menu)
                .tint(.nyxAccent)
                Spacer(minLength: 0)
            }
            Text(verbatim: exploitNote.text)
                .font(.caption)
                .foregroundColor(exploitNote.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.nyxCard))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.nyxStroke))
    }

    private var exploitNote: (text: String, color: Color) {
        let ios = "iOS \(DeviceInfo.systemVersion)"
        if isUnsupported && exploit == .cryptsn0w {
            return ("CryptSn0w работает до iOS 27.1 — \(ios) не поддерживается", .red)
        }
        if exploit.supports(DeviceInfo.version) {
            return ("\(exploit.supportedRange) · подходит для \(ios)", .green)
        }
        return ("\(exploit.supportedRange) · не рекомендуется для \(ios)", .orange)
    }

    private var launchButton: some View {
        Button(action: onLaunch) {
            Text("Запуск")
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(LinearGradient.nyxAccent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .nyxAccent.opacity(0.5), radius: 16, y: 6)
        }
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
