# Vision Statement — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Vision Statement feature — a guided wizard for creating a personal recovery vision, hub screen for viewing/editing, home screen card, version history, and morning commitment integration.

**Architecture:** Observable ViewModel drives a multi-step wizard (prompts, identity, values, scripture, review) with UserDefaults draft persistence, SwiftData for storage, and separate view files per step. Follows the Three Circles builder pattern.

**Tech Stack:** SwiftUI, SwiftData, Observation framework

**Specifications:** `docs/superpowers/specs/2026-04-18-vision-statement-design.md`

**Feature Flag:** `feature.vision` (already exists in `FeatureFlagStore.flagDefaults`, default `false`)

**Base path:** `ios/RegalRecovery/RegalRecovery`

---

## Task 1: Data Model & Types

**Files:**
- Modify: `Data/Models/RRModels.swift`
- Create: `Models/VisionTypes.swift`

- [ ] **Step 1: Add RRVisionStatement to RRModels.swift**

Add before the `// MARK: - Model Container Configuration` section (before line 1303):

```swift
// MARK: - Vision Statement

@Model
final class RRVisionStatement {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var identityStatement: String
    var visionBody: String
    var coreValues: [String]
    var scriptureReference: String?
    var scriptureText: String?
    var promptResponsesJSON: String?
    var version: Int
    var isCurrent: Bool
    var createdAt: Date
    var modifiedAt: Date

    var promptResponses: [String: String] {
        get {
            guard let json = promptResponsesJSON,
                  let data = json.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                promptResponsesJSON = json
            }
        }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        identityStatement: String,
        visionBody: String = "",
        coreValues: [String] = [],
        scriptureReference: String? = nil,
        scriptureText: String? = nil,
        promptResponsesJSON: String? = nil,
        version: Int = 1,
        isCurrent: Bool = true,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.identityStatement = identityStatement
        self.visionBody = visionBody
        self.coreValues = coreValues
        self.scriptureReference = scriptureReference
        self.scriptureText = scriptureText
        self.promptResponsesJSON = promptResponsesJSON
        self.version = version
        self.isCurrent = isCurrent
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
```

- [ ] **Step 2: Register in allModels**

Add `RRVisionStatement.self,` to the `allModels` array in `RRModelConfiguration`, after `RRDailyScore.self,` (line 1338):

```swift
        RRDailyScore.self,
        RRVisionStatement.self,
```

- [ ] **Step 3: Create VisionTypes.swift**

Create `Models/VisionTypes.swift`:

