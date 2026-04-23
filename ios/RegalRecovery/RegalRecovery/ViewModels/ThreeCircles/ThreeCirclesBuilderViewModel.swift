import Foundation
import Observation

// MARK: - Builder Step

/// Steps in the Three Circles onboarding builder flow.
/// Guided mode enforces this order; express mode allows flexible navigation.
enum BuilderStep: Int, CaseIterable, Sendable {
    case emotionalCheckin = 0
    case modeSelection
    case recoveryArea
    case framework
    case innerCircle
    case outerCircle
    case middleCircle
    case review

    var title: String {
        switch self {
        case .emotionalCheckin: return "Check-In"
        case .modeSelection: return "Choose Your Path"
        case .recoveryArea: return "Recovery Area"
        case .framework: return "Framework"
        case .innerCircle: return "Inner Circle"
        case .outerCircle: return "Outer Circle"
        case .middleCircle: return "Middle Circle"
        case .review: return "Review"
        }
    }

    /// Steps that represent actual progress (excludes emotional check-in and mode selection).
    static var progressSteps: [BuilderStep] {
        [.recoveryArea, .framework, .innerCircle, .outerCircle, .middleCircle, .review]
    }
}

// MARK: - Emotional Check-In Path

/// Paths available when user is struggling during emotional check-in.
enum StrugglingPath: Sendable {
    case startAnyway
    case saveForLater
    case getSupport
}

// MARK: - Builder Item

/// A local draft item used during circle building, before committing to the API.
struct BuilderItem: Identifiable, Hashable, Sendable {
    let id: UUID
    var behaviorName: String
    var notes: String?
    var category: String?
    var source: CircleItemSource
    var isUncertain: Bool

    init(
        id: UUID = UUID(),
        behaviorName: String,
        notes: String? = nil,
        category: String? = nil,
        source: CircleItemSource = .user,
        isUncertain: Bool = false
    ) {
        self.id = id
        self.behaviorName = behaviorName
        self.notes = notes
        self.category = category
        self.source = source
        self.isUncertain = isUncertain
    }

    /// Convert to API CircleItem for persistence.
    func toCircleItem(circle: CircleType) -> CircleItem {
        CircleItem(
            itemId: id.uuidString,
            circle: circle,
            behaviorName: behaviorName,
            notes: notes,
            specificityDetail: nil,
            category: category,
            source: source,
            flags: isUncertain ? CircleItemFlags(uncertain: true) : nil,
            createdAt: Date(),
            modifiedAt: nil
        )
    }
}

// MARK: - JSON Coding Helpers

extension JSONEncoder {
    static let regalRecovery: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let regalRecovery: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

// MARK: - Guardrail Nudge

/// Non-blocking guidance messages shown during circle building.
struct GuardrailNudge: Identifiable, Sendable {
    let id = UUID()
    let message: String
    let severity: Severity

    enum Severity: Sendable {
        case info
        case suggestion
        case warning
    }
}

// MARK: - Builder ViewModel

/// Orchestrates the entire Three Circles onboarding builder flow.
///
/// Supports three modes:
/// - **Guided**: Step-by-step with enforced order (emotional check-in through review)
/// - **Starter Pack**: Select a pre-built pack, review, customize, then commit
/// - **Express**: Flexible step order for experienced users
@Observable
final class ThreeCirclesBuilderViewModel {

    // MARK: - Flow State

    var mode: OnboardingMode = .guided
    var currentStep: BuilderStep = .modeSelection
    var emotionalCheckinScore: Int = 0 // 0 = not yet selected, 1-5

    // MARK: - Selections

    var selectedRecoveryAreas: Set<RecoveryArea> = []
    var selectedFramework: FrameworkPreference?

    // MARK: - Circle Items (local drafts)

    var innerCircleItems: [BuilderItem] = []
    var middleCircleItems: [BuilderItem] = []
    var outerCircleItems: [BuilderItem] = []

    // MARK: - Starter Pack State

