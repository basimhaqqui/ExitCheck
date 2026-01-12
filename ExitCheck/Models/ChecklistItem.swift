import Foundation
import SwiftData

@Model
final class ChecklistItem {
    var id: UUID
    var title: String
    var emoji: String
    var order: Int
    var isActive: Bool
    var category: String?
    var createdAt: Date
    var forgottenCount: Int
    var lastForgottenDate: Date?

    @Transient
    var isChecked: Bool = false

    init(
        title: String,
        emoji: String = "",
        order: Int = 0,
        isActive: Bool = true,
        category: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.emoji = emoji
        self.order = order
        self.isActive = isActive
        self.category = category
        self.createdAt = Date()
        self.forgottenCount = 0
        self.lastForgottenDate = nil
    }

    var displayText: String {
        if emoji.isEmpty {
            return title
        }
        return "\(emoji) \(title)"
    }

    func markForgotten() {
        forgottenCount += 1
        lastForgottenDate = Date()
    }
}

extension ChecklistItem {
    static var sampleItems: [ChecklistItem] {
        [
            ChecklistItem(title: "Keys", emoji: "🔑", order: 0),
            ChecklistItem(title: "Wallet", emoji: "👛", order: 1),
            ChecklistItem(title: "Phone", emoji: "📱", order: 2),
            ChecklistItem(title: "Headphones", emoji: "🎧", order: 3)
        ]
    }
}
