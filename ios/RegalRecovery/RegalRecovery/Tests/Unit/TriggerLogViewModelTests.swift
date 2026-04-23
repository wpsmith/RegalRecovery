import Testing
@testable import RegalRecovery

@Suite("TriggerLogViewModel Tests")
struct TriggerLogViewModelTests {

    @Test("initial state has no triggers selected and intensity at 5")
    func testInitialState() {
        let vm = TriggerLogViewModel()

        #expect(vm.selectedTriggerIds.isEmpty)
        #expect(vm.intensity == 5)
        #expect(vm.logDepth == .quick)
        #expect(!vm.isSubmitting)
    }

    @Test("submit requires at least one trigger selected")
    func testSubmit_NoTriggers_Throws() async {
        let vm = TriggerLogViewModel()
        vm.selectedTriggerIds = []

        do {
            try await vm.submit()
            #expect(false, "Expected validation error")
        } catch {
            #expect(error is ActivityError)
        }
    }

    @Test("submit with trigger selection succeeds")
    func testSubmit_WithTriggerSelection_Succeeds() async throws {
        let vm = TriggerLogViewModel()

        // Set up a trigger option
        let triggerOption = TriggerLogViewModel.TriggerOption(
            id: UUID(),
            label: "Stress",
            category: .emotional
        )
        vm.availableTriggers = [triggerOption]
        vm.selectedTriggerIds = [triggerOption.id]

        try await vm.submit()

        #expect(vm.recentEntries.count == 1)
        let entry = vm.recentEntries.first!
        #expect(entry.triggerSnapshots.count == 1)
        #expect(entry.triggerSnapshots[0].label == "Stress")
        #expect(entry.triggerSnapshots[0].category == "emotional")
    }

    @Test("submit resets form state")
    func testSubmit_ResetsFormState() async throws {
        let vm = TriggerLogViewModel()

        // Set up initial state
        let triggerOption = TriggerLogViewModel.TriggerOption(
            id: UUID(),
            label: "Loneliness",
            category: .emotional
        )
        vm.availableTriggers = [triggerOption]
        vm.selectedTriggerIds = [triggerOption.id]
        vm.intensity = 8
        vm.includeIntensity = true
        vm.logDepth = .standard
        vm.mood = "Anxious"
        vm.situation = "At work"
        vm.socialContext = .alone

        try await vm.submit()

        // Verify reset
        #expect(vm.selectedTriggerIds.isEmpty)
        #expect(vm.intensity == 5)
        #expect(vm.includeIntensity == true)
        #expect(vm.logDepth == .quick)
        #expect(vm.mood == nil)
        #expect(vm.situation == nil)
        #expect(vm.socialContext == nil)
    }

    @Test("intensity determines risk level on submission")
    func testSubmit_IntensityDeterminesRiskLevel() async throws {
        let vm = TriggerLogViewModel()

        let triggerOption = TriggerLogViewModel.TriggerOption(
            id: UUID(),
            label: "Anger",
            category: .emotional
        )
        vm.availableTriggers = [triggerOption]
        vm.selectedTriggerIds = [triggerOption.id]
        vm.intensity = 8
        vm.includeIntensity = true

        try await vm.submit()

        #expect(vm.recentEntries.count == 1)
        let entry = vm.recentEntries.first!
        #expect(entry.intensity == 8)
        #expect(entry.riskLevel == .high)
    }

    @Test("submit without intensity saves nil intensity")
    func testSubmit_WithoutIntensity_SavesNilIntensity() async throws {
        let vm = TriggerLogViewModel()

        let triggerOption = TriggerLogViewModel.TriggerOption(
            id: UUID(),
            label: "Boredom",
            category: .emotional
        )
        vm.availableTriggers = [triggerOption]
        vm.selectedTriggerIds = [triggerOption.id]
        vm.includeIntensity = false

        try await vm.submit()

        #expect(vm.recentEntries.count == 1)
        let entry = vm.recentEntries.first!
        #expect(entry.intensity == nil)
        #expect(entry.riskLevel == nil)
    }

