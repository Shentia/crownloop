import SwiftUI

struct SettingsView: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("invertCrown") private var invertCrown: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Toggle("Haptics", isOn: $hapticsEnabled)
                .toggleStyle(SwitchToggleStyle())
                .accessibilityLabel("Enable haptics")
                .accessibilityValue(hapticsEnabled ? "On" : "Off")

            Toggle("Invert Crown Direction", isOn: $invertCrown)
                .toggleStyle(SwitchToggleStyle())
                .accessibilityLabel("Invert crown direction")
                .accessibilityValue(invertCrown ? "Inverted" : "Normal")

            Spacer()
        }
        .padding()
        .background(Color.black)
    }
}
