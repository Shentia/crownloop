import Foundation
import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Game engine that drives the Crown Loop game logic.
///
/// This is a pure Swift model (no UI, no timers). It is ObservableObject so views
/// can observe changes to published properties. The class provides helper
/// pure functions for normalization and angular math so they are unit-testable.
final class GameEngine: ObservableObject {
    // MARK: - Published game state

    /// Current score.
    @Published var score: Int = 0

    /// Lives remaining (0...3). Max is 3.
    @Published var lives: Int = 3

    /// Current hit streak.
    @Published var streak: Int = 0

    /// Persisted high score (loaded/saved via UserDefaults with key "highScore").
    @Published var highScore: Int = 0

    /// Angle of the player's ring in degrees [0, 360).
    @Published var ringAngle: Double = 0 {
        didSet {
            // Normalize when set. Only re-assign if normalization actually changes value
            // to avoid unnecessary publishes.
            let normalized = Self.normalize(angle: ringAngle)
            if normalized != ringAngle {
                ringAngle = normalized
            }
        }
    }

    /// Angle of the gate in degrees [0, 360).
    @Published var gateAngle: Double = 0 {
        didSet {
            let normalized = Self.normalize(angle: gateAngle)
            if normalized != gateAngle {
                gateAngle = normalized
            }
        }
    }

    /// Time remaining for the current gate. This is the per-gate countdown that
    /// starts at `perGateDuration` for each gate and is decreased via `tick(delta:)`.
    @Published var timeRemaining: TimeInterval = 0

    /// Flag set when the game is over.
    @Published var isGameOver: Bool = false

    /// Daily challenge mode flag. When true, gates are produced from a seeded RNG
    /// so the sequence is repeatable for the day.
    @Published var isDailyChallenge: Bool = false

    /// Best score for today's daily challenge. Persisted to UserDefaults key "dailyBest"
    @Published var dailyBest: Int = 0

    /// Internal seeded RNG used for daily challenge sequences. Optional when not in daily mode.
    private var dailyRNG: SplitMix64? = nil

    /// Visual skin for ring/gate selection. Persisted via UserDefaults key "ringSkin".
    @Published var skin: RingSkin = .neonCyan {
        didSet {
            saveSkin()
        }
    }

    // MARK: - Configuration & internal state

    /// UserDefaults key for high score.
    private static let highScoreKey = "highScore"
    private static let skinKey = "ringSkin"
    private static let dailyBestKey = "dailyBest"
    private static let dailyBestDateKey = "dailyBestDate"

    /// Base per-gate duration which will be reduced as difficulty increases.
    private(set) var perGateDuration: TimeInterval = 2.0

    /// Minimum per-gate duration (difficulty cap).
    private let minPerGateDuration: TimeInterval = 0.8

    /// Amount to reduce perGateDuration after each difficulty step.
    private let perGateReduction: TimeInterval = 0.2

    /// Points required to trigger a difficulty reduction.
    private let pointsPerDifficultyStep: Int = 10

    /// Hit tolerance in degrees.
    private let hitToleranceDegrees: Double = 8.0

    // MARK: - Initialization

    init() {
        loadHighScore()
        loadSkin()
        loadDailyBest()
    }

    // MARK: - Daily challenge helpers

    /// Produce a stable 64-bit seed derived from the provided date's YYYYMMDD.
    func seedForToday(date: Date = .now) -> UInt64 {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 1970
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        // YYYYMMDD as integer
        let v = UInt64(y * 10000 + m * 100 + d)
        // Mix into a 64-bit value (simple expansion)
        return (v << 32) ^ UInt64(v & 0xffffffff)
    }

