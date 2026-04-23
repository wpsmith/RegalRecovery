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
                _ = viewModel.resumeLatestDraft(context: modelContext, userId: userId)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(PostMortemViewModel.FlowStep.allCases, id: \.rawValue) { step in
                    Capsule()
                        .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
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
        case .eventType:
            EventTypeStepView(viewModel: viewModel, addictions: addictions)
        case .dayBefore:
            DayBeforeSectionView(viewModel: viewModel)
        case .morning:
            MorningSectionView(viewModel: viewModel)
        case .throughoutTheDay:
            ThroughoutTheDayView(viewModel: viewModel)
        case .buildUp:
            BuildUpSectionView(viewModel: viewModel)
        case .actingOut:
            ActingOutSectionView(viewModel: viewModel, addictions: addictions)
        case .immediatelyAfter:
            ImmediatelyAfterSectionView(viewModel: viewModel)
        case .triggers:
            TriggersStepView(viewModel: viewModel)
        case .fasterMapping:
            FasterMappingStepView(viewModel: viewModel)
        case .actionPlan:
            ActionPlanStepView(viewModel: viewModel)
        case .review:
            ReviewStepView(viewModel: viewModel, modelContext: modelContext)
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
                    if viewModel.currentStep == .review {
                        // Complete on review step
                        Task {
                            do {
                                try viewModel.saveDraft(context: modelContext)
                            } catch {
                                viewModel.error = error.localizedDescription
                            }
                        }
                        viewModel.showCompletionMessage = true
                    } else {
                        viewModel.advance()
                        // Auto-save after each step
                        Task {
                            do {
                                try viewModel.saveDraft(context: modelContext)
                            } catch {
                                viewModel.error = error.localizedDescription
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.currentStep == .review ? "Complete" : "Next")
                    Image(systemName: viewModel.currentStep == .review ? "checkmark" : "chevron.right")
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

            Text(viewModel.completionMessage ?? "Thank you for your honesty and courage. Every insight you have gained here is a step toward lasting freedom.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
        .presentationDetents([.medium])
    }
}

// MARK: - Event Type Step

private struct EventTypeStepView: View {
    @Bindable var viewModel: PostMortemViewModel
    let addictions: [RRAddiction]

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("What type of event is this?")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    VStack(spacing: 12) {
                        eventTypeButton("relapse", title: "Relapse", description: "I acted out", icon: "exclamationmark.triangle.fill", color: .red)
                        eventTypeButton("near-miss", title: "Near Miss", description: "I came close but didn't act out", icon: "shield.fill", color: .orange)
                        eventTypeButton("combined", title: "Both", description: "Near miss followed by relapse", icon: "arrow.triangle.2.circlepath", color: .purple)
                    }
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("When did this happen?")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    DatePicker("Date & Time", selection: $viewModel.timestamp, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
            }
            .padding(.horizontal)

            if viewModel.eventType == "relapse" {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Relapse ID (optional)")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrText)

                        TextField("Enter relapse ID if available", text: Binding(
                            get: { viewModel.relapseId ?? "" },
                            set: { viewModel.relapseId = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal)
            }

            if addictions.count > 1 {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Which addiction?")
                            .font(RRFont.title3)
                            .foregroundStyle(Color.rrText)

                        ForEach(addictions, id: \.id) { addiction in
                            Button {
                                viewModel.addictionId = addiction.id.uuidString
                            } label: {
                                HStack {
                                    Image(systemName: viewModel.addictionId == addiction.id.uuidString ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(viewModel.addictionId == addiction.id.uuidString ? Color.rrPrimary : Color.rrTextSecondary)
                                    Text(addiction.name)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                    Spacer()
                                }
                                .padding(12)
                                .background(viewModel.addictionId == addiction.id.uuidString ? Color.rrPrimary.opacity(0.1) : Color.rrSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
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

// MARK: - Day Before Section

private struct DayBeforeSectionView: View {
    @Bindable var viewModel: PostMortemViewModel

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The Day Before")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Describe what happened the day before. What was your emotional state? Were there any warning signs?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()

                    TextEditor(text: $viewModel.dayBeforeText)
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
                    Toggle(isOn: $viewModel.dayBeforeRecoveryPracticesKept) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recovery practices kept")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                            Text("Did you maintain your routines?")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                    .tint(Color.rrPrimary)
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

// MARK: - Morning Section

private struct MorningSectionView: View {
    @Bindable var viewModel: PostMortemViewModel

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The Morning")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("How did your morning start? Did you follow your routine? What was different?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()

                    TextEditor(text: $viewModel.morningText)
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
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mood Rating")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    PostMortemMoodRatingView(rating: $viewModel.morningMoodRating)
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $viewModel.morningCommitmentCompleted) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Morning commitment completed")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                    .tint(Color.rrPrimary)

                    Divider()

                    Toggle(isOn: $viewModel.morningAffirmationViewed) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Affirmation viewed")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                    .tint(Color.rrPrimary)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Throughout the Day

private struct ThroughoutTheDayView: View {
    @Bindable var viewModel: PostMortemViewModel
    @State private var showAddTimeBlock = false

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Throughout the Day")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Add time blocks to describe key moments. When did things start to shift?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()

                    Button {
                        showAddTimeBlock = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Time Block")
                        }
                        .font(RRFont.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.rrPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .padding(.horizontal)

            if !viewModel.timeBlocks.isEmpty {
                ForEach(Array(viewModel.timeBlocks.enumerated()), id: \.element.id) { index, block in
                    TimeBlockCard(block: block) {
                        viewModel.timeBlocks.remove(at: index)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .sheet(isPresented: $showAddTimeBlock) {
            AddTimeBlockSheet(viewModel: viewModel)
        }
    }
}

private struct TimeBlockCard: View {
    let block: TimeBlockEntry
    let onDelete: () -> Void

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(block.period.capitalized)
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrPrimary)

                    Spacer()

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }

                if !block.activity.isEmpty {
                    HStack(alignment: .top) {
                        Text("Activity:")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text(block.activity)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                    }
                }

                if !block.location.isEmpty {
                    HStack(alignment: .top) {
                        Text("Location:")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text(block.location)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                    }
                }

                if !block.thoughts.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Thoughts:")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text(block.thoughts)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                    }
                }
            }
        }
    }
}

private struct AddTimeBlockSheet: View {
    @Bindable var viewModel: PostMortemViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var period = "morning"
    @State private var activity = ""
    @State private var location = ""
    @State private var company = ""
    @State private var thoughts = ""
    @State private var feelings = ""

    let periods = ["morning", "midday", "afternoon", "evening"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Time Period") {
                    Picker("Period", selection: $period) {
                        ForEach(periods, id: \.self) { period in
                            Text(period.capitalized).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    TextField("Activity", text: $activity)
                    TextField("Location", text: $location)
                    TextField("Company", text: $company)
                }

                Section("Internal State") {
                    TextField("Thoughts", text: $thoughts, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Feelings", text: $feelings, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Time Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let block = TimeBlockEntry(
                            period: period,
                            activity: activity,
                            location: location,
                            company: company,
                            thoughts: thoughts,
                            feelings: feelings
                        )
                        viewModel.timeBlocks.append(block)
                        dismiss()
                    }
                    .disabled(activity.isEmpty && thoughts.isEmpty)
                }
            }
        }
    }
}

// MARK: - Build-Up Section

private struct BuildUpSectionView: View {
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

                    TextEditor(text: $viewModel.buildUpFirstNoticed)
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
                        Text("Triggers")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        Spacer()

                        Button {
                            viewModel.buildUpTriggers.append(TriggerEntry())
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }

                    if viewModel.buildUpTriggers.isEmpty {
                        Text("Tap + to add triggers")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()
                    } else {
                        ForEach(Array(viewModel.buildUpTriggers.enumerated()), id: \.element.id) { index, trigger in
                            TriggerEntryView(trigger: binding(for: index)) {
                                viewModel.buildUpTriggers.remove(at: index)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Response to warnings (optional)")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    TextEditor(text: $viewModel.buildUpResponseToWarnings)
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

    private func binding(for index: Int) -> Binding<TriggerEntry> {
        Binding(
            get: { viewModel.buildUpTriggers[index] },
            set: { viewModel.buildUpTriggers[index] = $0 }
        )
    }
}

private struct TriggerEntryView: View {
    @Binding var trigger: TriggerEntry
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Category", selection: $trigger.category) {
                    Text("Select...").tag("")
                    ForEach(PostMortemViewModel.triggerCategories, id: \.self) { category in
                        Text(category.capitalized).tag(category)
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

            TextField("Surface trigger", text: $trigger.surface)
                .textFieldStyle(.roundedBorder)

            TextField("Underlying emotion", text: $trigger.underlying)
                .textFieldStyle(.roundedBorder)

            TextField("Core wound", text: $trigger.coreWound)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
        .background(Color.rrBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Acting Out Section

private struct ActingOutSectionView: View {
    @Bindable var viewModel: PostMortemViewModel
    let addictions: [RRAddiction]

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color.rrPrimary)
                        Text("This is a safe space")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()
                    }

                    Text("The Acting Out")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Describe what happened without graphic detail. What was the sequence of decisions?")
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

            if let linkedId = viewModel.actingOutLinkedRelapseId {
                RRCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Linked Relapse")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text(linkedId)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Immediately After Section

private struct ImmediatelyAfterSectionView: View {
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
                        ForEach(viewModel.afterFeelings, id: \.self) { feeling in
                            HStack(spacing: 4) {
                                Text(feeling)
                                    .font(RRFont.caption)
                                    .foregroundStyle(.white)
                                Button {
                                    viewModel.afterFeelings.removeAll { $0 == feeling }
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

                    TextEditor(text: $viewModel.afterWhatDidNext)
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
                    Toggle(isOn: $viewModel.afterReachedOut) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("I reached out to someone")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                    .tint(Color.rrPrimary)

                    if viewModel.afterReachedOut {
                        TextField("Who did you reach out to?", text: Binding(
                            get: { viewModel.afterReachedOutTo ?? "" },
                            set: { viewModel.afterReachedOutTo = $0.isEmpty ? nil : $0 }
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

                    TextEditor(text: $viewModel.afterWishDoneDifferently)
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
        guard !trimmed.isEmpty, !viewModel.afterFeelings.contains(trimmed) else { return }
        viewModel.afterFeelings.append(trimmed)
        newFeeling = ""
    }
}

// MARK: - Triggers Step

private struct TriggersStepView: View {
    @Bindable var viewModel: PostMortemViewModel

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Trigger Categories")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Select all that apply")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    FlowLayout(spacing: 10) {
                        ForEach(PostMortemViewModel.triggerCategories, id: \.self) { category in
                            Button {
                                viewModel.toggleTriggerCategory(category)
                            } label: {
                                Text(category.capitalized)
                                    .font(RRFont.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(viewModel.triggerSummary.contains(category) ? .white : Color.rrText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(viewModel.triggerSummary.contains(category) ? Color.rrPrimary : Color.rrSurface)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().strokeBorder(Color.rrTextSecondary.opacity(0.2), lineWidth: viewModel.triggerSummary.contains(category) ? 0 : 1)
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Detailed Triggers (optional)")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)

                        Spacer()

                        Button {
                            viewModel.addTrigger()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }

                    if viewModel.triggerDetails.isEmpty {
                        Text("Add detailed trigger analysis")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()
                    } else {
                        ForEach(Array(viewModel.triggerDetails.enumerated()), id: \.element.id) { index, _ in
                            TriggerEntryView(trigger: triggerBinding(for: index)) {
                                viewModel.removeTrigger(at: IndexSet(integer: index))
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
            get: { viewModel.triggerDetails[index] },
            set: { viewModel.triggerDetails[index] = $0 }
        )
    }
}

// MARK: - FASTER Mapping Step

private struct FasterMappingStepView: View {
    @Bindable var viewModel: PostMortemViewModel

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("FASTER Scale Mapping")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Map your journey through the FASTER stages (optional)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()

                    Button {
                        viewModel.addFasterMappingEntry()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Mapping Point")
                        }
                        .font(RRFont.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.rrPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .padding(.horizontal)

            if !viewModel.fasterMapping.isEmpty {
                ForEach(Array(viewModel.fasterMapping.enumerated()), id: \.element.id) { index, entry in
                    FasterMappingCard(entry: fasterBinding(for: index)) {
                        viewModel.removeFasterMappingEntry(at: IndexSet(integer: index))
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func fasterBinding(for index: Int) -> Binding<FasterMappingEntry> {
        Binding(
            get: { viewModel.fasterMapping[index] },
            set: { viewModel.fasterMapping[index] = $0 }
        )
    }
}

private struct FasterMappingCard: View {
    @Binding var entry: FasterMappingEntry
    let onDelete: () -> Void

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Mapping Point")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    Spacer()

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }

                TextField("Time of day", text: $entry.timeOfDay)
                    .textFieldStyle(.roundedBorder)

                Picker("FASTER Stage", selection: $entry.stage) {
                    Text("Select...").tag("")
                    ForEach(PostMortemViewModel.fasterStages, id: \.self) { stage in
                        Text(stage.capitalized).tag(stage)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

// MARK: - Action Plan Step

private struct ActionPlanStepView: View {
    @Bindable var viewModel: PostMortemViewModel

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Action Plan")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Create 1-10 action items to prevent this from happening again")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()

                    HStack {
                        Text("\(viewModel.actionItems.count) / 10")
                            .font(RRFont.subheadline)
                            .foregroundStyle(viewModel.actionItemCountValid ? Color.rrSuccess : Color.rrDestructive)

                        Spacer()

                        Button {
                            viewModel.addActionItem()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Action")
                            }
                            .font(RRFont.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrPrimary)
                        }
                        .disabled(viewModel.actionItems.count >= 10)
                    }
                }
            }
            .padding(.horizontal)

            if viewModel.actionItems.isEmpty {
                RRCard {
                    Text("Add at least one action item to continue")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                }
                .padding(.horizontal)
            } else {
                ForEach(Array(viewModel.actionItems.enumerated()), id: \.element.id) { index, item in
                    ActionItemCard(item: actionBinding(for: index)) {
                        viewModel.removeActionItem(at: IndexSet(integer: index))
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func actionBinding(for index: Int) -> Binding<ActionItemEntry> {
        Binding(
            get: { viewModel.actionItems[index] },
            set: { viewModel.actionItems[index] = $0 }
        )
    }
}

private struct ActionItemCard: View {
    @Binding var item: ActionItemEntry
    let onDelete: () -> Void

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Action \(item.timelinePoint)")
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

                TextField("Timeline point (e.g., morning, before bed)", text: $item.timelinePoint)
                    .textFieldStyle(.roundedBorder)

                TextField("Action to take", text: $item.action, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)

                Picker("Category", selection: $item.category) {
                    Text("Select...").tag("")
                    ForEach(PostMortemViewModel.actionCategories, id: \.self) { category in
                        Text(category.capitalized).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
}

// MARK: - Review Step

private struct ReviewStepView: View {
    @Bindable var viewModel: PostMortemViewModel
    let modelContext: ModelContext

    var body: some View {
        VStack(spacing: 16) {
            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Review & Complete")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("Review your post-mortem analysis before completing")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Section Completion")
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    ForEach(PostMortemViewModel.allSectionNames, id: \.self) { section in
                        HStack {
                            Image(systemName: viewModel.isSectionComplete(section) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.isSectionComplete(section) ? Color.rrSuccess : Color.rrTextSecondary)
                            Text(sectionDisplayName(section))
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal)

            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: viewModel.actionItemCountValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(viewModel.actionItemCountValid ? Color.rrSuccess : Color.rrDestructive)
                        Text("Action Items: \(viewModel.actionItems.count)")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)

            if !viewModel.canComplete {
                RRCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Validation Errors")
                            .font(RRFont.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrDestructive)

                        ForEach(viewModel.validateForCompletion(), id: \.self) { error in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(Color.rrDestructive)
                                Text(error)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrText)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                RRCard {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.rrSuccess)
                        Text("Ready to complete")
                            .font(RRFont.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrSuccess)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func sectionDisplayName(_ section: String) -> String {
        switch section {
        case "dayBefore": return "The Day Before"
        case "morning": return "Morning"
        case "throughoutTheDay": return "Throughout the Day"
        case "buildUp": return "The Build-Up"
        case "actingOut": return "The Acting Out"
        case "immediatelyAfter": return "Immediately After"
        default: return section
        }
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
