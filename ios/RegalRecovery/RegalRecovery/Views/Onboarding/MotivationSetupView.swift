import SwiftUI
import SwiftData

struct MotivationSetupView: View {
    let name: String
    let email: String
    let selectedAddictions: [(name: String, date: Date)]
    let onNext: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var selectedMotivations: Set<String> = ["Faith", "Family", "Freedom"]

    private static let motivations = [
        "Faith", "Family", "Freedom", "Health", "Honesty",
        "Hope", "Integrity", "Intimacy", "Joy", "Love",
        "Marriage", "Peace", "Purpose", "Self-Respect", "Sobriety",
        "Spirituality", "Trust", "Wholeness"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Motivations")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)

                VStack(alignment: .leading, spacing: 12) {
                    Text("What motivates your recovery?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                        ForEach(Self.motivations, id: \.self) { motivation in
                            Button {
                                if selectedMotivations.contains(motivation) {
                                    selectedMotivations.remove(motivation)
                                } else {
                                    selectedMotivations.insert(motivation)
                                }
                            } label: {
                                Text(motivation)
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedMotivations.contains(motivation) ? .white : Color.rrText)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedMotivations.contains(motivation) ? Color.rrPrimary : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedMotivations.contains(motivation) ? Color.clear : Color.rrTextSecondary.opacity(0.4),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                }

                Spacer(minLength: 24)

                RRButton("Continue", icon: "arrow.right") {
                    completeSetup()
                    onNext()
                }
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.rrBackground.ignoresSafeArea())
    }

    private func completeSetup() {
        let user = RRUser(
            name: name,
            email: email,
            birthYear: 0,
            gender: "",
            timezone: TimeZone.current.identifier,
            bibleVersion: "ESV",
            motivations: Array(selectedMotivations),
            avatarInitial: String(name.prefix(1).uppercased())
        )
        modelContext.insert(user)

        for (index, entry) in selectedAddictions.enumerated() {
            let addiction = RRAddiction(
                name: entry.name,
                sobrietyDate: entry.date,
                userId: user.id,
                sortOrder: index
            )
            modelContext.insert(addiction)

            let streak = RRStreak(addictionId: addiction.id)
            modelContext.insert(streak)
        }
    }
}

#Preview {
    MotivationSetupView(
        name: "Alex",
        email: "alex@example.com",
        selectedAddictions: [
            (name: "Sex Addiction (SA)", date: Date()),
            (name: "Pornography", date: Date())
        ],
        onNext: {}
    )
}
