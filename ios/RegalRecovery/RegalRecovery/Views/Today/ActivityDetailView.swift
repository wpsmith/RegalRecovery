import SwiftUI
import SwiftData

struct ActivityDetailView: View {
    let activity: RecentActivity
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if let sourceType = activity.sourceType, let sourceId = activity.sourceId {
                    detailContent(for: sourceType, id: sourceId)
                }
            }
            .padding(16)
        }
        .background(Color.rrBackground)
        .navigationTitle(activity.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        RRCard {
            HStack(spacing: 16) {
                Image(systemName: activity.icon)
                    .font(.title2)
                    .foregroundStyle(activity.iconColor)
                    .frame(width: 48, height: 48)
                    .background(activity.iconColor.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)

                    Text(activity.time)
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Detail Content Router

    @ViewBuilder
    private func detailContent(for type: HistoryItemType, id: UUID) -> some View {
        switch type {
        case .morningCommitment, .eveningReview:
            commitmentDetail(id: id)
        case .journal:
            journalDetail(id: id)
        case .fasterScale:
            fasterDetail(id: id)
        case .urgeLog:
            urgeLogDetail(id: id)
        case .mood:
            moodDetail(id: id)
        case .gratitude:
            gratitudeDetail(id: id)
        case .prayer:
            prayerDetail(id: id)
        case .exercise:
            exerciseDetail(id: id)
        case .phoneCall:
            phoneCallDetail(id: id)
        case .meeting:
            meetingDetail(id: id)
        case .fanos, .fitnap:
            spouseCheckInDetail(id: id)
        case .triggerLog:
            triggerLogDetail(id: id)
        }
    }

    // MARK: - Commitment

    private func commitmentDetail(id: UUID) -> some View {
        let item = fetchModel(RRCommitment.self, id: id)
        return Group {
            if let c = item {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow("Type", value: c.type == "morning" ? "Morning Commitment" : "Evening Review")
                        detailRow("Date", value: c.date.formatted(date: .long, time: .shortened))
                        if let completedAt = c.completedAt {
                            detailRow("Completed", value: completedAt.formatted(date: .omitted, time: .shortened))
                        }
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    // MARK: - Journal

    private func journalDetail(id: UUID) -> some View {
        let item = fetchModel(RRJournalEntry.self, id: id)
        return Group {
            if let j = item {
                VStack(spacing: 16) {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow("Mode", value: j.mode.capitalized)
                            detailRow("Date", value: j.date.formatted(date: .long, time: .shortened))
                            if let prompt = j.prompt, !prompt.isEmpty {
                                detailRow("Prompt", value: prompt)
                            }
                        }
                    }
                    RRCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Entry")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Text(j.content)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    // MARK: - FASTER Scale

    /// Mood icons matching FASTERMoodPromptView (score 1-5).
    private static let moodIcons: [(score: Int, icon: String, label: String, color: Color)] = [
        (1, "face.smiling.inverse", "Great", Color(red: 0.176, green: 0.416, blue: 0.310)),
        (2, "face.smiling", "Good", Color(red: 0.482, green: 0.620, blue: 0.239)),
        (3, "minus.circle", "Okay", Color(red: 0.788, green: 0.635, blue: 0.153)),
        (4, "cloud", "Struggling", Color(red: 0.831, green: 0.502, blue: 0.165)),
        (5, "cloud.rain", "Rough", Color(red: 0.651, green: 0.239, blue: 0.251)),
    ]

    private func fasterDetail(id: UUID) -> some View {
        let item = fetchModel(RRFASTEREntry.self, id: id)
        return Group {
            if let f = item {
                let stage = FASTERStage(rawValue: f.stage) ?? .forgettingPriorities
                let indicators = decodeFASTERIndicators(f.selectedIndicatorsJSON)

                VStack(spacing: 16) {
                    // Mood card
                    if let moodScore = f.moodScore,
                       let mood = Self.moodIcons.first(where: { $0.score == moodScore }) {
                        RRCard {
                            HStack(spacing: 12) {
                                Image(systemName: mood.icon)
                                    .font(.system(size: 32))
                                    .foregroundStyle(mood.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Mood: \(mood.label)")
                                        .font(RRFont.headline)
                                        .foregroundStyle(Color.rrText)
                                    Text(f.date.formatted(date: .long, time: .shortened))
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                                Spacer()
                            }
                        }
                    }

                    // Thermometer
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            RRSectionHeader(title: "Assessment")
                            FASTERThermometerView(
                                assessedStage: stage,
                                selectedIndicators: indicators
                            )
                        }
                    }

                    // Selected indicators per stage
                    if !indicators.isEmpty {
                        RRCard {
                            VStack(alignment: .leading, spacing: 12) {
                                RRSectionHeader(title: "Selected Indicators")
                                ForEach(FASTERStage.allCases.filter { indicators[$0] != nil }) { s in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            Text(s.letter)
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                                .frame(width: 24, height: 24)
                                                .background(s.color)
                                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                            Text(s.name)
                                                .font(RRFont.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(Color.rrText)
                                        }
                                        FlowLayout(spacing: 6) {
                                            ForEach(Array(indicators[s] ?? []).sorted(), id: \.self) { indicator in
                                                Text(indicator)
                                                    .font(RRFont.caption)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .foregroundStyle(.white)
                                                    .background(s.color)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Adaptive content
                    RRCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(stage.color)
                                    .frame(width: 10, height: 10)
                                Text(stage.adaptiveContent.title)
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)
                            }
                            Text(stage.adaptiveContent.body)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Journal entries
                    if f.journalInsight != nil || f.journalWarning != nil || f.journalFreeText != nil {
                        RRCard {
                            VStack(alignment: .leading, spacing: 12) {
                                RRSectionHeader(title: "Reflections")
                                if let insight = f.journalInsight, !insight.isEmpty {
                                    journalReadOnlyField(label: "Ah-ha (insight)", text: insight)
                                }
                                if let warning = f.journalWarning, !warning.isEmpty {
                                    journalReadOnlyField(label: "Uh-oh (warning sign)", text: warning)
                                }
                                if let freeText = f.journalFreeText, !freeText.isEmpty {
                                    journalReadOnlyField(label: "Additional notes", text: freeText)
                                }
                            }
                        }
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    private func journalReadOnlyField(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrTextSecondary)
            Text(text)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Decode the JSON indicators string back into [FASTERStage: Set<String>].
    private func decodeFASTERIndicators(_ json: String?) -> [FASTERStage: Set<String>] {
        guard let json, let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        var result: [FASTERStage: Set<String>] = [:]
        for (stageName, indicators) in dict {
            if let stage = FASTERStage.allCases.first(where: { $0.name == stageName }) {
                result[stage] = Set(indicators)
            }
        }
        return result
    }

    // MARK: - Urge Log

    private func urgeLogDetail(id: UUID) -> some View {
        let item = fetchModel(RRUrgeLog.self, id: id)
        return Group {
            if let u = item {
                VStack(spacing: 16) {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow("Intensity", value: "\(u.intensity)/10")
                            detailRow("Date", value: u.date.formatted(date: .long, time: .shortened))
                            if !u.resolution.isEmpty {
                                detailRow("Resolution", value: u.resolution)
                            }
                        }
                    }
                    if !u.triggers.isEmpty {
                        RRCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Triggers")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                FlowLayout(spacing: 8) {
                                    ForEach(u.triggers, id: \.self) { trigger in
                                        RRBadge(text: trigger, color: .orange)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    if !u.notes.isEmpty {
                        RRCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text(u.notes)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    // MARK: - Mood

    private func moodDetail(id: UUID) -> some View {
        let item = fetchModel(RRMoodEntry.self, id: id)
        return Group {
            if let m = item {
                let mood = MoodPrimary(rawValue: m.primaryMood) ?? .surprise
                RRCard {
                    VStack(spacing: 16) {
                        SensaEmoji.forMoodPrimary(mood).image(size: 64)
                        Text(mood.rawValue)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(mood.color)
                        if let secondary = m.secondaryEmotion {
                            Text(secondary)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        if let intensity = m.intensity {
                            detailRow("Intensity", value: "\(intensity)/10")
                        }
                        if let urge = m.urgeToActOut, urge > 0 {
                            detailRow("Urge to Act Out", value: "\(urge)/10")
                        }
                        if !m.contextTags.isEmpty {
                            detailRow("Context", value: m.contextTags.joined(separator: ", "))
                        }
                        if let response = m.journalResponse, !response.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                if let prompt = m.journalPrompt {
                                    Text(prompt)
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .italic()
                                }
                                Text(response)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        detailRow("Date", value: m.date.formatted(date: .long, time: .shortened))
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    // MARK: - Gratitude

    private func gratitudeDetail(id: UUID) -> some View {
        let item = fetchModel(RRGratitudeEntry.self, id: id)
        return Group {
            if let g = item {
                VStack(spacing: 16) {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow("Items", value: "\(g.items.count)")
                            detailRow("Date", value: g.date.formatted(date: .long, time: .shortened))
                        }
                    }
                    RRCard {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(g.items.enumerated()), id: \.offset) { index, item in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .frame(width: 24, alignment: .trailing)
                                    Text(item.text)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    // MARK: - Prayer

    private func prayerDetail(id: UUID) -> some View {
        let item = fetchModel(RRPrayerLog.self, id: id)
        return Group {
            if let p = item {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow("Duration", value: "\(p.durationMinutes) min")
                        detailRow("Type", value: p.prayerType.capitalized)
                        detailRow("Date", value: p.date.formatted(date: .long, time: .shortened))
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    // MARK: - Exercise

    private func exerciseDetail(id: UUID) -> some View {
        let item = fetchModel(RRExerciseLog.self, id: id)
        return Group {
            if let e = item {
                VStack(spacing: 16) {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow("Type", value: e.exerciseType)
                            detailRow("Duration", value: "\(e.durationMinutes) min")
                            detailRow("Date", value: e.date.formatted(date: .long, time: .shortened))
                        }
                    }
                    if !e.notes.isEmpty {
                        RRCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text(e.notes)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    // MARK: - Phone Call

    private func phoneCallDetail(id: UUID) -> some View {
        let item = fetchModel(RRPhoneCallLog.self, id: id)
        return Group {
            if let pc = item {
                VStack(spacing: 16) {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow("Contact", value: pc.contactName)
                            detailRow("Role", value: pc.contactRole.capitalized)
                            detailRow("Duration", value: "\(pc.durationMinutes) min")
                            detailRow("Date", value: pc.date.formatted(date: .long, time: .shortened))
                        }
                    }
                    if !pc.notes.isEmpty {
                        RRCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text(pc.notes)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    // MARK: - Meeting

    private func meetingDetail(id: UUID) -> some View {
        let item = fetchModel(RRMeetingLog.self, id: id)
        return Group {
            if let ml = item {
                VStack(spacing: 16) {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow("Meeting", value: ml.meetingName)
                            detailRow("Duration", value: "\(ml.durationMinutes) min")
                            detailRow("Date", value: ml.date.formatted(date: .long, time: .shortened))
                        }
                    }
                    if !ml.notes.isEmpty {
                        RRCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text(ml.notes)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    // MARK: - Spouse Check-In

    private func spouseCheckInDetail(id: UUID) -> some View {
        let item = fetchModel(RRSpouseCheckIn.self, id: id)
        return Group {
            if let sc = item {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow("Framework", value: sc.framework)
                        detailRow("Date", value: sc.date.formatted(date: .long, time: .shortened))
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    // MARK: - Helpers

    private func detailRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
            Spacer()
        }
    }

    private var notFoundView: some View {
        RRCard {
            VStack(spacing: 12) {
                Image(systemName: "questionmark.circle")
                    .font(.title)
                    .foregroundStyle(Color.rrTextSecondary)
                Text("Details unavailable")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Trigger Log

    private func triggerLogDetail(id: UUID) -> some View {
        let item = fetchModel(RRTriggerLogEntry.self, id: id)
        return Group {
            if let entry = item {
                VStack(spacing: 16) {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            detailRow("Date", value: entry.timestamp.formatted(date: .long, time: .shortened))
                            detailRow("Log Depth", value: entry.logDepth.displayName)
                            if let intensity = entry.intensity {
                                detailRow("Intensity", value: "\(intensity)/10")
                            }
                            if let riskLevel = entry.riskLevel {
                                detailRow("Risk Level", value: riskLevel.displayName)
                            }
                        }
                    }

                    if !entry.triggerSnapshots.isEmpty {
                        RRCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Triggers")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                FlowLayout(spacing: 8) {
                                    ForEach(entry.triggerSnapshots, id: \.id) { snapshot in
                                        RRBadge(text: snapshot.label, color: TriggerCategory(rawValue: snapshot.category)?.color ?? .gray)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if let mood = entry.mood {
                        RRCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mood")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text(mood)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if let situation = entry.situation {
                        RRCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Situation")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text(situation)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if let reflection = entry.teacherReflection {
                        RRCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Teacher Reflection")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text(reflection)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } else {
                notFoundView
            }
        }
    }

    private func fetchModel<T: PersistentModel>(_ type: T.Type, id: UUID) -> T? {
        let descriptor = FetchDescriptor<T>(predicate: #Predicate { _ in true })
        guard let results = try? modelContext.fetch(descriptor) else { return nil }
        return results.first { model in
            (model as? any HasUUID)?.id == id
        }
    }
}

/// Protocol to enable generic UUID-based lookup across all RR models.
private protocol HasUUID {
    var id: UUID { get }
}

extension RRCommitment: HasUUID {}
extension RRJournalEntry: HasUUID {}
extension RRFASTEREntry: HasUUID {}
extension RRUrgeLog: HasUUID {}
extension RRMoodEntry: HasUUID {}
extension RRGratitudeEntry: HasUUID {}
extension RRPrayerLog: HasUUID {}
extension RRExerciseLog: HasUUID {}
extension RRPhoneCallLog: HasUUID {}
extension RRMeetingLog: HasUUID {}
extension RRSpouseCheckIn: HasUUID {}
extension RRTriggerLogEntry: HasUUID {}

#Preview {
    NavigationStack {
        ActivityDetailView(activity: RecentActivity(
            title: "Urge Log",
            detail: "7/10",
            time: "2h ago",
            icon: "exclamationmark.triangle.fill",
            iconColor: .orange,
            sourceType: .urgeLog,
            sourceId: UUID()
        ))
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