```swift
import Foundation

// MARK: - Wizard Step

enum VisionWizardStep: Equatable, Codable {
    case prompts(index: Int)
    case identity
    case values
    case scripture
    case review

    var title: String {
        switch self {
        case .prompts: return "Reflection"
        case .identity: return "Identity"
        case .values: return "Values"
        case .scripture: return "Scripture"
        case .review: return "Review"
        }
    }

    static let totalSteps = 8

    var progressIndex: Int {
        switch self {
        case .prompts(let index): return index + 1
        case .identity: return 5
        case .values: return 6
        case .scripture: return 7
        case .review: return 8
        }
    }

    var progressFraction: Double {
        Double(progressIndex) / Double(Self.totalSteps)
    }
}

// MARK: - Prompts

enum VisionPrompt: Int, CaseIterable {
    case oneYear = 0
    case relationships
    case timeAndEnergy
    case faithfulness

    var text: String {
        switch self {
        case .oneYear:
            return "What does your life look like one year from now if recovery goes well?"
        case .relationships:
            return "What kind of husband, father, or friend do you want to be?"
        case .timeAndEnergy:
            return "What would you do with your time and energy if addiction no longer consumed it?"
        case .faithfulness:
            return "What does faithfulness to God look like in your daily life?"
        }
    }

    static let maxLength = 500
}

// MARK: - Curated Values

enum CuratedValue: String, CaseIterable {
    case honesty = "Honesty"
    case integrity = "Integrity"
    case humility = "Humility"
    case courage = "Courage"
    case faithfulness = "Faithfulness"
    case service = "Service"
    case patience = "Patience"
    case gratitude = "Gratitude"
    case vulnerability = "Vulnerability"
    case discipline = "Discipline"
    case compassion = "Compassion"
    case selfControl = "Self-Control"
    case perseverance = "Perseverance"
    case wisdom = "Wisdom"
    case gentleness = "Gentleness"
}

// MARK: - Scripture Library

enum ScriptureCategory: String, CaseIterable, Codable {
    case identity = "Identity"
    case hope = "Hope"
    case transformation = "Transformation"
    case strength = "Strength"
    case freedom = "Freedom"
    case faithfulness = "Faithfulness"
}

struct ScriptureEntry: Identifiable {
    let id = UUID()
    let reference: String
    let text: String
    let category: ScriptureCategory
}

enum ScriptureLibrary {
    static let entries: [ScriptureEntry] = [
        // Identity
        ScriptureEntry(reference: "2 Corinthians 5:17", text: "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!", category: .identity),
        ScriptureEntry(reference: "Ephesians 2:10", text: "For we are God's handiwork, created in Christ Jesus to do good works.", category: .identity),
        ScriptureEntry(reference: "1 Peter 2:9", text: "But you are a chosen people, a royal priesthood, a holy nation, God's special possession.", category: .identity),
        ScriptureEntry(reference: "Psalm 139:14", text: "I praise you because I am fearfully and wonderfully made.", category: .identity),

        // Hope
        ScriptureEntry(reference: "Jeremiah 29:11", text: "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.", category: .hope),
        ScriptureEntry(reference: "Romans 8:28", text: "And we know that in all things God works for the good of those who love him.", category: .hope),
        ScriptureEntry(reference: "Lamentations 3:22-23", text: "Because of the Lord's great love we are not consumed, for his compassions never fail. They are new every morning.", category: .hope),
        ScriptureEntry(reference: "Romans 15:13", text: "May the God of hope fill you with all joy and peace as you trust in him.", category: .hope),

        // Transformation
        ScriptureEntry(reference: "Romans 12:2", text: "Do not conform to the pattern of this world, but be transformed by the renewing of your mind.", category: .transformation),
        ScriptureEntry(reference: "Philippians 1:6", text: "Being confident of this, that he who began a good work in you will carry it on to completion.", category: .transformation),
        ScriptureEntry(reference: "Ezekiel 36:26", text: "I will give you a new heart and put a new spirit in you.", category: .transformation),
        ScriptureEntry(reference: "2 Corinthians 3:18", text: "And we all, who with unveiled faces contemplate the Lord's glory, are being transformed into his image.", category: .transformation),

        // Strength
        ScriptureEntry(reference: "Philippians 4:13", text: "I can do all this through him who gives me strength.", category: .strength),
        ScriptureEntry(reference: "Isaiah 40:31", text: "But those who hope in the Lord will renew their strength. They will soar on wings like eagles.", category: .strength),
        ScriptureEntry(reference: "2 Timothy 1:7", text: "For the Spirit God gave us does not make us timid, but gives us power, love and self-discipline.", category: .strength),
        ScriptureEntry(reference: "Psalm 46:1", text: "God is our refuge and strength, an ever-present help in trouble.", category: .strength),

        // Freedom
        ScriptureEntry(reference: "Galatians 5:1", text: "It is for freedom that Christ has set us free. Stand firm, then, and do not let yourselves be burdened again by a yoke of slavery.", category: .freedom),
        ScriptureEntry(reference: "John 8:36", text: "So if the Son sets you free, you will be free indeed.", category: .freedom),
        ScriptureEntry(reference: "Romans 6:14", text: "For sin shall no longer be your master, because you are not under the law, but under grace.", category: .freedom),
        ScriptureEntry(reference: "Psalm 107:14", text: "He brought them out of darkness, the utter darkness, and broke away their chains.", category: .freedom),

        // Faithfulness
        ScriptureEntry(reference: "Proverbs 29:18", text: "Where there is no vision, the people perish; but he that keepeth the law, happy is he.", category: .faithfulness),
        ScriptureEntry(reference: "Proverbs 3:5-6", text: "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him.", category: .faithfulness),
        ScriptureEntry(reference: "Micah 6:8", text: "He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy and to walk humbly with your God.", category: .faithfulness),
        ScriptureEntry(reference: "Psalm 119:105", text: "Your word is a lamp for my feet, a light on my path.", category: .faithfulness),
    ]

    static func filtered(by category: ScriptureCategory?) -> [ScriptureEntry] {
        guard let category else { return entries }
        return entries.filter { $0.category == category }
    }

    static func search(_ query: String) -> [ScriptureEntry] {
        let lowered = query.lowercased()
        return entries.filter {
            $0.reference.lowercased().contains(lowered) ||
            $0.text.lowercased().contains(lowered)
        }
    }
}

// MARK: - Character Limits

enum VisionLimits {
    static let identityMaxLength = 280
    static let visionBodyMaxLength = 2000
    static let promptMaxLength = 500
    static let maxValues = 10
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(ios): add RRVisionStatement model and VisionTypes"
```

---

## Task 2: Vision Wizard ViewModel

**Files:**
- Create: `ViewModels/VisionWizardViewModel.swift`

- [ ] **Step 1: Create VisionWizardViewModel.swift**

