import Foundation
import GameKit
import WatchKit

final class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var playerAlias: String = ""
    @Published private(set) var lastError: Error?

    private init() {}

    func authenticate() {
        let local = GKLocalPlayer.local
        // Provide platform-specific typed handlers to avoid ambiguous closure type inference.
#if os(watchOS)
        // watchOS authenticateHandler signature provides only an Error?
        local.authenticateHandler = { [weak self] (error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = error
                }
                self?.isAuthenticated = local.isAuthenticated
                self?.playerAlias = local.alias
            }
        }
#elseif canImport(UIKit)
        // iOS/tvOS: provide UIViewController? + Error?
        local.authenticateHandler = { [weak self] (vc: UIViewController?, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = error
                    self?.isAuthenticated = local.isAuthenticated
                    self?.playerAlias = local.alias
                    return
                }
                self?.isAuthenticated = local.isAuthenticated
                self?.playerAlias = local.alias
            }
        }
#elseif canImport(AppKit)
        // macOS: provide NSViewController? + Error?
        local.authenticateHandler = { [weak self] (vc: NSViewController?, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = error
                    self?.isAuthenticated = local.isAuthenticated
                    self?.playerAlias = local.alias
                    return
                }
                self?.isAuthenticated = local.isAuthenticated
                self?.playerAlias = local.alias
            }
        }
#else
        // Fallback: generic Any? + Error?
        local.authenticateHandler = { [weak self] (_ vc: Any?, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = error
                    self?.isAuthenticated = local.isAuthenticated
                    self?.playerAlias = local.alias
                    return
                }
                self?.isAuthenticated = local.isAuthenticated
                self?.playerAlias = local.alias
            }
        }
#endif
    }

    func submitHighScore(_ score: Int, leaderboardID: String = "crownloop.highscore") {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let gkScore = GKScore(leaderboardIdentifier: leaderboardID)
        gkScore.value = Int64(score)
        GKScore.report([gkScore]) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.lastError = error
                }
            }
        }
    }

    /// Attempt to open the Game Center app or UI on the device. On watchOS this
    /// will try to open the Game Center scheme; may be unavailable and will fail
    /// gracefully.
    func openGameCenter() {
        guard let url = URL(string: "gamecenter:") else { return }
        WKExtension.shared().openSystemURL(url)
    }
}
