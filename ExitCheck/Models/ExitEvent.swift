import Foundation
import SwiftData

@Model
final class ExitEvent {
    var id: UUID
    var timestamp: Date
    var wasComplete: Bool
    var dismissedEarly: Bool
    var forgottenItems: [String]
    var dayOfWeek: Int
    var hourOfDay: Int
    var feedbackProvided: Bool
    var feedbackNote: String?

    init(
        wasComplete: Bool,
        dismissedEarly: Bool = false,
        forgottenItems: [String] = []
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.wasComplete = wasComplete
        self.dismissedEarly = dismissedEarly
        self.forgottenItems = forgottenItems

        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: Date())
        self.hourOfDay = calendar.component(.hour, from: Date())
        self.feedbackProvided = false
        self.feedbackNote = nil
    }

    var isWeekday: Bool {
        dayOfWeek >= 2 && dayOfWeek <= 6
    }

    var timeOfDayDescription: String {
        switch hourOfDay {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }
}

struct ExitPatternAnalysis {
    let itemTitle: String
    let forgottenCount: Int
    let commonDays: [Int]
    let commonTimes: [String]
    let suggestion: String?
}

extension Array where Element == ExitEvent {
    func analyzePatterns(for items: [ChecklistItem]) -> [ExitPatternAnalysis] {
        var patterns: [ExitPatternAnalysis] = []

        for item in items {
            let forgottenEvents = self.filter { $0.forgottenItems.contains(item.title) }

            guard forgottenEvents.count >= 2 else { continue }

            let dayFrequency = Dictionary(grouping: forgottenEvents, by: { $0.dayOfWeek })
                .sorted { $0.value.count > $1.value.count }
                .prefix(2)
                .map { $0.key }

            let timeFrequency = Dictionary(grouping: forgottenEvents, by: { $0.timeOfDayDescription })
                .sorted { $0.value.count > $1.value.count }
                .prefix(2)
                .map { $0.key }

            let weekdayForgotten = forgottenEvents.filter { $0.isWeekday }.count
            let weekendForgotten = forgottenEvents.filter { !$0.isWeekday }.count

            var suggestion: String?
            if weekdayForgotten > weekendForgotten * 2 {
                suggestion = "You often forget \(item.title) on weekdays. Consider moving it to the top!"
            } else if forgottenEvents.count >= 5 {
                suggestion = "\(item.title) is frequently forgotten. Want to highlight it?"
            }

            patterns.append(ExitPatternAnalysis(
                itemTitle: item.title,
                forgottenCount: forgottenEvents.count,
                commonDays: dayFrequency,
                commonTimes: timeFrequency,
                suggestion: suggestion
            ))
        }

        return patterns.sorted { $0.forgottenCount > $1.forgottenCount }
    }
}
