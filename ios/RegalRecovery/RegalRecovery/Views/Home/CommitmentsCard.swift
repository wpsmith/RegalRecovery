import SwiftUI

struct CommitmentsCard: View {
    let status: CommitmentStatus

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Activities")
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)

                commitmentRow(
                    title: String(localized: "Morning Commitment"),
                    isComplete: status.morningComplete,
                    detail: status.morningTime.map { String(localized: "Completed \($0)") } ?? String(localized: "Pending")
                )

                Divider()

                commitmentRow(
                    title: String(localized: "Evening Review"),
                    isComplete: status.eveningComplete,
                    detail: status.eveningTime.map { String(localized: "Completed \($0)") } ?? String(localized: "Pending")
                )
            }
        }
    }

    private func commitmentRow(title: String, isComplete: Bool, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isComplete ? Color.rrSuccess : Color.rrTextSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)

                Text(detail)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            Spacer()
        }
    }
}

#Preview {
    CommitmentsCard(status: CommitmentStatus(
        morningComplete: true,
        morningTime: "6:14 AM",
        eveningComplete: false,
        eveningTime: nil
    ))
    .padding()
    .background(Color.rrBackground)
}
