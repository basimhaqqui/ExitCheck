import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    static let exitChecklistCategory = "EXIT_CHECKLIST"
    static let openChecklistAction = "OPEN_CHECKLIST"
    static let dismissAction = "DISMISS"

    private override init() {
        super.init()
        checkAuthorizationStatus()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            Task { @MainActor in
                self.isAuthorized = granted
                if granted {
                    self.setupNotificationCategories()
                }
                self.checkAuthorizationStatus()
            }
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    private func setupNotificationCategories() {
        let openAction = UNNotificationAction(
            identifier: Self.openChecklistAction,
            title: "Open Checklist",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: Self.dismissAction,
            title: "I'm Rushing",
            options: [.destructive]
        )

        let category = UNNotificationCategory(
            identifier: Self.exitChecklistCategory,
            actions: [openAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func triggerExitNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Leaving Home?"
        content.body = "Tap to check your exit list before you go!"
        content.sound = .default
        content.categoryIdentifier = Self.exitChecklistCategory
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "exit_checklist_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            } else {
                print("Exit notification scheduled")
            }
        }

        // If app is in foreground, directly show the modal
        if UIApplication.shared.applicationState == .active {
            Task { @MainActor in
                AppState.shared.showExitChecklist = true
            }
        }
    }

    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