    @Test("multi-trigger selection limited to 10")
    func testToggleTrigger_LimitedTo10() {
        let vm = TriggerLogViewModel()

        // Try to add 12 triggers
        for i in 1...12 {
            let id = UUID()
            vm.toggleTrigger(id: id)
        }

        #expect(vm.selectedTriggerIds.count == 10)
    }

    @Test("affirming message rotates from curated set")
    func testAffirmingMessage_RotatesFromCuratedSet() {
        var messages = Set<String>()

        // Call 50 times to get multiple unique messages
        for _ in 1...50 {
            let message = TriggerLogViewModel.randomAffirmingMessage()
            messages.insert(message)
        }

        #expect(messages.count > 1)
    }

    @Test("next actions vary by risk level")
    func testNextActions_VaryByRiskLevel() {
        let lowActions = TriggerLogViewModel.nextActions(for: .low)
        let highActions = TriggerLogViewModel.nextActions(for: .high)

        // Low actions should NOT contain "reachOut"
        #expect(!lowActions.contains { $0.id == "reachOut" })

        // High actions SHOULD contain "reachOut"
        #expect(highActions.contains { $0.id == "reachOut" })
    }

    @Test("toggle trigger adds and removes correctly")
    func testToggleTrigger_AddsAndRemoves() {
        let vm = TriggerLogViewModel()
        let triggerId = UUID()

        // Add trigger
        vm.toggleTrigger(id: triggerId)
        #expect(vm.selectedTriggerIds.contains(triggerId))

        // Remove trigger
        vm.toggleTrigger(id: triggerId)
        #expect(!vm.selectedTriggerIds.contains(triggerId))
    }

    @Test("submit with multiple triggers saves all snapshots")
    func testSubmit_MultipleTriggersStored() async throws {
        let vm = TriggerLogViewModel()

        let trigger1 = TriggerLogViewModel.TriggerOption(id: UUID(), label: "Stress", category: .emotional)
        let trigger2 = TriggerLogViewModel.TriggerOption(id: UUID(), label: "Fatigue", category: .physical)
        let trigger3 = TriggerLogViewModel.TriggerOption(id: UUID(), label: "Conflict", category: .relational)

        vm.availableTriggers = [trigger1, trigger2, trigger3]
        vm.selectedTriggerIds = [trigger1.id, trigger2.id, trigger3.id]

        try await vm.submit()

        #expect(vm.recentEntries.count == 1)
        let entry = vm.recentEntries.first!
        #expect(entry.triggerSnapshots.count == 3)
    }

    @Test("submit sets isSubmitting to false after completion")
    func testSubmit_SetsIsSubmittingFalse() async throws {
        let vm = TriggerLogViewModel()

        let triggerOption = TriggerLogViewModel.TriggerOption(id: UUID(), label: "Test", category: .emotional)
        vm.availableTriggers = [triggerOption]
        vm.selectedTriggerIds = [triggerOption.id]

        try await vm.submit()

        #expect(!vm.isSubmitting)
    }

    @Test("next actions for nil risk level include journal")
    func testNextActions_NilRiskLevel_IncludesJournal() {
        let actions = TriggerLogViewModel.nextActions(for: nil)

        #expect(actions.contains { $0.id == "journal" })
        #expect(!actions.contains { $0.id == "reachOut" })
    }

    @Test("next actions for moderate risk include coping exercise")
    func testNextActions_ModerateRiskLevel_IncludesCopingExercise() {
        let actions = TriggerLogViewModel.nextActions(for: .moderate)

        #expect(actions.contains { $0.id == "copingExercise" })
        #expect(actions.contains { $0.id == "fasterScale" })
        #expect(!actions.contains { $0.id == "reachOut" })
    }
}
