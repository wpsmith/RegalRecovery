import SwiftUI
import SwiftData

struct FANOSCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Query(sort: \RRAddiction.sortOrder) private var addictions: [RRAddiction]
    @Query(sort: \RRSpouseCheckIn.date, order: .reverse) private var allCheckIns: [RRSpouseCheckIn]

    @State private var selectedEmotions: Set<PrimaryEmotion> = []
    @State private var emotionComments: [PrimaryEmotion: String] = [:]

    @State private var appreciation = ""

    @State private var selectedNeeds: Set<String> = []
    @State private var needsComments: [String: String] = [:]

    @State private var ownership = ""

    @State private var sobrietyReflection = ""

    @State private var expandedSection: Int?
    @State private var showLogSheet = false
    @State private var logComments = ""
    @State private var selectedDetailId: UUID?
    @State private var showDiscardAlert = false
    @State private var hasLoadedToday = false

    // Snapshot of loaded state for dirty checking
    @State private var savedSnapshot = FormSnapshot()

    private let needsList = [
        "Acceptance", "Affirmation", "Agency", "Belonging", "Comfort",
        "Compassion", "Connection", "Empathy", "Encouragement", "Forgiveness",
        "Grace", "Hope", "Love", "Peace", "Reassurance",
        "Respect", "Safety", "Security", "Understanding", "Validation"
    ]

    // MARK: - Derived state

    private var fanosCheckIns: [RRSpouseCheckIn] {
        allCheckIns.filter { $0.framework == "FANOS" }
    }

    private var todayCheckIn: RRSpouseCheckIn? {
        fanosCheckIns.first { Calendar.current.isDateInToday($0.date) }
    }

    private var isEditable: Bool {
        todayCheckIn?.sections.data["loggedAt"] == nil
    }

    private var canSave: Bool {
        selectedEmotions.count >= 2
            && selectedEmotions.allSatisfy { emotion in
                let comment = emotionComments[emotion] ?? ""
                return !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            && !selectedNeeds.isEmpty
            && selectedNeeds.allSatisfy { need in
                let comment = needsComments[need] ?? ""
                return !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
    }

    private var currentSnapshot: FormSnapshot {
        FormSnapshot(
            emotions: selectedEmotions,
            emotionComments: emotionComments,
            appreciation: appreciation,
            needs: selectedNeeds,
            needsComments: needsComments,
            ownership: ownership,
            sobriety: sobrietyReflection
        )
    }

    private var hasUnsavedChanges: Bool {
        isEditable && currentSnapshot != savedSnapshot
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                prepSection

                if isEditable {
                    RRButton("Save", icon: "square.and.arrow.down") {
                        save()
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                    .padding(.horizontal)
                }

                if todayCheckIn != nil && isEditable {
                    RRButton("Log Check-in Complete", icon: "checkmark.circle.fill") {
                        showLogSheet = true
                    }
                    .padding(.horizontal)
                }

                if !fanosCheckIns.isEmpty {
                    historySection
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .navigationTitle("FANOS Check-in")
        .navigationBarBackButtonHidden(hasUnsavedChanges)
        .toolbar {
            if hasUnsavedChanges {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showDiscardAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text("Back")
                        }
                    }
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showDiscardAlert) {
            Button("Save & Exit") {
                save()
                dismiss()
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Would you like to save before leaving?")
        }
        .onAppear { loadTodayIfExists() }
        .sheet(isPresented: $showLogSheet) {
            logSheet
        }
        .sheet(item: $selectedDetailId) { id in
            if let checkIn = fanosCheckIns.first(where: { $0.id == id }) {
                detailSheet(checkIn)
            }
        }
    }

    // MARK: - Prep Section

    private var prepSection: some View {
        VStack(spacing: 12) {
            feelingsCard
            appreciationCard
            needsCard
            ownershipCard
            sobrietyCard
        }
        .padding(.horizontal)
    }

    // MARK: - F: Feelings

    private var feelingsCard: some View {
        expandableCard(index: 0, letter: "F", title: "Feelings", color: .purple, required: true) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select at least 2 emotions and explain each")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(PrimaryEmotion.allCases, id: \.rawValue) { emotion in
                        Button {
                            guard isEditable else { return }
                            if selectedEmotions.contains(emotion) {
                                selectedEmotions.remove(emotion)
                                emotionComments.removeValue(forKey: emotion)
                            } else {
                                selectedEmotions.insert(emotion)
                            }
                        } label: {
                            Text(emotion.rawValue)
                                .font(RRFont.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(selectedEmotions.contains(emotion) ? .white : emotion.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(selectedEmotions.contains(emotion) ? emotion.color : emotion.color.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .disabled(!isEditable)
                    }
                }

                if selectedEmotions.count < 2 && !selectedEmotions.isEmpty {
                    Text("Select at least one more emotion")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.orange)
                }

                // Per-emotion explanation fields
                ForEach(selectedEmotions.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { emotion in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why do you feel \(emotion.rawValue.lowercased())?")
                            .font(RRFont.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(emotion.color)

                        let binding = Binding<String>(
                            get: { emotionComments[emotion] ?? "" },
                            set: { emotionComments[emotion] = $0 }
                        )

                        TextField("Explain\u{2026}", text: binding, axis: .vertical)
                            .font(RRFont.body)
                            .lineLimit(2...5)
                            .padding(8)
                            .background(Color.rrBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .disabled(!isEditable)
                    }
                }
            }
        }
    }

    // MARK: - A: Appreciation

    private var appreciationCard: some View {
        expandableCard(index: 1, letter: "A", title: "Appreciation", color: .yellow) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you appreciate about your spouse?")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                TextEditor(text: $appreciation)
                    .frame(minHeight: 80)
                    .font(RRFont.body)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color.rrBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .disabled(!isEditable)
            }
        }
    }

    // MARK: - N: Needs

    private var needsCard: some View {
        expandableCard(index: 2, letter: "N", title: "Needs", color: .blue, required: true) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Select your needs and explain each one")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                    ForEach(needsList, id: \.self) { need in
                        Button {
                            guard isEditable else { return }
                            if selectedNeeds.contains(need) {
                                selectedNeeds.remove(need)
                                needsComments.removeValue(forKey: need)
                            } else {
                                selectedNeeds.insert(need)
                            }
                        } label: {
                            Text(need)
                                .font(RRFont.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(selectedNeeds.contains(need) ? .white : Color.rrText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedNeeds.contains(need) ? Color.blue : Color.rrBackground)
                                .clipShape(Capsule())
                        }
                        .disabled(!isEditable)
                    }
                }

                ForEach(selectedNeeds.sorted(), id: \.self) { need in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(need)
                            .font(RRFont.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.blue)

                        let binding = Binding<String>(
                            get: { needsComments[need] ?? "" },
                            set: { needsComments[need] = $0 }
                        )

                        TextField("Why do you need \(need.lowercased())?", text: binding, axis: .vertical)
                            .font(RRFont.body)
                            .lineLimit(2...4)
                            .padding(8)
                            .background(Color.rrBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .disabled(!isEditable)
                    }
                }
            }
        }
    }

    // MARK: - O: Ownership

    private var ownershipCard: some View {
        expandableCard(index: 3, letter: "O", title: "Ownership", color: .orange) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What do you need to own or take responsibility for?")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                TextEditor(text: $ownership)
                    .frame(minHeight: 80)
                    .font(RRFont.body)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color.rrBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .disabled(!isEditable)
            }
        }
    }

    // MARK: - S: Sobriety

    private var sobrietyCard: some View {
        expandableCard(index: 4, letter: "S", title: "Sobriety", color: .rrSuccess) {
            VStack(alignment: .leading, spacing: 12) {
                if !addictions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(addictions) { addiction in
                            HStack(spacing: 8) {
                                Image(systemName: "shield.checkered")
                                    .foregroundStyle(Color.rrSuccess)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(addiction.name)
                                        .font(RRFont.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.rrText)
                                    let days = max(0, Calendar.current.dateComponents([.day], from: addiction.sobrietyDate, to: Date()).day ?? 0)
                                    Text("\(days) days \u{2014} since \(addiction.sobrietyDate, format: .dateTime.month(.abbreviated).day().year())")
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.rrSuccess.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Text("What did you learn about yourself or your recovery today?")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                TextEditor(text: $sobrietyReflection)
                    .frame(minHeight: 80)
                    .font(RRFont.body)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color.rrBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .disabled(!isEditable)
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)
                .padding(.horizontal)

            ForEach(fanosCheckIns) { checkIn in
                Button {
                    if !Calendar.current.isDateInToday(checkIn.date) {
                        selectedDetailId = checkIn.id
                    }
                } label: {
                    historyRow(checkIn)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    private func historyRow(_ checkIn: RRSpouseCheckIn) -> some View {
        let isLogged = checkIn.sections.data["loggedAt"] != nil
        let isToday = Calendar.current.isDateInToday(checkIn.date)

        return RRCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(checkIn.date, format: .dateTime.month(.abbreviated).day().year())
                            .font(RRFont.body)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrText)

                        if isToday {
                            Text("Today")
                                .font(RRFont.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.rrPrimary)
                                .clipShape(Capsule())
                        }
                    }

                    if isLogged {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.rrSuccess)
                                .font(.caption)
                            Text("Check-in logged")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrSuccess)
                        }
                    } else {
                        Text("Prep saved")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }

                Spacer()

                if !isToday {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.rrTextSecondary)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Log Sheet

    private var logSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.rrSuccess)

                Text("Log Your Check-in")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text("Record that the check-in happened. Add any notes about how it went.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                TextEditor(text: $logComments)
                    .frame(minHeight: 100)
                    .font(RRFont.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.rrSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.rrTextSecondary.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                Spacer()

                RRButton("Log Check-in", icon: "checkmark.circle.fill") {
                    logCheckIn()
                    showLogSheet = false
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .background(Color.rrBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { showLogSheet = false }
                }
            }
        }
    }

    // MARK: - Detail Sheet

    private func detailSheet(_ checkIn: RRSpouseCheckIn) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(checkIn.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Spacer()
                        if checkIn.sections.data["loggedAt"] != nil {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.rrSuccess)
                                Text("Logged")
                                    .foregroundStyle(Color.rrSuccess)
                            }
                            .font(RRFont.caption)
                        }
                    }

                    // Feelings with per-emotion detail
                    if let feelings = stringValue(checkIn.sections.data["feelings"]) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feelings")
                                .font(RRFont.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.rrTextSecondary)

                            if case .dictionary(let emotionDict) = checkIn.sections.data["emotionDetails"] {
                                ForEach(emotionDict.keys.sorted(), id: \.self) { emotion in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(emotion)
                                            .font(RRFont.body)
                                            .fontWeight(.medium)
                                            .foregroundStyle(Color.rrText)
                                        if case .string(let comment) = emotionDict[emotion], !comment.isEmpty {
                                            Text(comment)
                                                .font(RRFont.body)
                                                .foregroundStyle(Color.rrTextSecondary)
                                        }
                                    }
                                }
                            } else {
                                Text(feelings)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                        }
                    }

                    detailRow("Appreciation", value: stringValue(checkIn.sections.data["appreciation"]))
                    detailRow("Needs", value: stringValue(checkIn.sections.data["needs"]))
                    detailRow("Ownership", value: stringValue(checkIn.sections.data["ownership"]))
                    detailRow("Sobriety Reflection", value: stringValue(checkIn.sections.data["sobriety"]))

                    if let notes = stringValue(checkIn.sections.data["logComments"]), !notes.isEmpty {
                        detailRow("Check-in Notes", value: notes)
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle("FANOS Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { selectedDetailId = nil }
                }
            }
        }
    }

    private func detailRow(_ title: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(RRFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrTextSecondary)
            Text(value?.isEmpty == false ? value! : "Not filled in")
                .font(RRFont.body)
                .foregroundStyle(value?.isEmpty == false ? Color.rrText : Color.rrTextSecondary)
                .italic(value?.isEmpty != false)
        }
    }

    // MARK: - Expandable Card

    private func expandableCard<Content: View>(
        index: Int,
        letter: String,
        title: String,
        color: Color,
        required: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation {
                        expandedSection = expandedSection == index ? nil : index
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(letter)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(color)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(title)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        if required {
                            Text("Required")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.orange)
                        }
                        Spacer()
                        Image(systemName: expandedSection == index ? "chevron.up" : "chevron.down")
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }

                if expandedSection == index {
                    Divider()
                        .padding(.vertical, 10)
                    content()
                }
            }
        }
    }

    // MARK: - Actions

    private func save() {
        if let existing = todayCheckIn {
            existing.sections = buildSections()
            existing.modifiedAt = Date()
        } else {
            let userId = users.first?.id ?? UUID()
            let entry = RRSpouseCheckIn(
                userId: userId,
                date: Date(),
                framework: "FANOS",
                sections: buildSections()
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()
        savedSnapshot = currentSnapshot
    }

    private func logCheckIn() {
        // Save current form state first
        save()
        guard let checkIn = todayCheckIn else { return }
        var data = checkIn.sections.data
        data["loggedAt"] = .string(ISO8601DateFormatter().string(from: Date()))
        if !logComments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["logComments"] = .string(logComments)
        }
        checkIn.sections = JSONPayload(data)
        checkIn.modifiedAt = Date()
        try? modelContext.save()
        savedSnapshot = currentSnapshot
        logComments = ""
    }

    private func loadTodayIfExists() {
        guard !hasLoadedToday else { return }
        hasLoadedToday = true

        guard let checkIn = todayCheckIn else {
            savedSnapshot = currentSnapshot
            return
        }
        let data = checkIn.sections.data

        // Feelings — load per-emotion details
        if case .dictionary(let emotionDict) = data["emotionDetails"] {
            for (emotionName, val) in emotionDict {
                if let emotion = PrimaryEmotion(rawValue: emotionName) {
                    selectedEmotions.insert(emotion)
                    if case .string(let comment) = val {
                        emotionComments[emotion] = comment
                    }
                }
            }
        } else if case .string(let f) = data["feelings"] {
            let parts = f.components(separatedBy: ", ")
            selectedEmotions = Set(parts.compactMap { PrimaryEmotion(rawValue: $0) })
        }

        // Appreciation
        if case .string(let a) = data["appreciation"] {
            appreciation = a
        }

        // Needs
        if case .dictionary(let needsDict) = data["needsDetailed"] {
            for (need, val) in needsDict {
                selectedNeeds.insert(need)
                if case .string(let comment) = val {
                    needsComments[need] = comment
                }
            }
        } else if case .string(let n) = data["needs"] {
            let parts = n.components(separatedBy: ", ")
            selectedNeeds = Set(parts.filter { !$0.isEmpty })
        }

        // Ownership
        if case .string(let o) = data["ownership"] {
            ownership = o
        }

        // Sobriety
        if case .string(let s) = data["sobriety"] {
            sobrietyReflection = s
        }

        savedSnapshot = currentSnapshot
    }

    private func buildSections() -> JSONPayload {
        var data: [String: AnyCodableValue] = [:]

        // Feelings: store as comma-separated list + per-emotion detail dictionary
        let emotionNames = selectedEmotions.map(\.rawValue).sorted().joined(separator: ", ")
        data["feelings"] = .string(emotionNames)
        var emotionDict: [String: AnyCodableValue] = [:]
        for emotion in selectedEmotions {
            emotionDict[emotion.rawValue] = .string(emotionComments[emotion] ?? "")
        }
        data["emotionDetails"] = .dictionary(emotionDict)

        // Appreciation
        data["appreciation"] = .string(appreciation)

        // Needs: dictionary of need → comment
        var needsDict: [String: AnyCodableValue] = [:]
        for need in selectedNeeds {
            needsDict[need] = .string(needsComments[need] ?? "")
        }
        data["needsDetailed"] = .dictionary(needsDict)
        let needsSummary = selectedNeeds.sorted().map { need in
            let comment = needsComments[need] ?? ""
            return comment.isEmpty ? need : "\(need): \(comment)"
        }.joined(separator: "\n")
        data["needs"] = .string(needsSummary)

        // Ownership
        data["ownership"] = .string(ownership)

        // Sobriety
        data["sobriety"] = .string(sobrietyReflection)

        return JSONPayload(data)
    }

    private func stringValue(_ value: AnyCodableValue?) -> String? {
        guard let value else { return nil }
        if case .string(let s) = value { return s }
        return nil
    }
}

// MARK: - Form Snapshot (for dirty checking)

private struct FormSnapshot: Equatable {
    var emotions: Set<PrimaryEmotion> = []
    var emotionComments: [PrimaryEmotion: String] = [:]
    var appreciation: String = ""
    var needs: Set<String> = []
    var needsComments: [String: String] = [:]
    var ownership: String = ""
    var sobriety: String = ""
}

// MARK: - UUID Identifiable conformance for sheet binding

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

#Preview {
    NavigationStack {
        FANOSCheckInView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
