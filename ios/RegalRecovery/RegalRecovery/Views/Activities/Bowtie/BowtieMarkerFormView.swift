import SwiftUI

struct BowtieMarkerFormView: View {
    let vocabulary: EmotionVocabulary
    let availableRoles: [RRUserRole]
    let availableTriggers: [RRKnownEmotionalTrigger]
    let existingMarker: RRBowtieMarker?
    let onSave: (RRBowtieMarker) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BowtieMarkerViewModel()

    init(
        vocabulary: EmotionVocabulary,
        availableRoles: [RRUserRole],
        availableTriggers: [RRKnownEmotionalTrigger],
        existingMarker: RRBowtieMarker? = nil,
        onSave: @escaping (RRBowtieMarker) -> Void
    ) {
        self.vocabulary = vocabulary
        self.availableRoles = availableRoles
        self.availableTriggers = availableTriggers
        self.existingMarker = existingMarker
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    rolePickerSection
                    timeIntervalSection
                    emotionSection
                    triggersSection
                    descriptionSection
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle(existingMarker != nil
                ? String(localized: "Edit Marker")
                : String(localized: "Add Marker"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        let marker = viewModel.buildMarker()
                        onSave(marker)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onAppear {
                if let existing = existingMarker {
                    viewModel.loadFromMarker(existing)
                } else if let firstRole = availableRoles.first {
                    viewModel.selectedRoleId = firstRole.id
                }
            }
        }
    }

    // MARK: - Role Picker

    private var rolePickerSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Role"))
                    .font(.headline)
                    .foregroundStyle(Color.rrText)

                Picker(String(localized: "Role"), selection: $viewModel.selectedRoleId) {
                    Text(String(localized: "Select a role"))
                        .tag(UUID?.none)
                    ForEach(availableRoles, id: \.id) { role in
                        Text(role.label).tag(UUID?.some(role.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }

    // MARK: - Time Interval

    private var timeIntervalSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Time Interval"))
                    .font(.headline)
                    .foregroundStyle(Color.rrText)

                Picker(String(localized: "Hours"), selection: $viewModel.selectedTimeInterval) {
                    ForEach(BowtieSide.timeIntervals, id: \.self) { interval in
                        Text("\(interval)h").tag(interval)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Emotion Section

    private var emotionSection: some View {
        VStack(spacing: 16) {
            if vocabulary == .threeIs || vocabulary == .combined {
                threeIsSection
            }
            if vocabulary == .bigTicket || vocabulary == .combined {
                bigTicketSection
            }
        }
    }

    private var threeIsSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Three I's"))
                    .font(.headline)
                    .foregroundStyle(Color.rrText)

                ForEach(ThreeIType.allCases) { iType in
                    iTypeRow(iType)
                }
            }
        }
    }

    private func iTypeRow(_ iType: ThreeIType) -> some View {
        let isActive = viewModel.iActivations.contains { $0.iType == iType }
        let currentIntensity = viewModel.iActivations.first { $0.iType == iType }?.intensity ?? 5

        return VStack(spacing: 8) {
            Button {
                viewModel.toggleIActivation(iType)
            } label: {
                HStack {
                    Image(systemName: iType.icon)
                        .foregroundStyle(iType.color)
                    Text(iType.displayName)
                        .font(.subheadline)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(iType.color)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isActive {
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { Double(currentIntensity) },
                            set: { viewModel.updateIIntensity(iType, intensity: Int($0)) }
                        ),
                        in: 1...10,
                        step: 1
                    )
                    .tint(iType.color)

                    HStack {
                        Text(String(localized: "Low"))
                            .font(.caption2)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                        Text("\(currentIntensity)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(iType.color)
                        Spacer()
                        Text(String(localized: "High"))
                            .font(.caption2)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .padding(.leading, 28)
            }
        }
    }

    private var bigTicketSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Big Ticket Emotions"))
                    .font(.headline)
                    .foregroundStyle(Color.rrText)

                ForEach(BigTicketEmotion.allCases) { emotion in
                    bigTicketRow(emotion)
                }
            }
        }
    }

    private func bigTicketRow(_ emotion: BigTicketEmotion) -> some View {
        let isActive = viewModel.bigTicketEmotions.contains { $0.emotion == emotion }
        let currentIntensity = viewModel.bigTicketEmotions.first { $0.emotion == emotion }?.intensity ?? 5

        return VStack(spacing: 8) {
            Button {
                viewModel.toggleBigTicket(emotion)
            } label: {
                HStack {
                    Image(systemName: emotion.icon)
                        .foregroundStyle(emotion.color)
                    Text(emotion.displayName)
                        .font(.subheadline)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(emotion.color)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isActive {
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { Double(currentIntensity) },
                            set: { viewModel.updateBigTicketIntensity(emotion, intensity: Int($0)) }
                        ),
                        in: 1...10,
                        step: 1
                    )
                    .tint(emotion.color)

                    HStack {
                        Text(String(localized: "Low"))
                            .font(.caption2)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                        Text("\(currentIntensity)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(emotion.color)
                        Spacer()
                        Text(String(localized: "High"))
                            .font(.caption2)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .padding(.leading, 28)
            }
        }
    }

    // MARK: - Known Triggers

    private var triggersSection: some View {
        Group {
            if !availableTriggers.isEmpty {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Known Triggers"))
                            .font(.headline)
                            .foregroundStyle(Color.rrText)

                        FlowLayout(spacing: 8) {
                            ForEach(availableTriggers, id: \.id) { trigger in
                                triggerChip(trigger)
                            }
                        }
                    }
                }
            }
        }
    }

    private func triggerChip(_ trigger: RRKnownEmotionalTrigger) -> some View {
        let isSelected = viewModel.selectedTriggerIds.contains(trigger.id)
        return Button {
            if isSelected {
                viewModel.selectedTriggerIds.remove(trigger.id)
            } else {
                viewModel.selectedTriggerIds.insert(trigger.id)
            }
        } label: {
            Text(trigger.label)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.rrPrimary.opacity(0.2) : Color.rrSurface)
                .foregroundStyle(isSelected ? Color.rrPrimary : Color.rrText)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.rrPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Brief Description"))
                    .font(.headline)
                    .foregroundStyle(Color.rrText)

                TextField(
                    String(localized: "What happened?"),
                    text: $viewModel.briefDescription,
                    axis: .vertical
                )
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)

                HStack {
                    Spacer()
                    Text("\(viewModel.briefDescription.count)/\(BowtieMarkerViewModel.maxDescriptionLength)")
                        .font(.caption2)
                        .foregroundStyle(
                            viewModel.briefDescription.count > BowtieMarkerViewModel.maxDescriptionLength
                                ? Color.rrDestructive
                                : Color.rrTextSecondary
                        )
                }
            }
        }
    }
}
