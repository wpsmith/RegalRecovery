import SwiftUI
import SwiftData

struct SpouseCheckInPrepView: View {
    @Query(sort: \RRSpouseCheckIn.date, order: .reverse) private var recentCheckIns: [RRSpouseCheckIn]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Choose your check-in format")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.top, 16)

                NavigationLink {
                    FANOSCheckInView()
                } label: {
                    formatCard(
                        title: "FANOS",
                        subtitle: "Feelings, Appreciation, Needs, Ownership, Sobriety",
                        icon: "heart.fill",
                        color: .pink
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FITNAPCheckInView()
                } label: {
                    formatCard(
                        title: "FITNAP",
                        subtitle: "Feelings, Integrity, Triggers, Needs, Amends, Positives",
                        icon: "heart.text.clipboard",
                        color: .pink
                    )
                }
                .buttonStyle(.plain)

                if !recentCheckIns.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        ForEach(recentCheckIns.prefix(5)) { checkIn in
                            HStack {
                                Text(checkIn.framework)
                                    .font(RRFont.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.pink)
                                    .clipShape(Capsule())
                                Text(checkIn.date, style: .relative)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal)
        }
        .background(Color.rrBackground)
        .navigationTitle("Spouse Check-in")
    }

    private func formatCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        RRCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Text(subtitle)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SpouseCheckInPrepView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
