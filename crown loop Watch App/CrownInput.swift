import Foundation
import SwiftUI

/// Small utilities for normalizing an angle and producing a Binding for the ring angle
/// that automatically normalizes writes.
///
/// These helpers are intentionally tiny and pure where possible so they are easily
/// unit-testable and composable with `GameEngine`.

/// Normalize any angle to the interval [0, 360).
/// This uses the same normalization semantics as `GameEngine.normalize(angle:)`.
///
/// Examples (pseudo-tests):
/// - `normalizedAngle(-5)` -> `355`
/// - `normalizedAngle(361)` -> `1`
/// - `normalizedAngle(720)` -> `0`
func normalizedAngle(_ x: Double) -> Double {
    return GameEngine.normalize(angle: x)
}

/// Return a `Binding<Double>` that reads from `engine.ringAngle` and writes back
/// a normalized value so the engine always receives an angle in [0,360).
///
/// Example usage in SwiftUI:
/// ```swift
/// @StateObject private var engine = GameEngine()
/// Slider(value: bindingForRingAngle(engine: engine), in: 0...360)
/// ```
func bindingForRingAngle(engine: GameEngine) -> Binding<Double> {
    Binding<Double>(
        get: { engine.ringAngle },
        set: { newValue in
            let invert = UserDefaults.standard.bool(forKey: "invertCrown")
            let value = invert ? normalizedAngle(360 - newValue) : normalizedAngle(newValue)
            engine.ringAngle = value
        }
    )
}

/*
Additional sample I/O (informal unit-test cases):

normalizedAngle(-5)    // 355
normalizedAngle(361)   // 1
normalizedAngle(720)   // 0
normalizedAngle(-360)  // 0
normalizedAngle(-361)  // 359

These can be used as assertions in unit tests:
assert(normalizedAngle(-5) == 355)
assert(normalizedAngle(361) == 1)
*/
