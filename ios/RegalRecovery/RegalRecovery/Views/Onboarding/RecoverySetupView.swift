import SwiftUI
import SwiftData

struct RecoverySetupView: View {
    @Binding var name: String
    @Binding var email: String
    let onNext: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var selectedAddictions: Set<String> = ["Sex Addiction (SA)", "Pornography"]
    @State private var sobrietyDate = Date()
    @State private var selectedMotivations: Set<String> = ["Faith", "Family", "Freedom"]

    private let addictionTypes = ["Sex Addiction (SA)", "Pornography", "Substance Use", "Alcohol", "Drugs", "Gambling", "Other"]

    private static let motivations = [
        "Faith", "Family", "Freedom", "Health", "Honesty",
        "Hope", "Integrity", "Intimacy", "Joy", "Love",
        "Marriage", "Peace", "Purpose", "Self-Respect", "Sobriety",
        "Spirituality", "Trust", "Wholeness"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Recovery")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 48)

                // Addiction types (multi-select)
                VStack(alignment: .leading, spacing: 12) {
                    Text("What are you recovering from?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                        ForEach(addictionTypes, id: \.self) { type in
                            Button {
                                if selectedAddictions.contains(type) {
                                    selectedAddictions.remove(type)
                                } else {
                                    selectedAddictions.insert(type)
                                }
                            } label: {
                                Text(type)
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedAddictions.contains(type) ? .white : Color.rrText)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedAddictions.contains(type) ? Color.rrPrimary : Color.clear)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedAddictions.contains(type) ? Color.clear : Color.rrTextSecondary.opacity(0.4),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                }

                // Sobriety date
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sobriety Date")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    DatePicker("Sobriety Date", selection: $sobrietyDate, displayedComponents: .date)
                        .labelsHidden()
                        .padding(8)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                // Motivations
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

        for addiction in selectedAddictions {
            let a = RRAddiction(name: addiction, sobrietyDate: sobrietyDate, userId: user.id)
            modelContext.insert(a)

            let streak = RRStreak(addictionId: a.id)
            modelContext.insert(streak)
        }
    }
}

#Preview {
    RecoverySetupView(name: .constant("Alex"), email: .constant("alex@example.com"), onNext: {})
}
