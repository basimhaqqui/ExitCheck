import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager

    @Query(sort: \ChecklistItem.order) private var items: [ChecklistItem]
    @Query private var homeLocations: [HomeLocation]

    @State private var showingAddItem = false
    @State private var editingItem: ChecklistItem?
    @State private var showingTemplates = false

    var activeItems: [ChecklistItem] {
        items.filter { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if activeItems.isEmpty {
                    EmptyStateView(
                        showingAddItem: $showingAddItem,
                        showingTemplates: $showingTemplates
                    )
                } else {
                    ChecklistContentView(
                        items: activeItems,
                        editingItem: $editingItem,
                        onDelete: deleteItems,
                        onMove: moveItems
                    )
                }
            }
            .navigationTitle("My Checklist")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    StatusIndicator(isMonitoring: locationManager.isMonitoring)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingAddItem = true
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }

                        Button {
                            showingTemplates = true
                        } label: {
                            Label("Add from Template", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button {
                            appState.showExitChecklist = true
                        } label: {
                            Label("Test Exit Alert", systemImage: "bell.badge")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddEditItemView(mode: .add)
            }
            .sheet(item: $editingItem) { item in
                AddEditItemView(mode: .edit(item))
            }
            .sheet(isPresented: $showingTemplates) {
                TemplatePickerView()
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = activeItems[index]
            modelContext.delete(item)
        }
        HapticManager.impact(.medium)
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var reorderedItems = activeItems
        reorderedItems.move(fromOffsets: source, toOffset: destination)

        for (index, item) in reorderedItems.enumerated() {
            item.order = index
        }

        HapticManager.selection()
    }
}

struct StatusIndicator: View {
    let isMonitoring: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isMonitoring ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            Text(isMonitoring ? "Active" : "Inactive")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .fixedSize()
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct EmptyStateView: View {
    @Binding var showingAddItem: Bool
    @Binding var showingTemplates: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Items Yet")
                    .font(.title2.bold())

                Text("Add items you want to check\nbefore leaving home")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add Custom Item", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showingTemplates = true
                } label: {
                    Label("Choose Template", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

struct ChecklistContentView: View {
    let items: [ChecklistItem]
    @Binding var editingItem: ChecklistItem?
    let onDelete: (IndexSet) -> Void
    let onMove: (IndexSet, Int) -> Void

    var body: some View {
        List {
            StreakBannerView()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

            Section {
                ForEach(items) { item in
                    ChecklistItemRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingItem = item
                        }
                }
                .onDelete(perform: onDelete)
                .onMove(perform: onMove)
            } header: {
                Text("\(items.count) items")
            } footer: {
                Text("Tap to edit, swipe to delete, drag to reorder")
                    .font(.caption)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct ChecklistItemRow: View {
    let item: ChecklistItem

    var body: some View {
        HStack(spacing: 12) {
            Text(item.emoji.isEmpty ? "•" : item.emoji)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)

                if item.forgottenCount > 0 {
                    Text("Forgotten \(item.forgottenCount)x")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct StreakBannerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if let message = appState.streakMessage() {
            HStack {
                Text(message)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text("\(appState.currentStreak) days")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.1), .yellow.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [ChecklistItem.self, HomeLocation.self])
        .environmentObject(AppState.shared)
        .environmentObject(LocationManager.shared)
        .environmentObject(NotificationManager.shared)
}
