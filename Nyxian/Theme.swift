import SwiftUI

extension Color {
    static let nyxBackgroundTop = Color(red: 0.08, green: 0.05, blue: 0.18)
    static let nyxBackgroundBottom = Color(red: 0.02, green: 0.02, blue: 0.06)
    static let nyxAccent = Color(red: 0.64, green: 0.43, blue: 1.0)
    static let nyxAccentAlt = Color(red: 0.36, green: 0.62, blue: 1.0)
    static let nyxCard = Color.white.opacity(0.06)
    static let nyxStroke = Color.white.opacity(0.08)
}

extension LinearGradient {
    static let nyxAccent = LinearGradient(
        colors: [.nyxAccent, .nyxAccentAlt],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct NyxBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.nyxBackgroundTop, .nyxBackgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

extension InstallEngine.LogLine.Kind {
    var color: Color {
        switch self {
        case .info: return .secondary
        case .success: return .green
        case .warning: return .orange
        }
    }
}
