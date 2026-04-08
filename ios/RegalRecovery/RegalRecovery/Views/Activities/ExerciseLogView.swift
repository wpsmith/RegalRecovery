import SwiftUI
import SwiftData

struct ExerciseLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRExerciseLog.date, order: .reverse) private var entries: [RRExerciseLog]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var duration: Double = 30
    @State private var selectedType: ExerciseActivityType = .running
    @State private var customTypeLabel = ""
    @State private var selectedIntensity: ExerciseIntensity? = nil
    @State private var notes = ""
    @State private var moodBefore: Int? = nil
    @State private var moodAfter: Int? = nil
    @State private var entryDate = Date()
    @State private var showMoodSection = false
    @State private var showDatePicker = false

    private let quickDurations = [15, 30, 45, 60, 90]

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
                // Log Form
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

                            // Quick-select buttons
                            HStack(spacing: 8) {
                                ForEach(quickDurations, id: \.self) { min in
                                    Button {
                                        duration = Double(min)
                                    } label: {
                                        Text("\(min)")
                                            .font(RRFont.caption)
                                            .fontWeight(Int(duration) == min ? .bold : .regular)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Int(duration) == min ? Color.blue.opacity(0.15) : Color.clear)
                                            )
                                            .foregroundStyle(Int(duration) == min ? Color.blue : Color.rrTextSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Slider(value: $duration, in: 1...120, step: 5)
                                .tint(.blue)
                        }

                        Divider()

                        // Activity type (showing icons)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrText)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                                ForEach(ExerciseActivityType.allCases) { type in
                                    Button {
                                        selectedType = type
                                    } label: {
                                        VStack(spacing: 2) {
                                            Image(systemName: type.iconName)
                                                .font(.title3)
                                                .foregroundStyle(selectedType == type ? Color.blue : Color.rrTextSecondary)
                                            Text(type.displayName)
                                                .font(.system(size: 8))
                                                .foregroundStyle(selectedType == type ? Color.blue : Color.rrTextSecondary)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedType == type ? Color.blue.opacity(0.1) : Color.clear)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if selectedType == .other {
                                TextField("Activity name (e.g. Pickleball)", text: $customTypeLabel)
                                    .font(RRFont.body)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        Divider()

                        // Intensity (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Intensity (optional)")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrText)

                            HStack(spacing: 8) {
                                ForEach(ExerciseIntensity.allCases) { level in
                                    Button {
                                        if selectedIntensity == level {
                                            selectedIntensity = nil
                                        } else {
                                            selectedIntensity = level
                                        }
                                    } label: {
                                        VStack(spacing: 2) {
                                            Text(level.displayName)
                                                .font(RRFont.subheadline)
                                                .fontWeight(selectedIntensity == level ? .semibold : .regular)
                                            Text(level.helperText)
                                                .font(.system(size: 9))
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedIntensity == level ? Color.blue.opacity(0.1) : Color.clear)
                                        )
                                        .foregroundStyle(selectedIntensity == level ? Color.blue : Color.rrTextSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Divider()

                        // Mood before/after (optional, collapsible)
                        DisclosureGroup("Mood before/after", isExpanded: $showMoodSection) {
                            VStack(spacing: 12) {
                                moodPicker(label: "Before", value: $moodBefore)
                                moodPicker(label: "After", value: $moodAfter)
                            }
                            .padding(.top, 4)
                        }
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrText)

                        Divider()

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrText)
                            TextField(
                                ExerciseViewModel.notesPlaceholders.randomElement() ?? "How did it go?",
                                text: $notes,
                                axis: .vertical
                            )
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
                                    Image(systemName: iconName(for: entry.exerciseType))
                                        .foregroundStyle(.blue)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(entry.exerciseType.capitalized)
                                                .font(RRFont.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(Color.rrText)
                                            RRBadge(text: "\(entry.durationMinutes) min", color: .blue)
                                            if let intensity = entry.intensity {
                                                RRBadge(text: intensity.capitalized, color: .orange)
                                            }
                                        }
                                        HStack(spacing: 4) {
                                            Text(relativeDay(entry.date))
                                                .font(RRFont.caption)
                                                .foregroundStyle(Color.rrTextSecondary)
                                            if let mb = entry.moodBefore, let ma = entry.moodAfter {
                                                Text("Mood: \(mb) -> \(ma)")
                                                    .font(RRFont.caption)
                                                    .foregroundStyle(Color.rrTextSecondary)
                                            }
                                        }
                                        if !entry.notes.isEmpty {
                                            Text(entry.notes)
                                                .font(RRFont.caption)
                                                .foregroundStyle(Color.rrTextSecondary)
                                                .lineLimit(2)
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

    @ViewBuilder
    private func moodPicker(label: String, value: Binding<Int?>) -> some View {
        HStack {
            Text(label)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .frame(width: 50, alignment: .leading)
            ForEach(1...5, id: \.self) { score in
                Button {
                    if value.wrappedValue == score {
                        value.wrappedValue = nil
                    } else {
                        value.wrappedValue = score
                    }
                } label: {
                    Text("\(score)")
                        .font(RRFont.subheadline)
                        .fontWeight(value.wrappedValue == score ? .bold : .regular)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(value.wrappedValue == score ? Color.blue.opacity(0.15) : Color.clear)
                        )
                        .foregroundStyle(value.wrappedValue == score ? Color.blue : Color.rrTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func iconName(for type: String) -> String {
        if let actType = ExerciseActivityType(rawValue: type) {
            return actType.iconName
        }
        // Fallback for legacy type names
        switch type.lowercased() {
        case "run": return "figure.run"
        case "walk": return "figure.walk"
        case "weights": return "dumbbell.fill"
        case "yoga": return "figure.yoga"
        case "swimming": return "figure.pool.swim"
        default: return "figure.mixed.cardio"
        }
    }

    private func submitExercise() {
        let userId = users.first?.id ?? UUID()
        let entry = RRExerciseLog(
            userId: userId,
            date: entryDate,
            durationMinutes: Int(duration),
            exerciseType: selectedType.rawValue,
            customTypeLabel: selectedType == .other ? customTypeLabel : nil,
            intensity: selectedIntensity?.rawValue,
            notes: notes,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            source: "manual"
        )
        modelContext.insert(entry)

        // Reset form
        notes = ""
        moodBefore = nil
        moodAfter = nil
        selectedIntensity = nil
        duration = 30
        selectedType = .running
        customTypeLabel = ""
        entryDate = Date()
    }
}

#Preview {
    NavigationStack {
        ExerciseLogView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
