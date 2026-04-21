import SwiftUI
import SwiftData

struct SeedPersonaPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPersona: SeedPersona?
    @State private var showConfirmation = false
    @State private var isSeeding = false
    @State private var statusMessage: String?
    @State private var expandedSections: Set<SeedPersona.Category> = Set(SeedPersona.Category.allCases)

    private func expandedBinding(for category: SeedPersona.Category) -> Binding<Bool> {
        Binding(
            get: { expandedSections.contains(category) },
            set: { isExpanded in
                if isExpanded {
                    expandedSections.insert(category)
                } else {
                    expandedSections.remove(category)
                }
            }
        )
    }

    private var groupedPersonas: [(SeedPersona.Category, [SeedPersona])] {
        SeedPersona.Category.allCases.compactMap { cat in
            let personas = SeedPersona.allPersonas.filter { $0.category == cat }
            return personas.isEmpty ? nil : (cat, personas)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(groupedPersonas, id: \.0) { category, personas in
                        Section(isExpanded: expandedBinding(for: category)) {
                            ForEach(personas) { persona in
                                personaRow(persona)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedPersona = persona
                                        showConfirmation = true
                                    }
                            }
                        } header: {
                            Text(category.rawValue)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .disabled(isSeeding)

                if isSeeding {
                    seedingOverlay
                }
            }
            .navigationTitle("Seed App")
            .confirmationDialog(
                "Seed as \(selectedPersona?.name ?? "persona")?",
                isPresented: $showConfirmation,
                titleVisibility: .visible
            ) {
                Button("Erase & Seed", role: .destructive) {
                    if let persona = selectedPersona {
                        seedWithPersona(persona)
                    }
                }
                Button("Cancel", role: .cancel) {
                    selectedPersona = nil
                }
            } message: {
                if let persona = selectedPersona {
                    Text("This will erase ALL existing data and replace it with \(persona.name)'s \(persona.sobrietyDays)-day recovery profile. This cannot be undone.")
                }
            }
            .overlay(alignment: .bottom) {
                if let statusMessage {
                    successBanner(statusMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: statusMessage)
        }
    }

    // MARK: - Persona Row

    private func personaRow(_ persona: SeedPersona) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top: Avatar + name + tagline
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.rrPrimary)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(persona.avatarInitial)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(persona.name)
                        .font(RRFont.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.rrText)
                    Text(persona.tagline)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            // Bottom: Stats row
            HStack(spacing: 6) {
                // Sobriety days
                statPill(
                    icon: "flame.fill",
                    value: "\(persona.sobrietyDays)d",
                    color: persona.sobrietyDays >= 180 ? .rrSuccess : .orange
                )

                // Relapses
                let relapseCount = persona.addictions.flatMap(\.relapses).count
                if relapseCount > 0 {
                    statPill(
                        icon: "arrow.uturn.backward",
                        value: "\(relapseCount)",
                        color: .rrDestructive
                    )
                }

                // Activity level
                statPill(
                    icon: "chart.bar.fill",
                    value: persona.activityLevel.rawValue,
                    color: activityLevelColor(persona.activityLevel)
                )

                Spacer()
            }

            // Addiction badges
            FlowLayout(spacing: 6) {
                ForEach(persona.addictions.map(\.name), id: \.self) { name in
                    addictionBadge(name)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Stat Pill

    private func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(value)
                .font(RRFont.caption2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Addiction Badge

    private func addictionBadge(_ addiction: String) -> some View {
        Text(addiction)
            .font(RRFont.caption2)
            .fontWeight(.medium)
            .foregroundStyle(Color.rrPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.rrPrimary.opacity(0.1))
            .clipShape(Capsule())
    }

    // MARK: - Seeding Overlay

    private var seedingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.rrPrimary)
            Text("Seeding data...")
                .font(RRFont.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.rrText)
        }
        .frame(width: 160, height: 120)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Success Banner

    private func successBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.rrSuccess)
            Text(message)
                .font(RRFont.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.rrText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Activity Level Color

    private func activityLevelColor(_ level: SeedPersona.ActivityLevel) -> Color {
        switch level {
        case .intensive: return .rrSuccess
        case .moderate: return .blue
        case .minimal: return .orange
        case .single: return .rrTextSecondary
        case .inactive: return .rrDestructive
        }
    }

    // MARK: - Seed Logic

    private func seedWithPersona(_ persona: SeedPersona) {
        isSeeding = true
        statusMessage = nil
        let container = modelContext.container

        Task.detached {
            do {
                let context = ModelContext(container)
                context.autosaveEnabled = false

                try context.delete(model: RRUser.self)
                try context.delete(model: RRAddiction.self)
                try context.delete(model: RRStreak.self)
                try context.delete(model: RRMilestone.self)
                try context.delete(model: RRRelapse.self)
                try context.delete(model: RRActivity.self)
                try context.delete(model: RRCheckIn.self)
                try context.delete(model: RRMoodEntry.self)
                try context.delete(model: RRPrayerLog.self)
                try context.delete(model: RRExerciseLog.self)
                try context.delete(model: RRFASTEREntry.self)
                try context.delete(model: RRGratitudeEntry.self)
                try context.delete(model: RRJournalEntry.self)
                try context.delete(model: RRTimeBlock.self)
                try context.delete(model: RRUrgeLog.self)
                try context.delete(model: RRPhoneCallLog.self)
                try context.delete(model: RRMeetingLog.self)
                try context.delete(model: RRCommitment.self)
                try context.delete(model: RRSpouseCheckIn.self)
                try context.delete(model: RRStepWork.self)
                try context.delete(model: RRGoal.self)
                try context.delete(model: RRSupportContact.self)
                try context.delete(model: RRFeatureFlag.self)
                try context.delete(model: RRAffirmationFavorite.self)
                try context.delete(model: RRDevotionalProgress.self)
                try context.delete(model: RRRecoveryPlan.self)
                try context.delete(model: RRDailyPlanItem.self)
                try context.delete(model: RRDailyScore.self)
                try context.delete(model: RRSyncQueueItem.self)
                try context.save()

                UserDefaults.standard.removeObject(forKey: SeedData.seedKey)
                UserDefaults.standard.removeObject(forKey: "hasSeededDatabase")

                try SeedPersonaData.seed(persona: persona, context: context)

                await MainActor.run {
                    statusMessage = "\(persona.name)'s data seeded successfully"
                    isSeeding = false
                }

                try await Task.sleep(for: .seconds(1.5))
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Error: \(error.localizedDescription)"
                    isSeeding = false
                }
            }
        }
    }
}

#Preview {
    SeedPersonaPickerView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
