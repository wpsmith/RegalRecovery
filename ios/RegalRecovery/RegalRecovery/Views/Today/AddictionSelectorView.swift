import SwiftUI
import SwiftData

/// Inline addiction selector shown on the Today screen when the user
/// has no addictions configured yet.  Multi-select grid with a shared
/// sobriety date and a "Save & Continue" button.
struct AddictionSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    var onSave: () -> Void

    @State private var selectedAddictions: Set<String> = []
    @State private var sobrietyDate = Date()

    // MARK: - Addiction Type List

    private let allAddictions = [
        "Affair / Infidelity",
        "Alcohol",
        "Cannabis / Marijuana",
        "Cocaine",
        "Compulsive Sexual Behavior",
        "Cybersex",
        "Gambling",
        "Gaming",
        "Heroin / Opioids",
        "Internet / Social Media",
        "Love / Relationship",
        "Masturbation",
        "Methamphetamine",
        "Nicotine / Tobacco",
        "Phone Sex / Sexting",
        "Pornography",
        "Prescription Drugs",
        "Sex",
        "Sexual Fantasy",
        "Shopping / Spending",
        "Other",
    ]

    private var canSave: Bool {
        !selectedAddictions.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.rrPrimary)

                    Text("What are you recovering from?")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("Select one or more. You can change this later in Settings.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                    ForEach(allAddictions, id: \.self) { type in
                        addictionChip(type)
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

                // Save button
                RRButton("Save & Continue", icon: "checkmark") {
                    saveAddictions()
                }
                .disabled(!canSave)
                .opacity(canSave ? 1.0 : 0.5)
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.rrBackground.ignoresSafeArea())
    }

    // MARK: - Chip

    private func addictionChip(_ type: String) -> some View {
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

    // MARK: - Save

    private func saveAddictions() {
        let userId = users.first?.id ?? UUID()
        let existingCount = (try? modelContext.fetchCount(FetchDescriptor<RRAddiction>())) ?? 0

        for (index, name) in selectedAddictions.sorted().enumerated() {
            let addiction = RRAddiction(
                name: name,
                sobrietyDate: sobrietyDate,
                userId: userId,
                sortOrder: existingCount + index
            )
            modelContext.insert(addiction)

            let streak = RRStreak(addictionId: addiction.id)
            modelContext.insert(streak)
        }

        try? modelContext.save()
        onSave()
    }
}

#Preview {
    AddictionSelectorView(onSave: {})
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
