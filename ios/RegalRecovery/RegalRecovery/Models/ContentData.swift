import SwiftUI

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Static Content Catalog
// Content data for the app — affirmations, prayers, glossary terms, crisis resources,
// devotional days, motivations, needs, commitment questions, and notification defaults.
// This is NOT mock/test data — it's the app's real static content.

enum ContentData {

    // MARK: - Affirmation Packs

    static let affirmationPacks: [AffirmationPack] = [
        AffirmationPack(name: "I Am Accepted", count: 11, affirmations: [
            Affirmation(text: "I am God's child.", scripture: "John 1:12", isFavorite: false),
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
            Affirmation(text: "I am forever free from condemnation.", scripture: "Romans 8:1-2", isFavorite: false),
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
            Affirmation(text: "I can do all things through Christ who strengthens me.", scripture: "Philippians 4:13", isFavorite: false),
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

    // MARK: - Default Favorite Affirmations

    static let defaultFavoriteAffirmations: [Affirmation] = [
        Affirmation(text: "I am God's child.", scripture: "John 1:12", isFavorite: true),
        Affirmation(text: "I am forever free from condemnation.", scripture: "Romans 8:1-2", isFavorite: true),
        Affirmation(text: "I can do all things through Christ who strengthens me.", scripture: "Philippians 4:13", isFavorite: true),
        Affirmation(text: "I am a new creation in Christ.", scripture: "2 Corinthians 5:17", isFavorite: true),
        Affirmation(text: "God's power is made perfect in my weakness.", scripture: "2 Corinthians 12:9", isFavorite: true),
    ]

    // MARK: - Today's Affirmation

    static var todaysAffirmation: Affirmation {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let allAffirmations = affirmationPacks.flatMap(\.affirmations)
        let index = (dayOfYear - 1) % allAffirmations.count
        return allAffirmations[index]
    }

    // MARK: - Devotional

    static let devotionalDays: [DevotionalDay] = (1...30).map { day in
        DevotionalDay(
            day: day,
            title: devotionalTitles[day - 1],
            scripture: devotionalScriptures[day - 1],
            scriptureText: devotionalScriptureTexts[day - 1],
            reflection: devotionalReflections[day - 1],
            isComplete: false
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
        PrayerItem(title: "Third Step Prayer", icon: "hands.and.sparkles.fill", text: "God, I offer myself to Thee — to build with me and to do with me as Thou wilt. Relieve me of the bondage of self, that I may better do Thy will. Take away my difficulties, that victory over them may bear witness to those I would help of Thy power, Thy love, and Thy way of life. May I do Thy will always. Amen."),
        PrayerItem(title: "Prayer for My Spouse", icon: "heart.fill", text: "Lord, I lift up my spouse to You. Heal the wounds that my addiction has caused. Give them strength, peace, and hope. Help me to be patient, honest, and present. Rebuild the trust I have broken, one day at a time. Teach me to love the way You love — sacrificially, faithfully, and completely. In Jesus' name, Amen."),
        PrayerItem(title: "Prayer in Temptation", icon: "shield.fill", text: "Father, I am struggling right now. The pull is strong but You are stronger. I claim Your promise that no temptation has overtaken me except what is common to mankind. You are faithful — You will not let me be tempted beyond what I can bear. Show me the way out that You have provided. I choose You over my addiction. Right now, in this moment, I choose You. In Jesus' name, Amen."),
    ]

    // MARK: - Journal Prompts

    static let promptCategories = ["verse", "daily", "sobriety", "emotional", "relationships", "spiritual", "shame", "triggers", "amends", "gratitude", "deep"]

    static let prompts: [PromptItem] = [
        // Verse Prompts (Memory Verses)
        PromptItem(text: "\"Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!\" — 2 Corinthians 5:17\n\nWhat does being a \"new creation\" mean for your recovery today?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.\" — Proverbs 3:5-6\n\nWhere are you leaning on your own understanding instead of trusting God?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Then you will know the truth, and the truth will set you free.\" — John 8:32\n\nWhat truth about yourself or your addiction is God revealing to you right now?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"But he said to me, 'My grace is sufficient for you, for my power is made perfect in weakness.'\" — 2 Corinthians 12:9-10\n\nHow has God shown His strength through your weakness in recovery?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"'For I know the plans I have for you,' declares the Lord, 'plans to prosper you and not to harm you, plans to give you hope and a future.'\" — Jeremiah 29:11\n\nWhat does God's plan for your future look like beyond addiction?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Commit your way to the Lord; trust in him and he will do this.\" — Psalm 37:5\n\nWhat part of your recovery are you still trying to control instead of committing to God?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.\" — Joshua 1:9\n\nWhat step in your recovery requires courage today? How does God's presence change that?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Therefore, I urge you, brothers and sisters, in view of God's mercy, to offer your bodies as a living sacrifice, holy and pleasing to God.\" — Romans 12:1\n\nWhat does it mean to honor God with your body in the context of sexual sobriety?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Be kind and compassionate to one another, forgiving each other, just as in Christ God forgave you.\" — Ephesians 4:32\n\nWho do you need to forgive — including yourself? What would that forgiveness look like?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Humble yourselves before the Lord, and he will lift you up.\" — James 4:10\n\nHow does humility play a role in your recovery? Where is pride getting in the way?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Wait for the Lord; be strong and take heart and wait for the Lord.\" — Psalm 27:14\n\nWhat are you waiting on God for right now? How can you practice patience in recovery?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Give thanks in all circumstances; for this is God's will for you in Christ Jesus.\" — 1 Thessalonians 5:18\n\nWhat can you thank God for even in the hard parts of recovery?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Serve one another humbly in love.\" — Galatians 5:13\n\nHow can you serve someone in your recovery community this week?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"And let us consider how we may spur one another on toward love and good deeds, not giving up meeting together.\" — Hebrews 10:24-25\n\nWho is encouraging you in recovery? Who can you encourage?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Above all else, guard your heart, for everything you do flows from it.\" — Proverbs 4:23\n\nWhat are you allowing into your heart and mind? What boundaries do you need to set?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"The Lord is compassionate and gracious, slow to anger, abounding in love.\" — Psalm 103:8-12\n\nWhat does God's compassion say about how He sees you — even after a fall?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Therefore confess your sins to each other and pray for each other so that you may be healed.\" — James 5:16\n\nWhat are you carrying alone that you need to confess to a trusted person?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Let us not become weary in doing good, for at the proper time we will reap a harvest if we do not give up.\" — Galatians 6:9\n\nWhere are you feeling weary in recovery? What keeps you going?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Consider it pure joy, my brothers and sisters, whenever you face trials of many kinds.\" — James 1:2-4\n\nWhat trial in your recovery has God used to grow you? What is He teaching you through it?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Do not conform to the pattern of this world, but be transformed by the renewing of your mind.\" — Romans 12:2\n\nWhat old thought patterns are you still conforming to? How is God renewing your mind?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"But if we walk in the light, as he is in the light, we have fellowship with one another.\" — 1 John 1:7\n\nWhat does \"walking in the light\" look like in your daily life? Where are you hiding?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Therefore, there is now no condemnation for those who are in Christ Jesus.\" — Romans 8:1\n\nHow does this truth challenge the shame you carry? What would life look like without condemnation?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"For we are God's handiwork, created in Christ Jesus to do good works.\" — Ephesians 2:10\n\nWhat does it mean that you are God's handiwork — not a mistake, but a masterpiece in progress?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Create in me a pure heart, O God, and renew a steadfast spirit within me.\" — Psalm 51:10\n\nWhat does a \"pure heart\" mean to you? What do you need God to create in you today?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"But those who hope in the Lord will renew their strength. They will soar on wings like eagles.\" — Isaiah 40:31\n\nWhere do you need renewed strength? How can you place your hope in the Lord today?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Come to me, all you who are weary and burdened, and I will give you rest.\" — Matthew 11:28-30\n\nWhat burden are you carrying that Jesus is asking you to lay down?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Because of the Lord's great love we are not consumed, for his compassions never fail. They are new every morning.\" — Lamentations 3:22-23\n\nWhat does it mean that God's mercies are new every morning — especially after a hard day?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Love is patient, love is kind. It does not envy, it does not boast, it is not proud.\" — 1 Corinthians 13:4-7\n\nHow does this description of love challenge how you treat yourself and others?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.\" — Philippians 4:6-7\n\nWhat anxiety are you holding onto? Can you turn it into a prayer right now?", category: "verse", tags: ["Memory Verse"]),
        PromptItem(text: "\"Brothers and sisters, I do not consider myself yet to have taken hold of it. But one thing I do: Forgetting what is behind and straining toward what is ahead.\" — Philippians 3:13-14\n\nWhat do you need to leave behind in order to press forward in recovery?", category: "verse", tags: ["Memory Verse"]),

        // Daily Reflection
        PromptItem(text: "What is one thing I am grateful for today?", category: "daily", tags: []),
        PromptItem(text: "Where was I honest today, and where did I fall short?", category: "daily", tags: []),
        PromptItem(text: "What did I do today to invest in my recovery?", category: "daily", tags: []),
        PromptItem(text: "How did I experience God's presence today?", category: "daily", tags: []),
        PromptItem(text: "What is one thing I can do differently tomorrow?", category: "daily", tags: []),
        // Sobriety & Urges
        PromptItem(text: "What urges did I experience today, and how did I respond?", category: "sobriety", tags: []),
        PromptItem(text: "What was happening emotionally right before my last urge?", category: "sobriety", tags: ["FASTER"]),
        PromptItem(text: "What middle-circle behaviors am I flirting with right now?", category: "sobriety", tags: ["3 Circles"]),
        PromptItem(text: "What would I lose if I acted out today?", category: "sobriety", tags: []),
        PromptItem(text: "Write a letter to your future self about why sobriety matters.", category: "sobriety", tags: []),
        // Emotional Awareness
        PromptItem(text: "Where am I on the FASTER Scale right now, and what got me here?", category: "emotional", tags: ["FASTER"]),
        PromptItem(text: "What emotion am I avoiding right now, and why?", category: "emotional", tags: []),
        PromptItem(text: "When I feel anxious, what am I really afraid of underneath?", category: "emotional", tags: ["FASTER"]),
        PromptItem(text: "What does loneliness feel like in my body?", category: "emotional", tags: []),
        PromptItem(text: "Am I numbing out? What feeling am I running from?", category: "emotional", tags: []),
        // Relationships & Trust
        PromptItem(text: "What is one honest thing I could share with my spouse today?", category: "relationships", tags: ["FANOS/FITNAP"]),
        PromptItem(text: "How has my addiction affected the people I love most?", category: "relationships", tags: []),
        PromptItem(text: "What does rebuilding trust look like this week — one specific action?", category: "relationships", tags: []),
        PromptItem(text: "What do I need from my sponsor that I haven't asked for?", category: "relationships", tags: []),
        PromptItem(text: "How can I show up more fully in my relationships today?", category: "relationships", tags: []),
        // Spiritual Growth
        PromptItem(text: "What does surrender look like for me today?", category: "spiritual", tags: ["12-Step"]),
        PromptItem(text: "Where am I trying to control outcomes instead of trusting God?", category: "spiritual", tags: []),
        PromptItem(text: "What scripture spoke to me this week, and why?", category: "spiritual", tags: []),
        PromptItem(text: "How is God working in my recovery, even when I can't see it?", category: "spiritual", tags: []),
        PromptItem(text: "What does Step 3 — turning my will over to God — mean in my life right now?", category: "spiritual", tags: ["12-Step"]),
        // Shame & Identity
        PromptItem(text: "What shame message played in my head today?", category: "shame", tags: []),
        PromptItem(text: "What does God say about who I am, versus what shame tells me?", category: "shame", tags: []),
        PromptItem(text: "A relapse does not define me. What does define me?", category: "shame", tags: []),
        PromptItem(text: "Where do I confuse guilt (I did something wrong) with shame (I am wrong)?", category: "shame", tags: []),
        PromptItem(text: "Write three true statements about your worth that have nothing to do with your behavior.", category: "shame", tags: []),
        // Triggers & Patterns
        PromptItem(text: "What time of day am I most vulnerable, and what can I do differently then?", category: "triggers", tags: []),
        PromptItem(text: "Map your last week: what situations moved you from green to yellow circle?", category: "triggers", tags: ["3 Circles"]),
        PromptItem(text: "What is the ritual that leads to my acting out, step by step?", category: "triggers", tags: []),
        PromptItem(text: "How is my PCI score trending, and what does that tell me?", category: "triggers", tags: ["PCI"]),
        PromptItem(text: "What HALT state (Hungry, Angry, Lonely, Tired) am I in right now?", category: "triggers", tags: []),
        // Amends & Accountability
        PromptItem(text: "Who do I owe an amend to, and what is holding me back?", category: "amends", tags: ["12-Step"]),
        PromptItem(text: "What did my moral inventory reveal that surprised me?", category: "amends", tags: ["12-Step"]),
        PromptItem(text: "Where was I dishonest this week, even in small ways?", category: "amends", tags: []),
        PromptItem(text: "What does making a living amend look like today?", category: "amends", tags: ["12-Step"]),
        PromptItem(text: "How transparent was I with my accountability partner this week?", category: "amends", tags: []),
        // Gratitude & Hope
        PromptItem(text: "Write three things about your recovery you never thought would be possible.", category: "gratitude", tags: []),
        PromptItem(text: "What milestone — no matter how small — can I celebrate today?", category: "gratitude", tags: []),
        PromptItem(text: "Who in my recovery community am I grateful for, and why?", category: "gratitude", tags: []),
        PromptItem(text: "What does freedom look like in my life compared to a year ago?", category: "gratitude", tags: []),
        PromptItem(text: "Write a letter to your past self from where you are now.", category: "gratitude", tags: []),
        // Deep Work
        PromptItem(text: "What childhood wound am I still carrying, and how does it connect to my addiction?", category: "deep", tags: []),
        PromptItem(text: "What unmet need was my addiction trying to fill?", category: "deep", tags: []),
        PromptItem(text: "What beliefs about myself formed in childhood that I still live by?", category: "deep", tags: []),
        PromptItem(text: "What would my life look like if I fully believed I was worthy of love?", category: "deep", tags: []),
        PromptItem(text: "What grief have I not yet processed related to what my addiction has cost me?", category: "deep", tags: []),
    ]

    static func prompts(for category: String) -> [PromptItem] {
        prompts.filter { $0.category == category }
    }

    static func randomPrompt(category: String? = nil) -> PromptItem? {
        let filtered = category.map { cat in prompts.filter { $0.category == cat } } ?? prompts
        return filtered.randomElement()
    }

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
        // Crisis & Suicide Prevention
        CrisisResource(name: "988 Suicide & Crisis Lifeline", phone: "988", description: "24/7 suicide and crisis support — call or text", textOption: "Text 988", category: "Crisis"),
        CrisisResource(name: "Crisis Text Line", phone: "", description: "Free 24/7 crisis counseling via text message", textOption: "Text HOME to 741741", category: "Crisis"),

        // Addiction & Substance Abuse
        CrisisResource(name: "SAMHSA National Helpline", phone: "1-800-662-4357", description: "Free 24/7 treatment referral and information for substance abuse and mental health", category: "Addiction"),
        CrisisResource(name: "SA Helpline", phone: "866-424-8777", description: "Sexaholics Anonymous 24/7 helpline for those struggling with sexual addiction", category: "Sexual Addiction"),
        CrisisResource(name: "SLAA", phone: "210-828-7900", description: "Sex and Love Addicts Anonymous fellowship office", category: "Sexual Addiction", is24x7: false),
        CrisisResource(name: "National Council on Problem Gambling", phone: "1-800-522-4700", description: "24/7 confidential helpline for gambling addiction", textOption: "Text 800-522-4700", category: "Addiction"),

        // Sexual Assault & Abuse
        CrisisResource(name: "RAINN", phone: "800-656-4673", description: "National Sexual Assault Hotline — 24/7 confidential support", category: "Abuse"),
        CrisisResource(name: "Childhelp National Hotline", phone: "1-800-422-4453", description: "24/7 crisis intervention for child abuse — call or text", textOption: "Text 1-800-422-4453", category: "Abuse"),

        // Family & Partner Support
        CrisisResource(name: "S-Anon", phone: "615-833-3152", description: "Support for family and friends of sexually addicted people", category: "Family Support", is24x7: false),
        CrisisResource(name: "COSA", phone: "866-899-2672", description: "Recovery for co-sex addicts — partners and family members", category: "Family Support", is24x7: false),
        CrisisResource(name: "Al-Anon", phone: "1-888-425-2666", description: "Support for families and friends affected by someone's drinking", category: "Family Support", is24x7: false),
        CrisisResource(name: "National Domestic Violence Hotline", phone: "1-800-799-7233", description: "24/7 confidential support for domestic violence", textOption: "Text START to 88788", category: "Abuse"),

        // Mental Health
        CrisisResource(name: "NAMI Helpline", phone: "1-800-950-6264", description: "Mental health information, referrals, and support", textOption: "Text HELPLINE to 62640", category: "Mental Health", is24x7: false),

        // Faith-Based
        CrisisResource(name: "Focus on the Family", phone: "1-800-232-6459", description: "Christian counseling referrals and family support", category: "Faith-Based", is24x7: false),

        // Veterans
        CrisisResource(name: "Veterans Crisis Line", phone: "988", description: "Dial 988, then press 1 — 24/7 support for veterans and their families", textOption: "Text 838255", category: "Veterans"),

        // Youth
        CrisisResource(name: "Boys Town National Hotline", phone: "1-800-448-3000", description: "24/7 crisis support for teens and families", textOption: "Text VOICE to 20121", category: "Youth"),
        CrisisResource(name: "The Trevor Project", phone: "1-866-488-7386", description: "24/7 crisis intervention for LGBTQ+ young people", textOption: "Text START to 678-678", category: "Youth"),
        CrisisResource(name: "Teen Line", phone: "1-800-852-8336", description: "Teens helping teens — evenings PST", textOption: "Text TEEN to 839863", category: "Youth", is24x7: false),

        // Eating Disorders (co-occurring)
        CrisisResource(name: "ANAD Helpline", phone: "1-888-375-7767", description: "National Association of Anorexia Nervosa and Associated Disorders", category: "Co-occurring", is24x7: false),
    ]

    // MARK: - Motivations (for onboarding)

    static let motivations = [
        "Faith", "Family", "Freedom", "Health", "Honesty",
        "Hope", "Integrity", "Intimacy", "Joy", "Love",
        "Marriage", "Peace", "Purpose", "Self-Respect", "Sobriety",
        "Spirituality", "Trust", "Wholeness"
    ]

    // MARK: - Needs (for Time Journal)

    static let needs = [
        "Acceptance", "Affirmation", "Agency", "Belonging", "Comfort",
        "Compassion", "Connection", "Empathy", "Encouragement", "Forgiveness",
        "Grace", "Hope", "Love", "Peace", "Reassurance",
        "Respect", "Safety", "Security", "Understanding", "Validation"
    ]

    // MARK: - Commitment Questions (defaults)

    static let morningQuestions: [CommitmentQuestion] = [
        CommitmentQuestion(text: "I commit to sexual sobriety today — no sex with self, no sex outside of marriage.", isChecked: false),
        CommitmentQuestion(text: "I will reach out to my sponsor or accountability partner if I am struggling.", isChecked: false),
        CommitmentQuestion(text: "I will attend my scheduled recovery meeting.", isChecked: false),
        CommitmentQuestion(text: "I will spend time in prayer and scripture today.", isChecked: false),
        CommitmentQuestion(text: "I will be honest with myself and others today.", isChecked: false),
        CommitmentQuestion(text: "I surrender this day to God and trust His plan for my recovery.", isChecked: false),
    ]

    static let eveningQuestions: [CommitmentQuestion] = [
        CommitmentQuestion(text: "Did I maintain my sobriety commitment today?", isChecked: false),
        CommitmentQuestion(text: "Was I honest in all my interactions today?", isChecked: false),
        CommitmentQuestion(text: "Did I reach out for support when I needed it?", isChecked: false),
        CommitmentQuestion(text: "What am I grateful for today?", isChecked: false),
    ]

    // MARK: - Notification Settings (defaults)

    static let defaultNotificationSettings: [NotificationSetting] = [
        NotificationSetting(title: "Morning Commitment", time: "6:00 AM", isEnabled: true),
        NotificationSetting(title: "Evening Review", time: "9:00 PM", isEnabled: true),
        NotificationSetting(title: "Daily Affirmation", time: "6:15 AM", isEnabled: true),
        NotificationSetting(title: "Meeting Reminders", time: "1 hr before", isEnabled: true),
    ]

    // MARK: - Sobriety Reset Encouragement Messages

    static let sobrietyResetMessages: [String] = [
        "His mercies are new this morning — and so are you. \"Because of the Lord's great love we are not consumed, for his compassions never fail. They are new every morning.\" (Lamentations 3:22-23)",
        "A reset is not the end of your story. It's a turning point. God is still writing.",
        "You are not defined by your worst moment. You are defined by the One who calls you His own.",
        "\"The righteous may fall seven times but still get up.\" (Proverbs 24:16) — Getting back up is what makes you righteous, not never falling.",
        "Right now, grace is louder than shame.",
        "God didn't flinch. He knew this day would come, and He's still here, still for you, still working.",
        "Peter denied Jesus three times and became the rock of the church. Your story isn't over. Not even close.",
        "\"There is therefore now no condemnation for those who are in Christ Jesus.\" (Romans 8:1) — No condemnation. Not some. None.",
        "You had the courage to be honest. That matters more than you know.",
        "This reset does not erase the growth that came before it. Every sober day still counted. Every prayer still mattered.",
        "\"He heals the brokenhearted and binds up their wounds.\" (Psalm 147:3) — Let Him tend to you today.",
        "Recovery is not a straight line. It never was. But the God who called you into it walks every twist and turn with you.",
        "Shame says \"hide.\" Grace says \"come as you are.\" You are welcome here.",
        "You are not starting over from nothing. You are starting again with experience, with wisdom, and with a God who never left.",
        "\"Come to me, all you who are weary and burdened, and I will give you rest.\" (Matthew 11:28) — He's not angry. He's inviting.",
        "One day at a time. One hour if you need it. One breath. He is faithful in all of them.",
        "The enemy wants you to believe this disqualifies you. It doesn't. Not from God's love, not from recovery, not from hope.",
        "David was called a man after God's own heart — not because he was perfect, but because he always came back. Keep coming back.",
        "\"If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness.\" (1 John 1:9) — Faithful. And. Just. He keeps His promises.",
        "You are loved right now. Not the future version of you. Not the cleaned-up version. You, right now, in this moment.",
        "Healing is not linear, and neither is freedom. But the One who began a good work in you will be faithful to complete it. (Philippians 1:6)",
        "A relapse is information, not identity. Learn from it, grieve it, and let God redeem it.",
        "The cross already covered this moment. It was enough then, and it is enough now.",
        "\"The Lord is close to the brokenhearted and saves those who are crushed in spirit.\" (Psalm 34:18) — He is close to you right now.",
        "You don't have to earn your way back. You never left His hand.",
        "Today is day one again, and day one takes more bravery than day one hundred. Be proud of this step.",
        "Your value to God has not changed. Not by one fraction. \"Neither height nor depth, nor anything else in all creation, will be able to separate us from the love of God.\" (Romans 8:39)",
        "Reach out today. Call someone. You were never meant to carry this alone.",
        "\"He gives strength to the weary and increases the power of the weak.\" (Isaiah 40:29) — Ask Him for strength today. He will give it.",
        "Resetting your date is an act of integrity. It takes tremendous honesty to start again.",
        "You are not too far gone. You are not too broken. You are not too much for God.",
        "Jesus sought out the lost sheep — not to scold it, but to carry it home on His shoulders with joy. (Luke 15:4-6)",
        "What happened does not have to happen again. But even if it does, His love will still be there. That's what unconditional means.",
        "\"Weeping may stay for the night, but rejoicing comes in the morning.\" (Psalm 30:5) — Morning is coming.",
        "Take a breath. Say a prayer. Call your person. That's enough for right now.",
        "God's grace is not a safety net you fell into by accident. It was built for exactly this moment.",
        "\"My grace is sufficient for you, for my power is made perfect in weakness.\" (2 Corinthians 12:9) — Your weakness is where His power shows up.",
        "You chose honesty over hiding. That is recovery in action.",
        "The Israelites wandered for forty years and God fed them every single morning. He will sustain you through this wilderness too.",
        "\"Forget the former things; do not dwell on the past. See, I am doing a new thing!\" (Isaiah 43:18-19) — He is doing a new thing in you, starting now.",
        "Addiction is a battle, and soldiers are not shamed for their wounds. Let the Healer do His work.",
        "You are still a child of God. That didn't change today. It can never change.",
        "\"The Lord your God is with you, the Mighty Warrior who saves. He will take great delight in you; in his love he will no longer rebuke you, but will rejoice over you with singing.\" (Zephaniah 3:17) — He is singing over you right now.",
        "Don't let today's pain write tomorrow's story. Let God do that.",
        "Every saint has a past. Every sinner has a future. Yours is held in the hands of a God who makes all things new. (Revelation 21:5)",
        "You showed up. You were honest. You reset. That is not weakness — that is the hardest kind of strength.",
        "\"Cast all your anxiety on him because he cares for you.\" (1 Peter 5:7) — Hand it over. All of it. He can hold it.",
        "This is a chapter, not the whole book. And the Author is good.",
        "The same power that raised Christ from the dead is alive in you. (Romans 8:11) — A setback cannot outmatch resurrection power.",
        "You are seen. You are known. You are loved. And tomorrow, you will rise again — because He already has.",
    ]
}
