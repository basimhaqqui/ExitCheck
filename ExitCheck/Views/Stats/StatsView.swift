import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    @Query(sort: \ExitEvent.timestamp, order: .reverse) private var exitEvents: [ExitEvent]
    @Query(sort: \ChecklistItem.order) private var items: [ChecklistItem]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak Card
                    StreakCard()

                    // Quick Stats
                    QuickStatsGrid(exitEvents: exitEvents)

                    // Patterns & Suggestions
                    if !suggestions.isEmpty {
                        SuggestionsSection(suggestions: suggestions)
                    }

                    // Recent Activity
                    RecentActivitySection(events: Array(exitEvents.prefix(10)))

                    // Most Forgotten Items
                    if !mostForgottenItems.isEmpty {
                        MostForgottenSection(items: mostForgottenItems)
                    }
                }
                .padding()
            }
            .navigationTitle("Stats")
            .background(Color(.systemGroupedBackground))
        }
    }

    private var suggestions: [ExitPatternAnalysis] {
        exitEvents.analyzePatterns(for: items)
    }

    private var mostForgottenItems: [ChecklistItem] {
        items.filter { $0.forgottenCount > 0 }
            .sorted { $0.forgottenCount > $1.forgottenCount }
            .prefix(5)
            .map { $0 }
    }
}

struct StreakCard: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(appState.currentStreak)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))

                        Text("days")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "flame.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        appState.currentStreak > 0
                            ? LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                    )
            }

            if let message = appState.streakMessage() {
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct QuickStatsGrid: View {
    let exitEvents: [ExitEvent]

    private var perfectExits: Int {
        exitEvents.filter { $0.wasComplete && !$0.dismissedEarly }.count
    }

    private var rushedExits: Int {
        exitEvents.filter { $0.dismissedEarly }.count
    }

    private var perfectRate: Double {
        guard !exitEvents.isEmpty else { return 0 }
        return Double(perfectExits) / Double(exitEvents.count) * 100
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Total Exits",
                value: "\(exitEvents.count)",
                icon: "door.left.hand.open",
                color: .blue
            )

            StatCard(
                title: "Perfect Exits",
                value: "\(perfectExits)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            StatCard(
                title: "Rushed Exits",
                value: "\(rushedExits)",
                icon: "hare.fill",
                color: .orange
            )

            StatCard(
                title: "Success Rate",
                value: String(format: "%.0f%%", perfectRate),
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title.weight(.bold))

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct SuggestionsSection: View {
    let suggestions: [ExitPatternAnalysis]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Smart Suggestions", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.yellow)

            ForEach(suggestions.prefix(3), id: \.itemTitle) { pattern in
                if let suggestion = pattern.suggestion {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)

                        Text(suggestion)
                            .font(.subheadline)

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct RecentActivitySection: View {
    let events: [ExitEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Activity", systemImage: "clock.fill")
                .font(.headline)

            if events.isEmpty {
                Text("No exits recorded yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical)
            } else {
                ForEach(events.prefix(5)) { event in
                    HStack {
                        Image(systemName: event.wasComplete ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(event.wasComplete ? .green : .orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.wasComplete ? "Perfect Exit" : "Rushed Exit")
                                .font(.subheadline.weight(.medium))

                            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if !event.forgottenItems.isEmpty {
                            Text("Forgot \(event.forgottenItems.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct MostForgottenSection: View {
    let items: [ChecklistItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Most Forgotten", systemImage: "brain.head.profile")
                .font(.headline)

            ForEach(items) { item in
                HStack {
                    Text(item.emoji.isEmpty ? "•" : item.emoji)
                        .frame(width: 28)

                    Text(item.title)
                        .font(.subheadline)

                    Spacer()

                    Text("\(item.forgottenCount)x")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [ChecklistItem.self, ExitEvent.self])
        .environmentObject(AppState.shared)
}
