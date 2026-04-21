import Foundation

// MARK: - Supporting Types

struct PersonaRelapse {
    let daysAgo: Int
    let notes: String
    let triggers: [String]
}

struct PersonaAddiction {
    let name: String
    let sobrietyDate: Date
    let relapses: [PersonaRelapse]
}

// MARK: - SeedPersona

struct SeedPersona: Identifiable {
    let id: String
    let name: String
    let email: String
    let birthYear: Int
    let gender: String
    let timezone: String
    let bibleVersion: String
    let motivations: [String]
    let avatarInitial: String

    /// Array of addictions with sobriety dates and relapse history.
    let addictions: [PersonaAddiction]

    /// How actively this persona uses the app day-to-day.
    let activityLevel: ActivityLevel

    /// Days since the most recent sobriety date across all addictions.
    let sobrietyDays: Int

    /// How long this persona has been using the app.
    let daysInApp: Int

    /// Short one-line label for display.
    let tagline: String

    /// Longer description of the persona's scenario.
    let description: String

    /// Which group this persona belongs to in the picker.
    let category: Category

    enum ActivityLevel: String {
        case intensive
        case moderate
        case minimal
        case single
        case inactive
    }

    enum Category: String, CaseIterable {
        case longTermRecovery = "Long-term Recovery"
        case earlyRecovery = "Early Recovery"
        case frequentRelapses = "Frequent Relapses"
        case multipleAddictions = "Multiple Addictions"
        case edgeCases = "Edge Cases"
    }
}

// MARK: - Date Helpers

private let _calendar = Calendar.current
private let _now = Date()

private func daysAgo(_ days: Int) -> Date {
    _calendar.date(byAdding: .day, value: -days, to: _now)!
}

// MARK: - Relapse Pattern Generators

/// Generates relapses every N days for a given span, starting from `startDaysAgo`.
private func relapsePattern(
    every interval: Int,
    over span: Int,
    startDaysAgo start: Int = 0,
    notes: String = "Relapse",
    triggers: [String] = []
) -> [PersonaRelapse] {
    var relapses: [PersonaRelapse] = []
    var day = start
    while day <= start + span {
        relapses.append(PersonaRelapse(daysAgo: day, notes: notes, triggers: triggers))
        day += interval
    }
    return relapses
}

/// Generates relapses at irregular intervals from a list of specific days-ago values.
private func irregularRelapses(
    daysAgoValues: [Int],
    notes: String = "Relapse",
    triggers: [String] = []
) -> [PersonaRelapse] {
    daysAgoValues.map {
        PersonaRelapse(daysAgo: $0, notes: notes, triggers: triggers)
    }
}

// MARK: - All Personas

extension SeedPersona {

