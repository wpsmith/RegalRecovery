import Testing
@testable import RegalRecovery
import Foundation

@Suite("MotivationDiscoveryViewModel Tests")
struct MotivationDiscoveryViewModelTests {

    @Test("initial step is intro")
    func testInitialStep() {
        let vm = MotivationDiscoveryViewModel()
        #expect(vm.currentStep == .intro)
    }

    @Test("goToNextStep advances from intro to valuesSelection")
    func testAdvanceFromIntro() {
        let vm = MotivationDiscoveryViewModel()
        vm.goToNextStep()
        #expect(vm.currentStep == .valuesSelection)
    }

    @Test("goToNextStep advances from valuesSelection to concretePrompts")
    func testAdvanceToConcretePrompts() {
        let vm = MotivationDiscoveryViewModel()
        vm.currentStep = .valuesSelection
        vm.selectedValues = [.spiritual]
        vm.goToNextStep()
        #expect(vm.currentStep == .concretePrompts)
    }

    @Test("goToPreviousStep goes back from valuesSelection to intro")
    func testGoBack() {
        let vm = MotivationDiscoveryViewModel()
        vm.currentStep = .valuesSelection
        vm.goToPreviousStep()
        #expect(vm.currentStep == .intro)
    }

    @Test("toggleValue adds and removes")
    func testToggleValue() {
        let vm = MotivationDiscoveryViewModel()
        vm.toggleValue(.spiritual)
        #expect(vm.selectedValues.contains(.spiritual))
        vm.toggleValue(.spiritual)
        #expect(!vm.selectedValues.contains(.spiritual))
    }

    @Test("toggleValue allows selecting all categories")
    func testSelectAll() {
        let vm = MotivationDiscoveryViewModel()
        for category in MotivationCategory.allCases {
            vm.toggleValue(category)
        }
        #expect(vm.selectedValues.count == MotivationCategory.allCases.count)
    }

    @Test("canProceed is false on valuesSelection with no values selected")
    func testCanProceedValues() {
        let vm = MotivationDiscoveryViewModel()
        vm.currentStep = .valuesSelection
        #expect(!vm.canProceed)
        vm.toggleValue(.health)
        #expect(vm.canProceed)
    }

    @Test("concretePromptCategories returns selected values")
    func testConcretePromptCategories() {
        let vm = MotivationDiscoveryViewModel()
        vm.selectedValues = [.spiritual, .relational]
        #expect(vm.concretePromptCategories == [.spiritual, .relational])
    }

    @Test("buildMotivations creates one motivation per concrete response")
    func testBuildMotivations() {
        let vm = MotivationDiscoveryViewModel()
        vm.selectedValues = [.spiritual, .relational]
        vm.concreteResponses[.spiritual] = "Walk in integrity before God"
        vm.concreteResponses[.relational] = "Be present for my daughter"
        vm.concreteScriptures[.spiritual] = "Psalm 51:10"

        let motivations = vm.buildMotivations(userId: UUID())
        #expect(motivations.count == 2)

        let spiritual = motivations.first { $0.motivationCategory == .spiritual }
        #expect(spiritual?.text == "Walk in integrity before God")
        #expect(spiritual?.scriptureReference == "Psalm 51:10")
        #expect(spiritual?.motivationSource == .discovery)

        let relational = motivations.first { $0.motivationCategory == .relational }
        #expect(relational?.text == "Be present for my daughter")
        #expect(relational?.scriptureReference == nil)
    }

    @Test("buildMotivations skips empty responses")
    func testBuildMotivationsSkipsEmpty() {
        let vm = MotivationDiscoveryViewModel()
        vm.selectedValues = [.spiritual, .relational]
        vm.concreteResponses[.spiritual] = "Walk in integrity"
        vm.concreteResponses[.relational] = "   "

        let motivations = vm.buildMotivations(userId: UUID())
        #expect(motivations.count == 1)
    }
}
