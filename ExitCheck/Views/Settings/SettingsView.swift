import SwiftUI
import SwiftData
import CoreLocation

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var appState: AppState

    @Query private var settingsArray: [UserSettings]
    @Query private var homeLocations: [HomeLocation]

    @State private var showResetConfirmation = false
    @State private var showLocationPicker = false

    private var settings: UserSettings {
        if let existing = settingsArray.first {
            return existing
        }
        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    private var homeLocation: HomeLocation? {
        homeLocations.first
    }

    var body: some View {
        NavigationStack {
            List {
                // Location Section
                Section {
                    if let home = homeLocation {
                        LabeledContent("Status") {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(locationManager.isMonitoring ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(locationManager.isMonitoring ? "Monitoring" : "Inactive")
                            }
                        }

                        LabeledContent("Coordinates") {
                            Text(String(format: "%.4f, %.4f", home.latitude, home.longitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Zone Radius")
                                Spacer()
                                Text("\(Int(home.radius))m")
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: Binding(
                                get: { home.radius },
                                set: { newValue in
                                    home.update(radius: newValue)
                                    restartMonitoring()
                                }
                            ), in: 50...300, step: 25)
                        }

                        Button {
                            updateToCurrentLocation()
                        } label: {
                            Label("Update to Current Location", systemImage: "location.fill")
                        }
                    } else {
                        Text("No home location set")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Home Location", systemImage: "house.fill")
                } footer: {
                    Text("Adjust the zone radius if alerts trigger too early or late.")
                }

                // Voice Section
                Section {
                    Toggle(isOn: Binding(
                        get: { settings.voiceReadoutEnabled },
                        set: { settings.voiceReadoutEnabled = $0 }
                    )) {
                        Label("Voice Readout", systemImage: "speaker.wave.2.fill")
                    }

                    if settings.voiceReadoutEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Speech Rate")
                                Spacer()
                                Text(speechRateDescription)
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: Binding(
                                get: { settings.speechRate },
                                set: { settings.speechRate = $0 }
                            ), in: 0.3...0.7, step: 0.05)
                        }

                        Button {
                            testVoice()
                        } label: {
                            Label("Test Voice", systemImage: "play.fill")
                        }
                    }
                } header: {
                    Label("Accessibility", systemImage: "accessibility")
                } footer: {
                    Text("When enabled, your checklist will be read aloud when leaving home.")
                }

                // Behavior Section
                Section {
                    Toggle(isOn: Binding(
                        get: { settings.hapticFeedbackEnabled },
                        set: { settings.hapticFeedbackEnabled = $0 }
                    )) {
                        Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    }

                    Toggle(isOn: Binding(
                        get: { settings.showStreakMessages },
                        set: { settings.showStreakMessages = $0 }
                    )) {
                        Label("Show Streak Messages", systemImage: "flame.fill")
                    }

                    Toggle(isOn: Binding(
                        get: { settings.autoCheckPhone },
                        set: { settings.autoCheckPhone = $0 }
                    )) {
                        Label("Auto-check Phone", systemImage: "iphone")
                    }
                } header: {
                    Label("Behavior", systemImage: "gearshape.fill")
                } footer: {
                    Text("Auto-check phone assumes you have it if you're seeing the alert!")
                }

                // Permissions Section
                Section {
                    LabeledContent("Location") {
                        Text(locationManager.authorizationStatus.description)
                            .foregroundStyle(
                                locationManager.hasAlwaysAuthorization ? .green : .orange
                            )
                    }

                    if !locationManager.hasAlwaysAuthorization {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Open Settings", systemImage: "arrow.up.forward.app")
                        }
                    }
                } header: {
                    Label("Permissions", systemImage: "lock.shield.fill")
                }

                // Data Section
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Label("Data", systemImage: "externaldrive.fill")
                }

                // About Section
                Section {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                } header: {
                    Label("About", systemImage: "info.circle.fill")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset All Data?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your checklist items, history, and settings. This cannot be undone.")
            }
        }
    }

    private var speechRateDescription: String {
        let rate = settings.speechRate
        if rate < 0.4 { return "Slow" }
        if rate < 0.55 { return "Normal" }
        return "Fast"
    }

    private func updateToCurrentLocation() {
        locationManager.requestCurrentLocation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let location = locationManager.currentLocation,
               let home = homeLocation {
                home.update(coordinate: location.coordinate)
                restartMonitoring()
                HapticManager.notification(.success)
            }
        }
    }

    private func restartMonitoring() {
        guard let home = homeLocation else { return }
        locationManager.stopMonitoring()
        locationManager.startMonitoring(for: home)
    }

    private func testVoice() {
        SpeechManager.shared.speak(
            "Leaving home checklist: keys, wallet, phone",
            rate: settings.speechRate,
            voiceIdentifier: settings.selectedVoiceIdentifier
        )
    }

    private func resetAllData() {
        // Clear UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasCompletedOnboarding")
        defaults.removeObject(forKey: "currentStreak")
        defaults.removeObject(forKey: "lastPerfectExitDate")
        defaults.removeObject(forKey: "totalPerfectExits")

        // Stop monitoring
        locationManager.stopMonitoring()

        // Reset app state
        appState.hasCompletedOnboarding = false
        appState.currentStreak = 0
        appState.totalPerfectExits = 0

        HapticManager.notification(.warning)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserSettings.self, HomeLocation.self])
        .environmentObject(LocationManager.shared)
        .environmentObject(AppState.shared)
}
