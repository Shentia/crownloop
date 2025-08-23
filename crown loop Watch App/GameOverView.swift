import SwiftUI

struct GameOverView: View {
    @ObservedObject var engine: GameEngine
    var onRetry: () -> Void
    var onMenu: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Game Over")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)

            Text("Score: \(engine.score)")
                .font(.headline)
                .foregroundColor(.white)
                .accessibilityLabel("Score")
                .accessibilityValue("\(engine.score)")

            Text("High Score: \(engine.highScore)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .accessibilityLabel("High score")
                .accessibilityValue("\(engine.highScore)")

            HStack(spacing: 12) {
                Button("Retry") {
                    onRetry()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Capsule().fill(Color.white))
                .foregroundColor(.black)

                Button("Menu") {
                    onMenu()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Capsule().stroke(Color.white, lineWidth: 1))
                .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black)
    }
}
