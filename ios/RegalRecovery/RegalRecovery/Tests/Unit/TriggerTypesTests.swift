import Testing
@testable import RegalRecovery

@Suite("TriggerTypes")
struct TriggerTypesTests {

    // MARK: - TriggerCategory Tests

    @Test("TriggerCategory has 7 cases")
    func triggerCategory_HasSevenCases() {
        #expect(TriggerCategory.allCases.count == 7)
    }

    @Test("TriggerCategory display names are non-empty")
    func triggerCategory_DisplayNamesNonEmpty() {
        for category in TriggerCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    @Test("TriggerCategory icons are non-empty")
    func triggerCategory_IconsNonEmpty() {
        for category in TriggerCategory.allCases {
            #expect(!category.icon.isEmpty)
        }
    }

    // MARK: - TimeOfDaySlot Tests

    @Test("TimeOfDaySlot.from maps hour 6 to earlyMorning")
    func timeOfDaySlot_From6ReturnsEarlyMorning() {
        #expect(TimeOfDaySlot.from(hour: 6) == .earlyMorning)
    }

    @Test("TimeOfDaySlot.from maps hour 10 to morning")
    func timeOfDaySlot_From10ReturnsMorning() {
        #expect(TimeOfDaySlot.from(hour: 10) == .morning)
    }

    @Test("TimeOfDaySlot.from maps hour 14 to afternoon")
    func timeOfDaySlot_From14ReturnsAfternoon() {
        #expect(TimeOfDaySlot.from(hour: 14) == .afternoon)
    }

    @Test("TimeOfDaySlot.from maps hour 19 to evening")
    func timeOfDaySlot_From19ReturnsEvening() {
        #expect(TimeOfDaySlot.from(hour: 19) == .evening)
    }

    @Test("TimeOfDaySlot.from maps hour 23 to lateNight")
    func timeOfDaySlot_From23ReturnsLateNight() {
        #expect(TimeOfDaySlot.from(hour: 23) == .lateNight)
    }

    @Test("TimeOfDaySlot.from maps hour 2 to lateNight")
    func timeOfDaySlot_From2ReturnsLateNight() {
        #expect(TimeOfDaySlot.from(hour: 2) == .lateNight)
    }

    // MARK: - RiskLevel Tests

    @Test("RiskLevel.from maps intensity 1 to low")
    func riskLevel_From1ReturnsLow() {
        #expect(RiskLevel.from(intensity: 1) == .low)
    }

    @Test("RiskLevel.from maps intensity 3 to low")
    func riskLevel_From3ReturnsLow() {
        #expect(RiskLevel.from(intensity: 3) == .low)
    }

    @Test("RiskLevel.from maps intensity 4 to moderate")
    func riskLevel_From4ReturnsModerate() {
        #expect(RiskLevel.from(intensity: 4) == .moderate)
    }

    @Test("RiskLevel.from maps intensity 6 to moderate")
    func riskLevel_From6ReturnsModerate() {
        #expect(RiskLevel.from(intensity: 6) == .moderate)
    }

    @Test("RiskLevel.from maps intensity 7 to high")
    func riskLevel_From7ReturnsHigh() {
        #expect(RiskLevel.from(intensity: 7) == .high)
    }

    @Test("RiskLevel.from maps intensity 10 to high")
    func riskLevel_From10ReturnsHigh() {
        #expect(RiskLevel.from(intensity: 10) == .high)
    }

    // MARK: - LogDepth Tests

    @Test("LogDepth has 3 cases")
    func logDepth_HasThreeCases() {
        #expect(LogDepth.allCases.count == 3)
    }

    // MARK: - SocialContext Tests

    @Test("SocialContext has 7 cases")
    func socialContext_HasSevenCases() {
        #expect(SocialContext.allCases.count == 7)
    }

    // MARK: - UnmetNeed Tests

    @Test("UnmetNeed has 7 cases")
    func unmetNeed_HasSevenCases() {
        #expect(UnmetNeed.allCases.count == 7)
    }
}
