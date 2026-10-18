import Combine
import UIKit

/// Фейковая «установка» примерно на полторы минуты, с подвисаниями на некоторых процентах.
@MainActor
final class InstallEngine: ObservableObject {
    enum Stage: Int, CaseIterable {
        case search, download, install, verify

        var title: String {
            switch self {
            case .search: return "Поиск"
            case .download: return "Загрузка"
            case .install: return "Установка"
            case .verify: return "Проверка"
            }
        }
    }

    struct LogLine: Identifiable {
        enum Kind {
            case info, success, warning

            var prefix: String {
                switch self {
                case .info: return "[*]"
                case .success: return "[+]"
                case .warning: return "[!]"
                }
            }
        }

        let id: Int
        let kind: Kind
        let text: String
    }

    /// Шаг сценария: дойти до `to` процентов за `duration` секунд.
    /// Если `to` равен текущему проценту — это подвисание.
    private struct Step {
        var stage: Stage
        var to: Double
        var duration: Double
        var detail: String? = nil
        var log: String? = nil
        var kind: LogLine.Kind = .info
    }

    static let packageSizeMB = 187.4
    private static let downloadRange = 13.0...52.0

    @Published private(set) var percent: Double = 0
    @Published private(set) var stage: Stage = .search
    @Published private(set) var detail = ""
    @Published private(set) var log: [LogLine] = []
    @Published private(set) var isFinished = false

    private var task: Task<Void, Never>?

    /// Сколько «скачано» — показывается только на этапе загрузки.
    var downloadedMB: Double? {
        guard stage == .download else { return nil }
        let range = Self.downloadRange
        let fraction = (percent - range.lowerBound) / (range.upperBound - range.lowerBound)
        return min(max(fraction, 0), 1) * Self.packageSizeMB
    }

    func start(onFinish: @escaping () -> Void) {
        guard task == nil else { return }
        task = Task {
            for step in Self.makeScript() {
                apply(step)
                // Небольшой разброс, чтобы каждый запуск выглядел по-разному.
                await advance(to: step.to, over: step.duration * Double.random(in: 0.95...1.15))
            }
            isFinished = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            onFinish()
        }
    }

    private func apply(_ step: Step) {
        if step.stage != stage {
            stage = step.stage
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        if let detail = step.detail {
            self.detail = detail
        }
        if let text = step.log {
            log.append(LogLine(id: log.count, kind: step.kind, text: text))
        }
    }

    private func advance(to target: Double, over duration: Double) async {
        let start = percent
        let begin = Date()
        while !Task.isCancelled {
            // Неровный шаг обновления — как у настоящих установщиков.
            let tick = Double.random(in: 0.08...0.3)
            try? await Task.sleep(nanoseconds: UInt64(tick * 1_000_000_000))
            let t = min(Date().timeIntervalSince(begin) / duration, 1)
            percent = start + (target - start) * t
            if t >= 1 { return }
        }
    }

    private static func makeScript() -> [Step] {
        let device = "\(DeviceInfo.modelName), iOS \(DeviceInfo.systemVersion)"
        let size = String(format: "%.1f", packageSizeMB)

        return [
            // 1. Поиск: 0 → 13 %
            Step(stage: .search, to: 3, duration: 2, detail: "Поиск совместимых компонентов…", log: "Запуск Nyxian 2.4.1"),
            Step(stage: .search, to: 8, duration: 3, log: "Устройство: \(device)"),
            Step(stage: .search, to: 8, duration: 3.5, detail: "Поиск зеркала загрузки…", log: "Опрос серверов загрузки…"),
            Step(stage: .search, to: 13, duration: 2.5, log: "Найден сервер: eu-2.cdn.nyxian.app", kind: .success),

            // 2. Загрузка: 13 → 52 %
            Step(stage: .download, to: 15, duration: 2, detail: "Загрузка пакетов…", log: "Загрузка nyxian-core.pkg (\(size) МБ)"),
            Step(stage: .download, to: 31, duration: 7),
            Step(stage: .download, to: 31, duration: 5, detail: "Переподключение…", log: "Низкая скорость соединения, переподключение…", kind: .warning),
            Step(stage: .download, to: 46, duration: 7, detail: "Загрузка пакетов…", log: "Соединение восстановлено", kind: .success),
            Step(stage: .download, to: 51, duration: 3),
            Step(stage: .download, to: 51, duration: 3, detail: "Проверка контрольной суммы…", log: "Проверка контрольной суммы пакета…"),
            Step(stage: .download, to: 52, duration: 1, log: "Пакет загружен", kind: .success),

            // 3. Установка: 52 → 84 %
            Step(stage: .install, to: 60, duration: 5, detail: "Распаковка…", log: "Распаковка архива…"),
            Step(stage: .install, to: 66, duration: 4, detail: "Установка компонентов…", log: "Установка nyxian-core (1/3)"),
            Step(stage: .install, to: 66, duration: 7, detail: "Настройка окружения…", log: "Настройка окружения, не закрывайте приложение", kind: .warning),
            Step(stage: .install, to: 74, duration: 3.5, detail: "Установка компонентов…", log: "Установка nyxian-ui (2/3)"),
            Step(stage: .install, to: 84, duration: 6, log: "Установка nyxian-extras (3/3)"),
            Step(stage: .install, to: 84, duration: 3, detail: "Регистрация компонентов…", log: "Регистрация компонентов…"),

            // 4. Проверка: 84 → 100 %
            Step(stage: .verify, to: 91, duration: 4, detail: "Проверка целостности…", log: "Проверка целостности файлов…"),
            Step(stage: .verify, to: 99, duration: 5, detail: "Проверка подписи…", log: "Проверка подписи…"),
            Step(stage: .verify, to: 99, duration: 7, detail: "Завершение…", log: "Финальная проверка…"),
            Step(stage: .verify, to: 100, duration: 1, detail: "Требуется ручной патч", log: "Автопатч не применён — нужен ручной патч", kind: .warning),
        ]
    }
}
