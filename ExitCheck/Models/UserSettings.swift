import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var voiceReadoutEnabled: Bool
    var hapticFeedbackEnabled: Bool
    var showStreakMessages: Bool
    var askForFeedback: Bool
    var feedbackAfterExits: Int
    var selectedVoiceIdentifier: String?
    var speechRate: Float
    var geofenceRadius: Double
    var autoCheckPhone: Bool

    init() {
        self.id = UUID()
        self.voiceReadoutEnabled = false
        self.hapticFeedbackEnabled = true
        self.showStreakMessages = true
        self.askForFeedback = true
        self.feedbackAfterExits = 5
        self.selectedVoiceIdentifier = nil
        self.speechRate = 0.5
        self.geofenceRadius = 100
        self.autoCheckPhone = true
    }
}

extension UserSettings {
    static func getOrCreate(context: ModelContext) -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = UserSettings()
        context.insert(settings)
        return settings
    }
}
