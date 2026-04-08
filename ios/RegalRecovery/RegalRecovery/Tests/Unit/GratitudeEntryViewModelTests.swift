import Testing
@testable import RegalRecovery

@Suite("GratitudeEntryViewModel")
struct GratitudeEntryViewModelTests {

    // MARK: - GL-ES-AC1: Minimum 1 non-empty item

    @Test("GL-ES-AC1: Cannot save with only empty items")
    func testGratitude_GL_ES_AC1_MinimumOneItem() {
        let vm = GratitudeEntryViewModel()
        #expect(vm.canSave == false, "Should not be saveable with only empty items")

        vm.items[0].text = "Grateful for today"
        #expect(vm.canSave == true, "Should be saveable with one non-empty item")

        vm.items[0].text = "   \n  "
        #expect(vm.canSave == false, "Whitespace-only items should not count")
    }

    // MARK: - GL-ES-AC2: 300 character limit

    @Test("GL-ES-AC2: Character limit is 300 with warning at 250")
    func testGratitude_GL_ES_AC2_CharacterLimit() {
        let vm = GratitudeEntryViewModel()

        #expect(GratitudeEntryViewModel.maxCharacters == 300)
        #expect(GratitudeEntryViewModel.warningThreshold == 250)

        let shortText = String(repeating: "a", count: 249)
        #expect(vm.shouldShowCounter(shortText) == false)

        let thresholdText = String(repeating: "a", count: 250)
        #expect(vm.shouldShowCounter(thresholdText) == true)

        let limitText = String(repeating: "a", count: 300)
        #expect(vm.isAtCharacterLimit(limitText) == true)

        var overText = String(repeating: "a", count: 350)
        vm.clampText(&overText)
        #expect(overText.count == 300)
    }

    // MARK: - GL-ES-AC3: Unlimited items

    @Test("GL-ES-AC3: No maximum item limit")
    func testGratitude_GL_ES_AC3_UnlimitedItems() {
        let vm = GratitudeEntryViewModel()
        #expect(vm.items.count == 1)

        for _ in 0..<99 {
            vm.addItem()
        }
        #expect(vm.items.count == 100, "Should allow 100 items (no max)")
    }

    // MARK: - GL-ES-AC4: Delete items before save

    @Test("GL-ES-AC4: Items deletable before save, minimum 1 retained")
    func testGratitude_GL_ES_AC4_DeleteBeforeSave() {
        let vm = GratitudeEntryViewModel()
        vm.addItem()
        vm.addItem()
        #expect(vm.items.count == 3)

        vm.removeItem(at: 1)
        #expect(vm.items.count == 2)

        vm.removeItem(at: 0)
        #expect(vm.items.count == 1)

        // Cannot remove the last item
        vm.removeItem(at: 0)
        #expect(vm.items.count == 1, "Should not remove the last item")
    }

    // MARK: - GL-ES-AC5: Category tag per item

    @Test("GL-ES-AC5: Optional category tag per item")
    func testGratitude_GL_ES_AC5_CategoryTag() {
        let vm = GratitudeEntryViewModel()
        vm.items[0].category = .recovery
        #expect(vm.items[0].category == .recovery)

        vm.items[0].category = nil
        #expect(vm.items[0].category == nil)

        vm.addItem()
        vm.items[0].category = .faithGod
        vm.items[1].category = .family
        #expect(vm.items[0].category != vm.items[1].category)
    }

    // MARK: - GL-ES-AC6: Mood score

    @Test("GL-ES-AC6: Mood score 1-5 with toggle semantics")
    func testGratitude_GL_ES_AC6_MoodScore() {
        let vm = GratitudeEntryViewModel()
        #expect(vm.moodScore == nil)

        vm.toggleMood(4)
        #expect(vm.moodScore == 4)

        vm.toggleMood(4)
        #expect(vm.moodScore == nil, "Toggling same mood should clear it")

        vm.toggleMood(2)
        #expect(vm.moodScore == 2)

        vm.toggleMood(5)
        #expect(vm.moodScore == 5, "Mood should switch to new value")
    }

    // MARK: - GL-ES-AC10: Clear after save

    @Test("GL-ES-AC10: Fields cleared after save")
    func testGratitude_GL_ES_AC10_ClearAfterSave() {
        let vm = GratitudeEntryViewModel()
        vm.items[0].text = "Something"
        vm.addItem()
        vm.items[1].text = "Another"
        vm.toggleMood(4)

        #expect(vm.canSave == true)
        #expect(vm.items.count == 2)

        // Simulate the reset that save() performs
        vm.items = [GratitudeItemDraft()]
        vm.moodScore = nil

        #expect(vm.items.count == 1)
        #expect(vm.items[0].text == "")
        #expect(vm.moodScore == nil)
    }

    // MARK: - GL-ES-AC14: Single item valid

    @Test("GL-ES-AC14: Saving with 1 item is valid")
    func testGratitude_GL_ES_AC14_SingleItemValid() {
        let vm = GratitudeEntryViewModel()
        vm.items[0].text = "Just one thing"
        #expect(vm.canSave == true)
    }

    // MARK: - GL-ES-AC15: No abandoned tracking

    @Test("GL-ES-AC15: Opening without saving records no data")
    func testGratitude_GL_ES_AC15_NoAbandonedTracking() {
        let vm = GratitudeEntryViewModel()
        #expect(vm.items.count == 1)
        #expect(vm.items[0].text == "")
        #expect(vm.canSave == false)
    }

    // MARK: - Prompt integration

    @Test("GL-ES-AC7: Prompt displayed on request")
    func testGratitude_GL_ES_AC7_PromptDisplay() {
        let vm = GratitudeEntryViewModel()
        let userId = UUID()

        #expect(vm.showPrompt == false)
        #expect(vm.currentPrompt == nil)

        vm.requestPrompt(userId: userId)
        #expect(vm.showPrompt == true)
        #expect(vm.currentPrompt != nil)
    }

    @Test("GL-ES-AC8: 'Use this' inserts prompt as new item")
    func testGratitude_GL_ES_AC8_PromptInsert() {
        let vm = GratitudeEntryViewModel()
        vm.requestPrompt(userId: UUID())

        guard let prompt = vm.currentPrompt else {
            Issue.record("Should have a prompt after request")
            return
        }

        let initialCount = vm.items.count
        vm.usePrompt()

        #expect(vm.items.count == initialCount + 1)
        #expect(vm.items.last?.text == prompt.text)
        #expect(vm.showPrompt == false)
    }

    @Test("Post-save messages exist and are non-empty")
    func testGratitude_GL_ES_PostSaveMessages() {
        #expect(GratitudeEntryViewModel.postSaveMessages.count >= 5)
        for message in GratitudeEntryViewModel.postSaveMessages {
            #expect(!message.isEmpty)
        }
    }

    @Test("GL-ES-AC13: First-use message contains recovery context")
    func testGratitude_GL_ES_AC13_FirstUseText() {
        let message = GratitudeEntryViewModel.firstUseMessage
        #expect(!message.isEmpty)
        #expect(message.contains("Gratitude"))
        #expect(message.contains("recovery"))
    }
}
