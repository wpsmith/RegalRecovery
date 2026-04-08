import SwiftUI

struct PersonCheckInCalendarView: View {
    @Bindable var viewModel: PersonCheckInViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    // Previous month
                } label: {
                    Image(systemName: "chevron.left")
                }

                Text(viewModel.selectedMonth)
                    .font(.headline)

                Button {
                    // Next month
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .pink, label: "Spouse")
                LegendItem(color: .blue, label: "Sponsor")
                LegendItem(color: .green, label: "Counselor")
            }
            .font(.caption)

            // Calendar grid placeholder
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Calendar days would be populated from viewModel.calendarDays
                ForEach(1...31, id: \.self) { day in
                    VStack(spacing: 2) {
                        Text("\(day)")
                            .font(.caption)

                        // Color-coded dots per sub-type
                        HStack(spacing: 2) {
                            if hasCheckIn(day: day, type: .spouse) {
                                Circle()
                                    .fill(.pink)
                                    .frame(width: 4, height: 4)
                            }
                            if hasCheckIn(day: day, type: .sponsor) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 4, height: 4)
                            }
                            if hasCheckIn(day: day, type: .counselorCoach) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                    .frame(height: 36)
                }
            }
            .padding(.horizontal)
        }
    }

    private func hasCheckIn(day: Int, type: PersonCheckInType) -> Bool {
        // Check viewModel.calendarDays for matches.
        let dateStr = String(format: "%@-%02d", viewModel.selectedMonth, day)
        return viewModel.calendarDays.contains { calDay in
            calDay.date == dateStr && calDay.checkIns.contains { $0.checkInType == type.rawValue }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

#Preview {
    PersonCheckInCalendarView(viewModel: PersonCheckInViewModel())
}
