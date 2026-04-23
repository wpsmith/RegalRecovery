import SwiftUI
import SwiftData

struct PostMortemView: View {
    @State private var viewModel = PostMortemViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Query(sort: \RRAddiction.name) private var addictions: [RRAddiction]

    var body: some View {
        VStack(spacing: 0) {
            progressBar

            ScrollView {
                VStack(spacing: 20) {
                    stepContent
                }
                .padding(.vertical)
            }

            navigationBar
        }
        .background(Color.rrBackground)
        .navigationTitle("Post-Mortem Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
        .sheet(isPresented: $viewModel.showCompletionMessage) {
            completionSheet
        }
        .onAppear {
            if let userId = users.first?.id {
                let date = viewModel.timestamp
                viewModel.loadDayContext(context: modelContext, userId: userId, date: date)
                viewModel.loadDayBeforeContext(context: modelContext, userId: userId, date: date)
                viewModel.loadUserTriggers(context: modelContext, userId: userId)
                viewModel.loadFasterHistory(context: modelContext, userId: userId)
                viewModel.loadActionPlanContext(context: modelContext, userId: userId, date: date)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(Array(PostMortemViewModel.FlowStep.allCases.enumerated()), id: \.offset) { index, step in
                    Capsule()
                        .fill(index <= viewModel.currentStep.rawValue ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal)

            HStack {
                Text("Step \(viewModel.currentStep.rawValue + 1) of \(PostMortemViewModel.FlowStep.allCases.count)")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.rrSurface)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .actingOut:
            ActingOutStepView(viewModel: viewModel, addictions: addictions)
        case .throughoutTheDay:
            ThroughoutTheDayStepView(viewModel: viewModel)
        case .dayBefore:
            DayBeforeStepView(viewModel: viewModel)
        case .buildUp:
            BuildUpStepView(viewModel: viewModel)
        case .triggers:
            TriggersStepView(viewModel: viewModel)
        case .immediatelyAfter:
            ImmediatelyAfterStepView(viewModel: viewModel)
        case .fasterHistory:
            FasterHistoryStepView(viewModel: viewModel)
        case .actionPlan:
            ActionPlanStepView(viewModel: viewModel)
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep.rawValue > 0 {
                Button {
                    withAnimation {
                        viewModel.goBack()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color.rrPrimary)
                    .background(Color.rrPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            Button {
                withAnimation {
                    if viewModel.currentStep == .actionPlan {
                        if viewModel.canComplete {
                            Task {
                                do {
                                    try viewModel.complete(context: modelContext)
                                    viewModel.showCompletionMessage = true
                                } catch {
                                    viewModel.error = error.localizedDescription
                                }
                            }
                        }
                    } else {
                        viewModel.advance()
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.currentStep == .actionPlan ? "Complete" : "Next")
                    Image(systemName: viewModel.currentStep == .actionPlan ? "checkmark" : "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(viewModel.canAdvance() ? Color.rrPrimary : Color.rrTextSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!viewModel.canAdvance())
        }
        .padding()
        .background(Color.rrSurface)
    }

    // MARK: - Completion Sheet

    private var completionSheet: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.rrPrimary)

            Text("Analysis Complete")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)

            Text("Thank you for your honesty and courage. Every insight you have gained here is a step toward lasting freedom.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !viewModel.selectedRecommendations.isEmpty || !viewModel.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Action Items Added")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    ForEach(Array(viewModel.selectedRecommendations), id: \.self) { activityType in
                        if let activity = viewModel.recommendedActivities.first(where: { $0.activityType == activityType }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.rrSuccess)
                                Text(activity.title)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrText)
                            }
                        }
                    }

                    ForEach(viewModel.actionItems, id: \.id) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.rrSuccess)
                            Text(item.action)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                }
                .padding()
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal)
            }