    var selectedStarterPack: StarterPack?
    var availableStarterPacks: [StarterPackListItem] = []
    var isLoadingStarterPacks: Bool = false

    // MARK: - Template State

    var availableTemplates: [Template] = []
    var isLoadingTemplates: Bool = false

    // MARK: - UI State

    var showPauseSheet: Bool = false
    var showSupportSheet: Bool = false
    var isCommitting: Bool = false
    var commitError: String?
    var showStrugglingOptions: Bool = false

    // MARK: - Persistence Key

    private static let draftKey = "ThreeCirclesBuilderDraft"

    // MARK: - Computed Properties

    /// The primary recovery area (first selected, used for template/pack lookups).
    var primaryRecoveryArea: RecoveryArea? {
        selectedRecoveryAreas.first
    }

    /// Whether the user can proceed to the next step.
    var canProceed: Bool {
        switch currentStep {
        case .emotionalCheckin:
            return emotionalCheckinScore > 0
        case .modeSelection:
            return true
        case .recoveryArea:
            return !selectedRecoveryAreas.isEmpty
        case .framework:
            return true // framework is optional
        case .innerCircle:
            return !innerCircleItems.isEmpty
        case .outerCircle:
            return !outerCircleItems.isEmpty
        case .middleCircle:
            return true // middle circle can be empty initially
        case .review:
            return !innerCircleItems.isEmpty // must have at least one inner circle item
        }
    }

    /// Whether back navigation is available from the current step.
    var canGoBack: Bool {
        switch currentStep {
        case .emotionalCheckin:
            return false
        default:
            return true
        }
    }

    /// Whether the current step can be skipped.
    var canSkip: Bool {
        switch currentStep {
        case .emotionalCheckin, .modeSelection:
            return true
        case .framework:
            return true
        case .middleCircle:
            return true
        case .recoveryArea, .innerCircle, .outerCircle, .review:
            return false
        }
    }

    /// Progress fraction (0.0 to 1.0) for the progress indicator.
    var progressFraction: Double {
        let progressSteps = BuilderStep.progressSteps
        guard let index = progressSteps.firstIndex(of: currentStep) else {
            return 0.0
        }
        return Double(index + 1) / Double(progressSteps.count)
    }

    /// Current progress step index (1-based) for display.
    var currentProgressIndex: Int {
        let progressSteps = BuilderStep.progressSteps
        guard let index = progressSteps.firstIndex(of: currentStep) else {
            return 0
        }
        return index + 1
    }

    /// Total number of progress steps.
    var totalProgressSteps: Int {
        BuilderStep.progressSteps.count
    }

    /// Guardrail nudges for the current state of circles.
    var guardrailNudges: [GuardrailNudge] {
        var nudges: [GuardrailNudge] = []

        // Overload check: too many items in a single circle
        if innerCircleItems.count > 15 {
            nudges.append(GuardrailNudge(
                message: "Your inner circle has many items. Consider focusing on the most critical boundaries to start.",
                severity: .suggestion
            ))
        }
        if outerCircleItems.count > 20 {
            nudges.append(GuardrailNudge(
                message: "A large outer circle can feel overwhelming. Focus on practices you can realistically maintain.",
                severity: .suggestion
            ))
        }

        // Depth check: too few items
        if currentStep == .review && innerCircleItems.count < 3 {
            nudges.append(GuardrailNudge(
                message: "Most people find it helpful to have at least 3-5 inner circle items. You can always add more later.",
                severity: .info
            ))
        }

        // Balance check
        if currentStep == .review && outerCircleItems.isEmpty {
            nudges.append(GuardrailNudge(
                message: "An outer circle with healthy practices gives you positive goals to work toward.",
                severity: .warning
            ))
        }

        return nudges
    }

    // MARK: - Navigation

    /// Advance to the next step in the builder flow.
    func goToNextStep() {
        switch mode {
        case .guided:
            advanceGuidedStep()
        case .express:
            advanceExpressStep()
        case .starterPack:
            advanceStarterPackStep()
        }
    }

