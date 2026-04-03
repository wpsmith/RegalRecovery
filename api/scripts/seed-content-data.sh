#!/usr/bin/env bash
# Seed regal-recovery-content database with all 12 collections
set -euo pipefail

echo "Seeding regal-recovery-content database..."
echo ""

docker compose exec -T mongodb mongosh regal-recovery-content --eval '
db.dropDatabase();
print("✓ Dropped existing content database for fresh seed");
print("");

var now = ISODate("2026-04-03T00:00:00Z");
var base = { tenantId: "SYSTEM", status: "published", createdAt: now, modifiedAt: now };

db.feature_abouts.insertMany([
  { ...base, slug: "faster-scale", title: "Understanding the FASTER Scale", summary: "The FASTER Scale helps identify where you are in the relapse cycle.", contentHtml: "<p>Developed by Michael Dye, the FASTER Scale maps six progressive stages leading to relapse.</p>", category: "activity", relatedFeatureFlag: "activity.faster-scale", iconName: "speedometer", sortOrder: 1 },
  { ...base, slug: "triggers", title: "Understanding Triggers", summary: "Learn to identify and manage the triggers that precede compulsive behavior.", contentHtml: "<p>In recovery, a trigger is any internal state or external stimulus that activates the urge to act out.</p>", category: "tool", relatedFeatureFlag: "feature.triggers", iconName: "alert-triangle", sortOrder: 1 },
  { ...base, slug: "3circles", title: "The Three Circles", summary: "A boundary-setting tool for categorizing behaviors into inner, middle, and outer circles.", contentHtml: "<p>The Three Circles model categorizes behaviors into inner (acting out), middle (warning), and outer (healthy) circles.</p>", category: "tool", relatedFeatureFlag: "feature.three-circles", iconName: "circles", sortOrder: 2 },
  { ...base, slug: "evening-review", title: "Evening Review", summary: "A structured end-of-day inventory for sobriety, honesty, and emotional health.", contentHtml: "<p>The evening review is the daily practice of Step 10 — an honest end-of-day accounting.</p>", category: "activity", relatedFeatureFlag: "activity.check-ins", iconName: "moon", sortOrder: 2 },
  { ...base, slug: "urge-logging", title: "Urge Logging", summary: "Track urges with intensity, triggers, and outcomes to reveal patterns.", contentHtml: "<p>Logging urges builds self-awareness and reveals patterns over time.</p>", category: "activity", relatedFeatureFlag: "activity.urge-logging", iconName: "flame", sortOrder: 3 },
  { ...base, slug: "journaling", title: "Recovery Journaling", summary: "Process thoughts and emotions through guided or free-form writing.", contentHtml: "<p>Journaling is a cornerstone recovery practice for processing emotions and tracking growth.</p>", category: "activity", relatedFeatureFlag: "activity.journaling", iconName: "book-open", sortOrder: 4 },
  { ...base, slug: "fanos", title: "FANOS Check-In", summary: "A structured framework for honest communication: Feelings, Appreciation, Needs, Ownership, Sobriety.", contentHtml: "<p>FANOS provides a safe structure for sharing with your spouse or accountability partner.</p>", category: "communication", relatedFeatureFlag: "activity.fanos", iconName: "message-circle", sortOrder: 1 },
  { ...base, slug: "fitnap", title: "FITNAP Check-In", summary: "An alternative check-in framework: Feelings, Intimacy, Triggers, Needs, Affirmations, Prayer.", contentHtml: "<p>FITNAP is an alternative to FANOS with explicit discussion of triggers and a spiritual component.</p>", category: "communication", relatedFeatureFlag: "activity.fitnap", iconName: "message-square", sortOrder: 2 },
  { ...base, slug: "pci", title: "Personal Craziness Index", summary: "Track 10 personalized warning behaviors that signal rising vulnerability.", contentHtml: "<p>Created by Patrick Carnes, the PCI measures overall life manageability across behavioral dimensions.</p>", category: "activity", relatedFeatureFlag: "activity.pci", iconName: "activity", sortOrder: 5 },
  { ...base, slug: "sobriety-commitment", title: "Sobriety Commitment", summary: "Declare your daily commitment to sobriety as a recovery anchor.", contentHtml: "<p>The sobriety commitment is a daily declaration that anchors your recovery intention.</p>", category: "activity", relatedFeatureFlag: "activity.sobriety-commitment", iconName: "shield", sortOrder: 6 },
  { ...base, slug: "affirmations", title: "Daily Affirmations", summary: "Scripture-based affirmations to renew your mind and identity.", contentHtml: "<p>Daily affirmations combat the lies of addiction with biblical truth about your identity.</p>", category: "content", relatedFeatureFlag: "activity.affirmations", iconName: "sun", sortOrder: 1 },
  { ...base, slug: "devotionals", title: "Daily Devotionals", summary: "Scripture, reflection, and prayer for your recovery journey.", contentHtml: "<p>Daily devotionals provide scripture-grounded reflection specific to recovery themes.</p>", category: "content", relatedFeatureFlag: "feature.content-resources", iconName: "book", sortOrder: 2 },
  { ...base, slug: "step-work", title: "12-Step Work", summary: "Guided journaling through the 12 Steps of recovery.", contentHtml: "<p>The 12 Steps guide you from admitting powerlessness through spiritual awakening and service.</p>", category: "content", relatedFeatureFlag: "activity.step-work", iconName: "list-ordered", sortOrder: 3 },
  { ...base, slug: "acting-in", title: "Acting In", summary: "Track subtle internalized addiction behaviors that occur within relationships.", contentHtml: "<p>Acting in refers to subtle behaviors like emotional withdrawal, dishonesty by omission, and manipulation.</p>", category: "activity", relatedFeatureFlag: "activity.acting-in", iconName: "eye-off", sortOrder: 7 },
  { ...base, slug: "arousal-template", title: "Arousal Template", summary: "Map the patterns of thoughts, feelings, and situations that fuel compulsive behavior.", contentHtml: "<p>Developed by Patrick Carnes, the arousal template describes your unique constellation of triggers.</p>", category: "tool", relatedFeatureFlag: "feature.arousal-template", iconName: "map", sortOrder: 3 },
  { ...base, slug: "relapse-prevention", title: "Relapse Prevention Plan", summary: "A structured plan of triggers, coping strategies, and emergency contacts.", contentHtml: "<p>Your relapse prevention plan is your personalized defense strategy for high-risk situations.</p>", category: "tool", relatedFeatureFlag: "feature.relapse-prevention", iconName: "shield-check", sortOrder: 4 },
  { ...base, slug: "vision-statement", title: "Vision Statement", summary: "Write the vision for the man you are becoming in recovery.", contentHtml: "<p>Your vision statement describes the life recovery is making possible — grounded and honest.</p>", category: "tool", relatedFeatureFlag: "feature.vision-statement", iconName: "target", sortOrder: 5 },
  { ...base, slug: "mood-tracking", title: "Mood Tracking", summary: "Rate and track your emotional state throughout the day.", contentHtml: "<p>Regular mood tracking builds emotional awareness — a core recovery skill.</p>", category: "activity", relatedFeatureFlag: "activity.mood-tracking", iconName: "smile", sortOrder: 8 },
  { ...base, slug: "gratitude-list", title: "Gratitude List", summary: "Capture what you are grateful for to shift focus from struggle to blessing.", contentHtml: "<p>Gratitude practice rewires the brain away from negativity bias and toward hope.</p>", category: "activity", relatedFeatureFlag: "activity.gratitude", iconName: "heart", sortOrder: 9 },
  { ...base, slug: "prayer", title: "Prayer", summary: "Log your prayer practice and track spiritual engagement.", contentHtml: "<p>Prayer is the lifeline of recovery — your direct communication with God.</p>", category: "activity", relatedFeatureFlag: "activity.prayer", iconName: "hands", sortOrder: 10 },
  { ...base, slug: "meetings", title: "Meeting Attendance", summary: "Track 12-step and recovery meeting attendance.", contentHtml: "<p>Regular meeting attendance is one of the strongest predictors of sustained recovery.</p>", category: "activity", relatedFeatureFlag: "activity.meetings", iconName: "users", sortOrder: 11 },
  { ...base, slug: "exercise", title: "Exercise", summary: "Log physical activity that supports recovery and emotional regulation.", contentHtml: "<p>Exercise releases endorphins, reduces stress, and rebuilds the brain pathways damaged by addiction.</p>", category: "activity", relatedFeatureFlag: "activity.exercise", iconName: "dumbbell", sortOrder: 12 },
  { ...base, slug: "time-journal", title: "Time Journal", summary: "Interval-based check-ins that capture location, emotion, and activity throughout the day.", contentHtml: "<p>The time journal is a structured, interval-based journaling activity for pattern recognition.</p>", category: "activity", relatedFeatureFlag: "activity.time-journal", iconName: "clock", sortOrder: 13 },
  { ...base, slug: "emotional-journal", title: "Emotional Journal", summary: "Quick emotional awareness captures with optional location and selfie.", contentHtml: "<p>The emotional journal is designed for frequent, low-friction emotional awareness throughout the day.</p>", category: "activity", relatedFeatureFlag: "activity.emotional-journal", iconName: "heart-pulse", sortOrder: 14 },
  { ...base, slug: "post-mortem", title: "Post-Mortem Analysis", summary: "Structured reflection after a relapse to learn and prevent recurrence.", contentHtml: "<p>A relapse is not a failure — it is information. The post-mortem helps you learn from what happened.</p>", category: "activity", relatedFeatureFlag: "activity.post-mortem", iconName: "search", sortOrder: 15 },
  { ...base, slug: "sast-r", title: "SAST-R Assessment", summary: "A validated screening tool for assessing sexual addiction patterns.", contentHtml: "<p>The Sexual Addiction Screening Test (Revised) measures behavioral patterns across multiple dimensions.</p>", category: "assessment", relatedFeatureFlag: "activity.sast-r", iconName: "clipboard-check", sortOrder: 1 },
  { ...base, slug: "denial", title: "Denial Assessment", summary: "Identify patterns of denial that block honest self-assessment.", contentHtml: "<p>Denial is the primary defense mechanism of addiction — recognizing it is the first step to freedom.</p>", category: "assessment", relatedFeatureFlag: "activity.denial", iconName: "shield-off", sortOrder: 2 },
  { ...base, slug: "rl-backbone", title: "Backbone", summary: "Build your daily recovery backbone — the non-negotiable practices that sustain freedom.", contentHtml: "<p>Your backbone is the set of daily recovery practices you commit to no matter what.</p>", category: "activity", relatedFeatureFlag: "activity.backbone", iconName: "spine", sortOrder: 16 },
  { ...base, slug: "memory-verse", title: "Memory Verse Review", summary: "Memorize and review scripture verses that anchor your recovery.", contentHtml: "<p>Scripture memorization renews the mind and provides truth to combat addictive thinking.</p>", category: "activity", relatedFeatureFlag: "activity.memory-verse", iconName: "bookmark", sortOrder: 17 },
  { ...base, slug: "nutrition", title: "Nutrition", summary: "Track meals and eating habits that support physical recovery.", contentHtml: "<p>Proper nutrition stabilizes blood sugar, supports brain healing, and reduces vulnerability to triggers.</p>", category: "activity", relatedFeatureFlag: "activity.nutrition", iconName: "apple", sortOrder: 18 },
  { ...base, slug: "book-reading", title: "Book Reading", summary: "Track recovery and spiritual reading progress.", contentHtml: "<p>Reading recovery literature and scripture deepens understanding and reinforces recovery principles.</p>", category: "activity", relatedFeatureFlag: "activity.book-reading", iconName: "book-open-check", sortOrder: 19 }
]);
print("✓ Created 31 feature abouts");

