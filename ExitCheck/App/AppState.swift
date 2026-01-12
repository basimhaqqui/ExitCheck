import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    @Published var showExitChecklist = false
    @Published var currentStreak: Int {
        didSet {
            UserDefaults.standard.set(currentStreak, forKey: "currentStreak")
        }
    }

    @Published var lastPerfectExitDate: Date? {
        didSet {
            UserDefaults.standard.set(lastPerfectExitDate, forKey: "lastPerfectExitDate")
        }
    }

    @Published var totalPerfectExits: Int {
        didSet {
            UserDefaults.standard.set(totalPerfectExits, forKey: "totalPerfectExits")
        }
    }

    private init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        self.lastPerfectExitDate = UserDefaults.standard.object(forKey: "lastPerfectExitDate") as? Date
        self.totalPerfectExits = UserDefaults.standard.integer(forKey: "totalPerfectExits")
    }

    func recordPerfectExit() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastPerfectExitDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                currentStreak += 1
            } else if daysDiff > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        lastPerfectExitDate = Date()
        totalPerfectExits += 1
    }

    func streakMessage() -> String? {
        guard currentStreak > 0 else { return nil }

        let messages: [(Int, String)] = [
            (30, "30-day legend! You're unstoppable! 👑"),
            (14, "Two weeks of perfect exits! 🌟"),
            (7, "7-day perfect exit streak! 🔥"),
            (5, "5 days strong! Keep it up! 💪"),
            (3, "3-day streak! You're on a roll! ✨")
        ]

        for (threshold, message) in messages {
            if currentStreak >= threshold {
                return message
            }
        }

        return nil
    }

    var funExitMessages: [String] {
        [
            "No U-turns today! 🔥",
            "Smooth exit, champ! 😎",
            "You remembered everything! 🎉",
            "Future you says thanks! 🙌",
            "Adulting level: Expert 💯",
            "Keys? Check. Wallet? Check. You? Awesome! ✨",
            "Exit status: Flawless 💎"
        ]
    }

    func randomFunMessage() -> String {
        funExitMessages.randomElement() ?? "Great job!"
    }
}
