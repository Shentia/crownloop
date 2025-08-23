//
//  crown_loopApp.swift
//  crown loop Watch App
//
//  Created by Ahmadreza Shamimi on 2025-08-20.
//

import SwiftUI

@main
struct crown_loop_Watch_AppApp: App {
    @StateObject private var engine = GameEngine()
    private let gk = GameCenterManager.shared

    var body: some Scene {
        WindowGroup {
            MainMenuView(engine: engine)
                .onAppear {
                    gk.authenticate()
                }
        }
    }
}
