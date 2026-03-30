import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = false
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $darkModeEnabled) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.indigo)
                        Text("Dark Mode")
                    }
                }
            } footer: {
                Text("Enable dark mode for a darker color scheme.")
            }
            
            Section("Preview") {
                HStack {
                    Text("Current Mode")
                    Spacer()
                    Text(colorScheme == .dark ? "Dark" : "Light")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Setting")
                    Spacer()
                    Text(darkModeEnabled ? "Dark" : "Light (System)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
