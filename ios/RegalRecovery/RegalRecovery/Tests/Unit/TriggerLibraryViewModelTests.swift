import Testing
@testable import RegalRecovery

@Suite("TriggerLibraryViewModel Tests")
struct TriggerLibraryViewModelTests {

    @Test("search filters triggers by label")
    func testSearchFiltersByLabel() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Boredom", category: .emotional, isCustom: false, useCount: 2),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Fatigue", category: .physical, isCustom: false, useCount: 3)
        ]

        vm.searchQuery = "str"

        #expect(vm.filteredTriggers.count == 1)
        #expect(vm.filteredTriggers.first?.label == "Stress")
    }

    @Test("category filter narrows results")
    func testCategoryFilterNarrowsResults() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Fatigue", category: .physical, isCustom: false, useCount: 3)
        ]

        vm.selectedCategory = .emotional

        #expect(vm.filteredTriggers.count == 1)
        #expect(vm.filteredTriggers.first?.label == "Stress")
    }

    @Test("grouped by category returns correct sections")
    func testGroupedByCategoryReturnsCorrectSections() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Fatigue", category: .physical, isCustom: false, useCount: 3)
        ]

        let grouped = vm.groupedByCategory

        #expect(grouped.count == 2)
        #expect(grouped[0].category == .emotional)
        #expect(grouped[0].items.count == 1)
        #expect(grouped[1].category == .physical)
        #expect(grouped[1].items.count == 1)
    }

    @Test("custom triggers identified correctly")
    func testCustomTriggersIdentifiedCorrectly() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "My trigger", category: .emotional, isCustom: true, useCount: 1)
        ]

        let customTriggers = vm.customTriggers

        #expect(customTriggers.count == 1)
        #expect(customTriggers.first?.label == "My trigger")
        #expect(customTriggers.first?.isCustom == true)
    }

    @Test("validate custom trigger rejects empty label")
    func testValidateCustomTriggerRejectsEmptyLabel() {
        let vm = TriggerLibraryViewModel()

        let result1 = vm.validateCustomTrigger(label: "", category: .emotional)
        #expect(!result1.isValid)
        #expect(result1.message == "Please enter a trigger name.")

        let result2 = vm.validateCustomTrigger(label: "   ", category: .emotional)
        #expect(!result2.isValid)
        #expect(result2.message == "Please enter a trigger name.")
    }

    @Test("validate custom trigger rejects duplicate label")
    func testValidateCustomTriggerRejectsDuplicateLabel() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5)
        ]

        let result1 = vm.validateCustomTrigger(label: "Stress", category: .emotional)
        #expect(!result1.isValid)
        #expect(result1.message == "A trigger with this name already exists.")

        // Case-insensitive match
        let result2 = vm.validateCustomTrigger(label: "STRESS", category: .emotional)
        #expect(!result2.isValid)
        #expect(result2.message == "A trigger with this name already exists.")

        let result3 = vm.validateCustomTrigger(label: "stress", category: .emotional)
        #expect(!result3.isValid)
        #expect(result3.message == "A trigger with this name already exists.")
    }

    @Test("validate custom trigger rejects long label")
    func testValidateCustomTriggerRejectsLongLabel() {
        let vm = TriggerLibraryViewModel()

        // 101 characters
        let longLabel = String(repeating: "a", count: 101)
        let result = vm.validateCustomTrigger(label: longLabel, category: .emotional)

        #expect(!result.isValid)
        #expect(result.message == "Trigger name must be 100 characters or less.")
    }

    @Test("validate custom trigger accepts valid label")
    func testValidateCustomTriggerAcceptsValidLabel() {
        let vm = TriggerLibraryViewModel()

        let result = vm.validateCustomTrigger(label: "My custom trigger", category: .emotional)

        #expect(result.isValid)
        #expect(result.message == nil)
    }

    @Test("search is case insensitive")
    func testSearchIsCaseInsensitive() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Boredom", category: .emotional, isCustom: false, useCount: 2)
        ]

        vm.searchQuery = "STRESS"

        #expect(vm.filteredTriggers.count == 1)
        #expect(vm.filteredTriggers.first?.label == "Stress")
    }

    @Test("empty search shows all triggers")
    func testEmptySearchShowsAllTriggers() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Boredom", category: .emotional, isCustom: false, useCount: 2),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Fatigue", category: .physical, isCustom: false, useCount: 3)
        ]

        vm.searchQuery = ""

        #expect(vm.filteredTriggers.count == 3)
    }

    @Test("search and category filter combine correctly")
    func testSearchAndCategoryFilterCombine() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Strength", category: .physical, isCustom: false, useCount: 2),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Boredom", category: .emotional, isCustom: false, useCount: 1)
        ]

        vm.searchQuery = "str"
        vm.selectedCategory = .emotional

        #expect(vm.filteredTriggers.count == 1)
        #expect(vm.filteredTriggers.first?.label == "Stress")
    }

    @Test("grouped by category respects filter state")
    func testGroupedByCategoryRespectsFilterState() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Boredom", category: .emotional, isCustom: false, useCount: 2),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Fatigue", category: .physical, isCustom: false, useCount: 3)
        ]

        vm.searchQuery = "str"

        let grouped = vm.groupedByCategory

        #expect(grouped.count == 1)
        #expect(grouped[0].category == .emotional)
        #expect(grouped[0].items.count == 1)
    }

    @Test("validate custom trigger with exactly 100 characters is valid")
    func testValidateCustomTriggerWithExactly100CharactersIsValid() {
        let vm = TriggerLibraryViewModel()

        // Exactly 100 characters
        let exactLabel = String(repeating: "a", count: 100)
        let result = vm.validateCustomTrigger(label: exactLabel, category: .emotional)

        #expect(result.isValid)
        #expect(result.message == nil)
    }

    @Test("custom triggers filter returns only custom items")
    func testCustomTriggersFilterReturnsOnlyCustomItems() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Custom 1", category: .emotional, isCustom: true, useCount: 1),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Fatigue", category: .physical, isCustom: false, useCount: 3),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Custom 2", category: .physical, isCustom: true, useCount: 2)
        ]

        let customTriggers = vm.customTriggers

        #expect(customTriggers.count == 2)
        #expect(customTriggers.allSatisfy { $0.isCustom })
        #expect(customTriggers.contains { $0.label == "Custom 1" })
        #expect(customTriggers.contains { $0.label == "Custom 2" })
    }

    @Test("grouped by category maintains category order")
    func testGroupedByCategoryMaintainsCategoryOrder() {
        let vm = TriggerLibraryViewModel()
        vm.allTriggers = [
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Conflict", category: .relational, isCustom: false, useCount: 1),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Stress", category: .emotional, isCustom: false, useCount: 5),
            TriggerLibraryViewModel.LibraryItem(id: UUID(), label: "Fatigue", category: .physical, isCustom: false, useCount: 3)
        ]

        let grouped = vm.groupedByCategory

        #expect(grouped.count == 3)
        // Order should match TriggerCategory.allCases
        #expect(grouped[0].category == .emotional)
        #expect(grouped[1].category == .physical)
        #expect(grouped[2].category == .relational)
    }
}
