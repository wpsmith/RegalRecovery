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
    @State private var locationService = LocationService()

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
                                SensaEmoji.forPrimaryEmotion(emotion).image(size: 56)
                                    .opacity(expandedEmotion == emotion ? 1.0 : 0.6)
                                    .background(
                                        Circle()
                                            .fill(emotion.color.opacity(expandedEmotion == emotion ? 0.2 : 0.1))
                                            .frame(width: 64, height: 64)
                                    )
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

                            FlowLayout(spacing: 8) {
                                ForEach(expanded.secondaryEmotions, id: \.self) { secondary in
                                    Button {
                                        selectedSecondary = secondary
                                    } label: {
                                        HStack(spacing: 4) {
                                            SensaEmoji.forSecondaryEmotion(secondary).image(size: 20)
                                            Text(secondary)
                                                .font(RRFont.caption)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                                .fixedSize(horizontal: true, vertical: false)
                                        }
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
                        if locationService.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else if let place = locationService.placeName {
                            Text(place)
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrTextSecondary)
                        } else if locationService.isAuthorized {
                            Button("Detect location") {
                                locationService.requestLocation()
                            }
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrPrimary)
                        } else {
                            Text("Location unavailable")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                    .onAppear { locationService.requestLocation() }

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
                        SensaEmoji.forSecondaryEmotion(entry.emotion).image(size: 28)

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
            Spacer()
                .frame(height: 40)
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.rrTextSecondary.opacity(0.4))
            Text("Insights Coming Soon")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrTextSecondary)
            Text("Log a few entries and we'll surface patterns in your emotional data.")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
                .frame(height: 40)
        }
        .frame(maxWidth: .infinity)
    }

    private func submitEmotion() {
        let userId = users.first?.id ?? UUID()
        let emotionName = selectedSecondary ?? expandedEmotion?.rawValue ?? "Unknown"
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
            location: locationService.placeName ?? ""
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