```swift
import Foundation
import Observation
import SwiftData

@Observable
final class VisionWizardViewModel {

    // MARK: - Flow State

    var currentStep: VisionWizardStep = .prompts(index: 0)

    // MARK: - Data

    var promptResponses: [Int: String] = [:]
    var identityStatement: String = ""
    var visionBody: String = ""
    var selectedValues: [String] = []
    var scriptureReference: String? = nil
    var scriptureText: String? = nil

    // MARK: - Editing

    var editingVisionId: UUID?

    // MARK: - UI State

    var showResumeAlert: Bool = false

    // MARK: - Persistence Key

    private static let draftKey = "vision.wizard.draft"

    // MARK: - Init

    init() {}

    init(editing vision: RRVisionStatement) {
        editingVisionId = vision.id
        identityStatement = vision.identityStatement
        visionBody = vision.visionBody
        selectedValues = vision.coreValues
        scriptureReference = vision.scriptureReference
        scriptureText = vision.scriptureText

        let responses = vision.promptResponses
        for (key, value) in responses {
            if let index = Int(key) {
                promptResponses[index] = value
            }
        }

        currentStep = .review
    }

    // MARK: - Navigation

    var canProceed: Bool {
        switch currentStep {
        case .prompts:
            return true
        case .identity:
            return !identityStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .values:
            return !selectedValues.isEmpty
        case .scripture:
            return true
        case .review:
            return !identityStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var canGoBack: Bool {
        switch currentStep {
        case .prompts(let index):
            return index > 0
        default:
            return true
        }
    }

    var canSkip: Bool {
        switch currentStep {
        case .prompts, .scripture:
            return true
        case .identity, .values, .review:
            return false
        }
    }

    func goToNextStep() {
        saveDraft()
        switch currentStep {
        case .prompts(let index):
            if index < VisionPrompt.allCases.count - 1 {
                currentStep = .prompts(index: index + 1)
            } else {
                currentStep = .identity
            }
        case .identity:
            currentStep = .values
        case .values:
            currentStep = .scripture
        case .scripture:
            currentStep = .review
        case .review:
            break
        }
    }

    func goToPreviousStep() {
        switch currentStep {
        case .prompts(let index):
            if index > 0 {
                currentStep = .prompts(index: index - 1)
            }
        case .identity:
            currentStep = .prompts(index: VisionPrompt.allCases.count - 1)
        case .values:
            currentStep = .identity
        case .scripture:
            currentStep = .values
        case .review:
            currentStep = .scripture
        }
    }

    func skipCurrentStep() {
        guard canSkip else { return }
        goToNextStep()
    }

    // MARK: - Values Management

    func toggleValue(_ value: String) {
        if let index = selectedValues.firstIndex(of: value) {
            selectedValues.remove(at: index)
        } else if selectedValues.count < VisionLimits.maxValues {
            selectedValues.append(value)
        }
    }

    func moveValue(from source: IndexSet, to destination: Int) {
        selectedValues.move(fromOffsets: source, toOffset: destination)
    }

    var isAtValueLimit: Bool {
        selectedValues.count >= VisionLimits.maxValues
    }

    // MARK: - Save

    func save(context: ModelContext, userId: UUID) {
        let trimmedIdentity = identityStatement.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = visionBody.trimmingCharacters(in: .whitespacesAndNewlines)

        var responsesDict: [String: String] = [:]
        for (index, text) in promptResponses {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                responsesDict[String(index)] = trimmed
            }
        }
        let responsesJSON: String? = {
            guard !responsesDict.isEmpty,
                  let data = try? JSONEncoder().encode(responsesDict),
                  let json = String(data: data, encoding: .utf8) else { return nil }
            return json
        }()

        // Determine version number
        var newVersion = 1
        if let editingId = editingVisionId {
            let descriptor = FetchDescriptor<RRVisionStatement>(
                predicate: #Predicate { $0.id == editingId }
            )
            if let existing = try? context.fetch(descriptor).first {
                newVersion = existing.version + 1
                existing.isCurrent = false
            }
        } else {
            let descriptor = FetchDescriptor<RRVisionStatement>(
                predicate: #Predicate { $0.isCurrent == true }
            )
            if let existing = try? context.fetch(descriptor).first {
                newVersion = existing.version + 1
                existing.isCurrent = false
            }
        }

        let statement = RRVisionStatement(
            userId: userId,
            identityStatement: trimmedIdentity,
            visionBody: trimmedBody,
            coreValues: selectedValues,
            scriptureReference: scriptureReference,
            scriptureText: scriptureText,
            promptResponsesJSON: responsesJSON,
            version: newVersion,
            isCurrent: true
        )
        context.insert(statement)

        clearDraft()
    }

    // MARK: - Draft Persistence

    func saveDraft() {
        let draft = VisionDraft(
            currentStep: currentStep,
            promptResponses: promptResponses,
            identityStatement: identityStatement,
            visionBody: visionBody,
            selectedValues: selectedValues,
            scriptureReference: scriptureReference,
            scriptureText: scriptureText,
            editingVisionId: editingVisionId
        )
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: Self.draftKey)
        }
    }

    func resumeDraft() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.draftKey),
              let draft = try? JSONDecoder().decode(VisionDraft.self, from: data) else {
            return false
        }
        currentStep = draft.currentStep
        promptResponses = draft.promptResponses
        identityStatement = draft.identityStatement
        visionBody = draft.visionBody
        selectedValues = draft.selectedValues
        scriptureReference = draft.scriptureReference
        scriptureText = draft.scriptureText
        editingVisionId = draft.editingVisionId
        return true
    }

    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: Self.draftKey)
    }

    var hasSavedDraft: Bool {
        UserDefaults.standard.data(forKey: Self.draftKey) != nil
    }
}

// MARK: - Draft Model

private struct VisionDraft: Codable {
    let currentStep: VisionWizardStep
    let promptResponses: [Int: String]
    let identityStatement: String
    let visionBody: String
    let selectedValues: [String]
    let scriptureReference: String?
    let scriptureText: String?
    let editingVisionId: UUID?
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(ios): add VisionWizardViewModel with draft persistence"
```

---

## Task 3: Vision Wizard Container View

**Files:**
- Create: `Views/Tools/Vision/VisionWizardView.swift`

- [ ] **Step 1: Create VisionWizardView.swift**

