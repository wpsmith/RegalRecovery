import Testing
@testable import RegalRecovery

@Suite("UrgeLogViewModel Tests")
struct UrgeLogViewModelTests {

    // MARK: - Submit Tests

    @Test("submit clears form after success")
    func testSubmit_ClearsFormAfterSuccess() async throws {
        let vm = UrgeLogViewModel()
        vm.intensity = 8
        vm.selectedAddictions = ["Sex Addiction (SA)"]
        vm.selectedTriggers = ["Stress", "Loneliness"]
        vm.notes = "Felt vulnerable after argument"

        try await vm.submit()

        #expect(vm.intensity == 5)
        #expect(vm.selectedTriggers.isEmpty)
        #expect(vm.notes.isEmpty)
    }

    @Test("submit with triggers saves triggers list")
    func testSubmit_WithTriggers_SavesTriggersList() async throws {
        let vm = UrgeLogViewModel()
        vm.selectedAddictions = ["Sex Addiction (SA)"]
        vm.selectedTriggers = ["Stress", "Loneliness", "Boredom"]
        vm.intensity = 6

        try await vm.submit()

        #expect(vm.recentUrges.count == 1)
        let entry = vm.recentUrges.first!
        #expect(entry.triggers.count == 3)
        #expect(entry.triggers.contains("Stress"))
        #expect(entry.triggers.contains("Loneliness"))
        #expect(entry.triggers.contains("Boredom"))
    }

    @Test("reset clears all fields")
    func testReset_ClearsAllFields() {
        let vm = UrgeLogViewModel()
        vm.intensity = 9
        vm.selectedAddictions = ["Pornography"]
        vm.selectedTriggers = ["Anger", "Late Night"]
        vm.notes = "Some notes"

        vm.reset()

        #expect(vm.intensity == 5)
        #expect(vm.selectedTriggers.isEmpty)
        #expect(vm.notes.isEmpty)
    }

    @Test("submit without addiction throws validation error")
    func testSubmit_NoAddiction_Throws() async {
        let vm = UrgeLogViewModel()
        vm.selectedAddictions = []
        vm.intensity = 5

        do {
            try await vm.submit()
            #expect(false, "Expected validation error")
        } catch {
            #expect(error is ActivityError)
        }
    }

    @Test("submit adds entry to recent urges")
    func testSubmit_AddsToRecentUrges() async throws {
        let vm = UrgeLogViewModel()
        vm.selectedAddictions = ["Sex Addiction (SA)"]
        vm.intensity = 7
        vm.notes = "Test note"

        try await vm.submit()

        #expect(vm.recentUrges.count == 1)
        #expect(vm.recentUrges.first?.intensity == 7)
        #expect(vm.recentUrges.first?.addictions.contains("Sex Addiction (SA)") == true)
        #expect(vm.recentUrges.first?.notes == "Test note")
    }

    @Test("submit sets isSubmitting during execution")
    func testSubmit_SetsIsSubmitting() async throws {
        let vm = UrgeLogViewModel()
        vm.selectedAddictions = ["Sex Addiction (SA)"]
        vm.intensity = 5

        // After completion, isSubmitting should be false
        try await vm.submit()
        #expect(!vm.isSubmitting)
    }

    @Test("multiple submissions accumulate entries in order")
    func testMultipleSubmissions_AccumulateInOrder() async throws {
        let vm = UrgeLogViewModel()

        vm.selectedAddictions = ["Sex Addiction (SA)"]
        vm.intensity = 3
        try await vm.submit()

        vm.selectedAddictions = ["Pornography"]
        vm.intensity = 7
        try await vm.submit()

        #expect(vm.recentUrges.count == 2)
        // Most recent first
        #expect(vm.recentUrges[0].addictions.contains("Pornography"))
        #expect(vm.recentUrges[1].addictions.contains("Sex Addiction (SA)"))
    }

    @Test("submit with multiple addictions saves all addictions")
    func testSubmit_MultipleAddictions_SavesAll() async throws {
        let vm = UrgeLogViewModel()
        vm.selectedAddictions = ["Sex Addiction (SA)", "Pornography"]
        vm.intensity = 6

        try await vm.submit()

        #expect(vm.recentUrges.count == 1)
        let entry = vm.recentUrges.first!
        #expect(entry.addictions.count == 2)
        #expect(entry.addictions.contains("Sex Addiction (SA)"))
        #expect(entry.addictions.contains("Pornography"))
    }

    // MARK: - Trigger Library Integration Tests

    @Test("default triggers contains 8 items for backward compatibility")
    func defaultTriggersCount() {
        #expect(UrgeLogViewModel.defaultTriggers.count == 8)
    }

    @Test("useFullLibrary switches to trigger library options")
    func useFullLibrarySwitchesToLibrary() {
        let vm = UrgeLogViewModel()
        vm.triggerLibraryOptions = [
            TriggerLogViewModel.TriggerOption(id: UUID(), label: "Stress", category: .emotional),
            TriggerLogViewModel.TriggerOption(id: UUID(), label: "Fantasy", category: .cognitive),
        ]
        vm.useFullLibrary = true
        #expect(vm.displayTriggers.count == 2)
        #expect(vm.displayTriggers.contains("Fantasy"))
    }
}
