import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var homeLocations: [HomeLocation]

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
                    .fullScreenCover(isPresented: $appState.showExitChecklist) {
                        ExitChecklistView()
                    }
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            setupGeofencing()
        }
        .onChange(of: appState.hasCompletedOnboarding) { _, completed in
            if completed {
                setupGeofencing()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            handleAppBecameActive()
        }
    }

    private func setupGeofencing() {
        guard appState.hasCompletedOnboarding,
              let homeLocation = homeLocations.first else { return }

        locationManager.onExitRegion = {
            Task { @MainActor in
                appState.showExitChecklist = true
            }
        }

        if locationManager.hasAlwaysAuthorization {
            locationManager.startMonitoring(for: homeLocation)
        }
    }

    private func handleAppBecameActive() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let hasExitNotification = notifications.contains {
                $0.request.content.categoryIdentifier == NotificationManager.exitChecklistCategory
            }

            if hasExitNotification {
                Task { @MainActor in
                    appState.showExitChecklist = true
                    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                }
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(NotificationManager.shared)
}