```swift
import SwiftUI
import SwiftData

struct VisionWizardView: View {
    @State var viewModel: VisionWizardViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var showResumeAlert = false

    init(editing vision: RRVisionStatement? = nil) {
        if let vision {
            _viewModel = State(initialValue: VisionWizardViewModel(editing: vision))
        } else {
            _viewModel = State(initialValue: VisionWizardViewModel())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rrBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    progressBar
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    stepContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if !isReviewStep {
                        navigationBar
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        viewModel.saveDraft()
                        dismiss()
                    }
                    .foregroundStyle(Color.rrTextSecondary)
                }
            }
            .alert("Resume Previous Work?", isPresented: $showResumeAlert) {
                Button("Resume") {
                    _ = viewModel.resumeDraft()
                }
                Button("Start Fresh", role: .destructive) {
                    viewModel.clearDraft()
                }
            } message: {
                Text("You have a saved draft from a previous session. Would you like to continue where you left off?")
            }
            .onAppear {
                if viewModel.editingVisionId == nil && viewModel.hasSavedDraft {
                    showResumeAlert = true
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Step \(viewModel.currentStep.progressIndex) of \(VisionWizardStep.totalSteps)")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rrSurface)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rrPrimary)
                        .frame(width: geometry.size.width * viewModel.currentStep.progressFraction, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep.progressFraction)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .prompts(let index):
            VisionPromptsStepView(viewModel: viewModel, promptIndex: index)

        case .identity:
            VisionIdentityStepView(viewModel: viewModel)

        case .values:
            VisionValuesStepView(viewModel: viewModel)

        case .scripture:
            VisionScriptureStepView(viewModel: viewModel)

        case .review:
            VisionReviewStepView(viewModel: viewModel) {
                let userId = users.first?.id ?? UUID()
                viewModel.save(context: modelContext, userId: userId)
                dismiss()
            }
        }
    }

    // MARK: - Navigation Bar

    private var isReviewStep: Bool {
        if case .review = viewModel.currentStep { return true }
        return false
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            if viewModel.canGoBack {
                Button {
                    viewModel.goToPreviousStep()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                        Text("Back")
                            .font(RRFont.body)
                    }
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }

            Spacer()

            if viewModel.canSkip {
                Button {
                    viewModel.skipCurrentStep()
                } label: {
                    Text("Skip")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }

            Button {
                viewModel.goToNextStep()
            } label: {
                HStack(spacing: 4) {
                    Text("Next")
                        .font(RRFont.body)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(minHeight: 44)
                .background(viewModel.canProceed ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!viewModel.canProceed)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VisionWizardView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: Will fail because step views don't exist yet — that's expected. Verify no syntax errors by checking the error is only about missing types `VisionPromptsStepView`, `VisionIdentityStepView`, `VisionValuesStepView`, `VisionScriptureStepView`, `VisionReviewStepView`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(ios): add VisionWizardView container with progress and navigation"
```

---

## Task 4: Wizard Step Views — Prompts & Identity

**Files:**
- Create: `Views/Tools/Vision/VisionPromptsStepView.swift`
- Create: `Views/Tools/Vision/VisionIdentityStepView.swift`

- [ ] **Step 1: Create VisionPromptsStepView.swift**

```swift
import SwiftUI

struct VisionPromptsStepView: View {
    @Bindable var viewModel: VisionWizardViewModel
    let promptIndex: Int

    private var prompt: VisionPrompt? {
        VisionPrompt(rawValue: promptIndex)
    }

    private var responseBinding: Binding<String> {
        Binding(
            get: { viewModel.promptResponses[promptIndex] ?? "" },
            set: { viewModel.promptResponses[promptIndex] = $0 }
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let prompt {
                    Text(prompt.text)
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .trailing, spacing: 8) {
                    TextEditor(text: responseBinding)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onChange(of: responseBinding.wrappedValue) { _, newValue in
                            if newValue.count > VisionPrompt.maxLength {
                                viewModel.promptResponses[promptIndex] = String(newValue.prefix(VisionPrompt.maxLength))
                            }
                        }

                    Text("\(responseBinding.wrappedValue.count)/\(VisionPrompt.maxLength)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Text("Take your time. There are no wrong answers.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .italic()
            }
            .padding()
        }
    }
}

#Preview {
    VisionPromptsStepView(viewModel: VisionWizardViewModel(), promptIndex: 0)
}
```

- [ ] **Step 2: Create VisionIdentityStepView.swift**

```swift
import SwiftUI

struct VisionIdentityStepView: View {
    @Bindable var viewModel: VisionWizardViewModel

    private let sampleStatements = [
        "...a man of integrity who keeps his word.",
        "...a present and loving father.",
        "...free from shame and walking in truth.",
        "...a faithful husband who honors his vows.",
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("I am becoming...")
                    .font(RRFont.largeTitle)
                    .foregroundStyle(Color.rrPrimary)

                Text("Complete this sentence with the identity you are growing into.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)

                VStack(alignment: .trailing, spacing: 8) {
                    TextField("...a man who...", text: $viewModel.identityStatement, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onChange(of: viewModel.identityStatement) { _, newValue in
                            if newValue.count > VisionLimits.identityMaxLength {
                                viewModel.identityStatement = String(newValue.prefix(VisionLimits.identityMaxLength))
                            }
                        }

                    Text("\(viewModel.identityStatement.count)/\(VisionLimits.identityMaxLength)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("For inspiration:")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    FlowLayout(spacing: 8) {
                        ForEach(sampleStatements, id: \.self) { sample in
                            Button {
                                if viewModel.identityStatement.isEmpty {
                                    viewModel.identityStatement = sample
                                }
                            } label: {
                                Text(sample)
                                    .font(RRFont.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(Color.rrPrimary)
                                    .background(Color.rrPrimary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    VisionIdentityStepView(viewModel: VisionWizardViewModel())
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: Still fails due to missing `VisionValuesStepView`, `VisionScriptureStepView`, `VisionReviewStepView` — that's expected.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(ios): add VisionPromptsStepView and VisionIdentityStepView"
```

