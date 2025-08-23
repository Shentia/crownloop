import Foundation

// A trimmed, pure-logic version of GameEngine for unit testing in the Swift package.
public final class GameEngine {
    // Published properties replaced with simple vars for tests.
    public private(set) var score: Int = 0
    public private(set) var lives: Int = 3
    public private(set) var streak: Int = 0
    public private(set) var strikes: Int = 0
    public private(set) var highScore: Int = 0

    public var ringAngle: Double = 0
    public var gateAngle: Double = 0

    public var isGameOver: Bool = false

    // Configuration
    public var perGateDuration: TimeInterval = 2.0
    public let minPerGateDuration: TimeInterval = 0.8
    public let perGateReduction: TimeInterval = 0.2
    public let pointsPerDifficultyStep: Int = 10
    public let hitToleranceDegrees: Double = 8.0
    
    // Strike system constants
    public let maxStrikes: Int = 3
    public let strikeTimeWindow: TimeInterval = 10.0
    
    // Strike tracking
    private var lastMissTime: Date?

    public init() {}

    // MARK: - Game flow

    public func startNewGame() {
        score = 0
        lives = 3
        streak = 0
        strikes = 0
        perGateDuration = 2.0
        isGameOver = false
        lastMissTime = nil
        nextGate()
    }

    public func registerHit() {
        guard !isGameOver else { return }
        score += 1
        streak += 1
        // Reset strikes on successful hit
        strikes = 0
        lastMissTime = nil
        // bonus at multiples of 5
        if streak % 5 == 0 {
            score += 1
        }
        updateDifficultyIfNeeded()
    }

    public func registerMiss() {
        guard !isGameOver else { return }
        streak = 0
        
        // Strike system logic (simplified for tests - no timer needed)
        let now = Date()
        
        if let lastMiss = lastMissTime,
           now.timeIntervalSince(lastMiss) <= strikeTimeWindow {
            strikes += 1
        } else {
            strikes = 1
        }
        
        lastMissTime = now
        
        // Check for strikeout
        if strikes >= maxStrikes {
            isGameOver = true
            return
        }
        
        lives = max(0, lives - 1)
        if lives == 0 {
            isGameOver = true
        }
    }

    public func isAligned() -> Bool {
        return abs(Self.angleDifference(from: ringAngle, to: gateAngle)) <= hitToleranceDegrees
    }

    // MARK: - Pure helpers

    public static func normalize(angle: Double) -> Double {
        var a = angle.truncatingRemainder(dividingBy: 360)
        if a < 0 { a += 360 }
        if a == -0.0 { a = 0 }
        return a
    }

    public static func angleDifference(from: Double, to: Double) -> Double {
        let f = normalize(angle: from)
        let t = normalize(angle: to)
        var diff = t - f
        if diff > 180 { diff -= 360 }
        else if diff <= -180 { diff += 360 }
        return diff
    }

    public func nextGate<R: RandomNumberGenerator>(using rng: inout R) {
        let angle = Double.random(in: 0..<360, using: &rng)
        gateAngle = angle
    }

    public func nextGate() {
        var sys = SystemRandomNumberGenerator()
        nextGate(using: &sys)
    }

    // Difficulty
    private func updateDifficultyIfNeeded() {
        guard perGateDuration > minPerGateDuration else { return }
        let reductions = score / pointsPerDifficultyStep
        let targetDuration = max(minPerGateDuration, 2.0 - (Double(reductions) * perGateReduction))
        if targetDuration < perGateDuration {
            perGateDuration = targetDuration
        }
    }

    // Daily seed helper (public for tests)
    public func seedForToday(date: Date = .now) -> UInt64 {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 1970
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        let v = UInt64(y * 10000 + m * 100 + d)
        return (v << 32) ^ UInt64(v & 0xffffffff)
    }
}