db.affirmation_packs.insertOne({
  ...base, packId: "pack_christian", name: "Christian Affirmations",
  description: "44 biblical affirmations for daily recovery",
  tier: "standard", price: 0, currency: "USD", affirmationCount: 5,
  category: "christian", thumbnailUrl: "", sortOrder: 1
});
print("✓ Created affirmation pack: Christian Affirmations");

db.affirmations.insertMany([
  { ...base, affirmationId: "aff_001", packId: "pack_christian", statement: "I am fearfully and wonderfully made.", scriptureReference: "Psalm 139:14", category: "identity", language: "en", sortOrder: 1 },
  { ...base, affirmationId: "aff_002", packId: "pack_christian", statement: "I can do all things through Christ who strengthens me.", scriptureReference: "Philippians 4:13", category: "strength", language: "en", sortOrder: 2 },
  { ...base, affirmationId: "aff_003", packId: "pack_christian", statement: "The Lord is my shepherd; I shall not want.", scriptureReference: "Psalm 23:1", category: "peace", language: "en", sortOrder: 3 },
  { ...base, affirmationId: "aff_004", packId: "pack_christian", statement: "God is my refuge and strength, an ever-present help in trouble.", scriptureReference: "Psalm 46:1", category: "strength", language: "en", sortOrder: 4 },
  { ...base, affirmationId: "aff_005", packId: "pack_christian", statement: "I am a new creation in Christ; the old has passed away.", scriptureReference: "2 Corinthians 5:17", category: "identity", language: "en", sortOrder: 5 }
]);
print("✓ Created 5 affirmations");

