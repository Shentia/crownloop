import Foundation
import WatchKit

/// Simple haptics helper for watchOS.
/// Use `Haptics.enabled = false` to globally disable.
public enum Haptics {
    private static let key = "hapticsEnabled"

    /// Global toggle for haptics persisted to UserDefaults (default true).
    public static var enabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: key) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    /// Light tap for successful hit.
    public static func successHit() {
        guard enabled else { return }
        WKInterfaceDevice.current().play(.click)
    }

    /// Stronger buzz for losing a life.
    public static func missLife() {
        guard enabled else { return }
        WKInterfaceDevice.current().play(.failure)
    }

    /// Longer/pleasant buzz for new high score.
    public static func newHighScore() {
        guard enabled else { return }
        WKInterfaceDevice.current().play(.success)
    }
}
