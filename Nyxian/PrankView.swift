import SwiftUI

struct PrankView: View {
    /// Один полный оборот картинки, в секундах.
    private let secondsPerTurn = 1.5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TimelineView(.animation) { context in
                let elapsed = context.date.timeIntervalSinceReferenceDate
                let angle = elapsed.truncatingRemainder(dividingBy: secondsPerTurn) / secondsPerTurn * 360

                Image("PrankCat")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320, maxHeight: 320)
                    .rotationEffect(.degrees(angle))
            }
            .padding(24)
        }
        .onAppear { SongPlayer.shared.play() }
        .onDisappear { SongPlayer.shared.stop() }
    }
}