db.devotional_packs.insertOne({
  ...base, packId: "dpack_foundations", name: "Foundations",
  description: "Core devotionals for the recovery journey",
  tier: "standard", price: 0, currency: "USD", devotionalCount: 3,
  category: "core", thumbnailUrl: "", sortOrder: 1
});
print("✓ Created devotional pack: Foundations");

db.devotionals.insertMany([
  { ...base, devotionalId: "dev_001", packId: "dpack_foundations", day: 1, title: "A New Beginning", scripture: "2 Corinthians 5:17", scriptureText: "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!", reflection: "Every day in recovery is a fresh start. God does not define us by our past failures but by His redeeming love.", prayerPrompt: "Lord, help me embrace this new beginning." },
  { ...base, devotionalId: "dev_002", packId: "dpack_foundations", day: 2, title: "Strength for the Journey", scripture: "Isaiah 40:31", scriptureText: "But those who hope in the Lord will renew their strength.", reflection: "Recovery requires daily surrender. When we place our hope in the Lord, He renews us.", prayerPrompt: "Father, renew my strength today as I place my hope in You." },
  { ...base, devotionalId: "dev_003", packId: "dpack_foundations", day: 3, title: "Freedom from Shame", scripture: "Romans 8:1", scriptureText: "Therefore, there is now no condemnation for those who are in Christ Jesus.", reflection: "Shame is the enemy of recovery. God has removed our condemnation through Jesus.", prayerPrompt: "God, free me from the weight of shame and help me walk in Your grace." }
]);
print("✓ Created 3 devotionals");

