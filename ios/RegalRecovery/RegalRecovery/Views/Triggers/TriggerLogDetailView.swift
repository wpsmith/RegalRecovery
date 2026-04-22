import SwiftUI

struct TriggerLogDetailView: View {
    let entry: DetailEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header: timestamp
                headerSection

                // Trigger chips
                triggerChipsSection

                // Intensity
                if let intensity = entry.intensity {
                    intensitySection(intensity)
                }

                // Mood
                if let mood = entry.mood {
                    detailRow(icon: "face.smiling", label: "Mood", content: mood)
                }

                // Situation
                if let situation = entry.situation {
                    detailRow(icon: "note.text", label: "Situation", content: situation)
                }

                // Social context
                if let social = entry.socialContext {
                    detailRow(icon: "person.2.fill", label: "Social Context", content: social.displayName)
                }

                // Location
                if let location = entry.locationCategory {
                    detailRow(icon: "mappin.circle.fill", label: "Location", content: location.displayName)
                }

                // Body sensation
                if let sensation = entry.bodySensation {
                    detailRow(icon: "figure.stand", label: "Body Sensation", content: sensation)
                }

                // Response taken
                if let response = entry.responseTaken {
                    detailRow(icon: "hand.raised.fill", label: "Response Taken", content: response)
                }

                // Unmet need
                if let need = entry.unmetNeed {
                    detailRow(icon: need.icon, label: "Unmet Need", content: need.displayName)
                }

                // Teacher reflection
                if let reflection = entry.teacherReflection {
                    detailRow(icon: "lightbulb.fill", label: "Teacher Reflection", content: reflection)
                }

                // FASTER position
                if let stage = entry.fasterPosition {
                    fasterSection(stage)
                }

                // Coping effectiveness
                if let effectiveness = entry.copingEffectiveness {
                    detailRow(icon: "chart.bar.fill", label: "Coping Effectiveness", content: "\(effectiveness)/10")
                }

                // Linked urge log
                if entry.linkedUrgeLogId != nil {
                    linkedUrgeSection
                }
            }
            .padding(16)
        }
        .navigationTitle("Trigger Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formatFullTimestamp(entry.timestamp))
                .font(.headline)
                .foregroundStyle(.rrText)

            Text(formatRelativeTimestamp(entry.timestamp))
                .font(.caption)
                .foregroundStyle(.rrTextSecondary)
        }
    }

    // MARK: - Trigger Chips Section

    private var triggerChipsSection: some View {
        FlowLayout(spacing: 8) {
            ForEach(entry.triggerLabels, id: \.label) { item in
                TriggerChipView(
                    label: item.label,
                    category: item.category,
                    isSelected: true,
                    onTap: {}
                )
            }
        }
    }

    // MARK: - Intensity Section

    private func intensitySection(_ intensity: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INTENSITY")
                .font(.caption)
                .foregroundStyle(.rrTextSecondary)

            HStack(spacing: 12) {
                Text("\(intensity)/10")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.rrText)

                if let risk = entry.riskLevel {
                    RRBadge(text: risk.displayName, color: risk.color)
                }

                Spacer()
            }
        }
    }

    // MARK: - FASTER Section

    private func fasterSection(_ stage: FASTERStage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FASTER POSITION")
                .font(.caption)
                .foregroundStyle(.rrTextSecondary)

            HStack(spacing: 12) {
                // Circle with letter
                ZStack {
                    Circle()
                        .fill(stage.color)
                        .frame(width: 40, height: 40)

                    Text(stage.letter)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                // Stage name
                Text(stage.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.rrText)

                Spacer()
            }
        }
    }

    // MARK: - Linked Urge Section

    private var linkedUrgeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LINKED ENTRY")
                .font(.caption)
                .foregroundStyle(.rrTextSecondary)

            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text("View urge log entry")
                    .font(.body)
                    .foregroundStyle(.rrPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.rrTextSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    // MARK: - Detail Row Helper

    private func detailRow(icon: String, label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.rrTextSecondary)

                Text(label.uppercased())
                    .font(.caption)
                    .foregroundStyle(.rrTextSecondary)
            }

            Text(content)
                .font(.body)
                .foregroundStyle(.rrText)
        }
    }

    // MARK: - Timestamp Formatters

    private func formatFullTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatRelativeTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - DetailEntry

struct DetailEntry {
    let id: UUID
    let triggerLabels: [(label: String, category: TriggerCategory)]
    let intensity: Int?
    let riskLevel: RiskLevel?
    let logDepth: LogDepth
    let timestamp: Date
    let mood: String?
    let situation: String?
    let socialContext: SocialContext?
    let bodySensation: String?
    let responseTaken: String?
    let unmetNeed: UnmetNeed?
    let teacherReflection: String?
    let fasterPosition: FASTERStage?
    let copingEffectiveness: Int?
    let locationCategory: LocationCategory?
    let linkedUrgeLogId: UUID?
}

// MARK: - Previews

#Preview("Quick Entry") {
    NavigationStack {
        TriggerLogDetailView(entry: DetailEntry(
            id: UUID(),
            triggerLabels: [
                (label: "Stress", category: .emotional),
                (label: "Work Pressure", category: .situational)
            ],
            intensity: 6,
            riskLevel: .moderate,
            logDepth: .quick,
            timestamp: Date().addingTimeInterval(-3600),
            mood: nil,
            situation: nil,
            socialContext: nil,
            bodySensation: nil,
            responseTaken: nil,
            unmetNeed: nil,
            teacherReflection: nil,
            fasterPosition: nil,
            copingEffectiveness: nil,
            locationCategory: nil,
            linkedUrgeLogId: nil
        ))
    }
}

#Preview("Standard Entry") {
    NavigationStack {
        TriggerLogDetailView(entry: DetailEntry(
            id: UUID(),
            triggerLabels: [
                (label: "Loneliness", category: .emotional),
                (label: "Isolation", category: .relational),
                (label: "Home Alone", category: .environmental)
            ],
            intensity: 7,
            riskLevel: .high,
            logDepth: .standard,
            timestamp: Date().addingTimeInterval(-86400),
            mood: "Sad and disconnected",
            situation: "Working from home, no social interaction all day",
            socialContext: .alone,
            bodySensation: "Heavy chest, tension in shoulders",
            responseTaken: "Called accountability partner",
            unmetNeed: .toBeIncluded,
            teacherReflection: nil,
            fasterPosition: nil,
            copingEffectiveness: nil,
            locationCategory: .home,
            linkedUrgeLogId: nil
        ))
    }
}

#Preview("Deep Entry") {
    NavigationStack {
        TriggerLogDetailView(entry: DetailEntry(
            id: UUID(),
            triggerLabels: [
                (label: "Anger", category: .emotional),
                (label: "Resentment", category: .cognitive),
                (label: "Conflict", category: .relational)
            ],
            intensity: 9,
            riskLevel: .high,
            logDepth: .deep,
            timestamp: Date().addingTimeInterval(-172800),
            mood: "Angry, defensive, and isolated",
            situation: "Argument with spouse about unmet expectations",
            socialContext: .spouse,
            bodySensation: "Rapid heartbeat, clenched jaw, hot face",
            responseTaken: "Went for a walk, prayed, journaled",
            unmetNeed: .toBeHeard,
            teacherReflection: "I realize my anger was masking hurt and fear of rejection. The trigger wasn't the argument itself but my perception that I'm not valued.",
            fasterPosition: .tickedOff,
            copingEffectiveness: 7,
            locationCategory: .home,
            linkedUrgeLogId: UUID()
        ))
    }
}
