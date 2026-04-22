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
                    iType: .insignificance,
                    pastValue: pastInsignificance,
                    futureValue: futureInsignificance
                )
                tallyRow(
                    iType: .incompetence,
                    pastValue: pastIncompetence,
                    futureValue: futureIncompetence
                )
                tallyRow(
                    iType: .impotence,
                    pastValue: pastImpotence,
                    futureValue: futureImpotence
                )
            }
        }
    }

    private func tallyRow(iType: ThreeIType, pastValue: Int, futureValue: Int) -> some View {
        HStack {
            Text(pastValue > 0 ? "\(pastValue)" : "-")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(pastValue > 0 ? iType.color : Color.rrTextSecondary)
                .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                Image(systemName: iType.icon)
                    .font(.caption2)
                Text(iType.displayName)
                    .font(.caption2)
            }
            .foregroundStyle(iType.color)
            .frame(width: 100)
            .multilineTextAlignment(.center)

            Text(futureValue > 0 ? "\(futureValue)" : "-")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(futureValue > 0 ? iType.color : Color.rrTextSecondary)
                .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(iType.displayName): past \(pastValue), future \(futureValue)"))
    }
}
