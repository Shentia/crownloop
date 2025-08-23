import SwiftUI

/// Main game view for Crown Loop (watchOS).
///
/// This view is purely UI: it observes `GameEngine` and forwards crown input
/// via `bindingForRingAngle(engine:)`. All game logic lives in `GameEngine`.
struct GameView: View {
    @ObservedObject var engine: GameEngine
    @State private var lastTimelineDate: Date? = nil
    @State private var hasScoredCurrentGate: Bool = false
    @State private var prevScore: Int = 0
    @State private var prevLives: Int = 3
    @State private var prevHighScore: Int = 0

    // Local display constant for maximum per-gate duration used for UI smoothing.
    // The true per-gate duration is managed by the engine; UI uses 2.0 as a
    // reasonable cap for the timer arc display.
    private let uiMaxGateDuration: TimeInterval = 2.0
    @State private var ringScale: CGFloat = 1.0
    @State private var ringPulse: Bool = false
    @State private var missFlash: Bool = false

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)

                    // Timer arc + play area grouped into a dedicated subview to limit redraw scope.
                    let diameter = min(geo.size.width, geo.size.height) * 0.75
                    ZStack {
                        // Background timer arc
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: min(geo.size.width, geo.size.height) * 0.9,
                                   height: min(geo.size.width, geo.size.height) * 0.9)

                        Circle()
                            .trim(from: 0, to: timerProgress)
                            .rotation(Angle(degrees: -90))
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: min(geo.size.width, geo.size.height) * 0.9,
                                   height: min(geo.size.width, geo.size.height) * 0.9)

                        PlayAreaView(
                            ringAngle: engine.ringAngle,
                            gateAngle: engine.gateAngle,
                            diameter: diameter,
                            skin: engine.skin,
                            timerProgress: timerProgress,
                            ringScale: ringScale,
                            ringPulse: ringPulse,
                            isGameOver: engine.isGameOver,
                            onAlignedCheck: { engine.isAligned() },
                            onHit: {
                                engine.registerHit()
                                engine.nextGate()
                            }
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // HUD separated to avoid redrawing the entire play area on score/lives updates.
                    VStack {
                        GameHUD(score: engine.score, streak: engine.streak, lives: engine.lives)
                            .padding(.horizontal, 10)
                        Spacer()
                    }

                    if engine.isGameOver {
                        VStack {
                            Spacer()
                            Text("Rotate the Digital Crown to align the ring with the gate")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.bottom, 6)
                        }
                    }

                    if engine.isGameOver || engine.timeRemaining <= 0 {
                        Button(action: {
                            engine.startNewGame()
                            engine.nextGate()
                            lastTimelineDate = nil
                        }) {
                            Text(engine.isGameOver ? "Restart" : "Start")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(Capsule().fill(Color.white))
                        }
                    }
                }
                // Update timing-driven logic via modifiers instead of placing
                // imperative statements directly in the ViewBuilder (which
                // causes 'buildExpression' errors).
                .onAppear {
                    lastTimelineDate = timeline.date
                }
                .onChange(of: timeline.date) { now in
                    let delta: TimeInterval
                    if let last = lastTimelineDate {
                        delta = now.timeIntervalSince(last)
                    } else {
                        delta = 0
                    }

                    if delta > 0 {
                        engine.tick(delta: delta)
                    }
                    lastTimelineDate = now

                    if engine.timeRemaining <= 0 && !engine.isGameOver {
                        engine.registerMiss()
                        if !engine.isGameOver {
                            engine.nextGate()
                        }
                    }
                }
                // Crown input kept on the top-level container (binding writes to engine)
                .focusable(true)
                .digitalCrownRotation(bindingForRingAngle(engine: engine), from: 0, through: 360, by: 1)
                // Haptics + animations respond to changes; keep these handlers shallow and time-limited.
                .onChange(of: engine.score) { new in
                    if new > prevScore {
                        if Haptics.enabled { Haptics.successHit() }
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            ringScale = 1.05
                        }
                        ringPulse = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                ringScale = 1.0
                            }
                            ringPulse = false
                        }
                    }
                    prevScore = new
                }
                .onChange(of: engine.lives) { new in
                    if new < prevLives {
                        if Haptics.enabled { Haptics.missLife() }
                        missFlash = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            missFlash = false
                        }
                    }
                    prevLives = new
                }
                .onChange(of: engine.highScore) { new in
                    guard Haptics.enabled else { prevHighScore = new; return }
                    if new > prevHighScore {
                        Haptics.newHighScore()
                    }
                    prevHighScore = new
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(missFlash ? 0.9 : 0.0), lineWidth: missFlash ? 4 : 0)
                        .animation(.easeOut(duration: 0.18), value: missFlash)
                )
                .sheet(isPresented: Binding(get: { engine.isGameOver }, set: { _ in }), onDismiss: {}) {
                    GameOverView(engine: engine, onRetry: {
                        engine.startNewGame()
                        engine.nextGate()
                        lastTimelineDate = nil
                    }, onMenu: {
                        engine.startNewGame()
                    })
                }
            }
        }
    }

    /// Compute timer progress for the UI as a fraction 0...1 using a UI cap.
    private var timerProgress: CGFloat {
        // Use the engine's current per-gate duration for accurate progress
        let gateDuration = max(0.001, engine.perGateDuration)
        let fraction = engine.timeRemaining / gateDuration
        return CGFloat(min(max(fraction, 0), 1))
    }
}

// Preview for Xcode canvas (watchOS preview)
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GameView(engine: GameEngine())
        }
    }
}

// MARK: - Subviews to minimize redraw regions

/// PlayAreaView contains the composited ring and gate visuals and handles
/// alignment detection via callbacks so it doesn't directly observe the engine.
struct PlayAreaView: View {
    let ringAngle: Double
    let gateAngle: Double
    let diameter: CGFloat
    let skin: GameEngine.RingSkin
    let timerProgress: CGFloat
    let ringScale: CGFloat
    let ringPulse: Bool
    let isGameOver: Bool

    let onAlignedCheck: () -> Bool
    let onHit: () -> Void

    @State private var hasScoredCurrentGate: Bool = false

    var body: some View {
        ZStack {
            RingView(ringAngle: ringAngle, diameter: diameter, lineWidth: 12, skin: skin, scale: ringScale, pulse: ringPulse)
            GateView(gateAngle: gateAngle, diameter: diameter, segmentDegrees: 20, skin: skin, progress: timerProgress)
                .onChange(of: gateAngle) { _ in hasScoredCurrentGate = false }
                .onAppear { hasScoredCurrentGate = false }
                .onChange(of: ringAngle) { _ in
                    guard !hasScoredCurrentGate, !isGameOver else { return }
                    if onAlignedCheck() {
                        hasScoredCurrentGate = true
                        onHit()
                    }
                }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(Text("Play area"))
    .accessibilityValue(Text("Ring angle \(Int(ringAngle)) degrees. Gate angle \(Int(gateAngle)) degrees. Time remaining \(Int(timerProgress * 100)) percent."))
    }
}

struct GameHUD: View {
    let score: Int
    let streak: Int
    let lives: Int

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Score")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.75))
                Text("\(score)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            Spacer()

            VStack(alignment: .center, spacing: 2) {
                Text("Streak")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.75))
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(streak)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<3) { idx in
                    let filled = idx < lives
                    Image(systemName: filled ? "heart.fill" : "heart")
                        .foregroundColor(filled ? .pink : .white.opacity(0.25))
                        .font(.caption)
                }
            }
        }
    }
}