---

## Task 5: Wizard Step Views — Values & Scripture

**Files:**
- Create: `Views/Tools/Vision/VisionValuesStepView.swift`
- Create: `Views/Tools/Vision/VisionScriptureStepView.swift`

- [ ] **Step 1: Create VisionValuesStepView.swift**

```swift
import SwiftUI

struct VisionValuesStepView: View {
    @Bindable var viewModel: VisionWizardViewModel
    @State private var customValueText = ""
    @State private var showCustomField = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("What values guide your recovery?")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text("Select up to \(VisionLimits.maxValues) values. Drag to reorder by priority.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)

                // Curated values grid
                FlowLayout(spacing: 8) {
                    ForEach(CuratedValue.allCases, id: \.rawValue) { value in
                        valueChip(value.rawValue)
                    }
                }

                // Custom values already added (that aren't curated)
                let customValues = viewModel.selectedValues.filter { val in
                    !CuratedValue.allCases.contains(where: { $0.rawValue == val })
                }
                if !customValues.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(customValues, id: \.self) { value in
                            valueChip(value)
                        }
                    }
                }

                // Add custom value
                if showCustomField {
                    HStack {
                        TextField("Custom value", text: $customValueText)
                            .padding(10)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Button {
                            let trimmed = customValueText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty && !viewModel.selectedValues.contains(trimmed) {
                                viewModel.toggleValue(trimmed)
                                customValueText = ""
                                showCustomField = false
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.rrPrimary)
                        }
                        .disabled(customValueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } else {
                    Button {
                        showCustomField = true
                    } label: {
                        Label("Add Custom Value", systemImage: "plus")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrPrimary)
                    }
                    .disabled(viewModel.isAtValueLimit)
                }

                if viewModel.isAtValueLimit {
                    Text("Maximum \(VisionLimits.maxValues) values selected.")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrDestructive)
                }

                // Selected values — reorderable list
                if !viewModel.selectedValues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your values (drag to reorder)")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        List {
                            ForEach(viewModel.selectedValues, id: \.self) { value in
                                HStack {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundStyle(Color.rrTextSecondary)
                                    Text(value)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                    Spacer()
                                    if let index = viewModel.selectedValues.firstIndex(of: value), index < 5 {
                                        RRBadge(text: "#\(index + 1)", color: .rrPrimary)
                                    }
                                }
                            }
                            .onMove { source, destination in
                                viewModel.moveValue(from: source, to: destination)
                            }
                        }
                        .listStyle(.plain)
                        .frame(minHeight: CGFloat(viewModel.selectedValues.count) * 50)
                    }
                }
            }
            .padding()
        }
    }

    private func valueChip(_ value: String) -> some View {
        let isSelected = viewModel.selectedValues.contains(value)
        let isDisabled = !isSelected && viewModel.isAtValueLimit

        return Button {
            viewModel.toggleValue(value)
        } label: {
            Text(value)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : (isDisabled ? Color.rrTextSecondary.opacity(0.5) : Color.rrPrimary))
                .background(isSelected ? Color.rrPrimary : (isDisabled ? Color.rrSurface.opacity(0.5) : Color.rrPrimary.opacity(0.1)))
                .clipShape(Capsule())
        }
        .disabled(isDisabled)
    }
}

#Preview {
    VisionValuesStepView(viewModel: VisionWizardViewModel())
}
```

- [ ] **Step 2: Create VisionScriptureStepView.swift**

