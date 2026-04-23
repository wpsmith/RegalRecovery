import Foundation

struct LBIDimensionContent: Identifiable {
    var id: LBIDimensionType { dimensionType }
    let dimensionType: LBIDimensionType
    let title: String
    let description: String
    let promptQuestion: String
    let exampleBehaviors: [String]
    let isPositiveCategory: Bool
    let positiveNote: String?
}

extension LBIDimensionContent {
    static let all: [LBIDimensionContent] = [
        // 1. Physical Health
        LBIDimensionContent(
            dimensionType: .physicalHealth,
            title: String(localized: "Physical Health"),
            description: String(localized: "The ultimate insanity is to not take care of our body. When our physical health deteriorates, we have nothing. Yet we seem to have little time for physical conditioning."),
            promptQuestion: String(localized: "How do you know that you are not taking care of your body?"),
            exampleBehaviors: [
                String(localized: "Exceeding target weight"),
                String(localized: "Missing exercise 2+ days"),
                String(localized: "Skipping meals"),
                String(localized: "Not sleeping enough"),
                String(localized: "Neglecting medication"),
                String(localized: "Skipping hygiene routines")
            ],
            isPositiveCategory: false,
            positiveNote: nil
        ),

        // 2. Environment
        LBIDimensionContent(
            dimensionType: .environment,
            title: String(localized: "Environment"),
            description: String(localized: "To not have time to do your personal chores is a comment on the order of your life. How you maintain your living space and handle daily logistics reflects your overall state of manageability."),
            promptQuestion: String(localized: "What are ways in which you neglect your living space or daily logistics?"),
            exampleBehaviors: [
                String(localized: "Unwashed dishes"),
                String(localized: "Overdue laundry"),
                String(localized: "Depleted groceries"),
                String(localized: "Neglected vehicle maintenance"),
                String(localized: "Cluttered living space"),
                String(localized: "Missed routine appointments"),
                String(localized: "Reckless driving")
            ],
            isPositiveCategory: false,
            positiveNote: nil
        ),

        // 3. Work
        LBIDimensionContent(
            dimensionType: .work,
            title: String(localized: "Work"),
            description: String(localized: "Chaos at work is risky for recovery. When professional responsibilities start slipping, it often signals that your overall life management is eroding."),
            promptQuestion: String(localized: "When your life is unmanageable at work, what are your behaviors?"),
            exampleBehaviors: [
                String(localized: "Unreturned calls/emails 24+ hours"),
                String(localized: "Late to meetings"),
                String(localized: "Falling behind on commitments"),
                String(localized: "Overloaded schedule"),
                String(localized: "Procrastinating important tasks")
            ],
            isPositiveCategory: false,
            positiveNote: nil
        ),

        // 4. Interests (POSITIVE category)
        LBIDimensionContent(
            dimensionType: .interests,
            title: String(localized: "Interests"),
            description: String(localized: "What are some positive interests, besides work, that give you perspective on the world? These are the activities that nourish your soul and keep you grounded."),
            promptQuestion: String(localized: "What positive activities give you perspective and joy when you're not overextended?"),
            exampleBehaviors: [
                String(localized: "Reading"),
                String(localized: "Music"),
                String(localized: "Cooking"),
                String(localized: "Gardening"),
                String(localized: "Fishing"),
                String(localized: "Photography"),
                String(localized: "Sports"),
                String(localized: "Creative hobbies"),
                String(localized: "Time in nature")
            ],
            isPositiveCategory: true,
            positiveNote: String(localized: "This is the only category where you list positive activities. If you select one of these for your daily tracking, it will be rephrased as \"Lack of [activity]\" to track when you're missing it.")
        ),

        // 5. Social Life
        LBIDimensionContent(
            dimensionType: .socialLife,
            title: String(localized: "Social Life"),
            description: String(localized: "Think of friends in your social network — beyond a significant other and family members — who provide significant support for you. Isolation is one of the earliest signs of lifestyle erosion."),
            promptQuestion: String(localized: "What are signs that you've become isolated from your social support network?"),
            exampleBehaviors: [
                String(localized: "Canceling plans"),
                String(localized: "Not returning friends' calls"),
                String(localized: "Avoiding social gatherings"),
                String(localized: "Spending weekends alone"),
                String(localized: "Losing touch with non-family friends")
            ],
            isPositiveCategory: false,
            positiveNote: nil
        ),

        // 6. Family, Relationships & Significant Others
        LBIDimensionContent(
            dimensionType: .familyAndSignificantOthers,
            title: String(localized: "Family, Relationships & Significant Others"),
            description: String(localized: "Examples of craziness in this area include staying silent, becoming overtly hostile, or engaging in passive-aggressive behaviors. How you treat those closest to you reveals your inner state."),
            promptQuestion: String(localized: "What behaviors indicate disconnection from those closest to you?"),
            exampleBehaviors: [
                String(localized: "Going silent"),
                String(localized: "Passive-aggressive behavior"),
                String(localized: "Avoiding conflict conversations"),
                String(localized: "Breaking promises to family"),
                String(localized: "Neglecting quality time"),
                String(localized: "Lying or withholding truth"),
                String(localized: "Boundary violations")
            ],
            isPositiveCategory: false,
            positiveNote: nil
        ),

        // 7. Finances
        LBIDimensionContent(
            dimensionType: .finances,
            title: String(localized: "Finances"),
            description: String(localized: "We handle our financial resources much like our personal resources. Signs of financial overextension often parallel various forms of emotional overextension."),
            promptQuestion: String(localized: "What signs indicate that you are financially overextended?"),
            exampleBehaviors: [
                String(localized: "Unbalanced checking account"),
                String(localized: "Overdue bills"),
                String(localized: "Spending more than earning"),
                String(localized: "Impulse purchases"),
                String(localized: "Avoiding looking at bank statements")
            ],
            isPositiveCategory: false,
            positiveNote: nil
        ),

        // 8. Spiritual Life & Personal Reflection
        LBIDimensionContent(
            dimensionType: .spiritualLife,
            title: String(localized: "Spiritual Life & Personal Reflection"),
            description: String(localized: "Spirituality can include prayer, meditation, Bible reading, devotionals, and church attendance. Personal reflection includes journaling, daily readings, and therapy."),
            promptQuestion: String(localized: "What sources of spiritual nourishment and personal reflection do you neglect when overextended?"),
            exampleBehaviors: [
                String(localized: "Skipping prayer/devotionals"),
                String(localized: "Missing church"),
                String(localized: "No Bible reading"),
                String(localized: "Neglecting journaling"),
                String(localized: "Avoiding quiet time"),
                String(localized: "Skipping therapy appointments")
            ],
            isPositiveCategory: false,
            positiveNote: nil
        ),

        // 9. Other Compulsive/Symptomatic Behaviors
        LBIDimensionContent(
            dimensionType: .compulsiveBehaviors,
            title: String(localized: "Other Compulsive/Symptomatic Behaviors"),
            description: String(localized: "Compulsive behaviors with negative consequences indicate something about your general well-being and state of overall recovery. Symptomatic behaviors like forgetfulness, slips of the tongue, or jealousy are further evidence of overextension."),
            promptQuestion: String(localized: "What negative compulsive or symptomatic behaviors appear when you feel 'on the edge'?"),
            exampleBehaviors: [
                String(localized: "Excessive screen time"),
                String(localized: "Overeating"),
                String(localized: "Nail biting"),
                String(localized: "Compulsive shopping"),
                String(localized: "Jealousy"),
                String(localized: "Forgetfulness"),
                String(localized: "Irritability"),
                String(localized: "Caffeine/sugar overuse")
            ],
            isPositiveCategory: false,
            positiveNote: nil
        ),

        // 10. Recovery Practice & Therapeutic Self-Care
        LBIDimensionContent(
            dimensionType: .recoveryPractice,
            title: String(localized: "Recovery Practice & Therapeutic Self-Care"),
            description: String(localized: "Living a recovery-focused life involves many practices. Group attendance, step work, sponsorship, service, and recovery phone calls become the foundation of good recovery."),
            promptQuestion: String(localized: "What recovery activities do you neglect first?"),
            exampleBehaviors: [
                String(localized: "Missing SA/Celebrate Recovery meetings"),
                String(localized: "Not calling sponsor"),
                String(localized: "Skipping step work"),
                String(localized: "Avoiding accountability check-ins"),
                String(localized: "Neglecting therapeutic homework")
            ],
            isPositiveCategory: false,
            positiveNote: nil
        )
    ]

    static func content(for type: LBIDimensionType) -> LBIDimensionContent {
        all.first { $0.dimensionType == type }!
    }
}
