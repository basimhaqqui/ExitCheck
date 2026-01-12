import SwiftUI
import SwiftData

@main
struct ExitCheckApp: App {
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var appState = AppState.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ChecklistItem.self,
            HomeLocation.self,
            ExitEvent.self,
            UserSettings.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationManager)
                .environmentObject(notificationManager)
                .environmentObject(appState)
                .onAppear {
                    notificationManager.requestAuthorization()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