```swift
import SwiftUI

struct VisionScriptureStepView: View {
    @Bindable var viewModel: VisionWizardViewModel
    @State private var selectedCategory: ScriptureCategory? = nil
    @State private var searchText = ""
    @State private var showCustomEntry = false
    @State private var customReference = ""
    @State private var customText = ""

    private var filteredEntries: [ScriptureEntry] {
        if !searchText.isEmpty {
            return ScriptureLibrary.search(searchText)
        }
        return ScriptureLibrary.filtered(by: selectedCategory)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Anchor your vision in Scripture")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text("Choose a verse that speaks to the man you are becoming. This is optional.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("Search verses...", text: $searchText)
                }
                .padding(10)
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Category filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryChip(nil, label: "All")
                        ForEach(ScriptureCategory.allCases, id: \.rawValue) { category in
                            categoryChip(category, label: category.rawValue)
                        }
                    }
                }

                // Verse list
                LazyVStack(spacing: 12) {
                    ForEach(filteredEntries) { entry in
                        scriptureRow(entry)
                    }
                }

                // Custom entry
                Divider()

                Button {
                    showCustomEntry.toggle()
                } label: {
                    Label("Or enter your own", systemImage: showCustomEntry ? "chevron.up" : "chevron.down")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrPrimary)
                }

                if showCustomEntry {
                    VStack(spacing: 12) {
                        TextField("Reference (e.g., John 3:16)", text: $customReference)
                            .padding(10)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        TextField("Verse text", text: $customText, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(10)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Button {
                            let ref = customReference.trimmingCharacters(in: .whitespacesAndNewlines)
                            let txt = customText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !ref.isEmpty {
                                viewModel.scriptureReference = ref
                                viewModel.scriptureText = txt.isEmpty ? nil : txt
                            }
                        } label: {
                            Text("Use This Verse")
                                .font(RRFont.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(customReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.rrTextSecondary.opacity(0.3) : Color.rrPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .disabled(customReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                // Current selection
                if let ref = viewModel.scriptureReference {
                    RRCard {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.rrSuccess)
                                Text("Selected")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrSuccess)
                                Spacer()
                                Button {
                                    viewModel.scriptureReference = nil
                                    viewModel.scriptureText = nil
                                } label: {
                                    Image(systemName: "xmark.circle")
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                            }
                            Text(ref)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            if let text = viewModel.scriptureText {
                                Text(text)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .italic()
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func categoryChip(_ category: ScriptureCategory?, label: String) -> some View {
        let isActive = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isActive ? .white : Color.rrPrimary)
                .background(isActive ? Color.rrPrimary : Color.rrPrimary.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private func scriptureRow(_ entry: ScriptureEntry) -> some View {
        let isSelected = viewModel.scriptureReference == entry.reference

        return Button {
            viewModel.scriptureReference = entry.reference
            viewModel.scriptureText = entry.text
        } label: {
            RRCard {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.reference)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.rrSuccess)
                        }
                    }
                    Text(entry.text)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                        .lineLimit(3)
                    RRBadge(text: entry.category.rawValue, color: .rrPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VisionScriptureStepView(viewModel: VisionWizardViewModel())
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: Still fails due to missing `VisionReviewStepView` — expected.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(ios): add VisionValuesStepView and VisionScriptureStepView"
```

---

## Task 6: Wizard Step View — Review

**Files:**
- Create: `Views/Tools/Vision/VisionReviewStepView.swift`

- [ ] **Step 1: Create VisionReviewStepView.swift**

```swift
import SwiftUI

struct VisionReviewStepView: View {
    @Bindable var viewModel: VisionWizardViewModel
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Review Your Vision")
                    .font(RRFont.largeTitle)
                    .foregroundStyle(Color.rrText)

                Text("Your vision is not a promise you are making. It is a direction you are facing.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .italic()

                // Identity Statement
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("I am becoming...")
                    Text(viewModel.identityStatement)
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Vision Body
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("My Vision")
                    if viewModel.visionBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        TextField("Write your full vision here (optional)...", text: $viewModel.visionBody, axis: .vertical)
                            .lineLimit(4...10)
                            .padding(12)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .onChange(of: viewModel.visionBody) { _, newValue in
                                if newValue.count > VisionLimits.visionBodyMaxLength {
                                    viewModel.visionBody = String(newValue.prefix(VisionLimits.visionBodyMaxLength))
                                }
                            }

                        Text("\(viewModel.visionBody.count)/\(VisionLimits.visionBodyMaxLength)")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        Text(viewModel.visionBody)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Prompt Responses
                let nonEmpty = viewModel.promptResponses.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                if !nonEmpty.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("Reflections")
                        ForEach(nonEmpty.sorted(by: { $0.key < $1.key }), id: \.key) { index, response in
                            if let prompt = VisionPrompt(rawValue: index) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(prompt.text)
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                    Text(response)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.rrSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }

                // Values
                if !viewModel.selectedValues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Core Values")
                        FlowLayout(spacing: 8) {
                            ForEach(Array(viewModel.selectedValues.enumerated()), id: \.element) { index, value in
                                HStack(spacing: 4) {
                                    if index < 5 {
                                        Text("#\(index + 1)")
                                            .font(RRFont.caption2)
                                            .fontWeight(.bold)
                                    }
                                    Text(value)
                                        .font(RRFont.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(.white)
                                .background(Color.rrPrimary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Scripture
                if let ref = viewModel.scriptureReference {
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("Scripture")
                        Text(ref)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        if let text = viewModel.scriptureText {
                            Text(text)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrTextSecondary)
                                .italic()
                        }
                    }
                }

                // Save button
                RRButton("Save Vision", icon: "checkmark.circle") {
                    onSave()
                }
                .disabled(!viewModel.canProceed)
                .padding(.top, 8)
            }
            .padding()
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(RRFont.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.rrTextSecondary)
            .tracking(1)
    }
}

#Preview {
    VisionReviewStepView(viewModel: VisionWizardViewModel()) {}
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED — all wizard step views now exist.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(ios): add VisionReviewStepView — wizard flow complete"
```

---

## Task 7: Vision Hub View

**Files:**
- Create: `Views/Tools/Vision/VisionHubView.swift`
- Create: `Views/Tools/Vision/VisionHistoryView.swift`

- [ ] **Step 1: Create VisionHubView.swift**

