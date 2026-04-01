import SwiftUI
import SwiftData

struct EmotionalJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RREmotionalJournal.date, order: .reverse) private var entries: [RREmotionalJournal]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var selectedTab = 0
    @State private var expandedEmotion: PrimaryEmotion?
    @State private var selectedSecondary: String?
    @State private var intensity: Double = 5
    @State private var activity = ""

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "purple": return .purple
        case "yellow": return .yellow
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        default: return .gray
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Tab", selection: $selectedTab) {
                    Text("New Entry").tag(0)
                    Text("History").tag(1)
                    Text("Insights").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch selectedTab {
                case 0:
                    newEntryTab
                case 1:
                    historyTab
                default:
                    insightsTab
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
    }

    // MARK: - New Entry

    private var newEntryTab: some View {
        VStack(spacing: 20) {
            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    RRSectionHeader(title: "How are you feeling?")

                    // Feelings wheel grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                        ForEach(PrimaryEmotion.allCases, id: \.rawValue) { emotion in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(emotion.color.opacity(expandedEmotion == emotion ? 1.0 : 0.6))
                                    .frame(width: 56, height: 56)
                                    .overlay {
                                        Text(emotion.rawValue.prefix(3).uppercased())
                                            .font(RRFont.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                    .onTapGesture {
                                        withAnimation {
                                            expandedEmotion = expandedEmotion == emotion ? nil : emotion
                                            selectedSecondary = nil
                                        }
                                    }

                                Text(emotion.rawValue)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrText)
                            }
                        }
                    }

                    // Secondary emotions
                    if let expanded = expandedEmotion {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Specific Feeling")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrTextSecondary)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                                ForEach(expanded.secondaryEmotions, id: \.self) { secondary in
                                    Button {
                                        selectedSecondary = secondary
                                    } label: {
                                        Text(secondary)
                                            .font(RRFont.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(selectedSecondary == secondary ? .white : expanded.color)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedSecondary == secondary ? expanded.color : expanded.color.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Intensity")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrText)
                        Spacer()
                        Text("\(Int(intensity))/10")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrPrimary)
                    }
                    Slider(value: $intensity, in: 1...10, step: 1)
                        .tint(Color.rrPrimary)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Activity")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                        TextField("What were you doing?", text: $activity)
                            .font(RRFont.body)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(Color.rrTextSecondary)
                        Text("Home, Austin TX")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    RRButton("Log Emotion", icon: "heart.circle.fill") {
                        submitEmotion()
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - History

    private var historyTab: some View {
        VStack(spacing: 12) {
            ForEach(entries) { entry in
                RRCard {
                    HStack(spacing: 12) {
                        RRColorDot(colorFromString(entry.emotionColor), size: 14)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.emotion)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Text(entry.activity)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(entry.intensity)/10")
                                .font(RRFont.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.rrPrimary)
                            Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Insights

    private var insightsTab: some View {
        VStack(spacing: 16) {
            RRCard {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundStyle(Color.rrPrimary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pattern Detected")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text("You feel Anxious most on Mondays")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal)

            RRCard {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Timing Insight")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text("High intensity peaks between 8-10 PM")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
    }

    private func submitEmotion() {
        let userId = users.first?.id ?? UUID()
        let emotionName = selectedSecondary ?? expandedEmotion?.rawValue ?? "Unknown"
        let emotionColor = expandedEmotion?.color ?? .gray
        let colorString: String = {
            switch expandedEmotion {
            case .happy: return "yellow"
            case .sad: return "blue"
            case .angry: return "red"
            case .fearful: return "purple"
            case .disgusted: return "green"
            case .surprised: return "orange"
            case .none: return "gray"
            }
        }()
        let entry = RREmotionalJournal(
            userId: userId,
            date: Date(),
            emotion: emotionName,
            emotionColor: colorString,
            intensity: Int(intensity),
            activity: activity,
            location: "Home, Austin TX"
        )
        modelContext.insert(entry)
        activity = ""
        expandedEmotion = nil
        selectedSecondary = nil
        intensity = 5
    }
}

#Preview {
    NavigationStack {
        EmotionalJournalView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
