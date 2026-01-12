import SwiftUI
import SwiftData

enum ItemEditMode: Identifiable {
    case add
    case edit(ChecklistItem)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let item): return item.id.uuidString
        }
    }
}

struct AddEditItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ChecklistItem.order) private var existingItems: [ChecklistItem]

    let mode: ItemEditMode

    @State private var title: String = ""
    @State private var emoji: String = ""
    @State private var category: String = ""
    @State private var showEmojiPicker = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editingItem: ChecklistItem? {
        if case .edit(let item) = mode { return item }
        return nil
    }

    private let suggestedEmojis = ["🔑", "👛", "📱", "💊", "🎧", "💻", "👜", "🧥", "☂️", "🕶️", "💧", "🎒", "🪪", "⌚️", "💳", "🔌"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item name", text: $title)
                        .font(.title3)

                    HStack {
                        Text("Emoji")
                        Spacer()
                        Button {
                            showEmojiPicker = true
                        } label: {
                            Text(emoji.isEmpty ? "None" : emoji)
                                .font(.title)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                } header: {
                    Text("Item Details")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(suggestedEmojis, id: \.self) { emojiOption in
                            Button {
                                emoji = emojiOption
                                HapticManager.selection()
                            } label: {
                                Text(emojiOption)
                                    .font(.title2)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(emoji == emojiOption ? Color.blue.opacity(0.2) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Quick Pick")
                }

                if isEditing, let item = editingItem {
                    Section {
                        LabeledContent("Created", value: item.createdAt.formatted(date: .abbreviated, time: .omitted))

                        if item.forgottenCount > 0 {
                            LabeledContent("Times forgotten", value: "\(item.forgottenCount)")
                        }
                    } header: {
                        Text("Info")
                    }

                    Section {
                        Button(role: .destructive) {
                            deleteItem()
                        } label: {
                            Label("Delete Item", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let item = editingItem {
                    title = item.title
                    emoji = item.emoji
                    category = item.category ?? ""
                }
            }
        }
    }

    private func saveItem() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if let item = editingItem {
            item.title = trimmedTitle
            item.emoji = emoji
            item.category = category.isEmpty ? nil : category
        } else {
            let newOrder = existingItems.count
            let newItem = ChecklistItem(
                title: trimmedTitle,
                emoji: emoji,
                order: newOrder,
                category: category.isEmpty ? nil : category
            )
            modelContext.insert(newItem)
        }

        HapticManager.notification(.success)
        dismiss()
    }

    private func deleteItem() {
        if let item = editingItem {
            modelContext.delete(item)
            HapticManager.impact(.medium)
            dismiss()
        }
    }
}

struct TemplatePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ChecklistItem.order) private var existingItems: [ChecklistItem]

    var body: some View {
        NavigationStack {
            List {
                ForEach(ChecklistTemplate.allTemplates) { template in
                    Button {
                        addTemplate(template)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: template.icon)
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(template.items.map { $0.emoji + " " + $0.title }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addTemplate(_ template: ChecklistTemplate) {
        let startOrder = existingItems.count

        for (index, itemData) in template.items.enumerated() {
            // Check if item already exists
            let exists = existingItems.contains { $0.title.lowercased() == itemData.title.lowercased() }
            if !exists {
                let newItem = ChecklistItem(
                    title: itemData.title,
                    emoji: itemData.emoji,
                    order: startOrder + index
                )
                modelContext.insert(newItem)
            }
        }

        HapticManager.notification(.success)
        dismiss()
    }
}

#Preview("Add") {
    AddEditItemView(mode: .add)
        .modelContainer(for: ChecklistItem.self)
}
