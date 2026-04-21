import Foundation
import SwiftData

/// Seeds the SwiftData store with data generated from a `SeedPersona` profile.
/// Activity volume and variety are driven by the persona's `activityLevel`.
enum SeedPersonaData {

    // MARK: - Date Helpers

    private static let calendar = Calendar.current
    private static let now = Date()

    private static func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now)!
    }

    private static func daysAgo(_ days: Int, hour: Int, minute: Int = 0) -> Date {
        let day = daysAgo(days)
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    private static func today(hour: Int, minute: Int = 0) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    // MARK: - Deterministic Random

    /// Simple seeded random for reproducible persona data.
    private struct SeededRandom {
        private var state: UInt64

        init(seed: UInt64) { state = seed }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }

        mutating func nextInt(in range: ClosedRange<Int>) -> Int {
            let span = UInt64(range.upperBound - range.lowerBound + 1)
            return range.lowerBound + Int(next() % span)
        }

        mutating func nextDouble() -> Double {
            Double(next() & 0x1F_FFFF_FFFF_FFFF) / Double(0x1F_FFFF_FFFF_FFFF)
        }

        mutating func nextBool(probability: Double = 0.5) -> Bool {
            nextDouble() < probability
        }
    }

    // MARK: - Milestone Scriptures

    private static let milestoneScriptures: [Int: String] = [
        1: "Lamentations 3:22-23 -- His mercies are new every morning.",
        3: "Psalm 30:5 -- Weeping may stay for the night, but rejoicing comes in the morning.",
        7: "Isaiah 40:31 -- Those who hope in the Lord will renew their strength.",
        14: "Philippians 1:6 -- He who began a good work in you will carry it on to completion.",
        30: "2 Corinthians 5:17 -- If anyone is in Christ, the new creation has come.",
        60: "Romans 8:37 -- We are more than conquerors through Him who loved us.",
        90: "Psalm 51:10 -- Create in me a pure heart, O God.",
        180: "James 1:12 -- Blessed is the one who perseveres under trial.",
        270: "Galatians 5:1 -- It is for freedom that Christ has set us free.",
        365: "Revelation 21:5 -- Behold, I am making all things new.",
    ]

    private static let milestoneDays = [1, 3, 7, 14, 30, 60, 90, 180, 270, 365]

    // MARK: - Main Seed Function

    static func seed(persona: SeedPersona, context: ModelContext) throws {
        let userId = UUID()
        var rng = SeededRandom(seed: UInt64(bitPattern: Int64(persona.name.hashValue &+ persona.birthYear)))

        // 1. Create user
        let user = seedUser(persona: persona, userId: userId, context: context)

        // 2. Create addictions, streaks, relapses, milestones
        let addictionIds = seedAddictions(
            persona: persona, userId: userId, user: user, context: context
        )

        // 3-8. Seed activities based on activity level
        switch persona.activityLevel {
        case .intensive:
            seedIntensive(persona: persona, userId: userId, addictionIds: addictionIds, rng: &rng, context: context)
        case .moderate:
            seedModerate(persona: persona, userId: userId, addictionIds: addictionIds, rng: &rng, context: context)
        case .minimal:
            seedMinimal(persona: persona, userId: userId, rng: &rng, context: context)
        case .single:
            seedSingle(persona: persona, userId: userId, rng: &rng, context: context)
        case .inactive:
            seedInactive(persona: persona, userId: userId, rng: &rng, context: context)
        }

        // Feature flags (shared with SeedData)
        try SeedData.seedFeatureFlags(context: context)

        try context.save()
        SeedData.markSeeded()
    }

    // MARK: - User

    @discardableResult
    private static func seedUser(
        persona: SeedPersona, userId: UUID, context: ModelContext
    ) -> RRUser {
        let user = RRUser(
            id: userId,
            name: persona.name,
            email: persona.email,
            birthYear: persona.birthYear,
            gender: persona.gender,
            timezone: persona.timezone,
            bibleVersion: persona.bibleVersion,
            motivations: persona.motivations,
            avatarInitial: persona.avatarInitial,
            createdAt: daysAgo(persona.daysInApp),
            modifiedAt: now
        )
        context.insert(user)
        return user
    }

    // MARK: - Addictions, Streaks, Relapses & Milestones

    /// Returns array of (addictionId, addictionName) tuples for downstream use.
    @discardableResult
    private static func seedAddictions(
        persona: SeedPersona, userId: UUID, user: RRUser, context: ModelContext
    ) -> [(id: UUID, name: String)] {
        var result: [(id: UUID, name: String)] = []

        for (index, pa) in persona.addictions.enumerated() {
            let addictionId = UUID()

            let addiction = RRAddiction(
                id: addictionId,
                name: pa.name,
                sobrietyDate: pa.sobrietyDate,
                userId: userId,
                sortOrder: index,
                createdAt: daysAgo(persona.daysInApp)
            )
            addiction.user = user
            context.insert(addiction)

            // Compute sobriety days from sobrietyDate
            let sobrietyDays = max(0, calendar.dateComponents([.day], from: pa.sobrietyDate, to: now).day ?? 0)

            // Compute longest streak from relapse history
            let longestStreak = computeLongestStreak(
                sobrietyDays: sobrietyDays,
                daysInApp: persona.daysInApp,
                relapses: pa.relapses
            )

            let streak = RRStreak(
                addictionId: addictionId,
                longestStreak: longestStreak,
                totalRelapses: pa.relapses.count,
                createdAt: daysAgo(persona.daysInApp)
            )
            streak.addiction = addiction
            context.insert(streak)

            // Relapses
            for relapse in pa.relapses {
                let r = RRRelapse(
                    addictionId: addictionId,
                    date: daysAgo(relapse.daysAgo),
                    notes: relapse.notes,
                    triggers: relapse.triggers,
                    createdAt: daysAgo(relapse.daysAgo)
                )
                r.addiction = addiction
                context.insert(r)
            }

            // Milestones — earned if sobriety days >= milestone threshold
            for days in milestoneDays where sobrietyDays >= days {
                let earnedAgo = sobrietyDays - days
                let scripture = milestoneScriptures[days] ?? "Psalm 23:4 -- Even though I walk through the valley of the shadow of death, I will fear no evil."
                let milestone = RRMilestone(
                    addictionId: addictionId,
                    days: days,
                    dateEarned: daysAgo(earnedAgo),
                    scripture: scripture,
                    createdAt: daysAgo(earnedAgo)
                )
                milestone.addiction = addiction
                context.insert(milestone)
            }

            result.append((id: addictionId, name: pa.name))
        }

        return result
    }

    private static func computeLongestStreak(
        sobrietyDays: Int, daysInApp: Int, relapses: [PersonaRelapse]
    ) -> Int {
        guard !relapses.isEmpty else { return sobrietyDays }

        let sortedRelapses = relapses.sorted { $0.daysAgo > $1.daysAgo }
        var longest = sobrietyDays // current streak from last relapse to now
        // Check gap from app start to first relapse
        let firstRelapseDaysAgo = sortedRelapses[0].daysAgo
        let startGap = daysInApp - firstRelapseDaysAgo
        longest = max(longest, startGap)

        // Check gaps between consecutive relapses
        for i in 0..<(sortedRelapses.count - 1) {
            let gap = sortedRelapses[i].daysAgo - sortedRelapses[i + 1].daysAgo
            longest = max(longest, gap)
        }

        return longest
    }

    // MARK: - Intensive Activity Level

    private static func seedIntensive(
        persona: SeedPersona, userId: UUID,
        addictionIds: [(id: UUID, name: String)],
        rng: inout SeededRandom, context: ModelContext
    ) {
        let span = min(persona.daysInApp, 90)

        seedCommitments(span: span, userId: userId, probability: 0.98, rng: &rng, context: context)
        seedMoodEntries(span: span, userId: userId, baseScore: 6, variance: 3, probability: 1.0, rng: &rng, context: context)
        seedFASTEREntries(span: span, userId: userId, probability: 5.0 / 7.0, stablePersona: true, rng: &rng, context: context)
        seedJournalEntries(span: span, userId: userId, perWeek: 3.5, rng: &rng, context: context)
        seedPrayerLogs(span: span, userId: userId, probability: 0.95, rng: &rng, context: context)
        seedExerciseLogs(span: span, userId: userId, probability: 4.5 / 7.0, rng: &rng, context: context)
        seedPhoneCallLogs(span: span, userId: userId, perWeek: 2.5, rng: &rng, context: context)
        seedMeetingLogs(span: span, userId: userId, perWeek: 2.5, rng: &rng, context: context)
        seedGratitudeEntries(span: span, userId: userId, probability: 0.95, rng: &rng, context: context)
        seedDailyScores(span: span, userId: userId, baseScore: 75, trendUp: true, rng: &rng, context: context)
        seedRecoveryPlan(userId: userId, itemCount: 12, context: context)
        seedStepWork(span: persona.daysInApp, userId: userId, completedSteps: 7, rng: &rng, context: context)
        seedGoals(userId: userId, count: 5, completedRatio: 0.8, rng: &rng, context: context)
        seedUrges(span: span, userId: userId, addictionIds: addictionIds, perWeek: 1.5, highIntensity: false, rng: &rng, context: context)
    }

    // MARK: - Moderate Activity Level

    private static func seedModerate(
        persona: SeedPersona, userId: UUID,
        addictionIds: [(id: UUID, name: String)],
        rng: inout SeededRandom, context: ModelContext
    ) {
        let span = min(persona.daysInApp, 60)

        seedCommitments(span: span, userId: userId, probability: 0.80, rng: &rng, context: context)
        seedMoodEntries(span: span, userId: userId, baseScore: 5, variance: 3, probability: 4.5 / 7.0, rng: &rng, context: context)
        seedFASTEREntries(span: span, userId: userId, probability: 2.5 / 7.0, stablePersona: true, rng: &rng, context: context)
        seedJournalEntries(span: span, userId: userId, perWeek: 1.5, rng: &rng, context: context)
        seedPrayerLogs(span: span, userId: userId, probability: 3.5 / 7.0, rng: &rng, context: context)
        seedExerciseLogs(span: span, userId: userId, probability: 2.5 / 7.0, rng: &rng, context: context)
        seedPhoneCallLogs(span: span, userId: userId, perWeek: 1.0, rng: &rng, context: context)
        seedMeetingLogs(span: span, userId: userId, perWeek: 1.5, rng: &rng, context: context)
        seedRecoveryPlan(userId: userId, itemCount: 7, context: context)
        seedStepWork(span: persona.daysInApp, userId: userId, completedSteps: 4, rng: &rng, context: context)
        seedDailyScores(span: span, userId: userId, baseScore: 60, trendUp: true, rng: &rng, context: context)
        seedUrges(span: span, userId: userId, addictionIds: addictionIds, perWeek: 2.0, highIntensity: false, rng: &rng, context: context)
    }

    // MARK: - Minimal Activity Level

    private static func seedMinimal(
        persona: SeedPersona, userId: UUID,
        rng: inout SeededRandom, context: ModelContext
    ) {
        let span = min(persona.daysInApp, 30)

        seedCommitments(span: span, userId: userId, probability: 0.35, rng: &rng, context: context)
        seedMoodEntries(span: span, userId: userId, baseScore: 4, variance: 3, probability: 2.5 / 7.0, rng: &rng, context: context)
        seedFASTEREntries(span: span, userId: userId, probability: 1.0 / 7.0, stablePersona: false, rng: &rng, context: context)
        seedRecoveryPlan(userId: userId, itemCount: 4, context: context)
        seedDailyScores(span: span, userId: userId, baseScore: 40, trendUp: false, rng: &rng, context: context)
    }

    // MARK: - Single Activity Level

    private static func seedSingle(
        persona: SeedPersona, userId: UUID,
        rng: inout SeededRandom, context: ModelContext
    ) {
        let span = min(persona.daysInApp, 60)

        // Pick one activity type deterministically based on persona name
        let activities = ["mood", "journal", "prayer", "exercise", "gratitude"]
        let pick = abs(persona.name.hashValue) % activities.count
        let chosen = activities[pick]

        switch chosen {
        case "mood":
            seedMoodEntries(span: span, userId: userId, baseScore: 5, variance: 3, probability: 0.95, rng: &rng, context: context)
        case "journal":
            seedJournalEntries(span: span, userId: userId, perWeek: 6.0, rng: &rng, context: context)
        case "prayer":
            seedPrayerLogs(span: span, userId: userId, probability: 0.95, rng: &rng, context: context)
        case "exercise":
            seedExerciseLogs(span: span, userId: userId, probability: 0.90, rng: &rng, context: context)
        case "gratitude":
            seedGratitudeEntries(span: span, userId: userId, probability: 0.95, rng: &rng, context: context)
        default:
            break
        }
    }

    // MARK: - Inactive Activity Level

    private static func seedInactive(
        persona: SeedPersona, userId: UUID,
        rng: inout SeededRandom, context: ModelContext
    ) {
        guard persona.daysInApp > 0 else { return }

        // Just 2-3 random mood entries
        let entryCount = rng.nextInt(in: 2...3)
        for _ in 0..<entryCount {
            let ago = rng.nextInt(in: 1...max(1, persona.daysInApp))
            let mood = RRMoodEntry(
                userId: userId,
                date: daysAgo(ago, hour: 14),
                score: rng.nextInt(in: 3...7),
                createdAt: daysAgo(ago, hour: 14)
            )
            context.insert(mood)
        }
    }

    // MARK: - Activity Generators

    private static func seedCommitments(
        span: Int, userId: UUID, probability: Double,
        rng: inout SeededRandom, context: ModelContext
    ) {
        for day in 0..<span {
            guard rng.nextBool(probability: probability) else { continue }
            let commitment = RRCommitment(
                userId: userId,
                date: daysAgo(day, hour: 6, minute: 14),
                type: "morning",
                completedAt: daysAgo(day, hour: 6, minute: 14),
                answers: JSONPayload([
                    "sobrietyCommit": .bool(true),
                    "reachOut": .bool(rng.nextBool(probability: 0.8)),
                    "attendMeeting": .bool(rng.nextBool(probability: 0.6)),
                    "prayerScripture": .bool(rng.nextBool(probability: 0.85)),
                    "honest": .bool(true),
                    "surrender": .bool(true),
                ]),
                createdAt: daysAgo(day, hour: 6, minute: 14)
            )
            context.insert(commitment)
        }
    }

    private static func seedMoodEntries(
        span: Int, userId: UUID, baseScore: Int, variance: Int,
        probability: Double, rng: inout SeededRandom, context: ModelContext
    ) {
        // Generate a trending mood pattern: earlier days lower, recent days higher
        for day in 0..<span {
            guard rng.nextBool(probability: probability) else { continue }

            let progress = Double(span - day) / Double(max(span, 1))
            let trend = Int(progress * 2.0) // 0-2 boost for more recent days
            let raw = baseScore + trend + rng.nextInt(in: 0...variance) - (variance / 2)
            let score = max(1, min(10, raw))

            let mood = RRMoodEntry(
                userId: userId,
                date: daysAgo(day, hour: rng.nextInt(in: 7...21)),
                score: score,
                createdAt: daysAgo(day, hour: 14)
            )
            context.insert(mood)
        }
    }

    private static func seedFASTEREntries(
        span: Int, userId: UUID, probability: Double,
        stablePersona: Bool, rng: inout SeededRandom, context: ModelContext
    ) {
        for day in 0..<span {
            guard rng.nextBool(probability: probability) else { continue }

            // Stage 0 = Restoration (healthy), higher = worse
            // Stable personas mostly at 0, occasionally 1
            // Unstable personas vary more widely
            let stage: Int
            if stablePersona {
                stage = rng.nextBool(probability: 0.80) ? 0 : 1
            } else {
                let roll = rng.nextInt(in: 0...10)
                switch roll {
                case 0...4: stage = 0
                case 5...7: stage = 1
                case 8...9: stage = 2
                default: stage = 3
                }
            }

            let entry = RRFASTEREntry(
                userId: userId,
                date: daysAgo(day, hour: 6, minute: 20),
                stage: stage,
                createdAt: daysAgo(day, hour: 6, minute: 20)
            )
            context.insert(entry)
        }
    }

    private static func seedJournalEntries(
        span: Int, userId: UUID, perWeek: Double,
        rng: inout SeededRandom, context: ModelContext
    ) {
        let modes = ["freeform", "prompted", "structured", "jotting"]
        let probability = perWeek / 7.0
        let prompts = [
            "Reflecting on gratitude and progress this week.",
            "Talked through feelings with a safe person tonight.",
            "Step work reflection — thinking about amends.",
            "Quick thought: the routine is anchoring my days.",
            "Processing a difficult conversation from today.",
            "Noticed a trigger and chose a healthy response.",
            "Feeling grateful for the small victories.",
            "Journaling about my fears and hopes.",
        ]

        for day in 0..<span {
            guard rng.nextBool(probability: probability) else { continue }

            let mode = modes[rng.nextInt(in: 0...(modes.count - 1))]
            let content = prompts[rng.nextInt(in: 0...(prompts.count - 1))]
            let entry = RRJournalEntry(
                userId: userId,
                date: daysAgo(day, hour: 21, minute: 15),
                mode: mode,
                content: content,
                createdAt: daysAgo(day, hour: 21, minute: 15)
            )
            context.insert(entry)
        }
    }

    private static func seedPrayerLogs(
        span: Int, userId: UUID, probability: Double,
        rng: inout SeededRandom, context: ModelContext
    ) {
        for day in 0..<span {
            guard rng.nextBool(probability: probability) else { continue }

            let prayer = RRPrayerLog(
                userId: userId,
                date: daysAgo(day, hour: 6),
                durationMinutes: rng.nextInt(in: 5...20),
                prayerType: "morning",
                createdAt: daysAgo(day, hour: 6)
            )
            context.insert(prayer)
        }
    }

    private static func seedExerciseLogs(
        span: Int, userId: UUID, probability: Double,
        rng: inout SeededRandom, context: ModelContext
    ) {
        let types = ["running", "weights", "yoga", "walking", "cycling"]

        for day in 0..<span {
            guard rng.nextBool(probability: probability) else { continue }

            let exerciseType = types[rng.nextInt(in: 0...(types.count - 1))]
            let log = RRExerciseLog(
                userId: userId,
                date: daysAgo(day, hour: 6, minute: 30),
                durationMinutes: rng.nextInt(in: 20...60),
                exerciseType: exerciseType,
                createdAt: daysAgo(day, hour: 6, minute: 30)
            )
            context.insert(log)
        }
    }

    private static func seedPhoneCallLogs(
        span: Int, userId: UUID, perWeek: Double,
        rng: inout SeededRandom, context: ModelContext
    ) {
        let names = ["James", "Mike", "Dr. Sarah", "David", "Pastor Tom"]
        let roles = ["sponsor", "accountabilityPartner", "counselor", "accountabilityPartner", "sponsor"]
        let probability = perWeek / 7.0

        for day in 0..<span {
            guard rng.nextBool(probability: probability) else { continue }

            let idx = rng.nextInt(in: 0...(names.count - 1))
            let log = RRPhoneCallLog(
                userId: userId,
                date: daysAgo(day, hour: 12, minute: 30),
                contactName: names[idx],
                contactRole: roles[idx],
                durationMinutes: rng.nextInt(in: 5...30),
                createdAt: daysAgo(day, hour: 12, minute: 30)
            )
            context.insert(log)
        }
    }

    private static func seedMeetingLogs(
        span: Int, userId: UUID, perWeek: Double,
        rng: inout SeededRandom, context: ModelContext
    ) {
        let meetingNames = ["SA Home Group", "SA Virtual Noon", "SA Step Study", "SA Sunday Night", "Recovery Group"]
        let probability = perWeek / 7.0

        for day in 0..<span {
            guard rng.nextBool(probability: probability) else { continue }

            let name = meetingNames[rng.nextInt(in: 0...(meetingNames.count - 1))]
            let log = RRMeetingLog(
                userId: userId,
                date: daysAgo(day, hour: 19),
                meetingName: name,
                durationMinutes: rng.nextInt(in: 60...90),
                createdAt: daysAgo(day, hour: 19)
            )
            context.insert(log)
        }
    }

    private static func seedGratitudeEntries(
        span: Int, userId: UUID, probability: Double,
        rng: inout SeededRandom, context: ModelContext
    ) {
        let texts: [(String, GratitudeCategory)] = [
            ("Another day of choosing recovery", .recovery),
            ("God's patience with me", .faithGod),
            ("A good conversation with my sponsor", .relationships),
            ("The quiet of early morning prayer", .faithGod),
            ("My family still believes in me", .family),
            ("A clear head this morning", .health),
            ("Progress in my step work", .growthProgress),
            ("The sunset on my evening walk", .natureBeauty),
            ("A good night of sleep", .health),
            ("The courage to be honest today", .recovery),
            ("Hot coffee and a moment of peace", .smallMoments),
            ("My counselor's wisdom", .relationships),
            ("Strength to resist temptation", .recovery),
            ("Learning something new about myself", .growthProgress),
            ("A productive day at work", .workCareer),
        ]

        for day in 0..<span {
            guard rng.nextBool(probability: probability) else { continue }

            let count = rng.nextInt(in: 2...4)
            var items: [GratitudeItem] = []
            var used: Set<Int> = []

            for order in 0..<count {
                var idx = rng.nextInt(in: 0...(texts.count - 1))
                while used.contains(idx) {
                    idx = (idx + 1) % texts.count
                }
                used.insert(idx)
                let (text, category) = texts[idx]
                items.append(GratitudeItem(
                    text: text,
                    category: category,
                    isFavorite: rng.nextBool(probability: 0.15),
                    sortOrder: order
                ))
            }

            let moodScore = rng.nextInt(in: 2...5)
            let entry = RRGratitudeEntry(
                userId: userId,
                date: daysAgo(day, hour: 7),
                items: items,
                moodScore: moodScore,
                isFavorite: rng.nextBool(probability: 0.1),
                createdAt: daysAgo(day, hour: 7)
            )
            context.insert(entry)
        }
    }

    private static func seedDailyScores(
        span: Int, userId: UUID, baseScore: Int,
        trendUp: Bool, rng: inout SeededRandom, context: ModelContext
    ) {
        for day in 0..<span {
            let progress = Double(span - day) / Double(max(span, 1))
            let trendBoost = trendUp ? Int(progress * 20.0) : 0
            let noise = rng.nextInt(in: -8...8)
            let score = max(10, min(100, baseScore + trendBoost + noise))

            let totalPlanned = rng.nextInt(in: 8...14)
            let completionRatio = Double(score) / 100.0
            let totalCompleted = min(totalPlanned, Int(round(Double(totalPlanned) * completionRatio)))
            let morningDone = score >= 30

            let breakdown = JSONPayload([
                "morningCommitment": .bool(morningDone),
                "otherCompleted": .int(max(0, totalCompleted - (morningDone ? 1 : 0))),
                "otherTotal": .int(totalPlanned - 1),
            ])

            let dailyScore = RRDailyScore(
                userId: userId,
                date: daysAgo(day, hour: 23, minute: 59),
                score: score,
                totalPlanned: totalPlanned,
                totalCompleted: totalCompleted,
                morningCommitmentCompleted: morningDone,
                breakdown: breakdown,
                createdAt: daysAgo(day, hour: 23, minute: 59)
            )
            context.insert(dailyScore)
        }
    }

    private static func seedRecoveryPlan(
        userId: UUID, itemCount: Int, context: ModelContext
    ) {
        let planId = UUID()
        let plan = RRRecoveryPlan(
            id: planId,
            userId: userId,
            isActive: true,
            isPaused: false,
            createdAt: daysAgo(30),
            modifiedAt: daysAgo(0)
        )
        context.insert(plan)

        // Pool of plan items ordered by priority
        let allItems: [(String, Int, Int, Int)] = [
            // (activityType, hour, minute, instanceIndex)
            (ActivityType.sobrietyCommitment.rawValue, 7, 0, 0),
            (ActivityType.affirmationLog.rawValue, 7, 0, 0),
            (ActivityType.journal.rawValue, 7, 0, 0),
            ("devotional", 7, 0, 0),
            (ActivityType.prayer.rawValue, 7, 0, 0),
            (ActivityType.exercise.rawValue, 8, 0, 0),
            (ActivityType.phoneCalls.rawValue, 12, 0, 0),
            (ActivityType.phoneCalls.rawValue, 17, 0, 1),
            (ActivityType.meetingsAttended.rawValue, 20, 0, 0),
            (ActivityType.fanos.rawValue, 21, 0, 0),
            (ActivityType.gratitude.rawValue, 21, 0, 0),
            ("pci", 21, 0, 0),
            (ActivityType.fasterScale.rawValue, 21, 0, 0),
        ]

        let count = min(itemCount, allItems.count)
        for sortOrder in 0..<count {
            let (activityType, hour, minute, instanceIndex) = allItems[sortOrder]
            let item = RRDailyPlanItem(
                planId: planId,
                activityType: activityType,
                scheduledHour: hour,
                scheduledMinute: minute,
                instanceIndex: instanceIndex,
                daysOfWeek: [],
                isEnabled: true,
                sortOrder: sortOrder,
                createdAt: daysAgo(30),
                modifiedAt: daysAgo(0)
            )
            item.plan = plan
            context.insert(item)
        }
    }

    private static func seedStepWork(
        span: Int, userId: UUID, completedSteps: Int,
        rng: inout SeededRandom, context: ModelContext
    ) {
        for num in 1...12 {
            let status: String
            let answers: JSONPayload

            if num <= completedSteps {
                status = "complete"
                answers = JSONPayload(["answeredCount": .int(10)])
            } else if num == completedSteps + 1 {
                status = "inProgress"
                answers = JSONPayload(["answeredCount": .int(rng.nextInt(in: 1...6))])
            } else {
                status = "locked"
                answers = JSONPayload()
            }

            let createdAgo = max(0, span - (num * 15))
            let step = RRStepWork(
                userId: userId,
                stepNumber: num,
                status: status,
                answers: answers,
                createdAt: daysAgo(createdAgo)
            )
            context.insert(step)
        }
    }

    private static func seedGoals(
        userId: UUID, count: Int, completedRatio: Double,
        rng: inout SeededRandom, context: ModelContext
    ) {
        let weekStart: Date = {
            let today = calendar.startOfDay(for: now)
            let weekday = calendar.component(.weekday, from: today)
            let daysFromMonday = (weekday + 5) % 7
            return calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!
        }()

        let goalPool: [(String, String)] = [
            ("Morning prayer & devotional daily", "Spiritual"),
            ("Run 3 times this week", "Physical"),
            ("Journal about feelings after sponsor call", "Emotional"),
            ("Read one chapter of recovery book", "Intellectual"),
            ("Plan quality time with family", "Relational"),
            ("Attend 2 meetings this week", "Spiritual"),
            ("Practice gratitude daily", "Emotional"),
            ("30 minutes of exercise 4 times", "Physical"),
        ]

        let goalCount = min(count, goalPool.count)
        for i in 0..<goalCount {
            let (title, dynamic) = goalPool[i]
            let isComplete = rng.nextBool(probability: completedRatio)
            let goal = RRGoal(
                userId: userId,
                title: title,
                dynamic: dynamic,
                isComplete: isComplete,
                weekStartDate: weekStart,
                createdAt: weekStart
            )
            context.insert(goal)
        }
    }

    private static func seedUrges(
        span: Int, userId: UUID,
        addictionIds: [(id: UUID, name: String)],
        perWeek: Double, highIntensity: Bool,
        rng: inout SeededRandom, context: ModelContext
    ) {
        guard !addictionIds.isEmpty else { return }
        let probability = perWeek / 7.0

        let triggerPool = ["emotional", "digital", "fatigue", "relational", "boredom", "stress", "loneliness", "anger"]
        let resolutions = [
            "Called sponsor",
            "Used breathing exercises",
            "Went for a walk",
            "Prayed through it",
            "Journaled about the feeling",
            "Went to bed early",
            "Talked to accountability partner",
            "Maintained sobriety",
        ]

        for day in 0..<span {
            guard rng.nextBool(probability: probability) else { continue }

            let addictionIdx = rng.nextInt(in: 0...(addictionIds.count - 1))
            let addictionId = addictionIds[addictionIdx].id

            let intensity: Int
            if highIntensity {
                intensity = rng.nextInt(in: 5...10)
            } else {
                intensity = rng.nextInt(in: 2...7)
            }

            let triggerCount = rng.nextInt(in: 1...3)
            var triggers: [String] = []
            for _ in 0..<triggerCount {
                let t = triggerPool[rng.nextInt(in: 0...(triggerPool.count - 1))]
                if !triggers.contains(t) { triggers.append(t) }
            }

            let resolution = resolutions[rng.nextInt(in: 0...(resolutions.count - 1))]

            let urge = RRUrgeLog(
                userId: userId,
                date: daysAgo(day, hour: rng.nextInt(in: 10...22), minute: rng.nextInt(in: 0...59)),
                intensity: intensity,
                addictionId: addictionId,
                triggers: triggers,
                notes: "Felt triggered. \(resolution).",
                resolution: resolution,
                createdAt: daysAgo(day, hour: 16, minute: 45)
            )
            context.insert(urge)
        }
    }
}
