import SwiftUI
import SwiftData

struct PPPFormView: View {
    let marker: RRBowtieMarker
    let onSave: () -> Void
    let existingEntry: RRPPPEntry?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PPPEntryViewModel()

    @Query(sort: \RRSupportContact.name) private var contacts: [RRSupportContact]

    init(
        marker: RRBowtieMarker,
        existingEntry: RRPPPEntry? = nil,
        onSave: @escaping () -> Void
    ) {
        self.marker = marker
        self.existingEntry = existingEntry
        self.onSave = onSave
    }

    /// Derive the primary Three-I type from the marker's highest-intensity activation.
    private var primaryIType: ThreeIType? {
        marker.iActivations
            .sorted { $0.intensity > $1.intensity }
            .first?.iType
    }

    /// Whether this is an edit of an entry whose anticipated time has already passed.
    private var showFollowUp: Bool {
        guard let entry = existingEntry, let session = marker.session else { return false }
        let anticipatedDate = session.referenceTimestamp.addingTimeInterval(
            TimeInterval(marker.timeIntervalHours * 3600)
        )
        return entry.outcome == nil && Date() > anticipatedDate
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    prayerSection
                    peopleSection
                    planSection
                    reminderSection

                    if showFollowUp {
                        followUpSection
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle(existingEntry != nil
                ? String(localized: "Edit Plan")
                : String(localized: "Prayer / People / Plan"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        if let existing = existingEntry {
                            applyEdits(to: existing)
                        } else {
                            viewModel.save(marker: marker, context: modelContext)
                        }
                        onSave()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onAppear {
                if let existing = existingEntry {
                    viewModel.loadFromExisting(existing)
                }
            }
        }
    }

    // MARK: - Prayer Section

    private var prayerSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Prayer"))
                    .font(.headline)
                    .foregroundStyle(Color.rrText)

                if let suggestion = prayerSuggestion {
                    Button {
                        if viewModel.prayer.isEmpty {
                            viewModel.prayer = suggestion
                        }
                    } label: {
                        Text(suggestion)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.rrPrimary.opacity(0.12))
                            .foregroundStyle(Color.rrPrimary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Tap to use suggested prayer"))
                }

                TextEditor(text: $viewModel.prayer)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.rrSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Group {
                            if viewModel.prayer.isEmpty {
                                Text(String(localized: "Write a prayer for this situation..."))
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .padding(.leading, 12)
                                    .padding(.top, 16)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }
        }
    }

    private var prayerSuggestion: String? {
        guard let iType = primaryIType else { return nil }
        switch iType {
        case .insignificance:
            return String(localized: "Lord, remind me that I am seen and valued by You")
        case .incompetence:
            return String(localized: "Lord, remind me that You equip me for what You call me to")
        case .impotence:
            return String(localized: "Lord, remind me that You are in control even when I am not")
        }
    }

    // MARK: - People Section

    private var peopleSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "People"))
                    .font(.headline)
                    .foregroundStyle(Color.rrText)

                if contacts.isEmpty {
                    Text(String(localized: "No support contacts configured yet."))
                        .font(.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(contacts, id: \.id) { contact in
                        contactRow(contact)
                    }
                }
            }
        }
    }

    private func contactRow(_ contact: RRSupportContact) -> some View {
        let isSelected = viewModel.selectedContactIds.contains(contact.id)
        return Button {
            if isSelected {
                viewModel.selectedContactIds.remove(contact.id)
            } else {
                viewModel.selectedContactIds.insert(contact.id)
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.rrPrimary : Color.rrTextSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.subheadline)
                        .foregroundStyle(Color.rrText)
                    Text(contact.role.capitalized)
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(contact.name), \(contact.role)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Plan Section

    private var planSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Plan"))
                    .font(.headline)
                    .foregroundStyle(Color.rrText)

                planField(
                    label: String(localized: "Before this situation, I will ___"),
                    text: $viewModel.planBefore
                )
                planField(
                    label: String(localized: "During this situation, I will ___"),
                    text: $viewModel.planDuring
                )
                planField(
                    label: String(localized: "After this situation, I will ___"),
                    text: $viewModel.planAfter
                )
            }
        }
    }

    private func planField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.rrTextSecondary)

            TextField(label, text: text, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Reminder Section

    private var reminderSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $viewModel.reminderEnabled) {
                    Text(String(localized: "Set Reminder"))
                        .font(.headline)
                        .foregroundStyle(Color.rrText)
                }
                .tint(Color.rrPrimary)

                if viewModel.reminderEnabled {
                    Picker(String(localized: "Remind me"), selection: $viewModel.reminderMinutesBefore) {
                        Text(String(localized: "30 minutes before")).tag(30)
                        Text(String(localized: "1 hour before")).tag(60)
                        Text(String(localized: "3 hours before")).tag(180)
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }

    // MARK: - Follow-Up Section

    private var followUpSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "How did it go?"))
                    .font(.headline)
                    .foregroundStyle(Color.rrText)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 10) {
                    ForEach(PPPOutcome.allCases, id: \.rawValue) { outcome in
                        outcomeButton(outcome)
                    }
                }

                if viewModel.followUpOutcome != nil && viewModel.followUpOutcome != .reflectLater {
                    TextEditor(text: $viewModel.followUpReflection)
                        .frame(minHeight: 60)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            Group {
                                if viewModel.followUpReflection.isEmpty {
                                    Text(String(localized: "Any reflections? (optional)"))
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .padding(.leading, 12)
                                        .padding(.top, 16)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
            }
        }
    }

    private func outcomeButton(_ outcome: PPPOutcome) -> some View {
        let isSelected = viewModel.followUpOutcome == outcome
        return Button {
            viewModel.followUpOutcome = outcome
        } label: {
            VStack(spacing: 6) {
                Image(systemName: outcome.icon)
                    .font(.title3)
                Text(outcome.displayName)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(isSelected ? Color.rrPrimary.opacity(0.15) : Color.rrSurface)
            .foregroundStyle(isSelected ? Color.rrPrimary : Color.rrText)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.rrPrimary : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(outcome.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Helpers

    private func applyEdits(to entry: RRPPPEntry) {
        entry.prayer = viewModel.prayer.isEmpty ? nil : viewModel.prayer
        entry.peopleContactIds = viewModel.selectedContactIds.isEmpty ? nil : Array(viewModel.selectedContactIds)
        entry.planBefore = viewModel.planBefore.isEmpty ? nil : viewModel.planBefore
        entry.planDuring = viewModel.planDuring.isEmpty ? nil : viewModel.planDuring
        entry.planAfter = viewModel.planAfter.isEmpty ? nil : viewModel.planAfter

        // Update reminder
        if viewModel.reminderEnabled, let session = marker.session {
            let anticipatedDate = session.referenceTimestamp.addingTimeInterval(
                TimeInterval(marker.timeIntervalHours * 3600)
            )
            let reminderDate = anticipatedDate.addingTimeInterval(
                -TimeInterval(viewModel.reminderMinutesBefore * 60)
            )
            viewModel.cancelReminder(id: entry.id)
            entry.reminderTime = reminderDate
            viewModel.scheduleReminder(id: entry.id, at: reminderDate)
        } else {
            viewModel.cancelReminder(id: entry.id)
            entry.reminderTime = nil
        }

        // Follow-up
        if let outcome = viewModel.followUpOutcome {
            viewModel.recordFollowUp(
                entry: entry,
                outcome: outcome,
                reflection: viewModel.followUpReflection
            )
        }
    }
}