    /// Go back to the previous step.
    func goToPreviousStep() {
        switch mode {
        case .guided:
            retreatGuidedStep()
        case .express:
            retreatExpressStep()
        case .starterPack:
            retreatStarterPackStep()
        }
    }

    /// Skip the current step (only available for skippable steps).
    func skipCurrentStep() {
        guard canSkip else { return }
        goToNextStep()
    }

    /// Navigate directly to a specific step (express mode or review editing).
    func goToStep(_ step: BuilderStep) {
        currentStep = step
    }

    // MARK: - Mode Selection

    /// Set the builder mode and advance past mode selection.
    func selectMode(_ newMode: OnboardingMode) {
        mode = newMode
        currentStep = .recoveryArea
    }

    /// Suggested mode based on emotional check-in score.
    var suggestedMode: OnboardingMode {
        switch emotionalCheckinScore {
        case 1...2:
            return .starterPack // Easier when struggling
        case 3:
            return .guided
        case 4...5:
            return .guided
        default:
            return .guided
        }
    }

    // MARK: - Emotional Check-In

    /// Record the emotional check-in score and handle struggling paths.
    func setEmotionalCheckin(_ score: Int) {
        emotionalCheckinScore = score
        if score <= 2 {
            showStrugglingOptions = true
        } else {
            currentStep = .modeSelection
        }
    }

    /// Handle the user's choice when they're struggling.
    func handleStrugglingPath(_ path: StrugglingPath) {
        showStrugglingOptions = false
        switch path {
        case .startAnyway:
            currentStep = .modeSelection
        case .saveForLater:
            saveDraft()
        case .getSupport:
            showSupportSheet = true
        }
    }

    // MARK: - Recovery Area

    /// Toggle selection of a recovery area.
    func toggleRecoveryArea(_ area: RecoveryArea) {
        if selectedRecoveryAreas.contains(area) {
            selectedRecoveryAreas.remove(area)
        } else {
            selectedRecoveryAreas.insert(area)
        }
    }

    // MARK: - Circle Item Management

    /// Add an item to the specified circle.
    func addItem(to circle: CircleType, behaviorName: String, source: CircleItemSource = .user) {
        let trimmed = behaviorName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let item = BuilderItem(behaviorName: trimmed, source: source)

        switch circle {
        case .inner:
            guard !innerCircleItems.contains(where: { $0.behaviorName.lowercased() == trimmed.lowercased() }) else { return }
            innerCircleItems.append(item)
        case .middle:
            guard !middleCircleItems.contains(where: { $0.behaviorName.lowercased() == trimmed.lowercased() }) else { return }
            middleCircleItems.append(item)
        case .outer:
            guard !outerCircleItems.contains(where: { $0.behaviorName.lowercased() == trimmed.lowercased() }) else { return }
            outerCircleItems.append(item)
        }
    }

    /// Remove an item from the specified circle.
    func removeItem(from circle: CircleType, item: BuilderItem) {
        switch circle {
        case .inner:
            innerCircleItems.removeAll { $0.id == item.id }
        case .middle:
            middleCircleItems.removeAll { $0.id == item.id }
        case .outer:
            outerCircleItems.removeAll { $0.id == item.id }
        }
    }

    /// Move an item within its circle (reorder).
    func moveItem(in circle: CircleType, from source: IndexSet, to destination: Int) {
        switch circle {
        case .inner:
            innerCircleItems.move(fromOffsets: source, toOffset: destination)
        case .middle:
            middleCircleItems.move(fromOffsets: source, toOffset: destination)
        case .outer:
            outerCircleItems.move(fromOffsets: source, toOffset: destination)
        }
    }

    /// Toggle the uncertain flag on an item.
    func toggleUncertain(_ item: BuilderItem, in circle: CircleType) {
        let items: [BuilderItem]
        switch circle {
        case .inner: items = innerCircleItems
        case .middle: items = middleCircleItems
        case .outer: items = outerCircleItems
        }

        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        switch circle {
        case .inner: innerCircleItems[index].isUncertain.toggle()
        case .middle: middleCircleItems[index].isUncertain.toggle()
        case .outer: outerCircleItems[index].isUncertain.toggle()
        }
    }

