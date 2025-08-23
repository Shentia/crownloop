import SwiftUI

struct SettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("invertCrown") private var invertCrown: Bool = false
    @State private var showingRules = false
    @State private var showingStrikeHistory = false
    @ObservedObject var engine: GameEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Settings Section
                VStack(spacing: 12) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .toggleStyle(SwitchToggleStyle())
                        .accessibilityLabel("Enable haptics")
                        .accessibilityValue(hapticsEnabled ? "On" : "Off")

                    Toggle("Invert Crown Direction", isOn: $invertCrown)
                        .toggleStyle(SwitchToggleStyle())
                        .accessibilityLabel("Invert crown direction")
                        .accessibilityValue(invertCrown ? "Inverted" : "Normal")
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // About & Rules Section
                VStack(spacing: 8) {
                    Button(action: { showingRules = true }) {
                        HStack {
                            Text("About & Rules")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showingStrikeHistory = true }) {
                        HStack {
                            Text("Strike History")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("(\(engine.strikeHistory.count))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.caption)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color.black)
        .sheet(isPresented: $showingRules) {
            RulesView()
        }
        .sheet(isPresented: $showingStrikeHistory) {
            StrikeHistoryView(engine: engine)
        }
    }
}

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Game Objective
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🎯 Objective")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Rotate the Digital Crown to align the cyan ring with the green gate segments. Score points by hitting gates before time runs out!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Controls
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚙️ Controls")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("• Rotate Digital Crown to move the cyan ring\n• Align the ring marker with the green gate\n• Hit gates before the timer (green arc) runs out")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Scoring System
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📊 Scoring System")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("• Base score: 1 point per hit\n• Streak bonus: +1 extra point per consecutive hit\n• Special bonus: +1 point every 5th consecutive hit\n• Example: 5th hit in a row = 6 points total")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Lives & Strikes System
                    VStack(alignment: .leading, spacing: 8) {
                        Text("❤️ Lives & ⚡ Strikes")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("• Start with 3 lives (hearts)\n• Lose 1 life for each missed gate\n• Strikes: 3 consecutive misses within 10 seconds = instant game over\n• Successful hits reset both streak and strikes\n• Game ends when lives reach 0 OR you get 3 strikes")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Difficulty Progression
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🚀 Difficulty")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("• Game speeds up every 10 points scored\n• Timer duration decreases from 2.0s to minimum 0.8s\n• Higher scores = faster gameplay = bigger challenge!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // HUD Elements
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📱 HUD Elements")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("• Score: Total points earned\n• Streak: Current consecutive hits (🔥)\n• Lives: Remaining chances (❤️)\n• Strikes: Recent misses within 10s (⚡)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Pro Tips")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("• Focus on maintaining streaks for maximum points\n• Watch the timer arc - it shows remaining time\n• Take your time early, speed comes with practice\n• Reset strikes by hitting any gate successfully")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Done button at the bottom
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Capsule().fill(Color.white))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Game Rules")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct StrikeHistoryView: View {
    @ObservedObject var engine: GameEngine
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    if engine.strikeHistory.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "clock.badge.xmark")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("No Strikes Yet")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Your strike history will appear here as you play")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                    } else {
                        // Strike history list
                        LazyVStack(spacing: 8) {
                            ForEach(engine.strikeHistory) { strike in
                                StrikeHistoryRow(strike: strike)
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        // Clear history button
                        Button(action: { showingClearAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                Text("Clear History")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 16)
                    }
                    
                    // Done button
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Capsule().fill(Color.white))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Strike History")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Clear Strike History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                engine.clearStrikeHistory()
            }
        } message: {
            Text("This will permanently delete all strike records.")
        }
    }
}

struct StrikeHistoryRow: View {
    let strike: GameEngine.StrikeRecord
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Strike indicator
            VStack(spacing: 2) {
                Image(systemName: strike.wasGameEnder ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(strike.wasGameEnder ? .red : .yellow)
                    .font(.system(size: 16, weight: .medium))
                
                Text("\(strike.strikeNumber)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 24)
            
            // Strike details
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(dateFormatter.string(from: strike.date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    if strike.wasGameEnder {
                        Text("GAME OVER")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.red.opacity(0.2))
                            )
                    }
                }
                
                Text("Score: \(strike.gameScore) • Strike #\(strike.strikeNumber)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(strike.wasGameEnder ? Color.red.opacity(0.3) : Color.yellow.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
