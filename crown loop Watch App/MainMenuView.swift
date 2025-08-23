import SwiftUI

struct MainMenuView: View {
    @ObservedObject var engine: GameEngine
    @State private var isPlaying: Bool = false
    @State private var showGKError: Bool = false
    private let gk = GameCenterManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Spacer()
                Text("Crown Loop")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .accessibilityAddTraits(.isHeader)

                Text("High Score: \(engine.highScore)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .accessibilityLabel("High score")
                    .accessibilityValue("\(engine.highScore)")

                // Skin picker
                VStack(spacing: 6) {
                    Text("Ring Skin")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))

                    Picker("Skin", selection: Binding(get: { engine.skin }, set: { engine.skin = $0 })) {
                        ForEach(GameEngine.RingSkin.allCases, id: \.self) { s in
                            Text(s.rawValue.capitalized)
                                .tag(s)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .accessibilityLabel("Ring skin")
                }

                Spacer()

                NavigationLink(destination: GameView(engine: engine), isActive: $isPlaying) {
                    Button("Start") {
                        engine.startNewGame()
                        engine.nextGate()
                        isPlaying = true
                    }
                    .font(.headline)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Capsule().fill(Color.white))
                    .foregroundColor(.black)
                }

                NavigationLink(destination: SettingsView()) {
                    Text("Settings")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }

                Button(action: {
                    if gk.isAuthenticated {
                        gk.openGameCenter()
                    } else {
                        showGKError = true
                    }
                }) {
                    Text("Leaderboard")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .alert(isPresented: $showGKError) {
                    Alert(title: Text("Game Center Unavailable"), message: Text("Please sign into Game Center on your device."), dismissButton: .default(Text("OK")))
                }

                Spacer()
            }
            .padding()
            .background(Color.black)
        }
    }
}
