import SwiftUI

struct BowtieTalliesCard: View {
    let pastInsignificance: Int
    let pastIncompetence: Int
    let pastImpotence: Int
    let futureInsignificance: Int
    let futureIncompetence: Int
    let futureImpotence: Int

    var body: some View {
        RRCard {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text(String(localized: "Past"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(maxWidth: .infinity)

                    Text(String(localized: "Now"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.rrPrimary)
                        .frame(width: 40)

                    Text(String(localized: "Future"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(maxWidth: .infinity)
                }

                Divider()

                // Rows
                tallyRow(
                    label: ThreeIType.insignificance.displayName,
                    color: ThreeIType.insignificance.color,
                    pastValue: pastInsignificance,
                    futureValue: futureInsignificance
                )
                tallyRow(
                    label: ThreeIType.incompetence.displayName,
                    color: ThreeIType.incompetence.color,
                    pastValue: pastIncompetence,
                    futureValue: futureIncompetence
                )
                tallyRow(
                    label: ThreeIType.impotence.displayName,
                    color: ThreeIType.impotence.color,
                    pastValue: pastImpotence,
                    futureValue: futureImpotence
                )
            }
        }
    }

    private func tallyRow(label: String, color: Color, pastValue: Int, futureValue: Int) -> some View {
        HStack {
            Text(pastValue > 0 ? "\(pastValue)" : "-")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(pastValue > 0 ? color : Color.rrTextSecondary)
                .frame(maxWidth: .infinity)

            Text(label)
                .font(.caption2)
                .foregroundStyle(color)
                .frame(width: 80)
                .multilineTextAlignment(.center)

            Text(futureValue > 0 ? "\(futureValue)" : "-")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(futureValue > 0 ? color : Color.rrTextSecondary)
                .frame(maxWidth: .infinity)
        }
    }
}
