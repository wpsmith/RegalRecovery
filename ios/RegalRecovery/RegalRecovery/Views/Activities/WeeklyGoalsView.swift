import SwiftUI
import SwiftData

struct WeeklyGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRGoal.title) private var goals: [RRGoal]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var newGoalTitle = ""
    @State private var newGoalDynamic = "Spiritual"

    private let dynamics = ["Spiritual", "Physical", "Emotional", "Intellectual", "Relational"]

    private var completedCount: Int {
        goals.filter { $0.isComplete }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress header
                RRCard {
                    VStack(spacing: 12) {
                        Text("\(completedCount) of \(goals.count) complete this week")
                            .font(RRFont.title3)
                            .foregroundStyle(Color.rrText)

                        ProgressView(value: Double(completedCount), total: max(Double(goals.count), 1))
                            .tint(Color.rrPrimary)
                            .scaleEffect(y: 2)
                    }
                }
                .padding(.horizontal)

                // Goals
                VStack(spacing: 12) {
                    ForEach(goals) { goal in
                        RRCard {
                            HStack(spacing: 14) {
                                Button {
                                    goal.isComplete.toggle()
                                } label: {
                                    Image(systemName: goal.isComplete ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(goal.isComplete ? Color.rrSuccess : Color.rrTextSecondary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.title)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                        .strikethrough(goal.isComplete, color: Color.rrTextSecondary)

                                    RRBadge(text: goal.dynamic, color: dynamicColor(goal.dynamic))
                                }

                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
    }

    private func dynamicColor(_ dynamic: String) -> Color {
        switch dynamic {
        case "Spiritual": return .rrPrimary
        case "Physical": return .blue
        case "Emotional": return .purple
        case "Intellectual": return .orange
        case "Relational": return .pink
        default: return .rrTextSecondary
        }
    }
}

#Preview {
    NavigationStack {
        WeeklyGoalsView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
