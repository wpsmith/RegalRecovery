import SwiftUI

struct TriggerLogHistoryView: View {
    let entries: [TriggerLogHistoryItem]

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .navigationTitle("Trigger History")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing to show yet",
            systemImage: "bolt.trianglebadge.exclamationmark",
            description: Text("Your trigger history will appear here once you start logging triggers.")
        )
    }

    // MARK: - History List

    private var historyList: some View {
        List(entries) { entry in
            NavigationLink(value: entry.id) {
                historyRow(entry)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(.plain)
    }

    // MARK: - History Row

    private func historyRow(_ entry: TriggerLogHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top: category icons + timestamp
            HStack(spacing: 8) {
                // Show first 3 category icons
                ForEach(Array(entry.categories.prefix(3)), id: \.self) { category in
                    Image(systemName: category.icon)
                        .font(.caption)
                        .foregroundStyle(category.color)
                }

                Spacer()

                Text(relativeTimestamp(entry.timestamp))
                    .font(.caption)
                    .foregroundStyle(.rrTextSecondary)
            }

            // Middle: trigger labels
            Text(entry.triggerLabels.joined(separator: ", "))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.rrText)
                .lineLimit(2)

            // Bottom: intensity + context summary
            HStack(spacing: 8) {
                if let intensity = entry.intensity {
                    HStack(spacing: 4) {
                        intensityCircle(intensity)

                        Text("Intensity \(intensity)")
                            .font(.caption)
                            .foregroundStyle(.rrTextSecondary)
                    }
                }

                if let context = entry.contextSummary {
                    Text("·")
                        .foregroundStyle(.rrTextSecondary)

                    Text(context)
                        .font(.caption)
                        .foregroundStyle(.rrTextSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Intensity Circle

    private func intensityCircle(_ intensity: Int) -> some View {
        let risk = RiskLevel.from(intensity: intensity)

        return Circle()
            .fill(risk.color)
            .frame(width: 8, height: 8)
    }

    // MARK: - Relative Timestamp

    private func relativeTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - TriggerLogHistoryItem

struct TriggerLogHistoryItem: Identifiable {
    let id: UUID
    let triggerLabels: [String]
    let intensity: Int?
    let riskLevel: RiskLevel?
    let categories: [TriggerCategory]
    let timestamp: Date
    let contextSummary: String?
}

// MARK: - Previews

#Preview("With History") {
    NavigationStack {
        TriggerLogHistoryView(entries: [
            TriggerLogHistoryItem(
                id: UUID(),
                triggerLabels: ["Stress", "Anxiety", "Work Pressure"],
                intensity: 7,
                riskLevel: .high,
                categories: [.emotional, .situational],
                timestamp: Date().addingTimeInterval(-3600),
                contextSummary: "At work, feeling overwhelmed"
            ),
            TriggerLogHistoryItem(
                id: UUID(),
                triggerLabels: ["Loneliness", "Isolation"],
                intensity: 5,
                riskLevel: .moderate,
                categories: [.emotional, .relational],
                timestamp: Date().addingTimeInterval(-86400),
                contextSummary: "Home alone"
            ),
            TriggerLogHistoryItem(
                id: UUID(),
                triggerLabels: ["Fatigue"],
                intensity: 3,
                riskLevel: .low,
                categories: [.physical],
                timestamp: Date().addingTimeInterval(-172800),
                contextSummary: nil
            ),
        ])
    }
}

#Preview("Empty") {
    NavigationStack {
        TriggerLogHistoryView(entries: [])
    }
}