    /// Get items for a specific circle type.
    func items(for circle: CircleType) -> [BuilderItem] {
        switch circle {
        case .inner: return innerCircleItems
        case .middle: return middleCircleItems
        case .outer: return outerCircleItems
        }
    }

    /// Item count for a specific circle.
    func itemCount(for circle: CircleType) -> Int {
        items(for: circle).count
    }

    // MARK: - Starter Pack

    /// Apply a starter pack, populating all three circles.
    func applyStarterPack(_ pack: StarterPack) {
        selectedStarterPack = pack

        // Populate circles from the pack
        innerCircleItems = (pack.innerCircle ?? []).map { packItem in
            BuilderItem(
                behaviorName: packItem.behaviorName,
                category: packItem.category,
                source: .starterPack
            )
        }
        middleCircleItems = (pack.middleCircle ?? []).map { packItem in
            BuilderItem(
                behaviorName: packItem.behaviorName,
                category: packItem.category,
                source: .starterPack
            )
        }
        outerCircleItems = (pack.outerCircle ?? []).map { packItem in
            BuilderItem(
                behaviorName: packItem.behaviorName,
                category: packItem.category,
                source: .starterPack
            )
        }

        // Jump to review
        currentStep = .review
    }

    // MARK: - Templates

    /// Add a template item to a circle.
    func addTemplate(_ template: Template) {
        addItem(to: template.circle, behaviorName: template.behaviorName, source: .template)
    }

    /// Check if a template is already added to its circle.
    func isTemplateAdded(_ template: Template) -> Bool {
        let circleItems = items(for: template.circle)
        return circleItems.contains { $0.behaviorName.lowercased() == template.behaviorName.lowercased() }
    }

    // MARK: - Commit

    private static let savedSetsKey = "threecircles.savedSets"

    /// Commit the circle set — persists locally and sets state.
    func commit(option: CommitOption) {
        isCommitting = true
        commitError = nil

        let status: CircleSetStatus = (option == .commitNow) ? .active : .draft
        let now = Date()
        let recoveryArea = selectedRecoveryAreas.first ?? .sexPornography

        let circleSet = CircleSet(
            setId: UUID().uuidString,
            userId: "local",
            name: recoveryArea.displayName,
            recoveryArea: recoveryArea,
            frameworkPreference: selectedFramework,
            status: status,
            innerCircle: innerCircleItems.map { $0.toCircleItem(circle: .inner) },
            middleCircle: middleCircleItems.map { $0.toCircleItem(circle: .middle) },
            outerCircle: outerCircleItems.map { $0.toCircleItem(circle: .outer) },
            versionNumber: 1,
            createdAt: now,
            modifiedAt: now,
            committedAt: status == .active ? now : nil
        )

        // Persist locally (single set — replace any existing)
        if let data = try? JSONEncoder.regalRecovery.encode([circleSet]) {
            UserDefaults.standard.set(data, forKey: Self.savedSetsKey)
        }
    }

    /// Reset commit state after completion.
    func commitCompleted(success: Bool, error: String? = nil) {
        isCommitting = false
        if !success {
            commitError = error
        }
    }

    /// Load locally saved circle sets.
    static func loadSavedSets() -> [CircleSet] {
        guard let data = UserDefaults.standard.data(forKey: savedSetsKey),
              let sets = try? JSONDecoder.regalRecovery.decode([CircleSet].self, from: data) else {
            return []
        }
        return sets
    }

    // MARK: - Draft Persistence

