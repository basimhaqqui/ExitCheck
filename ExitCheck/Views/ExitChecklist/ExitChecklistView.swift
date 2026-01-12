import SwiftUI
import SwiftData

struct ExitChecklistView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @Query(filter: #Predicate<ChecklistItem> { $0.isActive }, sort: \ChecklistItem.order)
    private var items: [ChecklistItem]

    @Query private var settings: [UserSettings]

    @State private var checkStates: [UUID: Bool] = [:]
    @State private var showSuccessView = false
    @State private var showFeedbackPrompt = false
    @State private var exitEvent: ExitEvent?

    private var currentSettings: UserSettings? {
        settings.first
    }

    private var allChecked: Bool {
        items.allSatisfy { checkStates[$0.id] == true }
    }

    private var uncheckedCount: Int {
        items.filter { checkStates[$0.id] != true }.count
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            if showSuccessView {
                SuccessView(dismiss: dismissChecklist)
            } else {
                checklistContent
            }
        }
        .onAppear {
            initializeCheckStates()
            speakChecklistIfEnabled()
        }
    }

    private var checklistContent: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.top, 20)
                .padding(.bottom, 10)

            // Items list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        ExitChecklistRow(
                            item: item,
                            isChecked: checkStates[item.id] ?? false
                        ) {
                            toggleItem(item)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }

            Spacer()

            // Bottom buttons
            bottomButtons
                .padding(.horizontal)
                .padding(.bottom, 40)
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "door.left.hand.open")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
                .symbolEffect(.bounce, value: items.count)

            Text("Leaving Home?")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            if uncheckedCount > 0 {
                Text("\(uncheckedCount) item\(uncheckedCount == 1 ? "" : "s") to check")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("All items checked!")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal)
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // All Good button
            Button {
                completeChecklist(perfect: true)
            } label: {
                HStack {
                    Image(systemName: allChecked ? "checkmark.circle.fill" : "checkmark.circle")
                    Text(allChecked ? "All Good, Let's Go!" : "Mark All & Go")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(allChecked ? Color.green : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // I'm Rushing button
            Button {
                completeChecklist(perfect: false)
            } label: {
                Text("I'm Rushing")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
    }

    private func initializeCheckStates() {
        // Auto-check phone if setting enabled
        for item in items {
            if currentSettings?.autoCheckPhone == true &&
               item.title.lowercased().contains("phone") {
                checkStates[item.id] = true
            } else {
                checkStates[item.id] = false
            }
        }
    }

    private func speakChecklistIfEnabled() {
        guard currentSettings?.voiceReadoutEnabled == true else { return }

        SpeechManager.shared.speakChecklistItems(
            items,
            rate: currentSettings?.speechRate ?? 0.5,
            voiceIdentifier: currentSettings?.selectedVoiceIdentifier
        )
    }

    private func toggleItem(_ item: ChecklistItem) {
        let newState = !(checkStates[item.id] ?? false)
        checkStates[item.id] = newState

        if newState {
            HapticManager.checkItem()
        } else {
            HapticManager.uncheckItem()
        }

        if allChecked {
            HapticManager.allChecked()
        }
    }

    private func completeChecklist(perfect: Bool) {
        SpeechManager.shared.stop()

        let forgottenItems = items.filter { checkStates[$0.id] != true }.map { $0.title }

        // Record exit event
        let event = ExitEvent(
            wasComplete: perfect && allChecked,
            dismissedEarly: !perfect,
            forgottenItems: forgottenItems
        )
        modelContext.insert(event)

        // Update forgotten counts
        if !perfect {
            for item in items where checkStates[item.id] != true {
                item.markForgotten()
            }
        }

        // Update streak
        if perfect && allChecked {
            appState.recordPerfectExit()
        }

        if perfect && allChecked {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showSuccessView = true
            }
        } else {
            HapticManager.exitDismissed()
            dismiss()
        }
    }

    private func dismissChecklist() {
        dismiss()
    }
}

struct ExitChecklistRow: View {
    let item: ChecklistItem
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    Circle()
                        .strokeBorder(isChecked ? Color.green : Color.orange, lineWidth: 2.5)
                        .frame(width: 32, height: 32)

                    if isChecked {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 32, height: 32)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isChecked)

                // Emoji
                Text(item.emoji.isEmpty ? "•" : item.emoji)
                    .font(.title2)
                    .frame(width: 32)

                // Title
                Text(item.title)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .strikethrough(isChecked, color: .secondary)

                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isChecked ? Color(.tertiarySystemBackground) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isChecked ? Color.clear : Color.orange.opacity(0.3),
                        lineWidth: isChecked ? 0 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.title), \(isChecked ? "checked" : "unchecked")")
        .accessibilityHint("Double tap to \(isChecked ? "uncheck" : "check")")
    }
}

struct SuccessView: View {
    @EnvironmentObject private var appState: AppState
    let dismiss: () -> Void

    @State private var showMessage = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: showMessage)

                VStack(spacing: 12) {
                    Text(appState.randomFunMessage())
                        .font(.title.weight(.bold))
                        .multilineTextAlignment(.center)

                    if let streakMessage = appState.streakMessage() {
                        Text(streakMessage)
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                }
                .opacity(showMessage ? 1 : 0)
                .offset(y: showMessage ? 0 : 20)
            }

            Spacer()

            Button {
                HapticManager.buttonTap()
                dismiss()
            } label: {
                Text("Let's Go!")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 30)
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .onAppear {
            HapticManager.allChecked()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                showMessage = true
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                showButton = true
            }
        }
    }
}

#Preview {
    ExitChecklistView()
        .modelContainer(for: [ChecklistItem.self, ExitEvent.self, UserSettings.self])
        .environmentObject(AppState.shared)
}