            VStack(spacing: 12) {
                RRButton("View Action Plan", icon: "list.bullet") {
                    viewModel.showCompletionMessage = false
                    dismiss()
                }

                Button("Close") {
                    viewModel.showCompletionMessage = false
                    dismiss()
                }
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 40)
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Step 1: Acting Out

private struct ActingOutStepView: View {
    @Bindable var viewModel: PostMortemViewModel
    let addictions: [RRAddiction]

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("What Happened?")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.rrPrimary)
                        Text("This is a safe, judgment-free space. Your honesty here is a powerful step toward healing.")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()
                    }

                    VStack(spacing: 12) {
                        eventTypeButton("relapse", title: "Relapse", description: "I acted out", icon: "exclamationmark.triangle.fill", color: .red)
                        eventTypeButton("near-miss", title: "Near Miss", description: "I came close but didn't act out", icon: "shield.fill", color: .orange)
                        eventTypeButton("combined", title: "Combined", description: "Near miss followed by relapse", icon: "arrow.triangle.2.circlepath", color: .purple)
                    }
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("When did this happen?")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    DatePicker("Date & Time", selection: $viewModel.timestamp, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
            }
            .padding(.horizontal)

            if viewModel.eventType == "relapse" && addictions.count > 1 {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Which addiction?")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        ForEach(addictions, id: \.id) { addiction in
                            Button {
                                viewModel.addictionId = addiction.id
                            } label: {
                                HStack {
                                    Image(systemName: viewModel.addictionId == addiction.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(viewModel.addictionId == addiction.id ? Color.rrPrimary : Color.rrTextSecondary)
                                    Text(addiction.name)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                    Spacer()
                                }
                                .padding(12)
                                .background(viewModel.addictionId == addiction.id ? Color.rrPrimary.opacity(0.1) : Color.rrSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Describe what happened")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    Text("No graphic detail needed — focus on the sequence of decisions")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()

                    TextEditor(text: $viewModel.actingOutDescription)
                        .frame(minHeight: 120)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration (optional)")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    HStack {
                        TextField("Minutes", value: $viewModel.actingOutDurationMinutes, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        Text("minutes")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func eventTypeButton(_ type: String, title: String, description: String, icon: String, color: Color) -> some View {
        Button {
            viewModel.eventType = type
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(viewModel.eventType == type ? color : Color.rrTextSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(RRFont.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)
                    Text(description)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Spacer()

                Image(systemName: viewModel.eventType == type ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(viewModel.eventType == type ? Color.rrPrimary : Color.rrTextSecondary)
            }
            .padding()
            .background(viewModel.eventType == type ? color.opacity(0.1) : Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Step 2: Throughout the Day

private struct ThroughoutTheDayStepView: View {
    @Bindable var viewModel: PostMortemViewModel
    @State private var showAddEntry = false
    @State private var newEntryTime = Date()
    @State private var newEntryDescription = ""

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Let's Walk Through Your Day")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Working backwards from what happened...")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                }
            }
            .padding(.horizontal)

            // Timeline view showing time journal and activities
            if !viewModel.timeBlocksForDay.isEmpty || !viewModel.activitiesForDay.isEmpty {
                VStack(spacing: 12) {
                    ForEach(viewModel.timeBlocksForDay.sorted { $0.timestamp > $1.timestamp }, id: \.id) { block in
                        TimelineEntryCard(
                            time: block.timestamp,
                            title: block.activity,
                            detail: block.need,
                            icon: "clock.fill",
                            color: .purple
                        )
                        .padding(.horizontal)
                    }

                    ForEach(viewModel.activitiesForDay.sorted { $0.date > $1.date }, id: \.id) { activity in
                        TimelineEntryCard(
                            time: activity.date,
                            title: activity.activityType,
                            detail: activity.summary ?? "",
                            icon: activity.icon ?? "circle.fill",
                            color: activity.iconColor ?? .rrPrimary
                        )
                        .padding(.horizontal)
                    }
                }
            }

            // Free-form entries
            if !viewModel.freeFormEntries.isEmpty {
                ForEach(viewModel.freeFormEntries, id: \.id) { entry in
                    TimelineEntryCard(
                        time: entry.time,
                        title: "Custom Entry",
                        detail: entry.text,
                        icon: "pencil.circle.fill",
                        color: .rrSecondary
                    )
                    .padding(.horizontal)
                }
            }

            RRCard {
                VStack(spacing: 12) {
                    Button {
                        showAddEntry = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Timeline Entry")
                        }
                        .font(RRFont.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.rrPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    Text("What happened before that?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showAddEntry) {
            NavigationStack {
                Form {
                    Section("Time") {
                        DatePicker("When", selection: $newEntryTime, displayedComponents: [.hourAndMinute])
                    }

                    Section("Description") {
                        TextEditor(text: $newEntryDescription)
                            .frame(minHeight: 100)
                    }
                }
                .navigationTitle("Add Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddEntry = false
                            newEntryDescription = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            viewModel.addFreeFormEntry(time: newEntryTime, description: newEntryDescription)
                            showAddEntry = false
                            newEntryDescription = ""
                        }
                        .disabled(newEntryDescription.isEmpty)
                    }
                }
            }
        }
    }
}

private struct TimelineEntryCard: View {
    let time: Any  // Can be Date or String
    let title: String
    let detail: String
    let icon: String
    let color: Color

    var body: some View {
        RRCard {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)

                    if let dateTime = time as? Date {
                        Text(dateTime.formatted(date: .omitted, time: .shortened))
                            .font(RRFont.caption2)
                            .foregroundStyle(Color.rrTextSecondary)
                    } else if let stringTime = time as? String {
                        Text(stringTime)
                            .font(RRFont.caption2)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .frame(width: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    if !detail.isEmpty {
                        Text(detail)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Step 3: Day Before

private struct DayBeforeStepView: View {
    @Bindable var viewModel: PostMortemViewModel

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The Day Before")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("What was happening the day before the event?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                }
            }
            .padding(.horizontal)

            // Activity History
            if !viewModel.dayBeforeActivities.isEmpty {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity History")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(viewModel.dayBeforeActivities, id: \.title) { activity in
                                ActivityStatusTile(activity: activity)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's missing from this picture?")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    TextEditor(text: $viewModel.dayBeforeText)
                        .frame(minHeight: 100)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mood Rating")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    PostMortemMoodRatingView(rating: $viewModel.dayBeforeMoodRating)
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Unresolved conflicts (optional)")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    TextEditor(text: $viewModel.dayBeforeUnresolvedConflicts)
                        .frame(minHeight: 80)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct ActivityStatusTile: View {
    let activity: DayActivityRecord

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: activity.icon)
                .font(.title2)
                .foregroundStyle(activity.iconColor)

            Text(activity.title)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrText)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Image(systemName: activity.wasCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(activity.wasCompleted ? Color.rrSuccess : Color.rrDestructive)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(activity.wasCompleted ? Color.rrSuccess.opacity(0.08) : Color.rrDestructive.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Step 4: Build-Up

private struct BuildUpStepView: View {
    @Bindable var viewModel: PostMortemViewModel

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The Build-Up")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("When did you first notice something was off?")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    TextEditor(text: $viewModel.firstNoticed)
                        .frame(minHeight: 100)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Trigger Exploration")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        Spacer()

                        Button {
                            viewModel.addBuildUpTrigger()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }

                    if viewModel.triggers.isEmpty {
                        Text("Tap + to add triggers with 3-layer exploration")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()
                    } else {
                        ForEach(Array(viewModel.triggers.enumerated()), id: \.element.id) { index, _ in
                            BuildUpTriggerCard(trigger: triggerBinding(for: index)) {
                                viewModel.removeBuildUpTrigger(at: index)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How did you respond to the warning signs?")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    TextEditor(text: $viewModel.responseToWarnings)
                        .frame(minHeight: 80)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Missed Help Opportunities")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        Spacer()

                        Button {
                            viewModel.addMissedHelpOpportunity()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }

                    if !viewModel.missedHelpOpportunities.isEmpty {
                        ForEach(Array(viewModel.missedHelpOpportunities.enumerated()), id: \.element.id) { index, _ in
                            MissedOpportunityCard(opportunity: opportunityBinding(for: index)) {
                                viewModel.removeMissedHelpOpportunity(at: index)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Decision Points")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        Spacer()

                        Button {
                            viewModel.addDecisionPoint()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }

                    if !viewModel.decisionPoints.isEmpty {
                        ForEach(Array(viewModel.decisionPoints.enumerated()), id: \.element.id) { index, _ in
                            DecisionPointCard(point: decisionPointBinding(for: index)) {
                                viewModel.removeDecisionPoint(at: index)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func triggerBinding(for index: Int) -> Binding<TriggerEntry> {
        Binding(
            get: { viewModel.triggers[index] },
            set: { viewModel.triggers[index] = $0 }
        )
    }

    private func opportunityBinding(for index: Int) -> Binding<MissedHelpEntry> {
        Binding(
            get: { viewModel.missedHelpOpportunities[index] },
            set: { viewModel.missedHelpOpportunities[index] = $0 }
        )
    }

    private func decisionPointBinding(for index: Int) -> Binding<DecisionPointEntry> {
        Binding(
            get: { viewModel.decisionPoints[index] },
            set: { viewModel.decisionPoints[index] = $0 }
        )
    }
}

private struct BuildUpTriggerCard: View {
    @Binding var trigger: TriggerEntry
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Category", selection: $trigger.category) {
                    Text("Select...").tag("")
                    ForEach(TriggerCategory.allCases, id: \.rawValue) { category in
                        Text(category.displayName).tag(category.rawValue)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }

            VStack(spacing: 6) {
                TextField("Surface trigger (what happened)", text: $trigger.surface)
                    .textFieldStyle(.roundedBorder)

                TextField("Underlying emotion (what you felt)", text: $trigger.underlying)
                    .textFieldStyle(.roundedBorder)

                TextField("Core wound (deeper root)", text: $trigger.coreWound)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .background(Color.rrBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MissedOpportunityCard: View {
    @Binding var opportunity: MissedHelpEntry
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Opportunity")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                Spacer()
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }

            TextField("What could you have done?", text: $opportunity.description)
                .textFieldStyle(.roundedBorder)

            TextField("Why didn't you?", text: $opportunity.reason)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color.rrBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DecisionPointCard: View {
    @Binding var point: DecisionPointEntry
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Time of day", text: $point.timeOfDay)
                    .textFieldStyle(.roundedBorder)
                Spacer()
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }

            TextField("What happened", text: $point.description)
                .textFieldStyle(.roundedBorder)

            TextField("Could have done instead", text: $point.couldHaveDone)
                .textFieldStyle(.roundedBorder)

            TextField("What you did instead", text: $point.insteadDid)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color.rrBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Step 5: Triggers

private struct TriggersStepView: View {
    @Bindable var viewModel: PostMortemViewModel

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Identify Your Triggers")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Select from your trigger library and explore deeper layers")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                }
            }
            .padding(.horizontal)

            // Category summary
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    FlowLayout(spacing: 8) {
                        ForEach(TriggerCategory.allCases) { category in
                            let isActive = viewModel.userTriggers.contains { $0.category == category.rawValue && $0.isSelected }
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.caption2)
                                Text(category.displayName)
                                    .font(RRFont.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isActive ? category.color.opacity(0.15) : Color.rrSurface)
                            .foregroundStyle(isActive ? category.color : Color.rrTextSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().strokeBorder(category.color.opacity(isActive ? 0.3 : 0.1), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)

            // My Triggers
            if !viewModel.userTriggers.isEmpty {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Triggers")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        ForEach(TriggerCategory.allCases) { category in
                            let triggersInCategory = viewModel.userTriggers.filter { $0.category == category.rawValue }
                            if !triggersInCategory.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 4) {
                                        Image(systemName: category.icon)
                                            .font(.caption2)
                                        Text(category.displayName)
                                            .font(RRFont.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(category.color)

                                    FlowLayout(spacing: 8) {
                                        ForEach(triggersInCategory, id: \.label) { trigger in
                                            Button {
                                                viewModel.toggleUserTrigger(trigger.id)
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Text(trigger.label)
                                                        .font(RRFont.caption)
                                                    if trigger.isSelected {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.caption2)
                                                    }
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(trigger.isSelected ? category.color : Color.rrSurface)
                                                .foregroundStyle(trigger.isSelected ? .white : Color.rrText)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule().strokeBorder(Color.rrTextSecondary.opacity(0.2), lineWidth: trigger.isSelected ? 0 : 1)
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Add custom triggers
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Add Custom Triggers")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        Spacer()

                        Button {
                            viewModel.addCustomTrigger()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }

                    if !viewModel.triggerDetails.isEmpty {
                        ForEach(Array(viewModel.triggerDetails.enumerated()), id: \.element.id) { index, _ in
                            CustomTriggerCard(trigger: customTriggerBinding(for: index)) {
                                viewModel.removeCustomTrigger(at: index)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func customTriggerBinding(for index: Int) -> Binding<TriggerEntry> {
        Binding(
            get: { viewModel.triggerDetails[index] },
            set: { viewModel.triggerDetails[index] = $0 }
        )
    }
}

private struct CustomTriggerCard: View {
    @Binding var trigger: TriggerEntry
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Category", selection: $trigger.category) {
                    Text("Select...").tag("")
                    ForEach(TriggerCategory.allCases, id: \.rawValue) { category in
                        Text(category.displayName).tag(category.rawValue)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }

            TextField("Trigger description", text: $trigger.surface)
                .textFieldStyle(.roundedBorder)

            TextField("Underlying emotion (optional)", text: $trigger.underlying)
                .textFieldStyle(.roundedBorder)

            TextField("Core wound (optional)", text: $trigger.coreWound)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color.rrBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Step 6: Immediately After

private struct ImmediatelyAfterStepView: View {
    @Bindable var viewModel: PostMortemViewModel
    @State private var newFeeling = ""

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Immediately After")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Feelings")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.feelings, id: \.self) { feeling in
                            HStack(spacing: 4) {
                                Text(feeling)
                                    .font(RRFont.caption)
                                    .foregroundStyle(.white)
                                Button {
                                    viewModel.removeFeeling(feeling)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.rrPrimary)
                            .clipShape(Capsule())
                        }

                        HStack(spacing: 4) {
                            TextField("Add feeling", text: $newFeeling)
                                .textFieldStyle(.plain)
                                .font(RRFont.caption)
                                .frame(minWidth: 80)
                                .onSubmit {
                                    addFeeling()
                                }
                            Button {
                                addFeeling()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.rrPrimary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.rrSurface)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.rrTextSecondary.opacity(0.2), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What did you do next?")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    TextEditor(text: $viewModel.whatDidNext)
                        .frame(minHeight: 100)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $viewModel.reachedOut) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("I reached out to someone")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                    .tint(Color.rrPrimary)

                    if viewModel.afterReachedOut {
                        TextField("Who did you reach out to?", text: Binding(
                            get: { viewModel.reachedOutTo ?? "" },
                            set: { viewModel.reachedOutTo = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What do you wish you had done differently?")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    TextEditor(text: $viewModel.wishDoneDifferently)
                        .frame(minHeight: 100)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal)
        }
    }

    private func addFeeling() {
        let trimmed = newFeeling.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !viewModel.feelings.contains(trimmed) else { return }
        viewModel.addFeeling(trimmed)
        newFeeling = ""
    }
}

// MARK: - Step 7: FASTER History

private struct FasterHistoryStepView: View {
    @Bindable var viewModel: PostMortemViewModel

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("FASTER Scale History")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Visualize your journey through the FASTER stages over the past 4 weeks")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                }
            }
            .padding(.horizontal)

            if !viewModel.hasFasterData {
                RRCard {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.rrTextSecondary)

                        Text("No FASTER Scale data available")
                            .font(RRFont.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        Text("You can skip this step or start using the FASTER Scale check-in to build your history.")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                .padding(.horizontal)
            } else {
                FASTERHistoryChart(entries: viewModel.fasterHistory)
                    .frame(height: 300)
                    .padding(.horizontal)

                if let selectedEntry = viewModel.selectedFasterEntry {
                    RRCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(selectedEntry.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Spacer()
                                if let moodScore = selectedEntry.moodScore {
                                    Text("Mood: \(moodScore)/10")
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                            }

                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedEntry.stageColor)
                                    .frame(width: 4)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedEntry.stageName)
                                        .font(RRFont.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.rrText)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

private struct FASTERHistoryChart: View {
    let entries: [FASTERHistoryEntry]

    var body: some View {
        GeometryReader { geometry in
            let chartWidth = geometry.size.width - 60
            let chartHeight = geometry.size.height - 40
            let stages = FASTERStage.allCases
            let stageCount = CGFloat(stages.count)

            ZStack(alignment: .topLeading) {
                // Y-axis labels
                VStack(spacing: 0) {
                    ForEach(stages.reversed(), id: \.rawValue) { stage in
                        HStack(spacing: 4) {
                            Text(stage.letter)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(stage.color)
                                .frame(width: 30, alignment: .trailing)

                            Rectangle()
                                .fill(Color.rrTextSecondary.opacity(0.1))
                                .frame(height: 1)
                        }
                        .frame(height: chartHeight / stageCount)
                    }
                }
                .offset(y: 20)

                // Data points
                ForEach(entries, id: \.date) { entry in
                    let xPosition = xPositionFor(entry: entry, in: chartWidth, entries: entries)
                    let yPosition = yPositionFor(stage: entry.stage, in: chartHeight, stageCount: stageCount)

                    Circle()
                        .fill(entry.stageColor)
                        .frame(width: 8, height: 8)
                        .offset(x: xPosition + 35, y: yPosition + 20)
                }
            }
        }
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func xPositionFor(entry: FASTERHistoryEntry, in width: CGFloat, entries: [FASTERHistoryEntry]) -> CGFloat {
        guard let oldestDate = entries.map({ $0.date }).min(),
              let newestDate = entries.map({ $0.date }).max() else {
            return 0
        }

        let totalTimeSpan = newestDate.timeIntervalSince(oldestDate)
        guard totalTimeSpan > 0 else { return 0 }

        let entryTimeOffset = entry.date.timeIntervalSince(oldestDate)
        let normalizedPosition = entryTimeOffset / totalTimeSpan

        return CGFloat(normalizedPosition) * width
    }

    private func yPositionFor(stage: Int, in height: CGFloat, stageCount: CGFloat) -> CGFloat {
        let stages = FASTERStage.allCases.reversed()
        guard let fasterStage = FASTERStage(rawValue: stage),
              let index = stages.firstIndex(of: fasterStage) else { return 0 }

        let slotHeight = height / stageCount
        return CGFloat(index) * slotHeight + (slotHeight / 2) - 4
    }
}

// MARK: - Step 8: Action Plan

private struct ActionPlanStepView: View {
    @Bindable var viewModel: PostMortemViewModel

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Action Plan")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Build your recovery plan based on insights from this analysis")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                }
            }
            .padding(.horizontal)

            // Missed Activities
            if !viewModel.missedActivities.isEmpty {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.rrDestructive)
                            Text("Missed Recovery Activities")
                                .font(RRFont.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.rrText)
                        }

                        Text("These activities were missed on the day of the event")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(viewModel.missedActivities, id: \.title) { activity in
                                VStack(spacing: 6) {
                                    Image(systemName: activity.icon)
                                        .font(.title2)
                                        .foregroundStyle(Color.rrDestructive)

                                    Text(activity.title)
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrText)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)

                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.rrDestructive)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.rrDestructive.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Recommended Activities
            if !viewModel.recommendedActivities.isEmpty {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended Activities")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        Text("Consider adding these to your recovery plan")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        ForEach(viewModel.recommendedActivities, id: \.activityType) { activity in
                            Button {
                                viewModel.toggleRecommendation(activity.activityType)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: activity.icon)
                                        .font(.title3)
                                        .foregroundStyle(activity.iconColor)
                                        .frame(width: 40)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(activity.title)
                                            .font(RRFont.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(Color.rrText)

                                        Text(activity.reason)
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: viewModel.selectedRecommendations.contains(activity.activityType) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(viewModel.selectedRecommendations.contains(activity.activityType) ? Color.rrSuccess : Color.rrTextSecondary)
                                }
                                .padding()
                                .background(viewModel.selectedRecommendations.contains(activity.activityType) ? Color.rrSuccess.opacity(0.08) : Color.rrBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Custom Action Items
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Custom Action Items")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        Spacer()

                        Button {
                            viewModel.addActionItem()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add")
                            }
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrPrimary)
                        }
                    }

                    if viewModel.actionItems.isEmpty {
                        Text("Add specific actions to prevent this from happening again")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()
                    } else {
                        ForEach(Array(viewModel.actionItems.enumerated()), id: \.element.id) { index, _ in
                            CustomActionItemCard(item: actionItemBinding(for: index)) {
                                viewModel.removeActionItemAt(at: index)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            if !viewModel.canComplete {
                RRCard {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.rrSecondary)
                        Text("Add at least one action item to complete")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func actionItemBinding(for index: Int) -> Binding<ActionItemEntry> {
        Binding(
            get: { viewModel.actionItems[index] },
            set: { viewModel.actionItems[index] = $0 }
        )
    }
}

private struct CustomActionItemCard: View {
    @Binding var item: ActionItemEntry
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Category", selection: $item.category) {
                    Text("Select...").tag("")
                    Text("Recovery Practice").tag("recovery")
                    Text("Connection").tag("connection")
                    Text("Self-Care").tag("self-care")
                    Text("Boundaries").tag("boundaries")
                    Text("Accountability").tag("accountability")
                }
                .pickerStyle(.menu)
                .font(RRFont.caption)

                Spacer()

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }

            TextField("Action to take", text: $item.action, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
        .padding()
        .background(Color.rrBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Mood Rating Component

private struct PostMortemMoodRatingView: View {
    @Binding var rating: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        ZStack {
                            Circle()
                                .fill(rating == value ? moodColor(for: value) : Color.rrSurface)
                                .frame(width: 32, height: 32)

                            Circle()
                                .strokeBorder(rating == value ? Color.clear : Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
                                .frame(width: 32, height: 32)

                            Text("\(value)")
                                .font(RRFont.caption)
                                .fontWeight(rating == value ? .bold : .regular)
                                .foregroundStyle(rating == value ? .white : Color.rrText)
                        }
                    }
                }
            }

            HStack {
                Text("Low")
                    .font(RRFont.caption2)
                    .foregroundStyle(Color.rrTextSecondary)
                Spacer()
                Text("High")
                    .font(RRFont.caption2)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }

    private func moodColor(for value: Int) -> Color {
        switch value {
        case 1...3: return .red
        case 4...5: return .orange
        case 6...7: return .yellow
        case 8...9: return Color(red: 0.5, green: 0.8, blue: 0.4)
        default: return .green
        }
    }
}

#Preview {
    NavigationStack {
        PostMortemView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