```swift
import SwiftUI
import SwiftData

struct VisionHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<RRVisionStatement> { $0.isCurrent == true })
    private var currentVisions: [RRVisionStatement]

    @State private var showWizard = false
    @State private var showDeleteConfirmation = false
    @State private var isExpanded = false

    private var currentVision: RRVisionStatement? {
        currentVisions.first
    }

    var body: some View {
        ScrollView {
            if let vision = currentVision {
                populatedState(vision)
            } else {
                emptyState
            }
        }
        .background(Color.rrBackground)
        .navigationTitle("Vision Statement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if currentVision != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink {
                            VisionHistoryView()
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(Color.rrPrimary)
                        }

                        Button {
                            showWizard = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showWizard) {
            if let vision = currentVision {
                VisionWizardView(editing: vision)
            } else {
                VisionWizardView()
            }
        }
        .alert("Delete Vision Statement?", isPresented: $showDeleteConfirmation) {
            Button("Delete All Versions", role: .destructive) {
                deleteAllVisions()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove your vision statement and all previous versions.")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "eye.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrPrimary)

            Text("Your recovery needs a destination")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)

            Text("A vision statement answers:\nWhat kind of man am I becoming?")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)

            RRButton("Create My Vision", icon: "plus") {
                showWizard = true
            }
            .padding(.horizontal, 32)

            Text("Your vision is not a promise you are making.\nIt is a direction you are facing.")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer()
        }
        .padding()
    }

    // MARK: - Populated State

    private func populatedState(_ vision: RRVisionStatement) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    // Identity statement
                    Text("I am becoming...")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    Text(vision.identityStatement)
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Vision body
                    if !vision.visionBody.isEmpty {
                        Divider()
                        if isExpanded || vision.visionBody.count <= 200 {
                            Text(vision.visionBody)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text(vision.visionBody)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .lineLimit(4)

                            Button {
                                withAnimation { isExpanded = true }
                            } label: {
                                Text("Read more")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrPrimary)
                            }
                        }
                    }

                    // Values
                    if !vision.coreValues.isEmpty {
                        Divider()
                        FlowLayout(spacing: 8) {
                            ForEach(Array(vision.coreValues.enumerated()), id: \.element) { index, value in
                                Text(value)
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .foregroundStyle(index < 5 ? .white : Color.rrPrimary)
                                    .background(index < 5 ? Color.rrPrimary : Color.rrPrimary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    // Scripture
                    if let ref = vision.scriptureReference {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ref)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            if let text = vision.scriptureText {
                                Text(text)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .italic()
                            }
                        }
                    }
                }
            }

            // Last updated
            let daysAgo = Calendar.current.dateComponents([.day], from: vision.modifiedAt, to: Date()).day ?? 0
            let updateText = daysAgo == 0 ? "Updated today" : "Last updated \(daysAgo) day\(daysAgo == 1 ? "" : "s") ago"
            Text(updateText)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .frame(maxWidth: .infinity, alignment: .center)

            // Delete option
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Text("Delete Vision Statement")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrDestructive)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 8)
        }
        .padding()
    }

    private func deleteAllVisions() {
        let descriptor = FetchDescriptor<RRVisionStatement>()
        if let allVisions = try? modelContext.fetch(descriptor) {
            for vision in allVisions {
                modelContext.delete(vision)
            }
        }
    }
}

#Preview {
    NavigationStack {
        VisionHubView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
```

- [ ] **Step 2: Create VisionHistoryView.swift**

```swift
import SwiftUI
import SwiftData

struct VisionHistoryView: View {
    @Query(sort: \RRVisionStatement.version, order: .reverse)
    private var allVersions: [RRVisionStatement]

    @State private var selectedVersion: RRVisionStatement?

    var body: some View {
        ScrollView {
            if allVersions.isEmpty {
                Text("No version history yet.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(allVersions) { vision in
                        Button {
                            selectedVersion = vision
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                // Timeline indicator
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(vision.isCurrent ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                    if vision.id != allVersions.last?.id {
                                        Rectangle()
                                            .fill(Color.rrTextSecondary.opacity(0.2))
                                            .frame(width: 2)
                                            .frame(maxHeight: .infinity)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Version \(vision.version)")
                                            .font(RRFont.headline)
                                            .foregroundStyle(Color.rrText)
                                        if vision.isCurrent {
                                            RRBadge(text: "Current", color: .rrPrimary)
                                        }
                                        Spacer()
                                    }

                                    Text(vision.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)

                                    Text(String(vision.identityStatement.prefix(100)))
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .lineLimit(2)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.rrBackground)
        .navigationTitle("Version History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedVersion) { vision in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Version \(vision.version)")
                            .font(RRFont.title)
                            .foregroundStyle(Color.rrText)

                        Text(vision.modifiedAt.formatted(date: .long, time: .shortened))
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        Divider()

                        Text("I am becoming...")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text(vision.identityStatement)
                            .font(RRFont.title)
                            .foregroundStyle(Color.rrPrimary)

                        if !vision.visionBody.isEmpty {
                            Text(vision.visionBody)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }

                        if !vision.coreValues.isEmpty {
                            Divider()
                            FlowLayout(spacing: 8) {
                                ForEach(vision.coreValues, id: \.self) { value in
                                    Text(value)
                                        .font(RRFont.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .foregroundStyle(Color.rrPrimary)
                                        .background(Color.rrPrimary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        if let ref = vision.scriptureReference {
                            Divider()
                            Text(ref)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            if let text = vision.scriptureText {
                                Text(text)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .italic()
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.rrBackground)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { selectedVersion = nil }
                    }
                }
            }
            .presentationDetents([.large])
        }
    }
}

#Preview {
    NavigationStack {
        VisionHistoryView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(ios): add VisionHubView and VisionHistoryView"
```