db.journal_prompts.insertMany([
  { ...base, promptId: "prompt_001", text: "What am I most grateful for today, and what was the hardest part of my day?", category: "daily", tags: [], sortOrder: 1 },
  { ...base, promptId: "prompt_002", text: "What triggers did I encounter today, and how did I respond?", category: "sobriety", tags: ["FASTER", "triggers"], sortOrder: 1 },
  { ...base, promptId: "prompt_003", text: "What emotions am I experiencing right now? Where do I feel them in my body?", category: "emotional", tags: ["FANOS/FITNAP"], sortOrder: 1 },
  { ...base, promptId: "prompt_004", text: "What relationship brought me joy today? What relationship challenged me?", category: "relationships", tags: [], sortOrder: 1 },
  { ...base, promptId: "prompt_005", text: "How did I experience God today? Where did I see His hand at work?", category: "spiritual", tags: ["12-Step"], sortOrder: 1 }
]);
print("✓ Created 5 journal prompts");

db.glossary_terms.insertMany([
  { ...base, termId: "term_faster", term: "FASTER Scale", definition: "A relapse-awareness tool developed by Michael Dye that maps six progressive stages leading to relapse: Forgetting Priorities, Anxiety, Speeding Up, Ticked Off, Exhausted, Relapse.", relatedSlugs: ["faster-scale"], sortOrder: 1 },
  { ...base, termId: "term_fanos", term: "FANOS", definition: "A structured couples check-in framework: Feelings, Affirmations, Needs, Ownership, Sobriety.", relatedSlugs: ["fanos"], sortOrder: 2 },
  { ...base, termId: "term_3circles", term: "3 Circles", definition: "A boundary-setting tool where behaviors are categorized into inner (acting out), middle (warning), and outer (healthy) circles.", relatedSlugs: ["3circles"], sortOrder: 3 },
  { ...base, termId: "term_pci", term: "PCI", definition: "Personal Craziness Index — a self-assessment tool by Patrick Carnes that measures overall life manageability.", relatedSlugs: ["pci"], sortOrder: 4 },
  { ...base, termId: "term_sastr", term: "SAST-R", definition: "Sexual Addiction Screening Test (Revised) — a validated clinical screening instrument for sexual addiction.", relatedSlugs: ["sast-r"], sortOrder: 5 }
]);
print("✓ Created 5 glossary terms");

