import Foundation

struct ChecklistTemplate: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let items: [(title: String, emoji: String)]

    static let allTemplates: [ChecklistTemplate] = [
        essentials,
        workDay,
        gym,
        weekendTrip,
        dateNight,
        parentingMode,
        petOwner
    ]

    static let essentials = ChecklistTemplate(
        name: "Daily Essentials",
        icon: "star.fill",
        description: "The basics you need every day",
        items: [
            ("Keys", "🔑"),
            ("Wallet", "👛"),
            ("Phone", "📱"),
            ("Headphones", "🎧")
        ]
    )

    static let workDay = ChecklistTemplate(
        name: "Work Day",
        icon: "briefcase.fill",
        description: "Everything for the office",
        items: [
            ("Keys", "🔑"),
            ("Wallet", "👛"),
            ("Phone", "📱"),
            ("Laptop", "💻"),
            ("Badge/ID", "🪪"),
            ("Lunch", "🥗"),
            ("Water Bottle", "💧"),
            ("Headphones", "🎧")
        ]
    )

    static let gym = ChecklistTemplate(
        name: "Gym Session",
        icon: "dumbbell.fill",
        description: "Ready to work out",
        items: [
            ("Keys", "🔑"),
            ("Phone", "📱"),
            ("Gym Bag", "🎒"),
            ("Water Bottle", "💧"),
            ("Headphones", "🎧"),
            ("Towel", "🧴"),
            ("Lock", "🔒")
        ]
    )

    static let weekendTrip = ChecklistTemplate(
        name: "Weekend Trip",
        icon: "car.fill",
        description: "Short getaway checklist",
        items: [
            ("Keys", "🔑"),
            ("Wallet", "👛"),
            ("Phone", "📱"),
            ("Charger", "🔌"),
            ("Toiletries", "🧴"),
            ("Change of Clothes", "👕"),
            ("Snacks", "🍎"),
            ("Windows Locked", "🪟"),
            ("Lights Off", "💡"),
            ("Pet Fed", "🐕")
        ]
    )

    static let dateNight = ChecklistTemplate(
        name: "Date Night",
        icon: "heart.fill",
        description: "Look good, feel good",
        items: [
            ("Keys", "🔑"),
            ("Wallet", "👛"),
            ("Phone", "📱"),
            ("Breath Mints", "🍬"),
            ("Cologne/Perfume", "✨"),
            ("Reservation Confirmed", "📋")
        ]
    )

    static let parentingMode = ChecklistTemplate(
        name: "Parenting Mode",
        icon: "figure.and.child.holdinghands",
        description: "Out with the kids",
        items: [
            ("Keys", "🔑"),
            ("Wallet", "👛"),
            ("Phone", "📱"),
            ("Diaper Bag", "👜"),
            ("Snacks", "🍎"),
            ("Water/Juice", "🧃"),
            ("Wipes", "🧻"),
            ("Change of Clothes", "👕"),
            ("Favorite Toy", "🧸")
        ]
    )

    static let petOwner = ChecklistTemplate(
        name: "Pet Owner",
        icon: "pawprint.fill",
        description: "Don't forget the fur baby",
        items: [
            ("Keys", "🔑"),
            ("Wallet", "👛"),
            ("Phone", "📱"),
            ("Pet Fed", "🍖"),
            ("Pet Water Fresh", "💧"),
            ("Said Goodbye", "👋"),
            ("Treats for Later", "🦴")
        ]
    )

    func toChecklistItems() -> [ChecklistItem] {
        items.enumerated().map { index, item in
            ChecklistItem(title: item.title, emoji: item.emoji, order: index)
        }
    }
}
