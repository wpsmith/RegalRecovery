import SwiftUI
import SwiftData

struct MotivationReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<RRMotivation> { !$0.isArchived },
           sort: \RRMotivation.importanceRating, order: .reverse)
    private var motivations: [RRMotivation]

    @State private var currentIndex: Int = 0
    @State private var sessionStart: Date = Date()
    @State private var viewedIndices: Set<Int> = [0]

    var body: some View {
        Group {
            if motivations.isEmpty {
                emptyState
            } else {
                reviewContent
            }
        }
        .background(Color.rrBackground)
        .navigationTitle("Remember Your Why")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !motivations.isEmpty {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        logActivity()
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: currentIndex) { _, newValue in
            viewedIndices.insert(newValue)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "flame")
                .font(.system(size: 50))
                .foregroundStyle(Color.rrTextSecondary)
            Text("No motivations yet. Add your reasons for recovery in the Motivations tool.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var reviewContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Sit with this for a moment.")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            TabView(selection: $currentIndex) {
                ForEach(Array(motivations.enumerated()), id: \.element.id) { index, motivation in
                    motivationCard(motivation)
                        .tag(index)
                        .padding(.horizontal)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(minHeight: 280)

            Text("\(currentIndex + 1) of \(motivations.count)")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            Spacer()
        }
    }

    private func motivationCard(_ motivation: RRMotivation) -> some View {
        RRCard {
            VStack(spacing: 16) {
                Image(systemName: motivation.motivationCategory.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(motivation.motivationCategory.color)

                Text(motivation.text)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
                    .multilineTextAlignment(.center)

                if let scripture = motivation.scriptureReference, !scripture.isEmpty {
                    Text("— \(scripture)")
                        .font(RRFont.body)
                        .italic()
                        .foregroundStyle(Color.rrTextSecondary)
                }

                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { value in
                        Image(systemName: value <= motivation.importanceRating ? "flame.fill" : "flame")
                            .font(.caption)
                            .foregroundStyle(value <= motivation.importanceRating ? Color.orange : Color.rrTextSecondary)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    private func logActivity() {
        let durationSeconds = Int(Date().timeIntervalSince(sessionStart))
        let reviewed = viewedIndices.count
        let total = motivations.count

        let activity = RRActivity(
            userId: UUID(),
            activityType: ActivityType.motivations.rawValue,
            date: sessionStart,
            data: JSONPayload([
                "motivationsReviewed": .int(reviewed),
                "motivationsTotal": .int(total),
                "durationSeconds": .int(durationSeconds),
            ])
        )
        modelContext.insert(activity)

        for index in viewedIndices where index < motivations.count {
            let motivation = motivations[index]
            motivation.lastSurfacedAt = Date()
            motivation.surfaceCount += 1
        }

        do {
            try modelContext.save()
        } catch {
            print("[Motivations] Activity log failed: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        MotivationReviewView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