db.evening_review_questions.insertMany([
  { ...base, questionId: "erq_001", text: "Was I sober today in thought, word, and action?", dimension: "sobriety", sortOrder: 1 },
  { ...base, questionId: "erq_002", text: "Was I fully honest today — no lies, omissions, or secrets?", dimension: "sobriety", sortOrder: 2 },
  { ...base, questionId: "erq_003", text: "What emotions did I experience today? Can I name at least three?", dimension: "emotional", sortOrder: 1 },
  { ...base, questionId: "erq_004", text: "Did I treat the people around me with respect and kindness today?", dimension: "relational", sortOrder: 1 },
  { ...base, questionId: "erq_005", text: "Did I spend time with God today — in prayer, scripture, or quiet listening?", dimension: "spiritual", sortOrder: 1 },
  { ...base, questionId: "erq_006", text: "Did I work my recovery plan today?", dimension: "recovery", sortOrder: 1 },
  { ...base, questionId: "erq_007", text: "Where am I on the FASTER Scale right now, honestly?", dimension: "faster-scale", sortOrder: 1 },
  { ...base, questionId: "erq_008", text: "What is one thing I need to do differently tomorrow?", dimension: "looking-forward", sortOrder: 1 }
]);
print("✓ Created 8 evening review questions");

db.acting_in_behaviors.insertMany([
  { ...base, behaviorId: "aib_001", name: "Blame", description: "", sortOrder: 1 },
  { ...base, behaviorId: "aib_002", name: "Shame", description: "", sortOrder: 2 },
  { ...base, behaviorId: "aib_003", name: "Criticism", description: "", sortOrder: 3 },
  { ...base, behaviorId: "aib_004", name: "Stonewall", description: "", sortOrder: 4 },
  { ...base, behaviorId: "aib_005", name: "Avoid", description: "", sortOrder: 5 },
  { ...base, behaviorId: "aib_006", name: "Hide", description: "", sortOrder: 6 },
  { ...base, behaviorId: "aib_007", name: "Lie", description: "", sortOrder: 7 },
  { ...base, behaviorId: "aib_008", name: "Excuse", description: "", sortOrder: 8 },
  { ...base, behaviorId: "aib_009", name: "Manipulate", description: "", sortOrder: 9 },
  { ...base, behaviorId: "aib_010", name: "Control with Anger", description: "", sortOrder: 10 },
  { ...base, behaviorId: "aib_011", name: "Passivity", description: "", sortOrder: 11 },
  { ...base, behaviorId: "aib_012", name: "Humor", description: "", sortOrder: 12 },
  { ...base, behaviorId: "aib_013", name: "Placating", description: "", sortOrder: 13 },
  { ...base, behaviorId: "aib_014", name: "Withhold Love/Sex", description: "", sortOrder: 14 },
  { ...base, behaviorId: "aib_015", name: "HyperSpiritualize", description: "", sortOrder: 15 }
]);
print("✓ Created 15 acting-in behaviors");

db.needs.insertMany([
  { ...base, needId: "need_001", name: "Acceptance", description: "", sortOrder: 1 },
  { ...base, needId: "need_002", name: "Affirmation", description: "", sortOrder: 2 },
  { ...base, needId: "need_003", name: "Agency", description: "", sortOrder: 3 },
  { ...base, needId: "need_004", name: "Belonging", description: "", sortOrder: 4 },
  { ...base, needId: "need_005", name: "Comfort", description: "", sortOrder: 5 },
  { ...base, needId: "need_006", name: "Compassion", description: "", sortOrder: 6 },
  { ...base, needId: "need_007", name: "Connection", description: "", sortOrder: 7 },
  { ...base, needId: "need_008", name: "Empathy", description: "", sortOrder: 8 },
  { ...base, needId: "need_009", name: "Encouragement", description: "", sortOrder: 9 },
  { ...base, needId: "need_010", name: "Forgiveness", description: "", sortOrder: 10 },
  { ...base, needId: "need_011", name: "Grace", description: "", sortOrder: 11 },
  { ...base, needId: "need_012", name: "Hope", description: "", sortOrder: 12 },
  { ...base, needId: "need_013", name: "Love", description: "", sortOrder: 13 },
  { ...base, needId: "need_014", name: "Peace", description: "", sortOrder: 14 },
  { ...base, needId: "need_015", name: "Reassurance", description: "", sortOrder: 15 },
  { ...base, needId: "need_016", name: "Respect", description: "", sortOrder: 16 },
  { ...base, needId: "need_017", name: "Safety", description: "", sortOrder: 17 },
  { ...base, needId: "need_018", name: "Security", description: "", sortOrder: 18 },
  { ...base, needId: "need_019", name: "Understanding", description: "", sortOrder: 19 },
  { ...base, needId: "need_020", name: "Validation", description: "", sortOrder: 20 }
]);
print("✓ Created 20 needs");

