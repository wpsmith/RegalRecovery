import Testing
@testable import RegalRecovery
import Foundation

@Suite("MotivationLibraryViewModel Tests")
struct MotivationLibraryViewModelTests {

    @Test("initial state is empty")
    func testInitialState() {
        let vm = MotivationLibraryViewModel()
        #expect(vm.motivations.isEmpty)
        #expect(!vm.isLoading)
        #expect(vm.error == nil)
    }

    @Test("addMotivation appends to motivations")
    func testAddMotivation() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(
            text: "My daughter deserves a present father",
            category: .relational,
            importanceRating: 5,
            scriptureReference: "Prov 22:6",
            source: .manual
        )
        #expect(vm.motivations.count == 1)
        #expect(vm.motivations.first?.text == "My daughter deserves a present father")
        #expect(vm.motivations.first?.motivationCategory == .relational)
        #expect(vm.motivations.first?.importanceRating == 5)
        #expect(vm.motivations.first?.scriptureReference == "Prov 22:6")
    }

    @Test("addMotivation trims whitespace")
    func testTrimsWhitespace() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(
            text: "  Integrity before God  ",
            category: .spiritual,
            importanceRating: 4,
            scriptureReference: nil,
            source: .manual
        )
        #expect(vm.motivations.first?.text == "Integrity before God")
    }

    @Test("deleteMotivation removes from list")
    func testDeleteMotivation() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(text: "To delete", category: .health, importanceRating: 3, scriptureReference: nil, source: .manual)
        let id = vm.motivations.first!.id
        vm.deleteMotivation(id: id)
        #expect(vm.motivations.isEmpty)
    }

    @Test("updateMotivation modifies text and updates modifiedAt")
    func testUpdateMotivation() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(text: "Original", category: .spiritual, importanceRating: 3, scriptureReference: nil, source: .manual)
        let id = vm.motivations.first!.id
        let originalModifiedAt = vm.motivations.first!.modifiedAt

        vm.updateMotivation(id: id, text: "Updated", category: .spiritual, importanceRating: 4, scriptureReference: "Rom 8:28")

        let updated = vm.motivations.first { $0.id == id }
        #expect(updated?.text == "Updated")
        #expect(updated?.importanceRating == 4)
        #expect(updated?.scriptureReference == "Rom 8:28")
        #expect(updated!.modifiedAt >= originalModifiedAt)
    }

    @Test("groupedByCategory returns categories in order")
    func testGroupedByCategory() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(text: "Spiritual one", category: .spiritual, importanceRating: 3, scriptureReference: nil, source: .manual)
        vm.addMotivation(text: "Family one", category: .relational, importanceRating: 5, scriptureReference: nil, source: .manual)
        vm.addMotivation(text: "Spiritual two", category: .spiritual, importanceRating: 4, scriptureReference: nil, source: .manual)

        let grouped = vm.groupedByCategory
        #expect(grouped.count == 2)

        let spiritualGroup = grouped.first { $0.category == .spiritual }
        #expect(spiritualGroup != nil)
        #expect(spiritualGroup!.motivations.count == 2)
        #expect(spiritualGroup!.motivations.first?.importanceRating == 4)
    }

    @Test("addMotivation validates text is not empty")
    func testRejectsEmptyText() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(text: "   ", category: .spiritual, importanceRating: 3, scriptureReference: nil, source: .manual)
        #expect(vm.motivations.isEmpty)
        #expect(vm.error != nil)
    }
}
