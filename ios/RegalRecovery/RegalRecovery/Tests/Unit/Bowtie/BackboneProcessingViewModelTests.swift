import XCTest
import SwiftData
@testable import RegalRecovery

final class BackboneProcessingViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() {
        super.setUp()
        container = try! RRModelConfiguration.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    func testInitialStep_IsLifeSituation() {
        let vm = BackboneProcessingViewModel()
        XCTAssertEqual(vm.currentStep, .lifeSituation)
    }

    func testCanAdvance_LifeSituation_RequiresText() {
        let vm = BackboneProcessingViewModel()
        XCTAssertFalse(vm.canAdvance)
        vm.lifeSituation = "Boss criticized my report"
        XCTAssertTrue(vm.canAdvance)
    }

    func testCanAdvance_LifeSituation_WhitespaceOnly_IsFalse() {
        let vm = BackboneProcessingViewModel()
        vm.lifeSituation = "   "
        XCTAssertFalse(vm.canAdvance)
    }

    func testCanAdvance_Emotions_RequiresOne() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .emotions
        XCTAssertFalse(vm.canAdvance)
        vm.selectedEmotions.insert("frustrated")
        XCTAssertTrue(vm.canAdvance)
    }

    func testCanAdvance_ThreeIs_RequiresOne() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .threeIs
        XCTAssertFalse(vm.canAdvance)
        vm.iActivations.append(IActivation(iType: .incompetence, intensity: 5))
        XCTAssertTrue(vm.canAdvance)
    }

    func testCanAdvance_SpiritualReflection_AlwaysTrue() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .spiritualReflection
        XCTAssertTrue(vm.canAdvance)
    }

    func testCanAdvance_Needs_RequiresOne() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .emotionalNeeds
        XCTAssertFalse(vm.canAdvance)
        vm.selectedNeeds.insert("affirmation")
        XCTAssertTrue(vm.canAdvance)
    }

    func testCanAdvance_Actions_RequiresOne() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .intimacyActions
        XCTAssertFalse(vm.canAdvance)
        vm.selectedActions.append(IntimacyAction(category: .self_, label: "Journal", isCustom: false))
        XCTAssertTrue(vm.canAdvance)
    }

    func testGoForward_AdvancesStep() {
        let vm = BackboneProcessingViewModel()
        vm.lifeSituation = "Something happened"
        vm.goForward()
        XCTAssertEqual(vm.currentStep, .emotions)
    }

    func testGoForward_WhenCannotAdvance_DoesNothing() {
        let vm = BackboneProcessingViewModel()
        vm.goForward()
        XCTAssertEqual(vm.currentStep, .lifeSituation)
    }

    func testGoBack_AtFirst_DoesNothing() {
        let vm = BackboneProcessingViewModel()
        vm.goBack()
        XCTAssertEqual(vm.currentStep, .lifeSituation)
    }

    func testGoBack_FromEmotions_GoesToLifeSituation() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .emotions
        vm.goBack()
        XCTAssertEqual(vm.currentStep, .lifeSituation)
    }

    func testProgressFraction() {
        let vm = BackboneProcessingViewModel()
        XCTAssertEqual(vm.progressFraction, 1.0 / 6.0, accuracy: 0.001)
        vm.currentStep = .intimacyActions
        XCTAssertEqual(vm.progressFraction, 1.0, accuracy: 0.001)
    }

    func testToggleEmotion() {
        let vm = BackboneProcessingViewModel()
        vm.toggleEmotion("sad")
        XCTAssertTrue(vm.selectedEmotions.contains("sad"))
        vm.toggleEmotion("sad")
        XCTAssertFalse(vm.selectedEmotions.contains("sad"))
    }

    func testToggleNeed() {
        let vm = BackboneProcessingViewModel()
        vm.toggleNeed("affirmation")
        XCTAssertTrue(vm.selectedNeeds.contains("affirmation"))
        vm.toggleNeed("affirmation")
        XCTAssertFalse(vm.selectedNeeds.contains("affirmation"))
    }

    func testToggleIActivation() {
        let vm = BackboneProcessingViewModel()
        vm.toggleIActivation(.incompetence, intensity: 7)
        XCTAssertEqual(vm.iActivations.count, 1)
        XCTAssertEqual(vm.iActivations.first?.iType, .incompetence)
        XCTAssertEqual(vm.iActivations.first?.intensity, 7)
        vm.toggleIActivation(.incompetence)
        XCTAssertTrue(vm.iActivations.isEmpty)
    }

    func testUpdateIntensity() {
        let vm = BackboneProcessingViewModel()
        vm.toggleIActivation(.impotence, intensity: 3)
        vm.updateIntensity(for: .impotence, to: 8)
        XCTAssertEqual(vm.iActivations.first?.intensity, 8)
    }

    func testUpdateIntensity_ClampsToRange() {
        let vm = BackboneProcessingViewModel()
        vm.toggleIActivation(.insignificance, intensity: 5)
        vm.updateIntensity(for: .insignificance, to: 0)
        XCTAssertEqual(vm.iActivations.first?.intensity, 1)
        vm.updateIntensity(for: .insignificance, to: 15)
        XCTAssertEqual(vm.iActivations.first?.intensity, 10)
    }

    func testToggleAction() {
        let vm = BackboneProcessingViewModel()
        let action = IntimacyAction(category: .self_, label: "Journal", isCustom: false)
        vm.toggleAction(action)
        XCTAssertEqual(vm.selectedActions.count, 1)
        vm.toggleAction(action)
        XCTAssertTrue(vm.selectedActions.isEmpty)
    }

    func testAddCustomAction() {
        let vm = BackboneProcessingViewModel()
        vm.addCustomAction(category: .god, label: "Meditation")
        XCTAssertEqual(vm.selectedActions.count, 1)
        XCTAssertTrue(vm.selectedActions.first?.isCustom ?? false)
        XCTAssertEqual(vm.selectedActions.first?.label, "Meditation")
    }

    func testAddCustomAction_EmptyLabel_DoesNothing() {
        let vm = BackboneProcessingViewModel()
        vm.addCustomAction(category: .god, label: "   ")
        XCTAssertTrue(vm.selectedActions.isEmpty)
    }

    func testAddCustomEmotion() {
        let vm = BackboneProcessingViewModel()
        vm.customEmotionText = "  Melancholy  "
        vm.addCustomEmotion()
        XCTAssertTrue(vm.selectedEmotions.contains("melancholy"))
        XCTAssertEqual(vm.customEmotionText, "")
    }

    func testAddCustomNeed() {
        let vm = BackboneProcessingViewModel()
        vm.customNeedText = " Dignity "
        vm.addCustomNeed()
        XCTAssertTrue(vm.selectedNeeds.contains("dignity"))
        XCTAssertEqual(vm.customNeedText, "")
    }

    func testSave_CreatesProcessingAndMarksMarker() {
        let session = RRBowtieSession(selectedRoleIds: [UUID()])
        context.insert(session)
        let marker = RRBowtieMarker(
            side: .past,
            timeIntervalHours: 6,
            roleId: UUID(),
            iActivations: [IActivation(iType: .incompetence, intensity: 5)]
        )
        marker.session = session
        context.insert(marker)

        let vm = BackboneProcessingViewModel()
        vm.lifeSituation = "Boss said my report was sloppy"
        vm.selectedEmotions = Set(["frustrated", "embarrassed"])
        vm.iActivations = [IActivation(iType: .incompetence, intensity: 7)]
        vm.spiritualReflectionText = "I felt distant from God"
        vm.selectedNeeds = Set(["affirmation", "respect"])
        vm.selectedActions = [IntimacyAction(category: .self_, label: "Journal", isCustom: false)]
        vm.save(marker: marker, context: context)

        XCTAssertTrue(marker.isProcessed)
        XCTAssertTrue(vm.showCompletion)
        XCTAssertNotNil(marker.backboneProcessing)
        XCTAssertEqual(marker.backboneProcessing?.lifeSituation, "Boss said my report was sloppy")
    }

    func testIsFirstStep_AndIsLastStep() {
        let vm = BackboneProcessingViewModel()
        XCTAssertTrue(vm.isFirstStep)
        XCTAssertFalse(vm.isLastStep)
        vm.currentStep = .intimacyActions
        XCTAssertFalse(vm.isFirstStep)
        XCTAssertTrue(vm.isLastStep)
    }
}
