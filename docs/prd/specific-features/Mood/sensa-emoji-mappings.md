# Sensa Emoji Mappings

All emotion-to-emoji mappings used across the RegalRecovery iOS app. Every mapping is defined in `SensaEmoji.swift` and rendered using SVG assets from `Assets.xcassets/SensaEmoji/`.

## Emotion Hierarchy

The app uses a three-tier emotion model based on established affective science (Shaver et al., Parrott's emotion wheel):

| Level | Description | Example | Emoji Coverage |
|-------|-------------|---------|----------------|
| **Primary** | Core universal emotions (6) | Happy, Sad, Angry | Full -- every primary has a SensaEmoji |
| **Secondary** | Nuanced sub-emotions under each primary | Joyful, Lonely, Frustrated | Full -- all 30 secondary emotions have SensaEmojis |
| **Tertiary** | Granular feelings (from MoodPrimary model) | Bliss, Agony, Wrath | None -- tertiary emotions do not have SensaEmoji mappings |

Two separate emotion models exist in the codebase:

- **`PrimaryEmotion`** (Emotional Journal) -- 6 primary + 30 secondary (flat strings). Both levels have SensaEmoji mappings.
- **`MoodPrimary`** (Layered Mood Check-In) -- 6 primary + 22 secondary (`SecondaryEmotion` objects) + ~132 tertiary (string arrays). Only primary level has SensaEmoji mappings; secondary/tertiary use text Unicode emoji.

## Summary

| Metric | Count |
|--------|-------|
| Total mappings | 68 |
| Unique emojis used | 29 |
| Total emojis available | 31 |
| Unmapped emojis | 2 |

---

## Asset Catalog

All 31 Sensa Emoji assets:

| Case | Asset Name |
|------|-----------|
| beaming | Beaming face with smiling eyes |
| smilingEyes | Smiling face with smiling eyes |
| grinning | Grinning face |
| slightlySmiling | Slightly smiling face |
| relieved | Relieved face |
| partying | Partying face |
| heartEyes | Smiling face with heart-eyes |
| starStruck | Star-struck |
| crying | Crying face |
| loudlyCrying | Loudly crying face |
| pensive | Pensive face |
| disappointed | Dissapointed face |
| angry | Angry face |
| pouting | Pouting face |
| steamFromNose | Face with steam from nose |
| fearful | Fearful face |
| anxious | Anxious face with sweat |
| worried | Worried face |
| nauseated | Nauseated face |
| confounded | Confounded face |
| astonished | Astonished face |
| hushed | Hushed face |
| explodingHead | Exploding head |
| neutral | Neutral face |
| expressionless | Expressioless face |
| slightlyFrowning | Slightly frowning face |
| frowning | Frowning face |
| downcastSweat | Downcast face with sweat |
| hugging | Hugging face |
| woozy | Woozy face |
| thinking | Thinking face |

---

## Primary Emotions -- Emotional Journal

> **Hierarchy level: PRIMARY**

**Method:** `SensaEmoji.forPrimaryEmotion(_:)`
**Used in:** EmotionalJournalView -- feelings wheel circles
**Source enum:** `PrimaryEmotion` (Types.swift)

| Primary Emotion | Emoji | Asset |
|-----------------|-------|-------|
| Happy | beaming | Beaming face with smiling eyes |
| Sad | crying | Crying face |
| Angry | angry | Angry face |
| Fearful | fearful | Fearful face |
| Disgusted | nauseated | Nauseated face |
| Surprised | astonished | Astonished face |

## Secondary Emotions -- Emotional Journal

> **Hierarchy level: SECONDARY** (children of Primary Emotions above)

**Method:** `SensaEmoji.forSecondaryEmotion(_:)`
**Used in:** EmotionalJournalView -- specific feeling chips
**Source:** `PrimaryEmotion.secondaryEmotions` (Types.swift)

### Happy (secondary)

| Secondary Feeling | Emoji | Asset |
|-------------------|-------|-------|
| Joyful | partying | Partying face |
| Grateful | heartEyes | Smiling face with heart-eyes |
| Content | smilingEyes | Smiling face with smiling eyes |
| Peaceful | relieved | Relieved face |
| Hopeful | slightlySmiling | Slightly smiling face |
| Proud | starStruck | Star-struck |

### Sad (secondary)

| Secondary Feeling | Emoji | Asset |
|-------------------|-------|-------|
| Lonely | pensive | Pensive face |
| Grieving | loudlyCrying | Loudly crying face |
| Disappointed | disappointed | Dissapointed face |
| Hopeless | downcastSweat | Downcast face with sweat |
| Ashamed | frowning | Frowning face |
| Empty | expressionless | Expressioless face |

### Angry (secondary)

| Secondary Feeling | Emoji | Asset |
|-------------------|-------|-------|
| Frustrated | steamFromNose | Face with steam from nose |
| Resentful | pouting | Pouting face |
| Irritated | angry | Angry face |
| Bitter | confounded | Confounded face |
| Jealous | slightlyFrowning | Slightly frowning face |
| Betrayed | pouting | Pouting face |

### Fearful (secondary)

| Secondary Feeling | Emoji | Asset |
|-------------------|-------|-------|
| Anxious | anxious | Anxious face with sweat |
| Insecure | worried | Worried face |
| Overwhelmed | downcastSweat | Downcast face with sweat |
| Vulnerable | slightlyFrowning | Slightly frowning face |
| Panicked | fearful | Fearful face |
| Worried | worried | Worried face |

### Disgusted (secondary)

| Secondary Feeling | Emoji | Asset |
|-------------------|-------|-------|
| Contemptuous | confounded | Confounded face |
| Repulsed | nauseated | Nauseated face |
| Self-loathing | frowning | Frowning face |
| Judgmental | neutral | Neutral face |

### Surprised (secondary)

| Secondary Feeling | Emoji | Asset |
|-------------------|-------|-------|
| Shocked | explodingHead | Exploding head |
| Confused | thinking | Thinking face |
| Amazed | astonished | Astonished face |
| Startled | hushed | Hushed face |

---

## Mood Primary -- Layered Check-In

> **Hierarchy level: PRIMARY** (alternate primary model for Mood Rating)

**Method:** `SensaEmoji.forMoodPrimary(_:)`
**Used in:** MoodRatingView layered check-in
**Source enum:** `MoodPrimary` (Types.swift)

This is a separate primary emotion model with its own secondary/tertiary hierarchy.
Secondary and tertiary levels use text Unicode emoji, not SensaEmoji.

| Primary Mood | Emoji | Asset |
|--------------|-------|-------|
| Love | heartEyes | Smiling face with heart-eyes |
| Joy | beaming | Beaming face with smiling eyes |
| Surprise | astonished | Astonished face |
| Anger | angry | Angry face |
| Sadness | crying | Crying face |
| Fear | fearful | Fearful face |

### MoodPrimary Secondary Emotions (no SensaEmoji -- uses Unicode emoji)

> **Hierarchy level: SECONDARY** under MoodPrimary

These are listed for completeness. They use text emoji, not SensaEmoji assets.

| Primary | Secondary | Unicode | Tertiary Count |
|---------|-----------|---------|----------------|
| Love | Affection | n/a | 8 |
| Love | Lust | n/a | 3 |
| Love | Longing | n/a | 1 |
| Joy | Cheerfulness | n/a | 15 |
| Joy | Zest | n/a | 5 |
| Joy | Contentment | n/a | 2 |
| Joy | Pride | n/a | 2 |
| Joy | Optimism | n/a | 3 |
| Joy | Enthrallment | n/a | 2 |
| Joy | Relief | n/a | 1 |
| Surprise | Surprise | n/a | 2 |
| Anger | Irritation | n/a | 5 |
| Anger | Exasperation | n/a | 2 |
| Anger | Rage | n/a | 13 |
| Anger | Disgust | n/a | 3 |
| Anger | Envy | n/a | 2 |
| Anger | Torment | n/a | 1 |
| Sadness | Suffering | n/a | 3 |
| Sadness | Sadness | n/a | 10 |
| Sadness | Disappointment | n/a | 3 |
| Sadness | Shame | n/a | 4 |
| Sadness | Neglect | n/a | 11 |
| Sadness | Sympathy | n/a | 2 |
| Fear | Horror | n/a | 8 |
| Fear | Nervousness | n/a | 8 |

> **Hierarchy level: TERTIARY** -- ~132 tertiary emotions exist under the above secondaries. None have SensaEmoji mappings. They appear as plain text labels in the Mood Check-In flow.

---

## Mood Score 1-10

> **Hierarchy level: N/A** (numeric scale, not emotion hierarchy)

**Method:** `SensaEmoji.forMoodScore10(_:)`
**Used in:** MoodRatingView

| Score Range | Emoji | Asset |
|-------------|-------|-------|
| 1-2 | loudlyCrying | Loudly crying face |
| 3-4 | worried | Worried face |
| 5-6 | neutral | Neutral face |
| 7-8 | smilingEyes | Smiling face with smiling eyes |
| 9-10 | beaming | Beaming face with smiling eyes |

## FASTER Mood 1-5

> **Hierarchy level: N/A** (numeric scale)

**Method:** `SensaEmoji.forFASTERMood(_:)`
**Used in:** FASTERScaleView, FASTERCheckInFlowView

| Score | Label | Emoji | Asset |
|-------|-------|-------|-------|
| 1 | Great | beaming | Beaming face with smiling eyes |
| 2 | Good | slightlySmiling | Slightly smiling face |
| 3 | Okay | neutral | Neutral face |
| 4 | Rough | worried | Worried face |
| 5 | Bad | loudlyCrying | Loudly crying face |

## Emotion Categories -- Time Journal

> **Hierarchy level: PRIMARY** (flat category list, no sub-levels)

**Method:** `SensaEmoji.forEmotionCategory(_:)`
**Used in:** TimeJournalDailyView

| Category | Emoji | Asset |
|----------|-------|-------|
| Happy | beaming | Beaming face with smiling eyes |
| Sad | crying | Crying face |
| Angry | angry | Angry face |
| Fearful | fearful | Fearful face |
| Shame | frowning | Frowning face |
| The Three I's | downcastSweat | Downcast face with sweat |
| Numb | expressionless | Expressioless face |
| Surprise | astonished | Astonished face |
| Connected | hugging | Hugging face |

## Gratitude Mood 1-5

> **Hierarchy level: N/A** (numeric scale)

**Method:** `SensaEmoji.forGratitudeMood(_:)`
**Used in:** GratitudeTabView

| Score | Label | Emoji | Asset |
|-------|-------|-------|-------|
| 1 | Low | loudlyCrying | Loudly crying face |
| 2 | Below Average | slightlyFrowning | Slightly frowning face |
| 3 | Average | neutral | Neutral face |
| 4 | Good | smilingEyes | Smiling face with smiling eyes |
| 5 | Great | starStruck | Star-struck |

---

## Unmapped Emojis

Emojis in the asset catalog not currently used in any mapping:

| Case | Asset Name |
|------|-----------|
| grinning | Grinning face |
| woozy | Woozy face |

## Coverage Gaps

| Gap | Detail |
|-----|--------|
| MoodPrimary secondary emotions (22) | Use Unicode emoji, not SensaEmoji assets |
| MoodPrimary tertiary emotions (~132) | Plain text labels, no emoji of any kind |
| Tertiary emotions in Emotional Journal | Not modeled -- PrimaryEmotion only has two levels |
