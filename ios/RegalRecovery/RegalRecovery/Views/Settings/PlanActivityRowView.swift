import SwiftUI

struct PlanActivityRowView: View {
    @Binding var item: PlanItemState
    var siblingCount: Int = 1

    @State private var isEditingName = false
    @FocusState private var nameFieldFocused: Bool

    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Row 1: Custom name (only if set or editing)
            if isEditingName {
                HStack(spacing: 6) {
                    TextField("Custom name", text: $item.customTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.rrPrimary)
                        .textFieldStyle(.plain)
                        .focused($nameFieldFocused)
                        .onSubmit { finishEditing() }

                    Button {
                        finishEditing()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.rrPrimary)
                    }
                    .buttonStyle(.borderless)
                }
            } else if !item.customTitle.isEmpty {
                Text(item.customTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.rrPrimary)
                    .lineLimit(1)
                    .onTapGesture { startEditing() }
            }

            // Row 2: Icon + activity name + rename button
            HStack(spacing: 8) {
                Group {
                    if item.activity.icon.hasPrefix("asset:") {
                        Image(String(item.activity.icon.dropFirst(6)))
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: item.activity.icon)
                            .font(.caption)
                    }
                }
                    .foregroundStyle(iconColor)
                    .frame(width: 22, height: 22)

                let typeLabel = siblingCount > 1
                    ? "\(item.activity.displayName) #\(item.instanceIndex + 1)"
                    : item.activity.displayName
                Text(typeLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.rrText)
                    .lineLimit(1)

                Spacer()

                if !isEditingName {
                    Button {
                        startEditing()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    .buttonStyle(.borderless)
                }
            }

            // Row 3: Time picker + day-of-week chips
            HStack(spacing: 8) {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { item.scheduledTime },
                        set: { item.scheduledTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .frame(width: 82)

                let isEveryDay = item.daysOfWeek.isEmpty
                HStack(spacing: 3) {
                    ForEach(1...7, id: \.self) { day in
                        let selected = isEveryDay || item.daysOfWeek.contains(day)
                        Button {
                            toggleDay(day, isEveryDay: isEveryDay)
                        } label: {
                            Text(dayLabels[day - 1])
                                .font(.system(size: 10, weight: .semibold))
                                .frame(width: 26, height: 26)
                                .foregroundStyle(selected ? .white : Color.rrTextSecondary)
                                .background(selected ? Color.rrPrimary : Color.rrSurface)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.borderless)
                    }

                    if !isEveryDay {
                        Button {
                            item.daysOfWeek.removeAll()
                        } label: {
                            Text("All")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.rrPrimary)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Editing

    private func startEditing() {
        isEditingName = true
        nameFieldFocused = true
    }

    private func finishEditing() {
        isEditingName = false
        nameFieldFocused = false
    }

    // MARK: - Day Toggle

    private func toggleDay(_ day: Int, isEveryDay: Bool) {
        if isEveryDay {
            item.daysOfWeek = Set(1...7)
            item.daysOfWeek.remove(day)
        } else if item.daysOfWeek.contains(day) {
            item.daysOfWeek.remove(day)
        } else {
            item.daysOfWeek.insert(day)
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
                daysOfWeek: [1, 3, 5],
                customTitle: "Morning devotion time"
            )),
            siblingCount: 2
        )
    }
}
