import Foundation
import SwiftData

/// Seeds the SwiftData store with Alex's 270-day mock recovery data on first launch.
enum SeedData {

    private static let calendar = Calendar.current
    private static let now = Date()

    private static func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now)!
    }

    private static func today(hour: Int, minute: Int = 0) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    private static func daysAgo(_ days: Int, hour: Int, minute: Int = 0) -> Date {
        let day = daysAgo(days)
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    private static let sobrietyDate: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 7
        components.day = 4
        return Calendar.current.date(from: components)!
    }()

    // MARK: - Seed Check

    static let seedKey = "com.regalrecovery.seeded"

    static func needsSeed() -> Bool {
        !UserDefaults.standard.bool(forKey: seedKey)
    }

    static func markSeeded() {
        UserDefaults.standard.set(true, forKey: seedKey)
    }

    // MARK: - Main Seed Function

    /// Populates the database with mock data for development and testing.
    /// Call on first launch from the app's init or a background task.
    @MainActor
    static func seedDatabase(context: ModelContext) throws {
        guard needsSeed() else { return }

        let userId = UUID()
        let saId = UUID()
        let pornId = UUID()

        let (user, saAddiction) = seedUser(
            context: context, userId: userId, saId: saId, pornId: pornId
        )
        seedAddictions(
            context: context, user: user, saAddiction: saAddiction,
            userId: userId, saId: saId, pornId: pornId
        )
        seedMilestones(context: context, saId: saId, saAddiction: saAddiction)
        seedSupportNetwork(context: context, userId: userId, user: user)
        seedMoodEntries(context: context, userId: userId)
        seedActivities(context: context, userId: userId)
        seedPrayerLogs(context: context, userId: userId)
        seedExerciseLogs(context: context, userId: userId)
        seedPhoneCallLogs(context: context, userId: userId)
        seedMeetingLogs(context: context, userId: userId)
        seedJournalEntries(context: context, userId: userId)
        seedFASTER(context: context, userId: userId)
        seedTimeBlocks(context: context, userId: userId)
        seedUrges(context: context, userId: userId, addictionId: saId)
        seedSpouseCheckIn(context: context, userId: userId)
        seedGratitude(context: context, userId: userId)
        seedStepWork(context: context, userId: userId)
        seedGoals(context: context, userId: userId)
        seedCommitments(context: context, userId: userId)
        try seedFeatureFlags(context: context)
        seedDevotionalProgress(context: context, userId: userId)
        seedAffirmationFavorites(context: context, userId: userId)
        seedRecoveryPlan(context: context, userId: userId)
        seedDailyScores(context: context, userId: userId)

        try context.save()
        markSeeded()
    }

    // MARK: - User Profile

    @discardableResult
    private static func seedUser(
        context: ModelContext, userId: UUID, saId: UUID, pornId: UUID
    ) -> (RRUser, RRAddiction) {
        let user = RRUser(
            id: userId,
            name: "Alex",
            email: "alex@example.com",
            birthYear: 1988,
            gender: "Male",
            timezone: "America/Chicago",
            bibleVersion: "ESV",
            motivations: ["Faith", "Family", "Freedom"],
            avatarInitial: "A",
            createdAt: daysAgo(270),
            modifiedAt: now
        )
        context.insert(user)

        let saAddiction = RRAddiction(
            id: saId,
            name: "Sex",
            sobrietyDate: sobrietyDate,
            userId: userId,
            sortOrder: 0,
            createdAt: daysAgo(270)
        )
        saAddiction.user = user
        context.insert(saAddiction)

        let pornAddiction = RRAddiction(
            id: pornId,
            name: "Pornography",
            sobrietyDate: sobrietyDate,
            userId: userId,
            sortOrder: 1,
            createdAt: daysAgo(270)
        )
        pornAddiction.user = user
        context.insert(pornAddiction)

        return (user, saAddiction)
    }

    // MARK: - Addictions & Streaks

    private static func seedAddictions(
        context: ModelContext, user: RRUser, saAddiction: RRAddiction,
        userId: UUID, saId: UUID, pornId: UUID
    ) {
        let saStreak = RRStreak(
            addictionId: saId,
            longestStreak: 270,
            totalRelapses: 2,
            createdAt: daysAgo(270)
        )
        saStreak.addiction = saAddiction
        context.insert(saStreak)

        // Fetch porn addiction for streak relationship
        let pornAddiction = user.addictions.first { $0.id == pornId }
        let pornStreak = RRStreak(
            addictionId: pornId,
            longestStreak: 270,
            totalRelapses: 2,
            createdAt: daysAgo(270)
        )
        pornStreak.addiction = pornAddiction
        context.insert(pornStreak)
    }

    // MARK: - Milestones

    private static func seedMilestones(
        context: ModelContext, saId: UUID, saAddiction: RRAddiction
    ) {
        let milestoneData: [(Int, Int, String)] = [
            (1, 269, "Lamentations 3:22-23 -- His mercies are new every morning."),
            (3, 267, "Psalm 30:5 -- Weeping may stay for the night, but rejoicing comes in the morning."),
            (7, 263, "Isaiah 40:31 -- Those who hope in the Lord will renew their strength."),
            (14, 256, "Philippians 1:6 -- He who began a good work in you will carry it on to completion."),
            (30, 240, "2 Corinthians 5:17 -- If anyone is in Christ, the new creation has come."),
            (60, 210, "Romans 8:37 -- We are more than conquerors through Him who loved us."),
            (90, 180, "Psalm 51:10 -- Create in me a pure heart, O God."),
            (180, 90, "James 1:12 -- Blessed is the one who perseveres under trial."),
            (270, 0, "Galatians 5:1 -- It is for freedom that Christ has set us free."),
        ]
        for (days, ago, scripture) in milestoneData {
            let milestone = RRMilestone(
                addictionId: saId,
                days: days,
                dateEarned: daysAgo(ago),
                scripture: scripture,
                createdAt: daysAgo(ago)
            )
            milestone.addiction = saAddiction
            context.insert(milestone)
        }
    }

    // MARK: - Support Network

    private static func seedSupportNetwork(
        context: ModelContext, userId: UUID, user: RRUser
    ) {
        let contactData: [(String, String, String, Int)] = [
            ("James", "sponsor", "(512) 555-0142", 260),
            ("Dr. Sarah", "counselor", "(512) 555-0198", 265),
            ("Rachel", "spouse", "(512) 555-0111", 250),
            ("Mike", "accountabilityPartner", "(512) 555-0167", 200),
        ]
        for (name, role, phone, ago) in contactData {
            let contact = RRSupportContact(
                userId: userId,
                name: name,
                role: role,
                phone: phone,
                linkedDate: daysAgo(ago),
                createdAt: daysAgo(ago)
            )
            contact.user = user
            context.insert(contact)
        }
    }

    // MARK: - Mood Entries

    private static func seedMoodEntries(context: ModelContext, userId: UUID) {
        let moodScores = [7, 6, 7, 8, 7, 8, 7, 6, 7, 8, 8, 7, 6, 8, 9, 7, 6, 7, 8, 8, 7, 8, 7, 7, 8, 6, 7, 8, 8, 7]
        for i in 0..<30 {
            let mood = RRMoodEntry(
                userId: userId,
                date: daysAgo(29 - i, hour: 14),
                score: moodScores[i],
                createdAt: daysAgo(29 - i, hour: 14)
            )
            context.insert(mood)
        }
    }

    // MARK: - Activities

    private static func seedActivities(context: ModelContext, userId: UUID) {
        let activityTypes: [(String, Int, Int)] = [
            ("fasterScale", 6, 20),
            ("sobrietyCommitment", 6, 14),
            ("prayer", 6, 0),
            ("journal", 21, 15),
            ("exercise", 6, 30),
            ("phoneCalls", 12, 30),
        ]

        for day in 0..<7 {
            for (type, hour, minute) in activityTypes {
                if day > 0 && type == "phoneCalls" && day % 2 == 0 { continue }
                if day > 0 && type == "exercise" && day % 3 == 0 { continue }
                if day == 0 && type == "journal" { continue }

                let activity = RRActivity(
                    userId: userId,
                    activityType: type,
                    date: daysAgo(day, hour: hour, minute: minute),
                    timestamp: daysAgo(day, hour: hour, minute: minute),
                    data: JSONPayload(["summary": .string("\(type) logged")]),
                    synced: true,
                    createdAt: daysAgo(day, hour: hour, minute: minute)
                )
                context.insert(activity)
            }
        }
    }

    // MARK: - Prayer Logs

    private static func seedPrayerLogs(context: ModelContext, userId: UUID) {
        for day in 0..<7 {
            let prayer = RRPrayerLog(
                userId: userId,
                date: daysAgo(day, hour: 6),
                durationMinutes: [10, 12, 8, 15, 10, 12, 10][day],
                prayerType: "morning",
                createdAt: daysAgo(day, hour: 6)
            )
            context.insert(prayer)
        }
    }

    // MARK: - Exercise Logs

    private static func seedExerciseLogs(context: ModelContext, userId: UUID) {
        let exerciseTypes = ["running", "running", "weights", "running", "yoga"]
        var exerciseDay = 0
        for i in 0..<5 {
            let log = RRExerciseLog(
                userId: userId,
                date: daysAgo(exerciseDay, hour: 6, minute: 30),
                durationMinutes: [30, 25, 45, 30, 30][i],
                exerciseType: exerciseTypes[i],
                createdAt: daysAgo(exerciseDay, hour: 6, minute: 30)
            )
            context.insert(log)
            exerciseDay += (i == 2 ? 2 : 1)
        }
    }

    // MARK: - Phone Call Logs

    private static func seedPhoneCallLogs(context: ModelContext, userId: UUID) {
        let callData: [(Int, String, String, Int)] = [
            (0, "James", "sponsor", 15),
            (2, "Mike", "accountabilityPartner", 10),
            (4, "James", "sponsor", 20),
            (6, "Dr. Sarah", "counselor", 50),
        ]
        for (ago, name, role, duration) in callData {
            let log = RRPhoneCallLog(
                userId: userId,
                date: daysAgo(ago, hour: 12, minute: 30),
                contactName: name,
                contactRole: role,
                durationMinutes: duration,
                createdAt: daysAgo(ago, hour: 12, minute: 30)
            )
            context.insert(log)
        }
    }

    // MARK: - Meeting Logs

    private static func seedMeetingLogs(context: ModelContext, userId: UUID) {
        let meetingData: [(Int, String, Int)] = [
            (1, "SA Home Group", 60),
            (3, "SA Virtual Noon", 60),
            (5, "SA Step Study", 90),
        ]
        for (ago, name, duration) in meetingData {
            let log = RRMeetingLog(
                userId: userId,
                date: daysAgo(ago, hour: 19),
                meetingName: name,
                durationMinutes: duration,
                createdAt: daysAgo(ago, hour: 19)
            )
            context.insert(log)
        }
    }

    // MARK: - Journal Entries

    private static func seedJournalEntries(context: ModelContext, userId: UUID) {
        let journalData: [(Int, String, String)] = [
            (1, "freeform", "Reflecting on gratitude and the progress I've made this month."),
            (3, "prompted", "Talked through my feelings with Rachel tonight. It was hard but good."),
            (5, "structured", "Step 8 work: thinking about amends to my brother."),
            (6, "jotting", "Quick thought: the morning routine is really anchoring my days."),
        ]
        for (ago, mode, content) in journalData {
            let entry = RRJournalEntry(
                userId: userId,
                date: daysAgo(ago, hour: 21, minute: 15),
                mode: mode,
                content: content,
                createdAt: daysAgo(ago, hour: 21, minute: 15)
            )
            context.insert(entry)
        }
    }

    // MARK: - FASTER Scale

    private static func seedFASTER(context: ModelContext, userId: UUID) {
        for i in 0..<30 {
            let stage = (i % 7 == 3) ? 1 : 0
            let entry = RRFASTEREntry(
                userId: userId,
                date: daysAgo(29 - i, hour: 6, minute: 20),
                stage: stage,
                createdAt: daysAgo(29 - i, hour: 6, minute: 20)
            )
            context.insert(entry)
        }
    }

    // MARK: - Time Blocks

    private static func seedTimeBlocks(context: ModelContext, userId: UUID) {
        let blocks: [(Int, Int, Int, String, String)] = [
            (6, 0, 30, "Prayer & Devotional", "Peace"),
            (6, 30, 30, "Exercise -- Run", "Agency"),
            (7, 0, 60, "Family Breakfast", "Connection"),
            (8, 0, 240, "Work", "Agency"),
            (12, 0, 30, "SA Meeting Call", "Belonging"),
            (12, 30, 30, "Lunch", "Comfort"),
            (13, 0, 240, "Work", "Agency"),
            (17, 0, 60, "Family Time", "Connection"),
            (18, 0, 60, "Dinner", "Connection"),
            (19, 0, 30, "Journal & Reflection", "Understanding"),
            (19, 30, 30, "Scripture Reading", "Hope"),
            (20, 0, 60, "Quality Time with Rachel", "Love"),
            (21, 0, 30, "Evening Review", "Peace"),
            (21, 30, 30, "Wind Down", "Comfort"),
        ]
        for (hour, minute, duration, activity, need) in blocks {
            let block = RRTimeBlock(
                userId: userId,
                date: today(hour: hour, minute: minute),
                startHour: hour,
                startMinute: minute,
                durationMinutes: duration,
                activity: activity,
                need: need,
                createdAt: today(hour: hour, minute: minute)
            )
            context.insert(block)
        }
    }

    // MARK: - Urge Logs

    private static func seedUrges(
        context: ModelContext, userId: UUID, addictionId: UUID
    ) {
        let urgeData: [(Int, Int, [String], String)] = [
            (1, 5, ["emotional", "digital"], "Feeling triggered by social media. Called James."),
            (4, 8, ["emotional", "relational"], "Difficult conversation with coworker. Used breathing exercises."),
            (6, 3, ["fatigue"], "Tired after long day. Went to bed early instead."),
        ]
        for (ago, intensity, triggers, notes) in urgeData {
            let urge = RRUrgeLog(
                userId: userId,
                date: daysAgo(ago, hour: 16, minute: 45),
                intensity: intensity,
                addictionId: addictionId,
                triggers: triggers,
                notes: notes,
                resolution: "Maintained sobriety",
                createdAt: daysAgo(ago, hour: 16, minute: 45)
            )
            context.insert(urge)
        }
    }

    // MARK: - Spouse Check-In

    private static func seedSpouseCheckIn(context: ModelContext, userId: UUID) {
        let spouseCheckIn = RRSpouseCheckIn(
            userId: userId,
            date: daysAgo(3, hour: 20),
            framework: "FANOS",
            sections: JSONPayload([
                "feelings": .string("Hopeful about our progress but nervous about the conversation"),
                "appreciation": .string("Thank you for being patient while I work through this"),
                "needs": .string("I need 30 minutes of uninterrupted time to share tonight"),
                "ownership": .string("I take responsibility for not communicating my schedule change yesterday"),
                "sobriety": .string("270 days sober. Had 2 urges this week, both managed."),
            ]),
            createdAt: daysAgo(3, hour: 20)
        )
        context.insert(spouseCheckIn)
    }

    // MARK: - Gratitude Entries

    private static func seedGratitude(context: ModelContext, userId: UUID) {
        let entries: [(Int, [GratitudeItem], Int?, Bool)] = [
            // (daysAgo, items, moodScore, isFavorite)
            (0, [
                GratitudeItem(text: "Woke up with a clear head and a sense of purpose", category: .recovery, sortOrder: 0),
                GratitudeItem(text: "Rachel made coffee before I was even up", category: .family, isFavorite: true, sortOrder: 1),
                GratitudeItem(text: "The sunrise on my morning walk", category: .natureBeauty, sortOrder: 2),
            ], 4, false),
            (1, [
                GratitudeItem(text: "47 days of sobriety — never thought I'd get here", category: .recovery, isFavorite: true, sortOrder: 0),
                GratitudeItem(text: "My sponsor answered the phone at 11pm without hesitation", category: .relationships, isFavorite: true, sortOrder: 1),
                GratitudeItem(text: "A good night's sleep for the first time in weeks", category: .health, sortOrder: 2),
                GratitudeItem(text: "The kids laughing at dinner", category: .family, sortOrder: 3),
            ], 5, true),
            (2, [
                GratitudeItem(text: "God's patience with me when I have none for myself", category: .faithGod, isFavorite: true, sortOrder: 0),
                GratitudeItem(text: "The courage to be honest in group tonight", category: .recovery, sortOrder: 1),
                GratitudeItem(text: "A warm meal and a roof over my head", category: .smallMoments, sortOrder: 2),
            ], 3, false),
            (3, [
                GratitudeItem(text: "My job didn't fire me when I told them the truth", category: .workCareer, sortOrder: 0),
                GratitudeItem(text: "Rachel said she sees the change in me", category: .family, isFavorite: true, sortOrder: 1),
            ], 4, false),
            (4, [
                GratitudeItem(text: "Reading scripture felt real today, not like homework", category: .faithGod, sortOrder: 0),
                GratitudeItem(text: "Ran a full mile without stopping", category: .health, sortOrder: 1),
                GratitudeItem(text: "The afternoon light through the kitchen window", category: .natureBeauty, sortOrder: 2),
                GratitudeItem(text: "Progress in Step 4 — hard but freeing", category: .growthProgress, sortOrder: 3),
            ], 4, false),
            (5, [
                GratitudeItem(text: "A text from my brother I wasn't expecting", category: .relationships, sortOrder: 0),
                GratitudeItem(text: "The fact that I wanted to call my sponsor instead of acting out", category: .recovery, isFavorite: true, sortOrder: 1),
                GratitudeItem(text: "Hot shower after a long day", category: .smallMoments, sortOrder: 2),
            ], 3, false),
            (6, [
                GratitudeItem(text: "Another day where I chose recovery", category: .recovery, sortOrder: 0),
                GratitudeItem(text: "The quiet of early morning prayer", category: .faithGod, sortOrder: 1),
                GratitudeItem(text: "My counselor's insight about shame vs guilt", category: .growthProgress, isFavorite: true, sortOrder: 2),
            ], 4, false),
            (8, [
                GratitudeItem(text: "Grace. Just grace.", category: .faithGod, isFavorite: true, sortOrder: 0),
            ], 2, false),
            (10, [
                GratitudeItem(text: "The meeting tonight — I needed every word of it", category: .recovery, sortOrder: 0),
                GratitudeItem(text: "My kids still want to be around me", category: .family, sortOrder: 1),
                GratitudeItem(text: "A good therapist who doesn't let me deflect", category: .relationships, sortOrder: 2),
            ], 3, false),
            (14, [
                GratitudeItem(text: "30 days clean — a milestone I didn't think was possible", category: .recovery, isFavorite: true, sortOrder: 0),
                GratitudeItem(text: "Rachel held my hand in church for the first time in months", category: .family, isFavorite: true, sortOrder: 1),
                GratitudeItem(text: "The view from the park bench where I do my morning reading", category: .natureBeauty, sortOrder: 2),
                GratitudeItem(text: "Learning that I'm worth fighting for", category: .growthProgress, sortOrder: 3),
                GratitudeItem(text: "A God who doesn't give up on people like me", category: .faithGod, isFavorite: true, sortOrder: 4),
            ], 5, true),
        ]

        for (ago, items, mood, favorite) in entries {
            let entryDate = daysAgo(ago, hour: 7)
            let entry = RRGratitudeEntry(
                userId: userId,
                date: entryDate,
                items: items,
                moodScore: mood,
                isFavorite: favorite,
                createdAt: entryDate
            )
            context.insert(entry)
        }
    }

    // MARK: - Step Work

    private static func seedStepWork(context: ModelContext, userId: UUID) {
        let stepData: [(Int, String)] = [
            (1, "complete"), (2, "complete"), (3, "complete"), (4, "complete"),
            (5, "complete"), (6, "complete"), (7, "complete"), (8, "inProgress"),
            (9, "locked"), (10, "locked"), (11, "locked"), (12, "locked"),
        ]
        for (num, status) in stepData {
            let answers: JSONPayload
            if status == "complete" {
                answers = JSONPayload(["answeredCount": .int(10)])
            } else if status == "inProgress" {
                answers = JSONPayload(["answeredCount": .int(3)])
            } else {
                answers = JSONPayload()
            }
            let step = RRStepWork(
                userId: userId,
                stepNumber: num,
                status: status,
                answers: answers,
                createdAt: daysAgo(270 - (num * 20))
            )
            context.insert(step)
        }
    }

    // MARK: - Goals

    private static func seedGoals(context: ModelContext, userId: UUID) {
        let weekStart = {
            let today = Calendar.current.startOfDay(for: Date())
            let weekday = Calendar.current.component(.weekday, from: today)
            let daysFromMonday = (weekday + 5) % 7
            return Calendar.current.date(byAdding: .day, value: -daysFromMonday, to: today)!
        }()
        let goals: [(String, String, Bool)] = [
            ("Morning prayer & devotional daily", "Spiritual", true),
            ("Run 3 times this week", "Physical", true),
            ("Journal about feelings after sponsor call", "Emotional", true),
            ("Read one chapter of recovery book", "Intellectual", true),
            ("Plan date night with Rachel", "Relational", false),
        ]
        for (title, dynamic, complete) in goals {
            let goal = RRGoal(
                userId: userId,
                title: title,
                dynamic: dynamic,
                isComplete: complete,
                weekStartDate: weekStart,
                createdAt: weekStart
            )
            context.insert(goal)
        }
    }

    // MARK: - Commitments

    private static func seedCommitments(context: ModelContext, userId: UUID) {
        let morningCommitment = RRCommitment(
            userId: userId,
            date: today(hour: 6, minute: 14),
            type: "morning",
            completedAt: today(hour: 6, minute: 14),
            answers: JSONPayload([
                "sobrietyCommit": .bool(true),
                "reachOut": .bool(true),
                "attendMeeting": .bool(true),
                "prayerScripture": .bool(true),
                "honest": .bool(true),
                "surrender": .bool(true),
            ]),
            createdAt: today(hour: 6, minute: 14)
        )
        context.insert(morningCommitment)
    }

    // MARK: - Feature Flags

    private static func seedFeatureFlags(context: ModelContext) throws {
        let flags: [(String, Bool, String)] = [
            // P0 Features
            ("feature.onboarding", true, "Onboarding flow"),
            ("feature.profile-management", true, "Profile management"),
            ("feature.content-resources", true, "Content and resources"),
            ("feature.commitments", true, "Commitments"),
            ("feature.themes", true, "Themes"),
            ("feature.offline-first", true, "Offline-first architecture"),
            ("feature.dsr", true, "Data subject rights"),
            // P1 Features
            ("feature.analytics-dashboard", true, "Analytics dashboard"),
            ("feature.meeting-finder", true, "Meeting finder"),
            ("feature.quick-actions", true, "Quick actions"),
            ("feature.backup", false, "Data backup"),
            ("feature.messaging-integrations", false, "Messaging integrations"),
            // P2 Features
            ("feature.community", false, "Community"),
            ("feature.therapist-portal", false, "Therapist portal"),
            ("feature.health-score", false, "Recovery health score"),
            ("feature.achievements", false, "Achievements"),
            ("feature.couples-mode", false, "Couples recovery mode"),
            ("feature.geofencing", false, "Geofencing"),
            ("feature.screen-time", false, "Screen time"),
            ("feature.sleep-tracking", false, "Sleep tracking"),
            ("feature.superbill", false, "Superbill / LMN"),
            // P3 Features
            ("feature.recovery-agent", false, "Recovery Agent (AI)"),
            ("feature.premium-analytics", false, "Premium analytics"),
            ("feature.panic-button-biometric", false, "Panic button (biometric)"),
            ("feature.recovery-stories", false, "Recovery stories"),
            ("feature.branding", false, "Branding (B2B)"),
            ("feature.tenancy", false, "Tenancy (B2B)"),
            ("feature.spotify", false, "Spotify integration"),
            // Activities
            ("activity.sobriety-commitment", true, "Sobriety commitment"),
            ("activity.affirmations", true, "Affirmations"),
            ("activity.urge-logging", true, "Urge logging"),
            ("activity.journaling", true, "Journaling"),
            ("activity.faster-scale", true, "FASTER scale"),
            ("activity.time-journal", true, "Time journal"),
            ("activity.fanos", false, "FANOS check-in"),
            ("activity.fitnap", false, "FITNAP check-in"),
            ("activity.person-check-ins", false, "Person check-ins"),
            ("activity.meetings", true, "Meetings attended"),
            ("activity.post-mortem", true, "Post-mortem analysis"),
            ("activity.step-work", true, "12-step work"),
            ("activity.goals", true, "Weekly goals"),
            ("activity.devotionals", true, "Devotionals"),
            ("activity.exercise", true, "Exercise"),
            ("activity.mood", true, "Mood ratings"),
            ("activity.gratitude", true, "Gratitude list"),
            ("activity.phone-calls", true, "Phone calls"),
            ("activity.prayer", true, "Prayer"),
            ("activity.integrity-inventory", false, "Integrity inventory"),
            ("activity.pci", false, "PCI"),
            // App Architecture
            ("feature.today-view", false, "Today view replaces Home dashboard"),
            ("feature.work-tab", true, "Work tab replaces Activities catalog"),
            ("feature.urge-surfing-timer", true, "Urge Surfing Timer on FAB tap"),
            ("feature.activities", true, "Activity logging on Today screen"),
            // Assessments
            ("assessment.sast-r", false, "SAST-R"),
            ("assessment.family-impact", false, "Family impact"),
            ("assessment.denial", false, "Denial"),
            ("assessment.addiction-severity", false, "Addiction severity"),
            ("assessment.relationship-health", false, "Relationship health"),
        ]

        for (key, enabled, desc) in flags {
            let flag = RRFeatureFlag(
                key: key,
                enabled: enabled,
                rolloutPercent: 100.0,
                flagDescription: desc
            )
            context.insert(flag)
        }
    }

    // MARK: - Devotional Progress

    private static func seedDevotionalProgress(context: ModelContext, userId: UUID) {
        for day in 1...30 {
            let progress = RRDevotionalProgress(
                userId: userId,
                day: day,
                completedAt: day <= 23 ? daysAgo(30 - day, hour: 6, minute: 30) : nil,
                createdAt: daysAgo(max(0, 30 - day))
            )
            context.insert(progress)
        }
    }

    // MARK: - Affirmation Favorites

    private static func seedAffirmationFavorites(context: ModelContext, userId: UUID) {
        let favorites: [(String, String, String)] = [
            ("I am God's child.", "John 1:12", "I Am Accepted"),
            ("I am forever free from condemnation.", "Romans 8:1-2", "I Am Secure"),
            ("I can do all things through Christ who strengthens me.", "Philippians 4:13", "I Am Significant"),
            ("I am a new creation in Christ.", "2 Corinthians 5:17", "I Am Accepted"),
            ("God's power is made perfect in my weakness.", "2 Corinthians 12:9", "I Am Secure"),
        ]
        for (text, scripture, pack) in favorites {
            let fav = RRAffirmationFavorite(
                userId: userId,
                affirmationText: text,
                scripture: scripture,
                packName: pack,
                createdAt: daysAgo(Int.random(in: 10...200))
            )
            context.insert(fav)
        }
    }

    // MARK: - Recovery Plan (Example 1: 14-activity intensive plan)

    private static func seedRecoveryPlan(context: ModelContext, userId: UUID) {
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

        // (activityType, hour, minute, instanceIndex)
        let items: [(String, Int, Int, Int)] = [
            // Morning Block — 7:00 AM
            (ActivityType.sobrietyCommitment.rawValue, 7, 0, 0),
            (ActivityType.affirmationLog.rawValue, 7, 0, 0),
            (ActivityType.journal.rawValue, 7, 0, 0),
            ("devotional", 7, 0, 0),
            (ActivityType.prayer.rawValue, 7, 0, 0),
            // Exercise — 8:00 AM
            (ActivityType.exercise.rawValue, 8, 0, 0),
            // Midday — 12:00 PM
            (ActivityType.phoneCalls.rawValue, 12, 0, 0),
            // Afternoon — 5:00 PM
            (ActivityType.phoneCalls.rawValue, 17, 0, 1),
            // Evening Block — 8:00-9:00 PM
            (ActivityType.meetingsAttended.rawValue, 20, 0, 0),
            (ActivityType.fanos.rawValue, 21, 0, 0),
            (ActivityType.gratitude.rawValue, 21, 0, 0),
            ("pci", 21, 0, 0),
            (ActivityType.fasterScale.rawValue, 21, 0, 0),
        ]

        for (sortOrder, (activityType, hour, minute, instanceIndex)) in items.enumerated() {
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

    // MARK: - Daily Scores (30 days of historical data)

    private static func seedDailyScores(context: ModelContext, userId: UUID) {
        // Trending upward from ~65 to ~95 over 30 days, with a couple dips
        let baseScores: [Int] = [
            65, 68, 72, 70, 74, 76, 73, 78, 80, 77,
            82, 84, 79, 85, 83, 87, 86, 88, 84, 90,
            88, 91, 67, 72, 89, 92, 93, 91, 95, 94,
        ]

        for i in 0..<30 {
            let dayOffset = 29 - i
            let score = baseScores[i]
            let totalPlanned = 14
            // Derive completed count from score using the formula:
            // score = (morning ? 20 : 0) + (completed_others / 13) * 80
            let morningDone = score >= 20
            let otherScore = morningDone ? score - 20 : score
            let otherCompleted = min(13, Int(round(Double(otherScore) * 13.0 / 80.0)))
            let totalCompleted = (morningDone ? 1 : 0) + otherCompleted

            // Build a simple breakdown payload
            let breakdown = JSONPayload([
                "morningCommitment": .bool(morningDone),
                "otherCompleted": .int(otherCompleted),
                "otherTotal": .int(13),
            ])

            let dailyScore = RRDailyScore(
                userId: userId,
                date: daysAgo(dayOffset, hour: 23, minute: 59),
                score: score,
                totalPlanned: totalPlanned,
                totalCompleted: totalCompleted,
                morningCommitmentCompleted: morningDone,
                breakdown: breakdown,
                createdAt: daysAgo(dayOffset, hour: 23, minute: 59)
            )
            context.insert(dailyScore)
        }
    }
}
