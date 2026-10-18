import SwiftUI

struct RootView: View {
    private enum Screen {
        case home, installing, patch, prank
    }

    @State private var screen: Screen = .home

    var body: some View {
        ZStack {
            switch screen {
            case .home:
                HomeView { show(.installing) }
                    .transition(.opacity)
            case .installing:
                InstallView { show(.patch) }
                    .transition(.opacity)
            case .patch:
                PatchView { show(.prank) }
                    .transition(.opacity)
            case .prank:
                PrankView()
                    .transition(.opacity)
            }
        }
    }

    private func show(_ next: Screen) {
        withAnimation(.easeInOut(duration: 0.5)) {
            screen = next
        }
    }
}