---

## Task 8: Home Screen Card

**Files:**
- Create: `Views/Home/VisionCard.swift`
- Modify: `Views/Home/HomeView.swift`

- [ ] **Step 1: Create VisionCard.swift**

```swift
import SwiftUI
import SwiftData

struct VisionCard: View {
    let identityStatement: String
    let scriptureReference: String?

    var body: some View {
        NavigationLink {
            VisionHubView()
        } label: {
            RRCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                            .foregroundStyle(Color.rrPrimary)
                        Text("My Vision")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Text("I am becoming \(identityStatement)")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    if let ref = scriptureReference {
                        Text(ref)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .italic()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.rrPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VisionCard(
        identityStatement: "a man of integrity who keeps his word",
        scriptureReference: "Proverbs 29:18"
    )
    .padding()
}
```

- [ ] **Step 2: Add VisionCard to HomeView**

In `HomeView.swift`, add a `@Query` for the current vision statement after the existing queries (after line 18):

```swift
    @Query(filter: #Predicate<RRVisionStatement> { $0.isCurrent == true })
    private var currentVisions: [RRVisionStatement]
```

Then in the `body`, add the vision card after `CommitmentsCard(status: commitmentStatus)` (after line 110) and before `QuickActionsRow()`:

```swift
                    if FeatureFlagStore.shared.isEnabled("feature.vision"),
                       let vision = currentVisions.first {
                        VisionCard(
                            identityStatement: vision.identityStatement,
                            scriptureReference: vision.scriptureReference
                        )
                    }
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(ios): add VisionCard to home screen"
```

---

## Task 9: ToolsView Integration

**Files:**
- Modify: `Views/Tools/ToolsView.swift`

- [ ] **Step 1: Add Vision Statement tool card to ToolsView**

In `ToolsView.swift`, inside the `LazyVGrid` (after the Panic Button `toolCard` at line 33, before the closing `}`), add:

```swift
                    if FeatureFlagStore.shared.isEnabled("feature.vision") {
                        toolCard(
                            destination: VisionHubView(),
                            icon: "eye.fill",
                            iconColor: .rrPrimary,
                            title: "Vision",
                            subtitle: "Your Recovery Why"
                        )
                    }
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(ios): add Vision Statement to ToolsView"
```

---

## Task 10: Morning Commitment Integration

**Files:**
- Modify: `Views/Activities/MorningCommitmentView.swift`

- [ ] **Step 1: Add vision snippet to MorningCommitmentView**

In `MorningCommitmentView.swift`, add a `@Query` for the current vision after the existing queries (after line 11):

```swift
    @Query(filter: #Predicate<RRVisionStatement> { $0.isCurrent == true })
    private var currentVisions: [RRVisionStatement]
```

Then, after the closing `}` of the outer `RRCard` block (after line 85, before `.padding(.horizontal)`), add:

```swift
                // Vision snippet (P1)
                if FeatureFlagStore.shared.isEnabled("feature.vision"),
                   let vision = currentVisions.first {
                    NavigationLink {
                        VisionHubView()
                    } label: {
                        RRCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.rrPrimary)
                                    Text("Your Vision")
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                                Text("I am becoming \(vision.identityStatement)")
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                                    .lineLimit(2)
                                Text("Tap to read full vision")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(ios): add vision snippet to MorningCommitmentView"
```

---

## Task 11: Xcode Project File Updates

**Files:**
- Modify: `RegalRecovery.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add all new Swift files to the Xcode project**

The new files to add:
- `Models/VisionTypes.swift`
- `ViewModels/VisionWizardViewModel.swift`
- `Views/Tools/Vision/VisionWizardView.swift`
- `Views/Tools/Vision/VisionPromptsStepView.swift`
- `Views/Tools/Vision/VisionIdentityStepView.swift`
- `Views/Tools/Vision/VisionValuesStepView.swift`
- `Views/Tools/Vision/VisionScriptureStepView.swift`
- `Views/Tools/Vision/VisionReviewStepView.swift`
- `Views/Tools/Vision/VisionHubView.swift`
- `Views/Tools/Vision/VisionHistoryView.swift`
- `Views/Home/VisionCard.swift`

Create the `Vision` directory under `Views/Tools/` and add PBXFileReference, PBXBuildFile, PBXGroup entries, and Sources build phase entries for each file. Follow the existing pattern used by the `ThreeCircles` group.

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED — all files compiled, no missing references.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "chore(ios): add Vision Statement files to Xcode project"
```

---

## Task 12: Final Verification

- [ ] **Step 1: Clean build**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16 Pro' clean build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Enable feature flag and smoke test**

In `FeatureFlagStore.flagDefaults`, temporarily change `"feature.vision": false` to `"feature.vision": true` for testing.

Run on simulator, verify:
1. Tools tab shows "Vision" card
2. Tapping it shows empty state with "Create My Vision" button
3. Wizard opens with 4 prompts, identity, values, scripture, review steps
4. Can complete wizard and save
5. Hub shows populated state with vision content
6. Home screen shows VisionCard
7. Version history accessible from hub
8. Editing creates new version

Revert `feature.vision` back to `false` after testing.

- [ ] **Step 3: Final commit**

```bash
git add -A && git commit -m "feat(ios): Vision Statement feature complete (P0+P1)"
```
