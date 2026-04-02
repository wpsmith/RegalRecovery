import SwiftUI

struct PlanActivityRowView: View {
    @Binding var item: PlanItemState
    var siblingCount: Int = 1

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Row 1: Icon + type label + custom title + time picker (all one line)
            HStack(spacing: 8) {
                Image(systemName: item.activity.icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
                    .frame(width: 22, height: 22)

                // Type label (e.g., "Prayer #2")
                let typeLabel = siblingCount > 1
                    ? "\(item.activity.displayName) #\(item.instanceIndex + 1)"
                    : item.activity.displayName
                Text(typeLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.rrText)
                    .lineLimit(1)

                // Custom title inline
                TextField("Custom name", text: $item.customTitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.rrPrimary)
                    .textFieldStyle(.plain)
                    .lineLimit(1)

                Spacer(minLength: 4)

                // Time picker (compact)
                DatePicker(
                    "",
                    selection: Binding(
                        get: { item.scheduledTime },
                        set: { item.scheduledTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .frame(width: 90)
            }

            // Row 2: Day-of-week chips (compact)
            let isEveryDay = item.daysOfWeek.isEmpty
            HStack(spacing: 4) {
                ForEach(1...7, id: \.self) { day in
                    let selected = isEveryDay || item.daysOfWeek.contains(day)
                    Button {
                        toggleDay(day, isEveryDay: isEveryDay)
                    } label: {
                        Text(dayLabels[day - 1])
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 28, height: 28)
                            .foregroundStyle(selected ? .white : Color.rrTextSecondary)
                            .background(selected ? Color.rrPrimary : Color.rrSurface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)
                }

                Spacer()

                if !isEveryDay {
                    Button {
                        item.daysOfWeek.removeAll()
                    } label: {
                        Text("All")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.rrPrimary)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func toggleDay(_ day: Int, isEveryDay: Bool) {
        if isEveryDay {
            // "Every day" → select all except this one
            item.daysOfWeek = Set(1...7)
            item.daysOfWeek.remove(day)
        } else if item.daysOfWeek.contains(day) {
            item.daysOfWeek.remove(day)
            // If none left, revert to "every day"
        } else {
            item.daysOfWeek.insert(day)
            // If all 7 selected, collapse to "every day"
            if item.daysOfWeek.count == 7 { item.daysOfWeek.removeAll() }
        }
    }

    private var iconColor: Color {
        if let at = ActivityType(rawValue: item.activity.activityType) {
            return at.iconColor
        }
        return .rrPrimary
    }
}

#Preview {
    List {
        PlanActivityRowView(
            item: .constant(PlanItemState(
                id: UUID(),
                activity: DailyEligibleActivity.all[0],
                isEnabled: true,
                scheduledHour: 7,
                scheduledMinute: 0,
                instanceIndex: 0,
                daysOfWeek: [],
                customTitle: ""
            ))
        )
        PlanActivityRowView(
            item: .constant(PlanItemState(
                id: UUID(),
                activity: DailyEligibleActivity.all[4],
                isEnabled: true,
                scheduledHour: 7,
                scheduledMinute: 0,
                instanceIndex: 0,
                daysOfWeek: [],
                customTitle: "Morning devotion time"
            )),
            siblingCount: 2
        )
    }
}
