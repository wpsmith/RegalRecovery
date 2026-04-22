import SwiftUI
import SwiftData

struct UrgeLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Query(sort: \RRAddiction.name) private var addictions: [RRAddiction]

    @State private var currentStep = 0
    @State private var intensity: Double = 5
    @State private var selectedAddictionIds: Set<UUID> = []
    @State private var selectedTriggers: Set<String> = []
    @State private var notes = ""

    // Custom trigger entry
    @State private var customTriggerText = ""
    @State private var showCustomTriggerField = false
    @AppStorage("customUrgeLogTriggers") private var customTriggersData: Data = Data()

    private var singleAddiction: Bool { addictions.count <= 1 }
    private var totalSteps: Int { singleAddiction ? 3 : 4 }

    private let defaultTriggers = ["Stress", "Loneliness", "Boredom", "Anger", "Tiredness", "Social Media", "Late Night", "Conflict"]

    private var customTriggers: [String] {
        guard !customTriggersData.isEmpty,
              let decoded = try? JSONDecoder().decode([String].self, from: customTriggersData) else {
            return []
        }
        return decoded
    }

    private var allTriggers: [String] {
        defaultTriggers + customTriggers
    }

    private func saveCustomTrigger(_ trigger: String) {
        var current = customTriggers
        let trimmed = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !defaultTriggers.contains(trimmed), !current.contains(trimmed) else { return }
        current.append(trimmed)
        if let data = try? JSONEncoder().encode(current) {
            customTriggersData = data
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }

                currentStepView

                // Navigation
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(Color.rrPrimary)
                            .background(Color.rrPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    if currentStep < totalSteps - 1 {
                        Button {
                            withAnimation { currentStep += 1 }
                        } label: {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color.rrPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .onAppear {
            if singleAddiction, let id = addictions.first?.id {
                selectedAddictionIds = [id]
            }
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        if singleAddiction {
            switch currentStep {
            case 0: step1Intensity
            case 1: step3Triggers
            default: step4Notes
            }
        } else {
            switch currentStep {
            case 0: step1Intensity
            case 1: step2Addiction
            case 2: step3Triggers
            default: step4Notes
            }
        }
    }

    // MARK: - Step 1: Intensity

    private var step1Intensity: some View {
        RRCard {
            VStack(spacing: 20) {
                Text("How intense is the urge?")
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)

                Text("\(Int(intensity))")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(intensityColor)

                Text("/10")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrTextSecondary)

                ZStack(alignment: .leading) {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 6)
                        .clipShape(Capsule())
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 30)

                    Slider(value: $intensity, in: 1...10, step: 1)
                        .tint(.clear)
                }
            }
        }
        .padding(.horizontal)
    }

    private var intensityColor: Color {
        switch Int(intensity) {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        default: return .red
        }
    }

    // MARK: - Step 2: Addiction (Multi-Select)

    private var step2Addiction: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Which addiction?")
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)

                Text("Select all that apply")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                ForEach(addictions, id: \.id) { addiction in
                    Button {
                        if selectedAddictionIds.contains(addiction.id) {
                            selectedAddictionIds.remove(addiction.id)
                        } else {
                            selectedAddictionIds.insert(addiction.id)
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedAddictionIds.contains(addiction.id) ? "checkmark.square.fill" : "square")
                                .foregroundStyle(selectedAddictionIds.contains(addiction.id) ? Color.rrPrimary : Color.rrTextSecondary)
                            Text(addiction.name)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selectedAddictionIds.contains(addiction.id) ? Color.rrPrimary.opacity(0.1) : Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Step 3: Triggers (with Custom Entry)

    private var step3Triggers: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("What triggered the urge?")
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)

                Text("Select all that apply")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                FlowLayout(spacing: 10) {
                    ForEach(allTriggers, id: \.self) { trigger in
                        Button {
                            if selectedTriggers.contains(trigger) {
                                selectedTriggers.remove(trigger)
                            } else {
                                selectedTriggers.insert(trigger)
                            }
                        } label: {
                            Text(trigger)
                                .font(RRFont.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(selectedTriggers.contains(trigger) ? .white : Color.rrText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedTriggers.contains(trigger) ? Color.rrPrimary : Color.rrSurface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().strokeBorder(Color.rrTextSecondary.opacity(0.2), lineWidth: selectedTriggers.contains(trigger) ? 0 : 1)
                                )
                        }
                    }

                    // Add custom trigger button
                    if showCustomTriggerField {
                        HStack(spacing: 6) {
                            TextField("Custom trigger", text: $customTriggerText)
                                .font(RRFont.subheadline)
                                .textFieldStyle(.plain)
                                .frame(minWidth: 100)
                                .onSubmit {
                                    confirmCustomTrigger()
                                }

                            Button {
                                confirmCustomTrigger()
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.rrPrimary)
                            }

                            Button {
                                showCustomTriggerField = false
                                customTriggerText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.rrSurface)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(Color.rrPrimary.opacity(0.5), lineWidth: 1)
                        )
                    } else {
                        Button {
                            showCustomTriggerField = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add")
                            }
                            .font(RRFont.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.rrPrimary.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func confirmCustomTrigger() {
        let trimmed = customTriggerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        saveCustomTrigger(trimmed)
        selectedTriggers.insert(trimmed)
        customTriggerText = ""
        showCustomTriggerField = false
    }

    // MARK: - Step 4: Notes

    private var step4Notes: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Any notes? (optional)")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)

            RRButton("Log Urge", icon: "exclamationmark.triangle.fill") {
                submitUrge()
            }
            .padding(.horizontal)
        }
    }

    private func submitUrge() {
        let userId = users.first?.id ?? UUID()
        let selectedIds = Array(selectedAddictionIds)
        let entry = RRUrgeLog(
            userId: userId,
            date: Date(),
            intensity: Int(intensity),
            addictionIds: selectedIds,
            triggers: Array(selectedTriggers),
            notes: notes,
            resolution: ""
        )
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        UrgeLogView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
