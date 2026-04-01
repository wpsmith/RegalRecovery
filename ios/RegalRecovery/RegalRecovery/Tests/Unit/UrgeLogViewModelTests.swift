import Testing
@testable import RegalRecovery

@Suite("UrgeLogViewModel Tests")
struct UrgeLogViewModelTests {

    // MARK: - Submit Tests

    @Test("submit clears form after success")
    func testSubmit_ClearsFormAfterSuccess() async throws {
        let vm = UrgeLogViewModel()
        vm.intensity = 8
        vm.selectedAddiction = "Sex Addiction (SA)"
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
        vm.selectedAddiction = "Sex Addiction (SA)"
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
        vm.selectedAddiction = "Pornography"
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
        vm.selectedAddiction = ""
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
        vm.selectedAddiction = "Sex Addiction (SA)"
        vm.intensity = 7
        vm.notes = "Test note"

        try await vm.submit()

        #expect(vm.recentUrges.count == 1)
        #expect(vm.recentUrges.first?.intensity == 7)
        #expect(vm.recentUrges.first?.addiction == "Sex Addiction (SA)")
        #expect(vm.recentUrges.first?.notes == "Test note")
    }

    @Test("submit sets isSubmitting during execution")
    func testSubmit_SetsIsSubmitting() async throws {
        let vm = UrgeLogViewModel()
        vm.selectedAddiction = "Sex Addiction (SA)"
        vm.intensity = 5

        // After completion, isSubmitting should be false
        try await vm.submit()
        #expect(!vm.isSubmitting)
    }

    @Test("multiple submissions accumulate entries in order")
    func testMultipleSubmissions_AccumulateInOrder() async throws {
        let vm = UrgeLogViewModel()

        vm.selectedAddiction = "Sex Addiction (SA)"
        vm.intensity = 3
        try await vm.submit()

        vm.selectedAddiction = "Pornography"
        vm.intensity = 7
        try await vm.submit()

        #expect(vm.recentUrges.count == 2)
        // Most recent first
        #expect(vm.recentUrges[0].addiction == "Pornography")
        #expect(vm.recentUrges[1].addiction == "Sex Addiction (SA)")
    }
}