db.sobriety_reset_messages.insertMany([
  { ...base, messageId: "srm_001", text: "His mercies are new this morning — and so are you.", scriptureReference: "Lamentations 3:22-23", sortOrder: 1 },
  { ...base, messageId: "srm_002", text: "A reset is not the end of your story. It is a turning point. God is still writing.", scriptureReference: "", sortOrder: 2 },
  { ...base, messageId: "srm_003", text: "You are not defined by your worst moment. You are defined by the One who calls you His own.", scriptureReference: "", sortOrder: 3 },
  { ...base, messageId: "srm_004", text: "The righteous may fall seven times but still get up.", scriptureReference: "Proverbs 24:16", sortOrder: 4 },
  { ...base, messageId: "srm_005", text: "Right now, grace is louder than shame.", scriptureReference: "", sortOrder: 5 },
  { ...base, messageId: "srm_006", text: "God did not flinch. He knew this day would come, and He is still here, still for you, still working.", scriptureReference: "", sortOrder: 6 },
  { ...base, messageId: "srm_007", text: "There is therefore now no condemnation for those who are in Christ Jesus.", scriptureReference: "Romans 8:1", sortOrder: 7 },
  { ...base, messageId: "srm_008", text: "You had the courage to be honest. That matters more than you know.", scriptureReference: "", sortOrder: 8 },
  { ...base, messageId: "srm_009", text: "This reset does not erase the growth that came before it. Every sober day still counted.", scriptureReference: "", sortOrder: 9 },
  { ...base, messageId: "srm_010", text: "He heals the brokenhearted and binds up their wounds.", scriptureReference: "Psalm 147:3", sortOrder: 10 }
]);
print("✓ Created 10 sobriety reset messages");

db.themes.insertMany([
  { ...base, themeId: "theme_light", name: "Light", description: "Clean, bright default theme", tier: "standard", price: 0, currency: "USD", colors: { primary: "#1E3A5F", secondary: "#4A90D9", accent: "#F5A623", background: "#FFFFFF", surface: "#F5F5F5", text: "#1A1A1A", textSecondary: "#666666" }, previewUrl: "", sortOrder: 1 },
  { ...base, themeId: "theme_dark", name: "Dark", description: "Easy-on-the-eyes dark theme", tier: "standard", price: 0, currency: "USD", colors: { primary: "#4A90D9", secondary: "#1E3A5F", accent: "#F5A623", background: "#121212", surface: "#1E1E1E", text: "#E0E0E0", textSecondary: "#A0A0A0" }, previewUrl: "", sortOrder: 2 },
  { ...base, themeId: "theme_midnight", name: "Midnight", description: "Deep navy dark theme", tier: "standard", price: 0, currency: "USD", colors: { primary: "#1A1A2E", secondary: "#16213E", accent: "#0F3460", background: "#0A0A1A", surface: "#1A1A2E", text: "#E0E0E0", textSecondary: "#A0A0A0" }, previewUrl: "", sortOrder: 3 }
]);
print("✓ Created 3 themes");

print("");
print("=============================================================================");
print("✅ CONTENT DATABASE SEED COMPLETE");
print("=============================================================================");
print("");
print("Collections seeded:");
print("  - Feature Abouts: 31");
print("  - Affirmation Packs: 1");
print("  - Affirmations: 5");
print("  - Devotional Packs: 1");
print("  - Devotionals: 3");
print("  - Journal Prompts: 5");
print("  - Glossary Terms: 5");
print("  - Evening Review Questions: 8");
print("  - Acting-In Behaviors: 15");
print("  - Needs: 20");
print("  - Sobriety Reset Messages: 10");
print("  - Themes: 3");
'

echo ""
echo "Content database seed complete!"
