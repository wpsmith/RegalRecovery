import SwiftUI

struct RecoveryWorkItemRow: View {
    let item: RecoveryWorkItem
    var onStart: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Activity icon
            Image(systemName: item.icon)
                .font(.body)
                .foregroundStyle(item.iconColor)
                .frame(width: 32, height: 32)
                .background(item.iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Title and trigger reason
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                Text(item.triggerReason)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .lineLimit(2)

                if let dueDate = item.dueDate, item.status != .completed {
                    Text(dueDateLabel(dueDate))
                        .font(RRFont.caption2)
                        .foregroundStyle(dueDateColor(dueDate))
                }
            }

            Spacer()

            // Status badge or Start button
            if item.status == .notStarted || item.status == .overdue {
                if let onStart {
                    Button(action: onStart) {
                        Text("Start")
                            .font(RRFont.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.rrPrimary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                } else {
                    statusBadge
                }
            } else {
                statusBadge
            }

            if item.status == .completed || item.status == .inProgress {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        RRBadge(text: item.status.label, color: item.status.color)
    }

    private func dueDateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0

        if days < 0 {
            return "\(abs(days)) days overdue"
        } else if days == 0 {
            return "Due today"
        } else if days == 1 {
            return "Due tomorrow"
        } else if days <= 7 {
            return "Due in \(days) days"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Due \(formatter.string(from: date))"
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0

        if days < 0 {
            return .orange
        } else if days <= 3 {
            return .rrDestructive
        } else if days <= 7 {
            return .rrSecondary
        } else {
            return .rrTextSecondary
        }
    }
}

#Preview {
    List {
        RecoveryWorkItemRow(
            item: RecoveryWorkItem(
                activityType: "threeCirclesReview",
                title: "3 Circles Review",
                triggerReason: "Last reviewed 62 days ago -- quarterly review recommended",
                dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
                priority: .high,
                status: .overdue,
                icon: "circles.hexagongrid.fill",
                iconColor: .red
            ),
            onStart: {}
        )

        RecoveryWorkItemRow(
            item: RecoveryWorkItem(
                activityType: "assessment.sast-r",
                title: "SAST-R Assessment",
                triggerReason: "90-day periodic assessment",
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                priority: .medium,
                status: .notStarted,
                icon: "clipboard.fill",
                iconColor: .purple
            )
        )

        RecoveryWorkItemRow(
            item: RecoveryWorkItem(
                activityType: "postMortem",
                title: "Post-Mortem Analysis",
                triggerReason: "Completed after slip on day 45",
                dueDate: nil,
                priority: .high,
                status: .completed,
                icon: "magnifyingglass.circle",
                iconColor: .red
            )
        )
    }
    .listStyle(.insetGrouped)
}
