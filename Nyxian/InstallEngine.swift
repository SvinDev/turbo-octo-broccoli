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

    /// Сколько длится вся «установка» — сценарий ниже сжимается под это время целиком.
    static let totalDuration: TimeInterval = 35
    /// Пауза на «Требуется ручной патч» перед экраном патча (входит в totalDuration).
    private static let finishPause: TimeInterval = 1.2

    static let packageSizeMB = 48.6
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
        let script = Self.makeScript()
        let scriptLength = script.reduce(0) { $0 + $1.duration }
        let timeScale = (Self.totalDuration - Self.finishPause) / scriptLength
        task = Task {
            for step in script {
                apply(step)
                // Небольшой разброс, чтобы каждый запуск выглядел по-разному.
                await advance(to: step.to, over: step.duration * timeScale * Double.random(in: 0.9...1.1))
            }
            isFinished = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            try? await Task.sleep(nanoseconds: UInt64(Self.finishPause * 1_000_000_000))
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
            // Неровный шаг обновления — как у настоящих установщиков, но без перебора по времени.
            let remaining = duration - Date().timeIntervalSince(begin)
            let tick = min(Double.random(in: 0.08...0.3), max(remaining, 0.01))
            try? await Task.sleep(nanoseconds: UInt64(tick * 1_000_000_000))
            let t = min(Date().timeIntervalSince(begin) / duration, 1)
            percent = start + (target - start) * t
            if t >= 1 { return }
        }
    }

    private static func makeScript() -> [Step] {
        let iosVersion = DeviceInfo.systemVersion
        let device = "\(DeviceInfo.modelName), iOS \(iosVersion)"
        let size = String(format: "%.1f", packageSizeMB)

        // 1. Поиск: 0 → 13 %
        var steps = [
            Step(stage: .search, to: 1.5, duration: 1, detail: "Поиск Standoff 2…", log: "Nyxian mod menu 2.4.1"),
            Step(stage: .search, to: 3, duration: 1, log: "by @pablofsky1 x @Chekush671"),
        ]
        if DeviceInfo.needsLocalPatch {
            // iOS вне диапазона «патчится локально» за то же время, что и обычное определение устройства.
            steps += [
                Step(stage: .search, to: 5.5, duration: 1.5, log: "Устройство: \(device)"),
                Step(stage: .search, to: 8, duration: 1.5, log: "iOS \(iosVersion): локальный патч применён", kind: .success),
            ]
        } else {
            steps.append(Step(stage: .search, to: 8, duration: 3, log: "Устройство: \(device)"))
        }

        steps += [
            Step(stage: .search, to: 8, duration: 3.5, detail: "Поиск процесса игры…", log: "Ожидание процесса Standoff2…"),
            Step(stage: .search, to: 13, duration: 2.5, log: "Найден процесс Standoff2 (pid 1337)", kind: .success),

            // 2. Загрузка: 13 → 52 %
            Step(stage: .download, to: 15, duration: 2, detail: "Загрузка мод-меню…", log: "Загрузка nyxian_menu.dylib (\(size) МБ)"),
            Step(stage: .download, to: 31, duration: 7),
            Step(stage: .download, to: 31, duration: 5, detail: "Переподключение…", log: "Сервер перегружен, переподключение…", kind: .warning),
            Step(stage: .download, to: 46, duration: 7, detail: "Загрузка мод-меню…", log: "Подключено к зеркалу eu-2.cdn.nyxian.app", kind: .success),
            Step(stage: .download, to: 51, duration: 3, log: "Загрузка offsets для Standoff 2"),
            Step(stage: .download, to: 51, duration: 3, detail: "Проверка контрольной суммы…", log: "Проверка контрольной суммы…"),
            Step(stage: .download, to: 52, duration: 1, log: "Мод-меню загружено", kind: .success),

            // 3. Установка: 52 → 84 %
            Step(stage: .install, to: 60, duration: 5, detail: "Распаковка…", log: "Дамп il2cpp-метаданных…"),
            Step(stage: .install, to: 66, duration: 4, detail: "Инжект в процесс…", log: "Инжект nyxian_menu.dylib в Standoff2"),
            Step(stage: .install, to: 66, duration: 7, detail: "Обход античита…", log: "Обход античита, не закрывайте приложение", kind: .warning),
            Step(stage: .install, to: 74, duration: 3.5, detail: "Установка модулей…", log: "Модули: Aimbot, Wallhack, ESP"),
            Step(stage: .install, to: 84, duration: 6, log: "Модули: SkinChanger, Bhop, NoRecoil"),
            Step(stage: .install, to: 84, duration: 3, detail: "Установка хуков…", log: "Установка хуков (47/47)…"),

            // 4. Проверка: 84 → 95 %, дальше — «ручной патч»
            Step(stage: .verify, to: 89, duration: 4, detail: "Проверка целостности…", log: "Проверка обхода античита…"),
            Step(stage: .verify, to: 95, duration: 5, detail: "Применение патча…", log: "Применение автопатча…"),
            Step(stage: .verify, to: 95, duration: 6, log: "Ожидание ответа системы…"),
            Step(stage: .verify, to: 95, duration: 1.5, detail: "Требуется ручной патч", log: "Автопатч не применён — нужен ручной патч", kind: .warning),
        ]
        return steps
    }
}