    /// A compact SplitMix64 RNG for deterministic sequences.
    private struct SplitMix64: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { state = seed &+ 0x9e3779b97f4a7c15 }
        mutating func next() -> UInt64 {
            state &+= 0x9e3779b97f4a7c15
            var z = state
            z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
            z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
            return z ^ (z >> 31)
        }
    }

    // MARK: - Skin persistence

    enum RingSkin: String, CaseIterable, Codable {
        case neonCyan
        case magenta
        case amber

        var ringColor: (ColorComponents) {
            switch self {
            case .neonCyan: return ColorComponents(r: 0.0, g: 1.0, b: 0.9)
            case .magenta: return ColorComponents(r: 1.0, g: 0.2, b: 0.8)
            case .amber: return ColorComponents(r: 1.0, g: 0.6, b: 0.0)
            }
        }
    }

    struct ColorComponents: Codable {
        let r: Double
        let g: Double
        let b: Double
    }

    private func loadSkin() {
        if let raw = UserDefaults.standard.string(forKey: Self.skinKey), let s = RingSkin(rawValue: raw) {
            skin = s
        } else {
            skin = .neonCyan
        }
    }

    private func saveSkin() {
        UserDefaults.standard.set(skin.rawValue, forKey: Self.skinKey)
    }

    // MARK: - Public API

    /// Start a brand new game.
    func startNewGame() {
        score = 0
        lives = 3
        streak = 0
        perGateDuration = 2.0
        isGameOver = false
        loadHighScore()
        // Prepare daily RNG if requested
        if isDailyChallenge {
            let seed = seedForToday()
            dailyRNG = SplitMix64(seed: seed)
        } else {
            dailyRNG = nil
        }
        nextGate()
    }

    /// End the current game and persist high score if needed.
    func endGame() {
        isGameOver = true
        saveHighScoreIfNeeded()
    // Submit high score to Game Center (graceful if not available)
    GameCenterManager.shared.submitHighScore(highScore)
    }

    /// Proceed to the next gate (randomizes `gateAngle` and resets the gate timer).
    func nextGate() {
        if var rng = dailyRNG {
            nextGate(using: &rng)
            dailyRNG = rng
        } else {
            var sys = SystemRandomNumberGenerator()
            nextGate(using: &sys)
        }
    }

    /// Produce a next gate using the provided random number generator.
    func nextGate<R: RandomNumberGenerator>(using rng: inout R) {
        gateAngle = Double.random(in: 0..<360, using: &rng)
        timeRemaining = perGateDuration
    }

    /// Decrease the per-gate timer by `delta` seconds. If time runs out a miss is
    /// registered and a new gate starts.
    ///
    /// - Parameter delta: seconds to decrement.
    func tick(delta: TimeInterval) {
        guard !isGameOver else { return }
        timeRemaining -= max(0, delta)
        if timeRemaining <= 0 {
            // Timeout => miss
            registerMiss()
            // Advance to next gate only if game isn't over.
            if !isGameOver {
                nextGate()
            }
        }
    }

    /// Call when the player registers a hit.
    ///
    /// Behavior:
    /// - Increments `streak`.
    /// - Increases `score` (1 + current streak).
    /// - Checks and updates difficulty.
    /// - Advances to the next gate.
    func registerHit() {
        guard !isGameOver else { return }

        streak += 1
        // Reward grows with streak: base 1 point plus current streak bonus.
        let pointsEarned = 1 + streak
        score += pointsEarned

        // Award +1 bonus when streak reaches multiples of 5
        if streak > 0 && streak % 5 == 0 {
            score += 1
        }

        // Possibly update high score on the fly.
        if score > highScore {
            highScore = score
            saveHighScoreIfNeeded()
        }

        updateDifficultyIfNeeded()

    // Note: progression to the next gate is controlled by the UI layer.
    // This keeps the model pure and allows the view to coordinate animations
    // or gate-state (single scoring per gate). The caller should call
    // `nextGate()` after invoking `registerHit()`.
    }

    /// Call when the player misses.
    ///
    /// Behavior:
    /// - Decrements `lives` (to minimum 0).
    /// - Resets `streak` to 0.
    /// - If `lives` reaches 0, sets `isGameOver` and persists high score.
    func registerMiss() {
        guard !isGameOver else { return }
        streak = 0
        lives = max(0, lives - 1)
        if lives == 0 {
            endGame()
        }
    }

    /// Returns true when `ringAngle` is aligned with `gateAngle` within tolerance.
    func isAligned() -> Bool {
        return abs(Self.angleDifference(from: ringAngle, to: gateAngle)) <= hitToleranceDegrees
    }

    // MARK: - Pure / static helpers (unit-testable)

    /// Normalize any angle (degrees) into the half-open interval [0, 360).
    static func normalize(angle: Double) -> Double {
        var a = angle.truncatingRemainder(dividingBy: 360)
        if a < 0 { a += 360 }
        // Avoid -0.0 representation
        if a == -0.0 { a = 0 }
        return a
    }

    /// Returns the minimal signed angular difference from `from` to `to`, in degrees
    /// in the range (-180, 180]. Example: from=350, to=10 => 20.
    static func angleDifference(from: Double, to: Double) -> Double {
        let f = normalize(angle: from)
        let t = normalize(angle: to)
        var diff = t - f
        if diff > 180 {
            diff -= 360
        } else if diff <= -180 {
            diff += 360
        }
        return diff
    }

    /// Returns a uniformly random angle in [0, 360).
    static func randomAngle() -> Double {
        Double.random(in: 0..<360)
    }

    // MARK: - Persistence

    private func loadHighScore() {
        let stored = UserDefaults.standard.integer(forKey: Self.highScoreKey)
        highScore = stored
    }

    private func saveHighScoreIfNeeded() {
        guard highScore > 0 else { return }
        UserDefaults.standard.set(highScore, forKey: Self.highScoreKey)
        // Notify widgets to reload timelines
        if #available(watchOS 7.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func loadDailyBest() {
        let storedDate = UserDefaults.standard.string(forKey: Self.dailyBestDateKey)
        let todayKey = keyForDate(Date())
        if storedDate == todayKey {
            let stored = UserDefaults.standard.integer(forKey: Self.dailyBestKey)
            dailyBest = stored
        } else {
            // new day => reset
            dailyBest = 0
            UserDefaults.standard.set(todayKey, forKey: Self.dailyBestDateKey)
            UserDefaults.standard.set(0, forKey: Self.dailyBestKey)
        }
    }

    private func saveDailyBest() {
        guard dailyBest > 0 else { return }
        let todayKey = keyForDate(Date())
        UserDefaults.standard.set(todayKey, forKey: Self.dailyBestDateKey)
        UserDefaults.standard.set(dailyBest, forKey: Self.dailyBestKey)
    }

    private func keyForDate(_ date: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 1970
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return String(format: "%04d%02d%02d", y, m, d)
    }

    // MARK: - Difficulty management

    private func updateDifficultyIfNeeded() {
        // Reduce per-gate duration after every `pointsPerDifficultyStep` points.
        // We check the total score for crossing multiple-of-10 thresholds.
        guard perGateDuration > minPerGateDuration else { return }
        // Determine how many reductions should be applied for the current score.
        let reductions = score / pointsPerDifficultyStep
        let targetDuration = max(minPerGateDuration, 2.0 - (Double(reductions) * perGateReduction))
        if targetDuration < perGateDuration {
            perGateDuration = targetDuration
        }
    }
}