    static let allPersonas: [SeedPersona] = {
        var personas: [SeedPersona] = []

        // =====================================================================
        // MARK: Group 1 -- Long-term Recovery
        // =====================================================================

        // 1. Alex -- The original demo persona
        personas.append(SeedPersona(
            id: "alex",
            name: "Alex",
            email: "alex@example.com",
            birthYear: 1990,
            gender: "Male",
            timezone: "America/Chicago",
            bibleVersion: "ESV",
            motivations: ["Faith", "Family", "Freedom"],
            avatarInitial: "A",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(270),
                    relapses: [
                        PersonaRelapse(daysAgo: 280, notes: "Emotional trigger after argument", triggers: ["emotional", "relational"]),
                        PersonaRelapse(daysAgo: 310, notes: "Traveling alone for work", triggers: ["isolation", "travel"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Pornography",
                    sobrietyDate: daysAgo(270),
                    relapses: [
                        PersonaRelapse(daysAgo: 280, notes: "Late night alone on phone", triggers: ["digital", "isolation"]),
                        PersonaRelapse(daysAgo: 310, notes: "Hotel room boredom", triggers: ["isolation", "travel"]),
                    ]
                ),
            ],
            activityLevel: .intensive,
            sobrietyDays: 270,
            daysInApp: 270,
            tagline: "Steady recovery, intensive engagement",
            description: "The original demo persona. 270 days sober from sex and porn addictions. Has sponsor, counselor, and spouse in support network. On step 8. Uses nearly every activity daily.",
            category: .longTermRecovery
        ))

        // 2. Marcus -- 2 years sober, alcohol and gambling
        personas.append(SeedPersona(
            id: "marcus",
            name: "Marcus",
            email: "marcus@example.com",
            birthYear: 1974,
            gender: "Male",
            timezone: "America/New_York",
            bibleVersion: "NIV",
            motivations: ["Sobriety", "Health", "Grandkids"],
            avatarInitial: "M",
            addictions: [
                PersonaAddiction(
                    name: "Alcohol",
                    sobrietyDate: daysAgo(730),
                    relapses: [
                        PersonaRelapse(daysAgo: 750, notes: "Holiday party pressure", triggers: ["social", "holiday"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Gambling",
                    sobrietyDate: daysAgo(730),
                    relapses: [
                        PersonaRelapse(daysAgo: 760, notes: "Sports season started", triggers: ["boredom", "habit"]),
                    ]
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 730,
            daysInApp: 760,
            tagline: "Two-year veteran, AA active",
            description: "2 years sober from alcohol and gambling. Moderate activity user. Active in AA meetings. Steady and reliable in recovery routines.",
            category: .longTermRecovery
        ))

        // 3. Elena -- 18 months sober, faith-based approach
        personas.append(SeedPersona(
            id: "elena",
            name: "Elena",
            email: "elena@example.com",
            birthYear: 1992,
            gender: "Female",
            timezone: "America/Denver",
            bibleVersion: "NLT",
            motivations: ["Faith", "Purity", "Marriage"],
            avatarInitial: "E",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(548),
                    relapses: [
                        PersonaRelapse(daysAgo: 570, notes: "Lonely weekend", triggers: ["loneliness", "emotional"]),
                        PersonaRelapse(daysAgo: 600, notes: "Dating app relapse", triggers: ["digital", "compulsive"]),
                    ]
                ),
            ],
            activityLevel: .intensive,
            sobrietyDays: 548,
            daysInApp: 600,
            tagline: "Faith-driven, prayer and devotionals focused",
            description: "18 months sober from sex addiction. Faith-based approach -- uses prayer and devotionals heavily. Deep scripture engagement and journaling.",
            category: .longTermRecovery
        ))

        // 4. David -- 3 years sober, porn only, minimal user
        personas.append(SeedPersona(
            id: "david",
            name: "David",
            email: "david@example.com",
            birthYear: 1981,
            gender: "Male",
            timezone: "America/Los_Angeles",
            bibleVersion: "KJV",
            motivations: ["Integrity", "Marriage", "Self-respect"],
            avatarInitial: "D",
            addictions: [
                PersonaAddiction(
                    name: "Pornography",
                    sobrietyDate: daysAgo(1095),
                    relapses: [
                        PersonaRelapse(daysAgo: 1100, notes: "Stress at work", triggers: ["stress", "digital"]),
                    ]
                ),
            ],
            activityLevel: .minimal,
            sobrietyDays: 1095,
            daysInApp: 1100,
            tagline: "Single addiction, long-term, light usage",
            description: "3 years sober from pornography only. Single addiction, minimal activity user -- just commitment and FASTER scale. Proof that simple routines work.",
            category: .longTermRecovery
        ))

        // 5. Grace -- 500+ days, codependency and love addiction
        personas.append(SeedPersona(
            id: "grace",
            name: "Grace",
            email: "grace@example.com",
            birthYear: 1997,
            gender: "Female",
            timezone: "America/Chicago",
            bibleVersion: "ESV",
            motivations: ["Independence", "Self-worth", "Healthy relationships"],
            avatarInitial: "G",
            addictions: [
                PersonaAddiction(
                    name: "Codependency",
                    sobrietyDate: daysAgo(520),
                    relapses: [
                        PersonaRelapse(daysAgo: 540, notes: "Tried to fix ex's problems again", triggers: ["relational", "compulsive"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Love Addiction",
                    sobrietyDate: daysAgo(520),
                    relapses: [
                        PersonaRelapse(daysAgo: 545, notes: "Obsessing over new crush", triggers: ["emotional", "fantasy"]),
                    ]
                ),
            ],
            activityLevel: .intensive,
            sobrietyDays: 520,
            daysInApp: 550,
            tagline: "Intensive journaler and gratitude logger",
            description: "500+ days sober from codependency and love addiction. Intensive journaler and gratitude logger. Writes long-form reflections almost every day.",
            category: .longTermRecovery
        ))

        // =====================================================================
        // MARK: Group 2 -- Early Recovery
        // =====================================================================

        // 6. Tyler -- 30 days, just started
        personas.append(SeedPersona(
            id: "tyler",
            name: "Tyler",
            email: "tyler@example.com",
            birthYear: 2002,
            gender: "Male",
            timezone: "America/New_York",
            bibleVersion: "NIV",
            motivations: ["Freedom", "Future"],
            avatarInitial: "T",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(30),
                    relapses: []
                ),
            ],
            activityLevel: .single,
            sobrietyDays: 30,
            daysInApp: 30,
            tagline: "Brand new, commitment only",
            description: "30 days sober from sex addiction. Just started the app and only uses the sobriety commitment activity. Tests the single-activity early user flow.",
            category: .earlyRecovery
        ))

        // 7. Sarah -- 14 days, porn and social media
        personas.append(SeedPersona(
            id: "sarah",
            name: "Sarah",
            email: "sarah@example.com",
            birthYear: 1995,
            gender: "Female",
            timezone: "America/Chicago",
            bibleVersion: "NLT",
            motivations: ["Mental health", "Presence", "Authenticity"],
            avatarInitial: "S",
            addictions: [
                PersonaAddiction(
                    name: "Pornography",
                    sobrietyDate: daysAgo(14),
                    relapses: [
                        PersonaRelapse(daysAgo: 16, notes: "Scrolled into triggering content", triggers: ["digital", "boredom"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Social Media",
                    sobrietyDate: daysAgo(14),
                    relapses: [
                        PersonaRelapse(daysAgo: 18, notes: "3-hour doom scroll late at night", triggers: ["boredom", "insomnia"]),
                    ]
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 14,
            daysInApp: 20,
            tagline: "Two weeks in, logging moods and urges",
            description: "14 days sober from porn and social media addiction. Moderate user logging moods and urges regularly. Still figuring out her routine.",
            category: .earlyRecovery
        ))

        // 8. James -- 7 days, trying everything
        personas.append(SeedPersona(
            id: "james",
            name: "James",
            email: "james@example.com",
            birthYear: 1988,
            gender: "Male",
            timezone: "America/Denver",
            bibleVersion: "ESV",
            motivations: ["Family", "Faith", "Healing"],
            avatarInitial: "J",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(7),
                    relapses: [
                        PersonaRelapse(daysAgo: 10, notes: "Fell after stressful week", triggers: ["stress", "fatigue"]),
                        PersonaRelapse(daysAgo: 14, notes: "Felt hopeless about marriage", triggers: ["emotional", "relational"]),
                    ]
                ),
            ],
            activityLevel: .intensive,
            sobrietyDays: 7,
            daysInApp: 14,
            tagline: "Brand new but trying everything",
            description: "7 days sober from sex addiction. Brand new to recovery but exploring every feature in the app with high energy and motivation.",
            category: .earlyRecovery
        ))

        // 9. Priya -- 45 days, journaling and gratitude
        personas.append(SeedPersona(
            id: "priya",
            name: "Priya",
            email: "priya@example.com",
            birthYear: 1999,
            gender: "Female",
            timezone: "Asia/Kolkata",
            bibleVersion: "NIV",
            motivations: ["Self-love", "Boundaries", "Growth"],
            avatarInitial: "P",
            addictions: [
                PersonaAddiction(
                    name: "Love Addiction",
                    sobrietyDate: daysAgo(45),
                    relapses: [
                        PersonaRelapse(daysAgo: 50, notes: "Texted ex after seeing his photo", triggers: ["digital", "nostalgia"]),
                    ]
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 45,
            daysInApp: 55,
            tagline: "Journaling and gratitude focused",
            description: "45 days sober from love/relationship addiction. Uses journaling and gratitude as her primary tools. Quiet but consistent.",
            category: .earlyRecovery
        ))

        // 10. Nate -- 3 days, barely using app
        personas.append(SeedPersona(
            id: "nate",
            name: "Nate",
            email: "nate@example.com",
            birthYear: 1984,
            gender: "Male",
            timezone: "America/Chicago",
            bibleVersion: "ESV",
            motivations: ["Health"],
            avatarInitial: "N",
            addictions: [
                PersonaAddiction(
                    name: "Alcohol",
                    sobrietyDate: daysAgo(3),
                    relapses: [
                        PersonaRelapse(daysAgo: 5, notes: "Drank after work", triggers: ["habit", "social"]),
                        PersonaRelapse(daysAgo: 8, notes: "Weekend binge", triggers: ["boredom", "social"]),
                    ]
                ),
            ],
            activityLevel: .inactive,
            sobrietyDays: 3,
            daysInApp: 10,
            tagline: "Just installed, barely logging",
            description: "3 days sober from alcohol. Barely using the app yet. Downloaded it but hasn't built a routine. Tests the near-empty data state.",
            category: .earlyRecovery
        ))

        // =====================================================================
        // MARK: Group 3 -- Frequent Relapses
        // =====================================================================

        // 11. Derek -- Daily resets for 30 days
        let derekRelapses = relapsePattern(
            every: 1,
            over: 29,
            startDaysAgo: 1,
            notes: "Daily struggle -- reset again",
            triggers: ["compulsive", "habitual"]
        )
        personas.append(SeedPersona(
            id: "derek",
            name: "Derek",
            email: "derek@example.com",
            birthYear: 1993,
            gender: "Male",
            timezone: "America/New_York",
            bibleVersion: "NIV",
            motivations: ["Freedom", "Sanity"],
            avatarInitial: "D",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(0),
                    relapses: derekRelapses
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 0,
            daysInApp: 30,
            tagline: "Daily resets, pattern of struggle",
            description: "Sex addiction with resets every day or every other day for the past 30 days. Shows the pattern of daily struggle with no sustained streak.",
            category: .frequentRelapses
        ))

        // 12. Carlos -- Dual addiction, alternating resets
        // Sex resets every other day starting on Mondays; alcohol resets every 4th day
        let carlosSexRelapses = relapsePattern(
            every: 2,
            over: 59,
            startDaysAgo: 0,
            notes: "Sex addiction reset",
            triggers: ["compulsive", "emotional"]
        )
        let carlosAlcoholRelapses = relapsePattern(
            every: 4,
            over: 59,
            startDaysAgo: 0,
            notes: "Alcohol reset",
            triggers: ["social", "stress"]
        )
        personas.append(SeedPersona(
            id: "carlos",
            name: "Carlos",
            email: "carlos@example.com",
            birthYear: 1998,
            gender: "Male",
            timezone: "America/Chicago",
            bibleVersion: "NLT",
            motivations: ["Family", "Career", "Control"],
            avatarInitial: "C",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(0),
                    relapses: carlosSexRelapses
                ),
                PersonaAddiction(
                    name: "Alcohol",
                    sobrietyDate: daysAgo(0),
                    relapses: carlosAlcoholRelapses
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 0,
            daysInApp: 60,
            tagline: "Dual addiction, alternating resets",
            description: "Dual addiction: sex (resets every other day) and alcohol (resets every 4th day). 60 days in app with a complex overlapping relapse pattern.",
            category: .frequentRelapses
        ))

        // 13. Ryan -- Weekly relapses for 3 months
        let ryanRelapses = relapsePattern(
            every: 7,
            over: 89,
            startDaysAgo: 0,
            notes: "Weekly relapse cycle",
            triggers: ["weekend", "boredom", "digital"]
        )
        personas.append(SeedPersona(
            id: "ryan",
            name: "Ryan",
            email: "ryan@example.com",
            birthYear: 2004,
            gender: "Male",
            timezone: "America/Los_Angeles",
            bibleVersion: "ESV",
            motivations: ["Self-improvement", "Discipline"],
            avatarInitial: "R",
            addictions: [
                PersonaAddiction(
                    name: "Pornography",
                    sobrietyDate: daysAgo(0),
                    relapses: ryanRelapses
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 0,
            daysInApp: 90,
            tagline: "Weekly relapse cycle, some activity logging",
            description: "Porn addiction with weekly relapses (every 7 days) for 3 months. Some activity logging between relapses. Tests the consistent weekly pattern.",
            category: .frequentRelapses
        ))

        // 14. Ashley -- Irregular relapses
        let ashleyRelapses = irregularRelapses(
            daysAgoValues: [5, 14, 27],
            notes: "Unpredictable relapse",
            triggers: ["emotional", "relational", "stress"]
        )
        personas.append(SeedPersona(
            id: "ashley",
            name: "Ashley",
            email: "ashley@example.com",
            birthYear: 1991,
            gender: "Female",
            timezone: "America/Denver",
            bibleVersion: "NIV",
            motivations: ["Healing", "Family", "Trust"],
            avatarInitial: "A",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(5),
                    relapses: ashleyRelapses
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 5,
            daysInApp: 60,
            tagline: "Irregular relapses, unpredictable pattern",
            description: "Sex addiction with irregular relapses -- 3 resets in past month at unpredictable intervals. Moderate user between episodes. Tests non-pattern data.",
            category: .frequentRelapses
        ))

        // 15. Tommy -- Alcohol and drugs, every 2-3 days
        let tommyAlcoholRelapses = relapsePattern(
            every: 2,
            over: 89,
            startDaysAgo: 0,
            notes: "Alcohol relapse",
            triggers: ["peers", "boredom"]
        )
        let tommyDrugRelapses = relapsePattern(
            every: 3,
            over: 89,
            startDaysAgo: 1,
            notes: "Drug relapse",
            triggers: ["peers", "availability"]
        )
        personas.append(SeedPersona(
            id: "tommy",
            name: "Tommy",
            email: "tommy@example.com",
            birthYear: 2007,
            gender: "Male",
            timezone: "America/New_York",
            bibleVersion: "NLT",
            motivations: ["Survival", "Mom"],
            avatarInitial: "T",
            addictions: [
                PersonaAddiction(
                    name: "Alcohol",
                    sobrietyDate: daysAgo(0),
                    relapses: tommyAlcoholRelapses
                ),
                PersonaAddiction(
                    name: "Drugs",
                    sobrietyDate: daysAgo(1),
                    relapses: tommyDrugRelapses
                ),
            ],
            activityLevel: .minimal,
            sobrietyDays: 0,
            daysInApp: 90,
            tagline: "Young, frequent relapses, minimal logging",
            description: "Alcohol and drugs, relapses every 2-3 days. Has been in app 90 days with minimal logging. Tests the heavy-relapse, low-engagement scenario.",
            category: .frequentRelapses
        ))

        // =====================================================================
        // MARK: Group 4 -- Multiple Addictions
        // =====================================================================

        // 16. Michael -- 4 addictions, different sobriety dates
        personas.append(SeedPersona(
            id: "michael",
            name: "Michael",
            email: "michael@example.com",
            birthYear: 1986,
            gender: "Male",
            timezone: "America/Chicago",
            bibleVersion: "ESV",
            motivations: ["Faith", "Family", "Career", "Health"],
            avatarInitial: "M",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(120),
                    relapses: [
                        PersonaRelapse(daysAgo: 125, notes: "Business trip relapse", triggers: ["travel", "isolation"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Pornography",
                    sobrietyDate: daysAgo(90),
                    relapses: [
                        PersonaRelapse(daysAgo: 95, notes: "Late night browsing", triggers: ["digital", "insomnia"]),
                        PersonaRelapse(daysAgo: 130, notes: "Stressful deadline", triggers: ["stress", "digital"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Alcohol",
                    sobrietyDate: daysAgo(90),
                    relapses: [
                        PersonaRelapse(daysAgo: 100, notes: "Client dinner", triggers: ["social", "professional"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Gambling",
                    sobrietyDate: daysAgo(90),
                    relapses: [
                        PersonaRelapse(daysAgo: 110, notes: "Fantasy football escalated", triggers: ["boredom", "competitive"]),
                    ]
                ),
            ],
            activityLevel: .intensive,
            sobrietyDays: 90,
            daysInApp: 150,
            tagline: "Four addictions, active recovery across all",
            description: "4 addictions: sex, porn, alcohol, gambling. 120 days sober from sex, 90 from others. Active user engaging with multiple activities daily.",
            category: .multipleAddictions
        ))

        // 17. Lisa -- 3 addictions: love, codependency, shopping
        personas.append(SeedPersona(
            id: "lisa",
            name: "Lisa",
            email: "lisa@example.com",
            birthYear: 1989,
            gender: "Female",
            timezone: "America/New_York",
            bibleVersion: "NLT",
            motivations: ["Independence", "Financial freedom", "Self-worth"],
            avatarInitial: "L",
            addictions: [
                PersonaAddiction(
                    name: "Love Addiction",
                    sobrietyDate: daysAgo(200),
                    relapses: [
                        PersonaRelapse(daysAgo: 210, notes: "Reached out to toxic ex", triggers: ["loneliness", "nostalgia"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Codependency",
                    sobrietyDate: daysAgo(150),
                    relapses: [
                        PersonaRelapse(daysAgo: 155, notes: "Took over friend's problems", triggers: ["relational", "compulsive"]),
                        PersonaRelapse(daysAgo: 220, notes: "Sacrificed boundaries for approval", triggers: ["fear", "people-pleasing"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Shopping/Spending",
                    sobrietyDate: daysAgo(100),
                    relapses: [
                        PersonaRelapse(daysAgo: 105, notes: "Emotional shopping spree", triggers: ["emotional", "boredom"]),
                        PersonaRelapse(daysAgo: 160, notes: "Online sale triggered binge", triggers: ["digital", "impulsive"]),
                    ]
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 100,
            daysInApp: 230,
            tagline: "Three behavioral addictions, staggered recovery",
            description: "3 addictions: love/relationship, codependency, shopping/spending. Each with different sobriety dates showing staggered recovery progress.",
            category: .multipleAddictions
        ))

        // 18. Victor -- Sex and cannabis, mixed patterns
        let victorSexRelapses = relapsePattern(
            every: 2,
            over: 59,
            startDaysAgo: 0,
            notes: "Sex addiction reset",
            triggers: ["compulsive", "loneliness"]
        )
        personas.append(SeedPersona(
            id: "victor",
            name: "Victor",
            email: "victor@example.com",
            birthYear: 1996,
            gender: "Male",
            timezone: "America/Los_Angeles",
            bibleVersion: "NIV",
            motivations: ["Clarity", "Ambition", "Relationships"],
            avatarInitial: "V",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(0),
                    relapses: victorSexRelapses
                ),
                PersonaAddiction(
                    name: "Cannabis",
                    sobrietyDate: daysAgo(60),
                    relapses: [
                        PersonaRelapse(daysAgo: 65, notes: "Friend offered at party", triggers: ["social", "availability"]),
                    ]
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 0,
            daysInApp: 70,
            tagline: "Split recovery -- one addiction active, one stable",
            description: "2 addictions: sex and cannabis. Sex resets every other day while cannabis is 60 days sober. Shows uneven recovery across addictions.",
            category: .multipleAddictions
        ))

        // 19. Diana -- 5 addictions, various histories
        personas.append(SeedPersona(
            id: "diana",
            name: "Diana",
            email: "diana@example.com",
            birthYear: 2001,
            gender: "Female",
            timezone: "America/Chicago",
            bibleVersion: "ESV",
            motivations: ["Focus", "Presence", "Health", "Career"],
            avatarInitial: "D",
            addictions: [
                PersonaAddiction(
                    name: "Pornography",
                    sobrietyDate: daysAgo(45),
                    relapses: [
                        PersonaRelapse(daysAgo: 50, notes: "Algorithm showed triggering content", triggers: ["digital", "accidental"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Social Media",
                    sobrietyDate: daysAgo(30),
                    relapses: [
                        PersonaRelapse(daysAgo: 35, notes: "Downloaded TikTok again", triggers: ["boredom", "habitual"]),
                        PersonaRelapse(daysAgo: 60, notes: "FOMO on friend's post", triggers: ["social", "comparison"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Gaming",
                    sobrietyDate: daysAgo(20),
                    relapses: [
                        PersonaRelapse(daysAgo: 25, notes: "New game release pulled me back", triggers: ["novelty", "escapism"]),
                        PersonaRelapse(daysAgo: 40, notes: "All-night gaming session", triggers: ["boredom", "escapism"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Shopping/Spending",
                    sobrietyDate: daysAgo(60),
                    relapses: [
                        PersonaRelapse(daysAgo: 70, notes: "Prime Day impulse buys", triggers: ["digital", "impulsive"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Caffeine",
                    sobrietyDate: daysAgo(10),
                    relapses: [
                        PersonaRelapse(daysAgo: 12, notes: "Grabbed an energy drink for deadline", triggers: ["stress", "fatigue"]),
                        PersonaRelapse(daysAgo: 15, notes: "Coffee with friends", triggers: ["social", "habitual"]),
                        PersonaRelapse(daysAgo: 20, notes: "Morning habit crept back", triggers: ["habitual"]),
                    ]
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 10,
            daysInApp: 80,
            tagline: "Five addictions, digital-age struggles",
            description: "5 addictions: porn, social media, gaming, shopping, caffeine. Different reset histories for each. Tests the many-addictions UI.",
            category: .multipleAddictions
        ))

        // 20. Samuel -- 3 addictions with uneven recovery
        let samuelSexRelapses = irregularRelapses(
            daysAgoValues: [3, 8, 14, 19, 25, 33, 40, 50, 58, 66, 75, 85],
            notes: "Sex addiction relapse",
            triggers: ["compulsive", "stress", "emotional"]
        )
        personas.append(SeedPersona(
            id: "samuel",
            name: "Samuel",
            email: "samuel@example.com",
            birthYear: 1978,
            gender: "Male",
            timezone: "America/New_York",
            bibleVersion: "KJV",
            motivations: ["Faith", "Marriage", "Legacy"],
            avatarInitial: "S",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(3),
                    relapses: samuelSexRelapses
                ),
                PersonaAddiction(
                    name: "Pornography",
                    sobrietyDate: daysAgo(45),
                    relapses: [
                        PersonaRelapse(daysAgo: 50, notes: "Stumbled online", triggers: ["digital", "habitual"]),
                        PersonaRelapse(daysAgo: 80, notes: "Insomnia browsing", triggers: ["insomnia", "digital"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Alcohol",
                    sobrietyDate: daysAgo(200),
                    relapses: [
                        PersonaRelapse(daysAgo: 210, notes: "Anniversary dinner wine", triggers: ["social", "celebration"]),
                    ]
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 3,
            daysInApp: 220,
            tagline: "Uneven recovery -- one addiction still active",
            description: "3 addictions: sex, porn, alcohol. Sex with many resets (12 in 90 days), porn 45 days clean, alcohol 200 days clean. Shows uneven recovery progress.",
            category: .multipleAddictions
        ))

        // =====================================================================
        // MARK: Group 5 -- Edge Cases
        // =====================================================================

        // 21. Noah -- Brand new, zero data
        personas.append(SeedPersona(
            id: "noah",
            name: "Noah",
            email: "noah@example.com",
            birthYear: 2006,
            gender: "Male",
            timezone: "America/Chicago",
            bibleVersion: "NIV",
            motivations: [],
            avatarInitial: "N",
            addictions: [],
            activityLevel: .inactive,
            sobrietyDays: 0,
            daysInApp: 0,
            tagline: "Fresh install, zero data",
            description: "Brand new user, just installed. Zero data, zero activities, no addictions configured. Tests the completely empty state.",
            category: .edgeCases
        ))

        // 22. Emma -- Single addiction, single activity, heavy usage
        personas.append(SeedPersona(
            id: "emma",
            name: "Emma",
            email: "emma@example.com",
            birthYear: 1994,
            gender: "Female",
            timezone: "America/Denver",
            bibleVersion: "NLT",
            motivations: ["Purity", "Mental health"],
            avatarInitial: "E",
            addictions: [
                PersonaAddiction(
                    name: "Pornography",
                    sobrietyDate: daysAgo(365),
                    relapses: [
                        PersonaRelapse(daysAgo: 370, notes: "Relapse after bad breakup", triggers: ["emotional", "loneliness"]),
                    ]
                ),
            ],
            activityLevel: .single,
            sobrietyDays: 365,
            daysInApp: 380,
            tagline: "One year sober, mood-only user",
            description: "Single addiction (porn), 1 year sober, uses ONLY mood rating every day. 365 consecutive mood entries. Tests single-activity heavy usage patterns.",
            category: .edgeCases
        ))

        // 23. Kevin -- Inactive gap then returned
        personas.append(SeedPersona(
            id: "kevin",
            name: "Kevin",
            email: "kevin@example.com",
            birthYear: 1971,
            gender: "Male",
            timezone: "America/New_York",
            bibleVersion: "KJV",
            motivations: ["Health", "Retirement", "Grandkids"],
            avatarInitial: "K",
            addictions: [
                PersonaAddiction(
                    name: "Alcohol",
                    sobrietyDate: daysAgo(400),
                    relapses: [
                        PersonaRelapse(daysAgo: 420, notes: "Retirement party relapse", triggers: ["social", "celebration"]),
                    ]
                ),
            ],
            activityLevel: .moderate,
            sobrietyDays: 400,
            daysInApp: 400,
            tagline: "Returned after 60-day gap",
            description: "Inactive for 60 days then came back. Has old data with a gap in the middle. Alcohol addiction, 400 days total. Tests data continuity with gaps.",
            category: .edgeCases
        ))

        // 24. Mia -- Uses every single activity daily
        personas.append(SeedPersona(
            id: "mia",
            name: "Mia",
            email: "mia@example.com",
            birthYear: 2000,
            gender: "Female",
            timezone: "America/Los_Angeles",
            bibleVersion: "ESV",
            motivations: ["Wholeness", "Faith", "Discipline", "Growth"],
            avatarInitial: "M",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(90),
                    relapses: [
                        PersonaRelapse(daysAgo: 95, notes: "Stressful week led to acting out", triggers: ["stress", "isolation"]),
                    ]
                ),
            ],
            activityLevel: .intensive,
            sobrietyDays: 90,
            daysInApp: 100,
            tagline: "Maximal engagement -- every activity, every day",
            description: "Uses every single activity type in the app daily. Intensive across all categories. Sex addiction, 90 days sober. The power user stress test.",
            category: .edgeCases
        ))

        // 25. Robert -- 1000+ days, veteran, light use
        personas.append(SeedPersona(
            id: "robert",
            name: "Robert",
            email: "robert@example.com",
            birthYear: 1966,
            gender: "Male",
            timezone: "America/Chicago",
            bibleVersion: "KJV",
            motivations: ["Legacy", "Service", "Gratitude"],
            avatarInitial: "R",
            addictions: [
                PersonaAddiction(
                    name: "Sex",
                    sobrietyDate: daysAgo(1095),
                    relapses: [
                        PersonaRelapse(daysAgo: 1100, notes: "Major life crisis years ago", triggers: ["grief", "isolation"]),
                    ]
                ),
                PersonaAddiction(
                    name: "Pornography",
                    sobrietyDate: daysAgo(1095),
                    relapses: [
                        PersonaRelapse(daysAgo: 1100, notes: "Same crisis period", triggers: ["grief", "digital"]),
                    ]
                ),
            ],
            activityLevel: .minimal,
            sobrietyDays: 1095,
            daysInApp: 1100,
            tagline: "Veteran recovery, light maintenance",
            description: "1000+ days sober from sex and porn. Veteran in recovery. Now only uses the sobriety commitment daily. Sponsors others. Tests the long-term minimal-use case.",
            category: .edgeCases
        ))

        return personas
    }()
}
