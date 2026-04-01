import SwiftUI
import SwiftData

struct ExerciseLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRExerciseLog.date, order: .reverse) private var entries: [RRExerciseLog]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var duration: Double = 30
    @State private var activityType = "Run"
    @State private var notes = ""

    private let activityTypes = ["Run", "Walk", "Weights", "Yoga", "Swimming", "Other"]

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Today, \(date.formatted(date: .omitted, time: .shortened))"
        }
        if cal.isDateInYesterday(date) {
            return "Yesterday, \(date.formatted(date: .omitted, time: .shortened))"
        }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days) days ago"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        RRSectionHeader(title: "Log Exercise")

                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration")
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrText)
                                Spacer()
                                Text("\(Int(duration)) min")
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.blue)
                            }
                            Slider(value: $duration, in: 5...90, step: 5)
                                .tint(.blue)
                        }

                        Divider()

                        // Activity type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrText)
                            Picker("Activity", selection: $activityType) {
                                ForEach(activityTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Divider()

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrText)
                            TextField("How did it go?", text: $notes, axis: .vertical)
                                .font(RRFont.body)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }

                        RRButton("Log Exercise", icon: "figure.run") {
                            submitExercise()
                        }
                    }
                }
                .padding(.horizontal)

                // History
                if !entries.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 16) {
                            RRSectionHeader(title: "History")

                            ForEach(entries) { entry in
                                HStack {
                                    Image(systemName: "figure.run")
                                        .foregroundStyle(.blue)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(entry.exerciseType.capitalized)
                                                .font(RRFont.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(Color.rrText)
                                            RRBadge(text: "\(entry.durationMinutes) min", color: .blue)
                                        }
                                        Text(relativeDay(entry.date))
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrTextSecondary)
                                        if !entry.notes.isEmpty {
                                            Text(entry.notes)
                                                .font(RRFont.caption)
                                                .foregroundStyle(Color.rrTextSecondary)
                                        }
                                    }
                                    Spacer()
                                }
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
    }

    private func submitExercise() {
        let userId = users.first?.id ?? UUID()
        let entry = RRExerciseLog(
            userId: userId,
            date: Date(),
            durationMinutes: Int(duration),
            exerciseType: activityType.lowercased(),
            notes: notes
        )
        modelContext.insert(entry)
        notes = ""
    }
}

#Preview {
    NavigationStack {
        ExerciseLogView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
