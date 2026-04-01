import SwiftUI

struct MilestoneBadgesRow: View {
    let milestones: [Milestone]

    @State private var selectedMilestone: Milestone?

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Milestones")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(milestones) { milestone in
                        RRMilestoneCoin(days: milestone.days)
                            .onTapGesture {
                                selectedMilestone = milestone
                            }
                    }
                }
                .padding(.trailing, 80)
            }
        }
        .sheet(item: $selectedMilestone) { milestone in
            VStack(spacing: 20) {
                RRMilestoneCoin(days: milestone.days, size: 80)

                Text("\(milestone.days) Days")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text("Earned \(formattedDate(milestone.dateEarned))")
                    .font(RRFont.subheadline)
                    .foregroundStyle(Color.rrTextSecondary)

                Text(milestone.scripture)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .multilineTextAlignment(.center)
                    .italic()
                    .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 40)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    MilestoneBadgesRow(milestones: [])
        .padding()
        .background(Color.rrBackground)
}
