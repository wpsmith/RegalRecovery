import Testing
@testable import RegalRecovery

@Suite("TriggerSeedData")
struct TriggerSeedDataTests {

    // MARK: - Total Count Tests

    @Test("Seed data contains exactly 120 triggers")
    func seedData_ContainsExactly120Triggers() {
        #expect(TriggerSeedData.allTriggers.count == 120)
    }

    @Test("Popular subset contains 20 items")
    func seedData_PopularContains20Items() {
        #expect(TriggerSeedData.popularTriggers.count == 20)
    }

    @Test("Popular items are a subset of allTriggers")
    func seedData_PopularItemsAreSubsetOfAll() {
        let allLabels = Set(TriggerSeedData.allTriggers.map { $0.label })
        let popularLabels = Set(TriggerSeedData.popularTriggers.map { $0.label })
        #expect(popularLabels.isSubset(of: allLabels))
    }

    // MARK: - Category Coverage Tests

    @Test("Seed data covers all 7 categories")
    func seedData_CoversAllSevenCategories() {
        let categories = Set(TriggerSeedData.allTriggers.map { $0.category })
        #expect(categories.count == 7)
        #expect(categories.contains(.emotional))
        #expect(categories.contains(.physical))
        #expect(categories.contains(.environmental))
        #expect(categories.contains(.relational))
        #expect(categories.contains(.cognitive))
        #expect(categories.contains(.spiritual))
        #expect(categories.contains(.situational))
    }

    // MARK: - Category Count Tests

    @Test("Emotional category has 24 items")
    func seedData_EmotionalCategoryHas24Items() {
        let emotionalTriggers = TriggerSeedData.allTriggers.filter { $0.category == .emotional }
        #expect(emotionalTriggers.count == 24)
    }

    @Test("Physical category has 13 items")
    func seedData_PhysicalCategoryHas13Items() {
        let physicalTriggers = TriggerSeedData.allTriggers.filter { $0.category == .physical }
        #expect(physicalTriggers.count == 13)
    }

    @Test("Environmental category has 17 items")
    func seedData_EnvironmentalCategoryHas17Items() {
        let environmentalTriggers = TriggerSeedData.allTriggers.filter { $0.category == .environmental }
        #expect(environmentalTriggers.count == 17)
    }

    @Test("Relational category has 18 items")
    func seedData_RelationalCategoryHas18Items() {
        let relationalTriggers = TriggerSeedData.allTriggers.filter { $0.category == .relational }
        #expect(relationalTriggers.count == 18)
    }

    @Test("Cognitive category has 17 items")
    func seedData_CognitiveCategoryHas17Items() {
        let cognitiveTriggers = TriggerSeedData.allTriggers.filter { $0.category == .cognitive }
        #expect(cognitiveTriggers.count == 17)
    }

    @Test("Spiritual category has 13 items")
    func seedData_SpiritualCategoryHas13Items() {
        let spiritualTriggers = TriggerSeedData.allTriggers.filter { $0.category == .spiritual }
        #expect(spiritualTriggers.count == 13)
    }

    @Test("Situational category has 18 items")
    func seedData_SituationalCategoryHas18Items() {
        let situationalTriggers = TriggerSeedData.allTriggers.filter { $0.category == .situational }
        #expect(situationalTriggers.count == 18)
    }

    // MARK: - Duplicate Tests

    @Test("No duplicate labels in emotional category")
    func seedData_NoDuplicateLabelsInEmotional() {
        let emotionalTriggers = TriggerSeedData.allTriggers.filter { $0.category == .emotional }
        let labels = emotionalTriggers.map { $0.label }
        let uniqueLabels = Set(labels)
        #expect(labels.count == uniqueLabels.count)
    }

    @Test("No duplicate labels in physical category")
    func seedData_NoDuplicateLabelsInPhysical() {
        let physicalTriggers = TriggerSeedData.allTriggers.filter { $0.category == .physical }
        let labels = physicalTriggers.map { $0.label }
        let uniqueLabels = Set(labels)
        #expect(labels.count == uniqueLabels.count)
    }

    @Test("No duplicate labels in environmental category")
    func seedData_NoDuplicateLabelsInEnvironmental() {
        let environmentalTriggers = TriggerSeedData.allTriggers.filter { $0.category == .environmental }
        let labels = environmentalTriggers.map { $0.label }
        let uniqueLabels = Set(labels)
        #expect(labels.count == uniqueLabels.count)
    }

    @Test("No duplicate labels in relational category")
    func seedData_NoDuplicateLabelsInRelational() {
        let relationalTriggers = TriggerSeedData.allTriggers.filter { $0.category == .relational }
        let labels = relationalTriggers.map { $0.label }
        let uniqueLabels = Set(labels)
        #expect(labels.count == uniqueLabels.count)
    }

    @Test("No duplicate labels in cognitive category")
    func seedData_NoDuplicateLabelsInCognitive() {
        let cognitiveTriggers = TriggerSeedData.allTriggers.filter { $0.category == .cognitive }
        let labels = cognitiveTriggers.map { $0.label }
        let uniqueLabels = Set(labels)
        #expect(labels.count == uniqueLabels.count)
    }

    @Test("No duplicate labels in spiritual category")
    func seedData_NoDuplicateLabelsInSpiritual() {
        let spiritualTriggers = TriggerSeedData.allTriggers.filter { $0.category == .spiritual }
        let labels = spiritualTriggers.map { $0.label }
        let uniqueLabels = Set(labels)
        #expect(labels.count == uniqueLabels.count)
    }

    @Test("No duplicate labels in situational category")
    func seedData_NoDuplicateLabelsInSituational() {
        let situationalTriggers = TriggerSeedData.allTriggers.filter { $0.category == .situational }
        let labels = situationalTriggers.map { $0.label }
        let uniqueLabels = Set(labels)
        #expect(labels.count == uniqueLabels.count)
    }

    // MARK: - Coping Strategies Tests

    @Test("System coping strategies cover all 7 categories")
    func copingStrategies_CoverAllSevenCategories() {
        let categories = Set(TriggerSeedData.systemCopingStrategies.map { $0.category })
        #expect(categories.count == 7)
        #expect(categories.contains(.emotional))
        #expect(categories.contains(.physical))
        #expect(categories.contains(.environmental))
        #expect(categories.contains(.relational))
        #expect(categories.contains(.cognitive))
        #expect(categories.contains(.spiritual))
        #expect(categories.contains(.situational))
    }

    @Test("System coping strategies contain 22 items")
    func copingStrategies_Contains22Items() {
        #expect(TriggerSeedData.systemCopingStrategies.count == 22)
    }

    @Test("All coping strategies have non-empty labels")
    func copingStrategies_AllHaveNonEmptyLabels() {
        for strategy in TriggerSeedData.systemCopingStrategies {
            #expect(!strategy.label.isEmpty)
        }
    }

    @Test("All coping strategies have non-empty descriptions")
    func copingStrategies_AllHaveNonEmptyDescriptions() {
        for strategy in TriggerSeedData.systemCopingStrategies {
            #expect(!strategy.description.isEmpty)
        }
    }
}
