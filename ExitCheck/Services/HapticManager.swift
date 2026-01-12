import UIKit

enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func checkItem() {
        impact(.light)
    }

    static func uncheckItem() {
        impact(.soft)
    }

    static func allChecked() {
        notification(.success)
    }

    static func exitDismissed() {
        impact(.medium)
    }

    static func buttonTap() {
        impact(.light)
    }

    static func error() {
        notification(.error)
    }

    static func warning() {
        notification(.warning)
    }
}