    /// Save current progress to UserDefaults.
    func saveDraft() {
        let draft = BuilderDraft(
            mode: mode,
            currentStep: currentStep,
            emotionalCheckinScore: emotionalCheckinScore,
            selectedRecoveryAreas: Array(selectedRecoveryAreas),
            selectedFramework: selectedFramework,
            innerCircleItems: innerCircleItems.map { DraftItem(from: $0) },
            middleCircleItems: middleCircleItems.map { DraftItem(from: $0) },
            outerCircleItems: outerCircleItems.map { DraftItem(from: $0) }
        )
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: Self.draftKey)
        }
    }

    /// Resume from a saved draft.
    func resumeDraft() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.draftKey),
              let draft = try? JSONDecoder().decode(BuilderDraft.self, from: data) else {
            return false
        }

        mode = draft.mode
        currentStep = draft.currentStep
        emotionalCheckinScore = draft.emotionalCheckinScore
        selectedRecoveryAreas = Set(draft.selectedRecoveryAreas)
        selectedFramework = draft.selectedFramework
        innerCircleItems = draft.innerCircleItems.map { $0.toBuilderItem() }
        middleCircleItems = draft.middleCircleItems.map { $0.toBuilderItem() }
        outerCircleItems = draft.outerCircleItems.map { $0.toBuilderItem() }

        return true
    }

    /// Clear saved draft.
    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: Self.draftKey)
    }

    /// Whether a saved draft exists.
    var hasSavedDraft: Bool {
        UserDefaults.standard.data(forKey: Self.draftKey) != nil
    }

    // MARK: - Private Navigation Helpers

    private func advanceGuidedStep() {
        let guidedOrder: [BuilderStep] = [
            .emotionalCheckin, .modeSelection, .recoveryArea, .framework,
            .innerCircle, .outerCircle, .middleCircle, .review
        ]
        guard let currentIndex = guidedOrder.firstIndex(of: currentStep),
              currentIndex + 1 < guidedOrder.count else { return }
        currentStep = guidedOrder[currentIndex + 1]
    }

    private func retreatGuidedStep() {
        let guidedOrder: [BuilderStep] = [
            .emotionalCheckin, .modeSelection, .recoveryArea, .framework,
            .innerCircle, .outerCircle, .middleCircle, .review
        ]
        guard let currentIndex = guidedOrder.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        currentStep = guidedOrder[currentIndex - 1]
    }

    private func advanceExpressStep() {
        // Express mode: same order but user can jump around
        advanceGuidedStep()
    }

    private func retreatExpressStep() {
        retreatGuidedStep()
    }

    private func advanceStarterPackStep() {
        switch currentStep {
        case .emotionalCheckin:
            currentStep = .modeSelection
        case .modeSelection:
            currentStep = .recoveryArea
        case .recoveryArea:
            // In starter pack mode, go straight to starter pack selection (handled by view)
            currentStep = .review
        default:
            advanceGuidedStep()
        }
    }

    private func retreatStarterPackStep() {
        switch currentStep {
        case .review:
            currentStep = .recoveryArea
        default:
            retreatGuidedStep()
        }
    }
}

// MARK: - Draft Persistence Models

private struct BuilderDraft: Codable {
    let mode: OnboardingMode
    let currentStep: BuilderStep
    let emotionalCheckinScore: Int
    let selectedRecoveryAreas: [RecoveryArea]
    let selectedFramework: FrameworkPreference?
    let innerCircleItems: [DraftItem]
    let middleCircleItems: [DraftItem]
    let outerCircleItems: [DraftItem]
}

extension BuilderStep: Codable {}

private struct DraftItem: Codable {
    let behaviorName: String
    let notes: String?
    let category: String?
    let sourceRaw: String
    let isUncertain: Bool

    init(from item: BuilderItem) {
        self.behaviorName = item.behaviorName
        self.notes = item.notes
        self.category = item.category
        self.sourceRaw = item.source.rawValue
        self.isUncertain = item.isUncertain
    }

    func toBuilderItem() -> BuilderItem {
        BuilderItem(
            behaviorName: behaviorName,
            notes: notes,
            category: category,
            source: CircleItemSource(rawValue: sourceRaw) ?? .user,
            isUncertain: isUncertain
        )
    }
}
