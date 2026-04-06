import SwiftUI

// MARK: - Mock Data for Alex (270 days sober)

enum MockData {

    // MARK: - Date Helpers

    static let calendar = Calendar.current
    static let now = Date()

    static func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now)!
    }

    static func today(hour: Int, minute: Int = 0) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    static func yesterday(hour: Int, minute: Int = 0) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: daysAgo(1))
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    // MARK: - Profile

    static let profile = UserProfile(
        name: "Alex",
        email: "alex@example.com",
        birthYear: 1988,
        gender: "Male",
        timezone: "America/Chicago",
        addictions: ["Sex Addiction (SA)", "Pornography"],
        sobrietyDate: sobrietyDate,
        bibleVersion: "ESV",
        motivations: ["Faith", "Family", "Freedom"],
        avatarInitial: "A"
    )

    static let sobrietyDate: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 7
        components.day = 4
        return Calendar.current.date(from: components)!
    }()

    // MARK: - Streak

    static let streak = StreakData(
        currentDays: 270,
        sobrietyDate: sobrietyDate,
        longestStreak: 270,
        totalRelapses: 2,
        nextMilestoneDays: 300,
        milestones: [
            Milestone(days: 1, dateEarned: daysAgo(269), scripture: "Lamentations 3:22-23 — His mercies are new every morning."),
            Milestone(days: 3, dateEarned: daysAgo(267), scripture: "Psalm 30:5 — Weeping may stay for the night, but rejoicing comes in the morning."),
            Milestone(days: 7, dateEarned: daysAgo(263), scripture: "Isaiah 40:31 — Those who hope in the Lord will renew their strength."),
            Milestone(days: 14, dateEarned: daysAgo(256), scripture: "Philippians 1:6 — He who began a good work in you will carry it on to completion."),
            Milestone(days: 30, dateEarned: daysAgo(240), scripture: "2 Corinthians 5:17 — If anyone is in Christ, the new creation has come."),
            Milestone(days: 60, dateEarned: daysAgo(210), scripture: "Romans 8:37 — We are more than conquerors through Him who loved us."),
            Milestone(days: 90, dateEarned: daysAgo(180), scripture: "Psalm 51:10 — Create in me a pure heart, O God."),
            Milestone(days: 180, dateEarned: daysAgo(90), scripture: "James 1:12 — Blessed is the one who perseveres under trial."),
            Milestone(days: 270, dateEarned: daysAgo(0), scripture: "Galatians 5:1 — It is for freedom that Christ has set us free."),
        ]
    )

    // MARK: - Support Network

    static let supportNetwork: [SupportContact] = [
        SupportContact(name: "James", role: .sponsor, permissionSummary: "Sees: All except journal & financial", linkedDaysAgo: 260, phone: "(512) 555-0142"),
        SupportContact(name: "Dr. Sarah", role: .counselor, permissionSummary: "Sees: All", linkedDaysAgo: 265, phone: "(512) 555-0198"),
        SupportContact(name: "Rachel", role: .spouse, permissionSummary: "Sees: All", linkedDaysAgo: 250, phone: "(512) 555-0111"),
        SupportContact(name: "Mike", role: .accountabilityPartner, permissionSummary: "Sees: All except journal & financial", linkedDaysAgo: 200, phone: "(512) 555-0167"),
    ]

    // MARK: - Commitments

    static let commitmentStatus = CommitmentStatus(
        morningComplete: true,
        morningTime: "6:14 AM",
        eveningComplete: false,
        eveningTime: nil
    )

    static let morningQuestions: [CommitmentQuestion] = [
        CommitmentQuestion(text: "I commit to sexual sobriety today — no sex with self, no sex outside of marriage.", isChecked: true),
        CommitmentQuestion(text: "I will reach out to my sponsor or accountability partner if I am struggling.", isChecked: true),
        CommitmentQuestion(text: "I will attend my scheduled recovery meeting.", isChecked: true),
        CommitmentQuestion(text: "I will spend time in prayer and scripture today.", isChecked: true),
        CommitmentQuestion(text: "I will be honest with myself and others today.", isChecked: true),
        CommitmentQuestion(text: "I surrender this day to God and trust His plan for my recovery.", isChecked: true),
    ]

    static let eveningQuestions: [CommitmentQuestion] = [
        CommitmentQuestion(text: "Did I maintain my sobriety commitment today?", isChecked: false),
        CommitmentQuestion(text: "Was I honest in all my interactions today?", isChecked: false),
        CommitmentQuestion(text: "Did I reach out for support when I needed it?", isChecked: false),
        CommitmentQuestion(text: "What am I grateful for today?", isChecked: false),
    ]

    // MARK: - Recent Activity Feed

    static let recentActivity: [RecentActivity] = [
        RecentActivity(title: "Recovery Check-in", detail: "Score: 82", time: "Today, 6:30 AM", icon: "heart.text.clipboard", iconColor: .rrPrimary),
        RecentActivity(title: "FASTER Scale", detail: "Green", time: "Today, 6:20 AM", icon: "gauge.with.needle", iconColor: .rrSuccess),
        RecentActivity(title: "Morning Commitment", detail: "Completed", time: "Today, 6:14 AM", icon: "sun.max.fill", iconColor: .rrSecondary),
        RecentActivity(title: "Prayer", detail: "12 min", time: "Today, 6:00 AM", icon: "hands.and.sparkles.fill", iconColor: .rrPrimary),
        RecentActivity(title: "Journal", detail: "Reflecting on gratitude...", time: "Yesterday, 9:15 PM", icon: "note.text", iconColor: .purple),
    ]

    // MARK: - Check-in History (7 days for sparkline)

    static let checkInScores: [Int] = [78, 75, 80, 85, 79, 84, 82]

    // MARK: - FASTER Scale History (30 days)

    static let fasterHistory: [FASTEREntry] = {
        var entries: [FASTEREntry] = []
        let stages: [FASTERStage] = [.restoration, .restoration, .forgettingPriorities, .restoration, .anxiety, .forgettingPriorities, .restoration]
        for i in 0..<30 {
            let stage = stages[i % stages.count]
            let indicators = Set(stage.indicators.prefix(i % 3 + 1))
            entries.append(FASTEREntry(
                date: daysAgo(29 - i),
                stage: stage,
                moodScore: (i % 5) + 1,
                selectedIndicators: [stage: indicators]
            ))
        }
        return entries
    }()

    // MARK: - Emotional Journal History

    static let emotionalJournalEntries: [EmotionalJournalEntry] = [
        EmotionalJournalEntry(date: today(hour: 7), emotion: "Anxious", emotionColor: .purple, intensity: 6, activity: "Work deadline", location: "Home, Austin TX"),
        EmotionalJournalEntry(date: yesterday(hour: 20), emotion: "Grateful", emotionColor: .yellow, intensity: 8, activity: "Family dinner", location: "Home, Austin TX"),
        EmotionalJournalEntry(date: daysAgo(2), emotion: "Peaceful", emotionColor: .blue, intensity: 7, activity: "Morning prayer", location: "Home, Austin TX"),
        EmotionalJournalEntry(date: daysAgo(3), emotion: "Frustrated", emotionColor: .red, intensity: 5, activity: "Traffic", location: "I-35, Austin TX"),
        EmotionalJournalEntry(date: daysAgo(4), emotion: "Hopeful", emotionColor: .yellow, intensity: 9, activity: "Sponsor call", location: "Home, Austin TX"),
        EmotionalJournalEntry(date: daysAgo(6), emotion: "Lonely", emotionColor: .blue, intensity: 4, activity: "Working late", location: "Office, Austin TX"),
        EmotionalJournalEntry(date: daysAgo(7), emotion: "Joyful", emotionColor: .yellow, intensity: 9, activity: "SA meeting", location: "First Baptist, Austin TX"),
    ]

    // MARK: - Time Journal Blocks (today)

    static let timeBlocks: [TimeBlock] = [
        TimeBlock(startHour: 6, startMinute: 0, durationMinutes: 30, activity: "Prayer & Devotional", need: "Peace", color: .rrPrimary),
        TimeBlock(startHour: 6, startMinute: 30, durationMinutes: 30, activity: "Exercise — Run", need: "Agency", color: .blue),
        TimeBlock(startHour: 7, startMinute: 0, durationMinutes: 60, activity: "Family Breakfast", need: "Connection", color: .pink),
        TimeBlock(startHour: 8, startMinute: 0, durationMinutes: 240, activity: "Work", need: "Agency", color: .gray),
        TimeBlock(startHour: 12, startMinute: 0, durationMinutes: 30, activity: "SA Meeting Call", need: "Belonging", color: .rrPrimary),
        TimeBlock(startHour: 12, startMinute: 30, durationMinutes: 30, activity: "Lunch", need: "Comfort", color: .orange),
        TimeBlock(startHour: 13, startMinute: 0, durationMinutes: 240, activity: "Work", need: "Agency", color: .gray),
        TimeBlock(startHour: 17, startMinute: 0, durationMinutes: 60, activity: "Family Time", need: "Connection", color: .pink),
        TimeBlock(startHour: 18, startMinute: 0, durationMinutes: 60, activity: "Dinner", need: "Connection", color: .pink),
        TimeBlock(startHour: 19, startMinute: 0, durationMinutes: 30, activity: "Journal & Reflection", need: "Understanding", color: .purple),
        TimeBlock(startHour: 19, startMinute: 30, durationMinutes: 30, activity: "Scripture Reading", need: "Hope", color: .rrPrimary),
        TimeBlock(startHour: 20, startMinute: 0, durationMinutes: 60, activity: "Quality Time with Rachel", need: "Love", color: .pink),
        TimeBlock(startHour: 21, startMinute: 0, durationMinutes: 30, activity: "Evening Review", need: "Peace", color: .rrPrimary),
        TimeBlock(startHour: 21, startMinute: 30, durationMinutes: 30, activity: "Wind Down", need: "Comfort", color: .rrTextSecondary),
    ]

    // MARK: - Three Circles

    static let threeCircles = ThreeCirclesData(
        red: ["Pornography", "Masturbation", "Objectifying others", "Visiting triggering websites"],
        yellow: ["Isolating from others", "Staying up late alone", "Skipping meetings", "Excessive screen time", "Fantasy", "Dishonesty", "Skipping prayer", "Avoiding sponsor calls"],
        green: ["Prayer", "Exercise", "Calling sponsor", "Attending meetings", "Journaling", "Scripture reading", "Date night with Rachel", "Fellowship", "Acts of service", "Meditation", "Gratitude practice", "Consistent sleep routine"]
    )

    // MARK: - Meetings

    static let meetings: [Meeting] = [
        Meeting(name: "SA Home Group", fellowship: "SA", day: "Saturday", time: "9:00 AM", distance: "1.2 mi", location: "First Baptist Church, Austin TX", isVirtual: false, isSaved: true, latitude: 30.2672, longitude: -97.7431),
        Meeting(name: "SA Men's Meeting", fellowship: "SA", day: "Tuesday", time: "7:00 PM", distance: "2.8 mi", location: "Community Center, Austin TX", isVirtual: false, isSaved: false, latitude: 30.2850, longitude: -97.7340),
        Meeting(name: "SA Virtual Noon", fellowship: "SA", day: "Daily", time: "12:00 PM", distance: nil, location: "Zoom", isVirtual: true, isSaved: true, latitude: 30.2672, longitude: -97.7431),
        Meeting(name: "Celebrate Recovery", fellowship: "CR", day: "Friday", time: "6:30 PM", distance: "3.1 mi", location: "Grace Church, Austin TX", isVirtual: false, isSaved: false, latitude: 30.2500, longitude: -97.7500),
        Meeting(name: "SA Step Study", fellowship: "SA", day: "Thursday", time: "8:00 PM", distance: nil, location: "Zoom", isVirtual: true, isSaved: true, latitude: 30.2672, longitude: -97.7431),
    ]

    // MARK: - Affirmation Packs

    static let affirmationPacks: [AffirmationPack] = [
        AffirmationPack(name: "I Am Accepted", count: 11, affirmations: [
            Affirmation(text: "I am God's child.", scripture: "John 1:12", isFavorite: true),
            Affirmation(text: "I am Christ's friend.", scripture: "John 15:15", isFavorite: false),
            Affirmation(text: "I have been justified.", scripture: "Romans 5:1", isFavorite: false),
            Affirmation(text: "I am united with the Lord.", scripture: "1 Corinthians 6:17", isFavorite: false),
            Affirmation(text: "I have been bought with a price. I belong to God.", scripture: "1 Corinthians 6:19-20", isFavorite: false),
            Affirmation(text: "I am a member of Christ's body.", scripture: "1 Corinthians 12:27", isFavorite: false),
            Affirmation(text: "I am a saint.", scripture: "Ephesians 1:1", isFavorite: false),
            Affirmation(text: "I have been adopted as God's child.", scripture: "Ephesians 1:5", isFavorite: false),
            Affirmation(text: "I have direct access to God through the Holy Spirit.", scripture: "Ephesians 2:18", isFavorite: false),
            Affirmation(text: "I have been redeemed and forgiven of all my sins.", scripture: "Colossians 1:14", isFavorite: false),
            Affirmation(text: "I am complete in Christ.", scripture: "Colossians 2:10", isFavorite: false),
        ]),
        AffirmationPack(name: "I Am Secure", count: 11, affirmations: [
            Affirmation(text: "I am forever free from condemnation.", scripture: "Romans 8:1-2", isFavorite: true),
            Affirmation(text: "I am assured all things work together for good.", scripture: "Romans 8:28", isFavorite: false),
            Affirmation(text: "I am free from any condemning charges against me.", scripture: "Romans 8:31-34", isFavorite: false),
            Affirmation(text: "I cannot be separated from the love of God.", scripture: "Romans 8:35-39", isFavorite: false),
            Affirmation(text: "I have been established, anointed and sealed by God.", scripture: "2 Corinthians 1:21-22", isFavorite: false),
            Affirmation(text: "I am hidden with Christ in God.", scripture: "Colossians 3:3", isFavorite: false),
            Affirmation(text: "I am confident that the good work God has begun in me will be perfected.", scripture: "Philippians 1:6", isFavorite: false),
            Affirmation(text: "I am a citizen of heaven.", scripture: "Philippians 3:20", isFavorite: false),
            Affirmation(text: "I have not been given a spirit of fear, but of power, love and a sound mind.", scripture: "2 Timothy 1:7", isFavorite: false),
            Affirmation(text: "I can find grace and mercy in time of need.", scripture: "Hebrews 4:16", isFavorite: false),
            Affirmation(text: "I am born of God, and the evil one cannot touch me.", scripture: "1 John 5:18", isFavorite: false),
        ]),
        AffirmationPack(name: "I Am Significant", count: 11, affirmations: [
            Affirmation(text: "I am the salt of the earth and the light of the world.", scripture: "Matthew 5:13-14", isFavorite: false),
            Affirmation(text: "I am a branch of the true Vine, a channel of His life.", scripture: "John 15:1-5", isFavorite: false),
            Affirmation(text: "I have been chosen and appointed to bear fruit.", scripture: "John 15:16", isFavorite: false),
            Affirmation(text: "I am a personal witness of Jesus Christ.", scripture: "Acts 1:8", isFavorite: false),
            Affirmation(text: "I am God's temple.", scripture: "1 Corinthians 3:16", isFavorite: false),
            Affirmation(text: "I am a minister of reconciliation for God.", scripture: "2 Corinthians 5:17-21", isFavorite: false),
            Affirmation(text: "I am God's co-worker.", scripture: "2 Corinthians 6:1", isFavorite: false),
            Affirmation(text: "I am seated with Christ in the heavenly realm.", scripture: "Ephesians 2:6", isFavorite: false),
            Affirmation(text: "I am God's workmanship.", scripture: "Ephesians 2:10", isFavorite: false),
            Affirmation(text: "I may approach God with freedom and confidence.", scripture: "Ephesians 3:12", isFavorite: false),
            Affirmation(text: "I can do all things through Christ who strengthens me.", scripture: "Philippians 4:13", isFavorite: true),
        ]),
        AffirmationPack(name: "Morning Affirmations", count: 14, affirmations: [
            Affirmation(text: "God woke me up this morning for a purpose.", scripture: "", isFavorite: false),
            Affirmation(text: "I will take the time to appreciate quiet moments this morning.", scripture: "", isFavorite: false),
            Affirmation(text: "I am grateful for each breath God gives me.", scripture: "", isFavorite: false),
            Affirmation(text: "I know how to be still so I can hear from God.", scripture: "", isFavorite: false),
            Affirmation(text: "I can be confident in God's power.", scripture: "", isFavorite: false),
            Affirmation(text: "God will give me the strength I need to do everything He wants me to do today.", scripture: "", isFavorite: false),
            Affirmation(text: "I will respect myself and others because we are all made in the image of God.", scripture: "", isFavorite: false),
            Affirmation(text: "God loves me with an everlasting love.", scripture: "Jeremiah 31:3", isFavorite: false),
            Affirmation(text: "I can have wisdom and guidance from God if I just ask.", scripture: "", isFavorite: false),
            Affirmation(text: "My identity is in Christ — not anyone or anything else.", scripture: "", isFavorite: false),
            Affirmation(text: "I am not too much for God to handle.", scripture: "", isFavorite: false),
            Affirmation(text: "I have confidence that I can do all things through Christ.", scripture: "Philippians 4:13", isFavorite: false),
            Affirmation(text: "I am accepted by God.", scripture: "", isFavorite: false),
            Affirmation(text: "Even if I mess up today, I can try again tomorrow.", scripture: "", isFavorite: false),
        ]),
        AffirmationPack(name: "Daily Faith", count: 25, affirmations: [
            Affirmation(text: "I have full access to an ever-flowing river within me of goodness, peace and joy.", scripture: "", isFavorite: false),
            Affirmation(text: "I rejoice in all that I have and I live today at a refreshing pace.", scripture: "", isFavorite: false),
            Affirmation(text: "The Holy Spirit fills me and is teaching me how to live a life of goodness, peace, joy and faith.", scripture: "", isFavorite: false),
            Affirmation(text: "Today is a gift and I will engage in it fully and with gratitude and joy.", scripture: "", isFavorite: false),
            Affirmation(text: "I am completely surrounded by God's goodness — there is no place in my mind for worry.", scripture: "", isFavorite: false),
        ]),
        AffirmationPack(name: "AA Promises", count: 11, affirmations: [
            Affirmation(text: "I know a new freedom and happiness.", scripture: "", isFavorite: false),
            Affirmation(text: "I embrace my past.", scripture: "", isFavorite: false),
            Affirmation(text: "I comprehend the word serenity and know peace.", scripture: "", isFavorite: false),
            Affirmation(text: "I can see how my experience can benefit others.", scripture: "", isFavorite: false),
            Affirmation(text: "That feeling of uselessness and self-pity has disappeared.", scripture: "", isFavorite: false),
            Affirmation(text: "As I lose interest in selfish things, I gain interest in my fellows.", scripture: "", isFavorite: false),
            Affirmation(text: "Self-seeking has slipped away.", scripture: "", isFavorite: false),
            Affirmation(text: "My whole attitude and outlook upon life is changing.", scripture: "", isFavorite: false),
            Affirmation(text: "Fear of people and economic insecurity has left.", scripture: "", isFavorite: false),
            Affirmation(text: "I intuitively know how to handle situations that used to baffle me.", scripture: "", isFavorite: false),
            Affirmation(text: "I realize that God is doing for me what I could not do for myself.", scripture: "", isFavorite: false),
        ]),
    ]

    static let favoriteAffirmations: [Affirmation] = [
        Affirmation(text: "I am God's child.", scripture: "John 1:12", isFavorite: true),
        Affirmation(text: "I am forever free from condemnation.", scripture: "Romans 8:1-2", isFavorite: true),
        Affirmation(text: "I can do all things through Christ who strengthens me.", scripture: "Philippians 4:13", isFavorite: true),
        Affirmation(text: "I am a new creation in Christ.", scripture: "2 Corinthians 5:17", isFavorite: true),
        Affirmation(text: "God's power is made perfect in my weakness.", scripture: "2 Corinthians 12:9", isFavorite: true),
    ]

    static let todaysAffirmation = Affirmation(text: "I am God's child.", scripture: "John 1:12", isFavorite: true)

    // MARK: - Devotional

    static let devotionalDays: [DevotionalDay] = (1...30).map { day in
        DevotionalDay(
            day: day,
            title: devotionalTitles[day - 1],
            scripture: devotionalScriptures[day - 1],
            scriptureText: devotionalScriptureTexts[day - 1],
            reflection: devotionalReflections[day - 1],
            isComplete: day <= 23
        )
    }

    private static let devotionalTitles = [
        "A New Beginning", "Surrender", "Honesty", "Powerlessness", "Hope",
        "Trust", "Courage", "Willingness", "Forgiveness", "Humility",
        "Patience", "Gratitude", "Service", "Community", "Boundaries",
        "Self-Compassion", "Accountability", "Perseverance", "Joy in Trials", "Renewed Mind",
        "Walking in Light", "Freedom from Shame", "Identity in Christ", "A Clean Heart",
        "Strength in Weakness", "Rest", "Faithfulness", "Love", "Peace", "The Journey Ahead"
    ]

    private static let devotionalScriptures = [
        "2 Corinthians 5:17", "Proverbs 3:5-6", "John 8:32", "2 Corinthians 12:9-10", "Jeremiah 29:11",
        "Psalm 37:5", "Joshua 1:9", "Romans 12:1", "Ephesians 4:32", "James 4:10",
        "Psalm 27:14", "1 Thessalonians 5:18", "Galatians 5:13", "Hebrews 10:24-25", "Proverbs 4:23",
        "Psalm 103:8-12", "James 5:16", "Galatians 6:9", "James 1:2-4", "Romans 12:2",
        "1 John 1:7", "Romans 8:1", "Ephesians 2:10", "Psalm 51:10",
        "Isaiah 40:31", "Matthew 11:28-30", "Lamentations 3:22-23", "1 Corinthians 13:4-7", "Philippians 4:6-7", "Philippians 3:13-14"
    ]

    private static let devotionalScriptureTexts = [
        "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!",
        "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.",
        "Then you will know the truth, and the truth will set you free.",
        "But he said to me, 'My grace is sufficient for you, for my power is made perfect in weakness.'",
        "'For I know the plans I have for you,' declares the Lord, 'plans to prosper you and not to harm you, plans to give you hope and a future.'",
        "Commit your way to the Lord; trust in him and he will do this.",
        "Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.",
        "Therefore, I urge you, brothers and sisters, in view of God's mercy, to offer your bodies as a living sacrifice, holy and pleasing to God.",
        "Be kind and compassionate to one another, forgiving each other, just as in Christ God forgave you.",
        "Humble yourselves before the Lord, and he will lift you up.",
        "Wait for the Lord; be strong and take heart and wait for the Lord.",
        "Give thanks in all circumstances; for this is God's will for you in Christ Jesus.",
        "Serve one another humbly in love.",
        "And let us consider how we may spur one another on toward love and good deeds, not giving up meeting together.",
        "Above all else, guard your heart, for everything you do flows from it.",
        "The Lord is compassionate and gracious, slow to anger, abounding in love.",
        "Therefore confess your sins to each other and pray for each other so that you may be healed.",
        "Let us not become weary in doing good, for at the proper time we will reap a harvest if we do not give up.",
        "Consider it pure joy, my brothers and sisters, whenever you face trials of many kinds.",
        "Do not conform to the pattern of this world, but be transformed by the renewing of your mind.",
        "But if we walk in the light, as he is in the light, we have fellowship with one another.",
        "Therefore, there is now no condemnation for those who are in Christ Jesus.",
        "For we are God's handiwork, created in Christ Jesus to do good works.",
        "Create in me a pure heart, O God, and renew a steadfast spirit within me.",
        "But those who hope in the Lord will renew their strength. They will soar on wings like eagles.",
        "Come to me, all you who are weary and burdened, and I will give you rest.",
        "Because of the Lord's great love we are not consumed, for his compassions never fail. They are new every morning.",
        "Love is patient, love is kind. It does not envy, it does not boast, it is not proud.",
        "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.",
        "Brothers and sisters, I do not consider myself yet to have taken hold of it. But one thing I do: Forgetting what is behind and straining toward what is ahead.",
    ]

    private static let devotionalReflections = [
        "Recovery is not about going back to who you were — it's about becoming who God created you to be. Today, embrace the new creation.",
        "We tried to control everything and failed. Surrender isn't weakness — it's wisdom. What do you need to release to God today?",
        "Addiction thrives in secrecy. Honesty — with God, yourself, and others — is the foundation of lasting recovery.",
        "Admitting powerlessness isn't giving up. It's making room for God's power to work in your life.",
        "Even in the darkest valley, God has a plan for your future. What hope can you hold onto today?",
        "Trust is rebuilt one day at a time. Commit your recovery journey to the Lord today.",
        "Courage isn't the absence of fear — it's moving forward despite it. Where do you need God's courage today?",
        "Willingness opens the door that willpower cannot. Are you willing to do whatever it takes for your recovery today?",
        "Forgiveness isn't forgetting — it's releasing the power someone's actions have over you. Who do you need to forgive?",
        "Humility means seeing ourselves accurately — no better, no worse than who God says we are.",
        "Recovery doesn't happen overnight. Be patient with yourself today as God does His work in you.",
        "Gratitude shifts our focus from what we've lost to what we've been given. Name three things you're grateful for.",
        "Serving others gets us out of our own heads and into God's purpose. How can you serve someone today?",
        "You weren't meant to recover alone. Who in your community can you reach out to today?",
        "Healthy boundaries protect your recovery. What boundary do you need to reinforce today?",
        "God's compassion for you is infinite. Extend that same compassion to yourself today.",
        "Confession and accountability aren't punishment — they're freedom. Be honest with your sponsor this week.",
        "Don't give up. The harvest comes to those who keep planting seeds of recovery, one day at a time.",
        "Trials develop perseverance, and perseverance produces character. What is this season teaching you?",
        "Recovery transforms how you think. What old thought pattern do you need to replace with truth today?",
        "Walking in the light means no more hiding. Let God's light shine on every area of your life.",
        "There is no condemnation in Christ. A relapse doesn't define you — getting back up does.",
        "You are God's masterpiece. Your recovery story is part of His beautiful design for your life.",
        "Ask God to purify your heart and renew your spirit. He is faithful to answer that prayer.",
        "When you feel weak, lean into God's strength. His power is made perfect in your weakness.",
        "Rest is not laziness — it's trust. Give yourself permission to rest in God's care today.",
        "God's faithfulness never fails. Even on your worst day, His mercies are new every morning.",
        "Love — real, sacrificial love — is what recovery makes possible again. Practice love today.",
        "Anxiety has no home in a heart surrendered to God. Bring your worries to Him in prayer.",
        "You've come so far. Keep pressing forward. The best of your recovery journey is still ahead.",
    ]

    // MARK: - Prayers

    static let prayers: [PrayerItem] = [
        PrayerItem(title: "Morning Prayer", icon: "sunrise.fill", text: "Lord, I give You this new day. I commit my sobriety to You. Guard my eyes, my mind, and my heart. Give me the strength to walk in integrity today. Help me to be honest, humble, and present with those I love. I cannot do this alone — I need You every moment. In Jesus' name, Amen."),
        PrayerItem(title: "Evening Prayer", icon: "moon.stars.fill", text: "Father, thank You for getting me through this day. Forgive me where I fell short. I surrender my worries, my temptations, and my failures to You. As I rest tonight, guard my mind. Restore my soul. Let me wake tomorrow ready to walk in Your freedom again. In Jesus' name, Amen."),
        PrayerItem(title: "Serenity Prayer", icon: "leaf.fill", text: "God, grant me the serenity to accept the things I cannot change, courage to change the things I can, and wisdom to know the difference. Living one day at a time, enjoying one moment at a time, accepting hardships as the pathway to peace. Taking, as He did, this sinful world as it is, not as I would have it. Trusting that He will make all things right if I surrender to His will. That I may be reasonably happy in this life and supremely happy with Him forever in the next. Amen."),
        PrayerItem(title: "SA Third Step Prayer", icon: "hands.and.sparkles.fill", text: "God, I offer myself to Thee — to build with me and to do with me as Thou wilt. Relieve me of the bondage of self, that I may better do Thy will. Take away my difficulties, that victory over them may bear witness to those I would help of Thy power, Thy love, and Thy way of life. May I do Thy will always. Amen."),
        PrayerItem(title: "Prayer for My Spouse", icon: "heart.fill", text: "Lord, I lift up my spouse to You. Heal the wounds that my addiction has caused. Give them strength, peace, and hope. Help me to be patient, honest, and present. Rebuild the trust I have broken, one day at a time. Teach me to love the way You love — sacrificially, faithfully, and completely. In Jesus' name, Amen."),
        PrayerItem(title: "Prayer in Temptation", icon: "shield.fill", text: "Father, I am struggling right now. The pull is strong but You are stronger. I claim Your promise that no temptation has overtaken me except what is common to mankind. You are faithful — You will not let me be tempted beyond what I can bear. Show me the way out that You have provided. I choose You over my addiction. Right now, in this moment, I choose You. In Jesus' name, Amen."),
    ]

    // MARK: - 12 Steps

    static let stepWork: [StepWorkItem] = [
        StepWorkItem(id: 1, title: "Powerlessness", description: "We admitted that we were powerless over lust — that our lives had become unmanageable.", scripture: "Romans 7:18", status: .complete, reflectionQuestions: [], answeredCount: 10),
        StepWorkItem(id: 2, title: "Hope", description: "Came to believe that a Power greater than ourselves could restore us to sanity.", scripture: "Hebrews 11:1", status: .complete, reflectionQuestions: [], answeredCount: 10),
        StepWorkItem(id: 3, title: "Surrender", description: "Made a decision to turn our will and our lives over to the care of God.", scripture: "Proverbs 3:5-6", status: .complete, reflectionQuestions: [], answeredCount: 10),
        StepWorkItem(id: 4, title: "Moral Inventory", description: "Made a searching and fearless moral inventory of ourselves.", scripture: "Lamentations 3:40", status: .complete, reflectionQuestions: [], answeredCount: 10),
        StepWorkItem(id: 5, title: "Confession", description: "Admitted to God, to ourselves, and to another human being the exact nature of our wrongs.", scripture: "James 5:16", status: .complete, reflectionQuestions: [], answeredCount: 10),
        StepWorkItem(id: 6, title: "Readiness", description: "Were entirely ready to have God remove all these defects of character.", scripture: "James 4:10", status: .complete, reflectionQuestions: [], answeredCount: 10),
        StepWorkItem(id: 7, title: "Humility", description: "Humbly asked Him to remove our shortcomings.", scripture: "1 John 1:9", status: .complete, reflectionQuestions: [], answeredCount: 10),
        StepWorkItem(id: 8, title: "Amends List", description: "Made a list of all persons we had harmed, and became willing to make amends to them all.", scripture: "Matthew 5:23-24", status: .inProgress, reflectionQuestions: [
            "Who have I harmed through my addiction? List every person.",
            "What specific harm did I cause each person?",
            "Am I willing to make amends to each of these people?",
            "Which amends might cause further harm if made directly?",
            "What fears do I have about making amends?",
            "How has my addiction affected my spouse/partner?",
            "How has my addiction affected my children or family?",
            "How has my addiction affected my work relationships?",
            "What amends do I need to make to myself?",
            "What does willingness to make amends look like in my daily life?"
        ], answeredCount: 3),
        StepWorkItem(id: 9, title: "Making Amends", description: "Made direct amends to such people wherever possible, except when to do so would injure them or others.", scripture: "Romans 12:18", status: .locked, reflectionQuestions: [], answeredCount: 0),
        StepWorkItem(id: 10, title: "Continued Inventory", description: "Continued to take personal inventory and when we were wrong promptly admitted it.", scripture: "1 Corinthians 10:12", status: .locked, reflectionQuestions: [], answeredCount: 0),
        StepWorkItem(id: 11, title: "Prayer & Meditation", description: "Sought through prayer and meditation to improve our conscious contact with God, praying only for knowledge of His will for us and the power to carry that out.", scripture: "Psalm 46:10", status: .locked, reflectionQuestions: [], answeredCount: 0),
        StepWorkItem(id: 12, title: "Service", description: "Having had a spiritual awakening as the result of these steps, we tried to carry this message to sexaholics, and to practice these principles in all our affairs.", scripture: "Galatians 6:1", status: .locked, reflectionQuestions: [], answeredCount: 0),
    ]

    // MARK: - Weekly Goals

    static let weeklyGoals: [WeeklyGoal] = [
        WeeklyGoal(title: "Morning prayer & devotional daily", dynamic: "Spiritual", isComplete: true),
        WeeklyGoal(title: "Run 3 times this week", dynamic: "Physical", isComplete: true),
        WeeklyGoal(title: "Journal about feelings after sponsor call", dynamic: "Emotional", isComplete: true),
        WeeklyGoal(title: "Read one chapter of recovery book", dynamic: "Intellectual", isComplete: true),
        WeeklyGoal(title: "Plan date night with Rachel", dynamic: "Relational", isComplete: false),
    ]

    // MARK: - Glossary

    static let glossary: [GlossaryTerm] = [
        GlossaryTerm(term: "FASTER Scale", definition: "A relapse-awareness tool by Michael Dye mapping six progressive stages: Forgetting Priorities, Anxiety, Speeding Up, Ticked Off, Exhausted, Relapse."),
        GlossaryTerm(term: "FANOS", definition: "Couples check-in framework: Feelings, Affirmations, Needs, Ownership, Sobriety."),
        GlossaryTerm(term: "FITNAP", definition: "Alternative couples check-in: Feelings, Intimacy, Triggers, Needs, Affirmations, Prayer."),
        GlossaryTerm(term: "3 Circles", definition: "Boundary tool with three rings: Red (acting out), Yellow (warning behaviors), Green (healthy behaviors)."),
        GlossaryTerm(term: "PCI", definition: "Personal Craziness Index — Patrick Carnes self-assessment measuring life manageability through personal warning behaviors."),
        GlossaryTerm(term: "SAST-R", definition: "Sexual Addiction Screening Test Revised — validated clinical screening instrument."),
        GlossaryTerm(term: "SA", definition: "Sexaholics Anonymous — defines sobriety as no sex with self and no sex with anyone other than spouse."),
        GlossaryTerm(term: "Celebrate Recovery", definition: "Christ-centered 12-step program addressing hurts, habits, and hang-ups."),
        GlossaryTerm(term: "CSAT", definition: "Certified Sex Addiction Therapist — clinical credential from IITAP."),
        GlossaryTerm(term: "Acting In", definition: "Subtle internalized addiction behaviors: emotional withdrawal, fantasy, objectification, dishonesty."),
        GlossaryTerm(term: "Arousal Template", definition: "Patrick Carnes framework describing the constellation of thoughts, feelings, and imagery in sexual arousal. Highest privacy tier."),
        GlossaryTerm(term: "12 Steps", definition: "Foundational SA/AA recovery framework from powerlessness through spiritual awakening and service."),
        GlossaryTerm(term: "Betrayal Trauma", definition: "Psychological trauma experienced by partners when discovering addictive behavior. Symptoms mirror PTSD."),
        GlossaryTerm(term: "Recovery Health Score", definition: "0-100 composite daily score: Sobriety 30%, Engagement 25%, Emotional Health 20%, Connection 15%, Growth 10%."),
    ]

    // MARK: - Crisis Resources

    static let crisisResources: [CrisisResource] = [
        CrisisResource(name: "SA Helpline", phone: "866-424-8777", description: "Sexaholics Anonymous 24/7 helpline"),
        CrisisResource(name: "988 Suicide & Crisis Lifeline", phone: "988", description: "24/7 crisis support — call or text"),
        CrisisResource(name: "RAINN", phone: "800-656-4673", description: "National Sexual Assault Hotline"),
    ]

    // MARK: - Notification Settings

    static let notificationSettings: [NotificationSetting] = [
        NotificationSetting(title: "Morning Commitment", time: "6:00 AM", isEnabled: true),
        NotificationSetting(title: "Evening Review", time: "9:00 PM", isEnabled: true),
        NotificationSetting(title: "Daily Affirmation", time: "6:15 AM", isEnabled: true),
        NotificationSetting(title: "Meeting Reminders", time: "1 hr before", isEnabled: true),
    ]

    // MARK: - Needs (for Time Journal)

    static let needs = [
        "Acceptance", "Affirmation", "Agency", "Belonging", "Comfort",
        "Compassion", "Connection", "Empathy", "Encouragement", "Forgiveness",
        "Grace", "Hope", "Love", "Peace", "Reassurance",
        "Respect", "Safety", "Security", "Understanding", "Validation"
    ]

    // MARK: - Motivations (for onboarding)

    static let motivations = [
        "Faith", "Family", "Freedom", "Health", "Honesty",
        "Hope", "Integrity", "Intimacy", "Joy", "Love",
        "Marriage", "Peace", "Purpose", "Self-Respect", "Sobriety",
        "Spirituality", "Trust", "Wholeness"
    ]
}
