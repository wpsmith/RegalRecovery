import XCTest
import SwiftData
@testable import RegalRecovery

final class BowtieOnboardingViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() {
        super.setUp()
        container = try! RRModelConfiguration.makeContainer(inMemory: true)
        context = ModelContext(container)
        UserDefaults.standard.removeObject(forKey: "bowtie.onboardingCompleted")
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    func testInitialStep_IsExplanation() {
        let vm = BowtieOnboardingViewModel()
        XCTAssertEqual(vm.currentStep, .explanation)
    }

    func testGoForward_AdvancesStep() {
        let vm = BowtieOnboardingViewModel()
        vm.goForward()
        XCTAssertEqual(vm.currentStep, .visualMetaphor)
    }

    func testGoBack_ReturnsToExplanation() {
        let vm = BowtieOnboardingViewModel()
        vm.goForward()
        vm.goBack()
        XCTAssertEqual(vm.currentStep, .explanation)
    }

    func testGoBack_DoesNothingOnFirstStep() {
        let vm = BowtieOnboardingViewModel()
        vm.goBack()
        XCTAssertEqual(vm.currentStep, .explanation)
    }

    func testGoForward_DoesNothingOnLastStep() {
        let vm = BowtieOnboardingViewModel()
        vm.goForward() // visualMetaphor
        vm.goForward() // roleSetup
        vm.goForward() // triggerSetup
        vm.goForward() // should stay
        XCTAssertEqual(vm.currentStep, .triggerSetup)
    }

    func testToggleRole_AddsAndRemoves() {
        let vm = BowtieOnboardingViewModel()
        vm.toggleSuggestionRole("Husband")
        XCTAssertTrue(vm.selectedSuggestionRoles.contains("Husband"))
        vm.toggleSuggestionRole("Husband")
        XCTAssertFalse(vm.selectedSuggestionRoles.contains("Husband"))
    }

    func testAddCustomRole_InsertsAndClearsField() {
        let vm = BowtieOnboardingViewModel()
        vm.customRoleLabel = "  Leader  "
        vm.addCustomRole()
        XCTAssertTrue(vm.selectedSuggestionRoles.contains("Leader"))
        XCTAssertEqual(vm.customRoleLabel, "")
    }

    func testAddCustomRole_IgnoresEmptyInput() {
        let vm = BowtieOnboardingViewModel()
        vm.customRoleLabel = "   "
        vm.addCustomRole()
        XCTAssertTrue(vm.selectedSuggestionRoles.isEmpty)
    }

    func testToggleTrigger_AddsAndRemoves() {
        let vm = BowtieOnboardingViewModel()
        vm.toggleSuggestionTrigger("Rejection")
        XCTAssertTrue(vm.selectedSuggestionTriggers.contains("Rejection"))
        vm.toggleSuggestionTrigger("Rejection")
        XCTAssertFalse(vm.selectedSuggestionTriggers.contains("Rejection"))
    }

    func testCompleteOnboarding_SavesRolesAndTriggers() {
        let vm = BowtieOnboardingViewModel()
        vm.selectedSuggestionRoles = Set(["Husband", "Father"])
        vm.selectedSuggestionTriggers = Set(["Rejection"])
        vm.completeOnboarding(context: context)

        let roles = try! context.fetch(FetchDescriptor<RRUserRole>())
        XCTAssertEqual(roles.count, 2)

        let triggers = try! context.fetch(FetchDescriptor<RRKnownEmotionalTrigger>())
        XCTAssertEqual(triggers.count, 1)
        XCTAssertEqual(triggers[0].mappedI, .insignificance)
    }

    func testCompleteOnboarding_SetsFlag() {
        let vm = BowtieOnboardingViewModel()
        vm.completeOnboarding(context: context)
        XCTAssertTrue(BowtieOnboardingViewModel.isOnboardingCompleted)
    }

    func testProgressFraction_CalculatesCorrectly() {
        let vm = BowtieOnboardingViewModel()
        XCTAssertEqual(vm.progressFraction, 0.25, accuracy: 0.01)
        vm.goForward()
        XCTAssertEqual(vm.progressFraction, 0.5, accuracy: 0.01)
        vm.goForward()
        XCTAssertEqual(vm.progressFraction, 0.75, accuracy: 0.01)
        vm.goForward()
        XCTAssertEqual(vm.progressFraction, 1.0, accuracy: 0.01)
    }

    func testIsFirstStep_AndIsLastStep() {
        let vm = BowtieOnboardingViewModel()
        XCTAssertTrue(vm.isFirstStep)
        XCTAssertFalse(vm.isLastStep)
        vm.goForward()
        vm.goForward()
        vm.goForward()
        XCTAssertFalse(vm.isFirstStep)
        XCTAssertTrue(vm.isLastStep)
    }
}
