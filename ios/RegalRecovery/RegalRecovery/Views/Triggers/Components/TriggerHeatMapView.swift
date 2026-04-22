// Views/Triggers/Components/TriggerHeatMapView.swift

import SwiftUI

/// A 7-column (days) x 5-row (time slots) grid showing trigger frequency.
struct TriggerHeatMapView: View {
    let data: [Int: [TimeOfDaySlot: Int]]
    private let maxCount: Int

    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    init(data: [Int: [TimeOfDaySlot: Int]]) {
        self.data = data

        // Compute maxCount from all values in the data
        var max = 0
        for (_, slotMap) in data {
            for (_, count) in slotMap {
                if count > max {
                    max = count
                }
            }
        }
        self.maxCount = max
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Column headers: empty spacer + day labels
            HStack(spacing: 1) {
                Spacer()
                    .frame(width: 60)

                ForEach(0..<7, id: \.self) { dayIndex in
                    Text(dayLabels[dayIndex])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 5 rows, one per TimeOfDaySlot
            ForEach(TimeOfDaySlot.allCases) { slot in
                HStack(spacing: 1) {
                    // Row label
                    Text(slot.shortName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .leading)

                    // 7 cells per row (1=Sunday through 7=Saturday)
                    ForEach(1...7, id: \.self) { dayOfWeek in
                        let count = data[dayOfWeek]?[slot] ?? 0
                        let opacity = maxCount > 0 ? max(0.08, Double(count) / Double(maxCount) * 0.9) : 0.08
                        let textColor: Color = opacity > 0.5 ? .white : .primary

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.rrPrimary.opacity(opacity))
                            .frame(height: 28)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(textColor)
                                }
                            }
                            .accessibilityLabel("\(dayLabels[dayOfWeek - 1]) \(slot.shortName): \(count) triggers")
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        // Preview with sample data
        TriggerHeatMapView(data: [
            1: [.earlyMorning: 2, .morning: 5, .afternoon: 3],
            3: [.morning: 4, .evening: 6],
            5: [.afternoon: 8, .lateNight: 2],
            7: [.earlyMorning: 1, .evening: 4]
        ])
        .padding()

        Divider()

        // Empty data
        TriggerHeatMapView(data: [:])
            .padding()
    }
}
