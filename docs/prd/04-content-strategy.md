# Regal Recovery — Content Strategy
**Part 4 of 4** | See also: [Strategic PRD](01-strategic-prd.md) · [Feature Specifications](02-feature-specifications.md) · [Technical Architecture](03-technical-architecture.md)

---

## Table of Contents

1. [Content Tiers & Monetization Model](#1-content-tiers--monetization-model)
2. [Affirmation Packs](#2-affirmation-packs)
3. [Prayer Content](#3-prayer-content)
4. [Devotionals](#4-devotionals)
5. [Memory Verse Packs](#5-memory-verse-packs)
6. [Recovery Stories](#6-recovery-stories)
7. [Book Logging & Recommended Reading](#7-book-logging--recommended-reading)
8. [Podcasts](#8-podcasts)
9. [External Links](#9-external-links)
10. [Music & Spotify Playlists](#10-music--spotify-playlists)
11. [Localization](#11-localization)
12. [Content Licensing Status](#12-content-licensing-status)

---

## 1. Content Tiers & Monetization Model

The Content/Resources System (Feature 4, P1) provides all content through a freemium model where premium content is **unlocked forever when purchased** — no recurring charges for content packs.

### Subscription Tiers

| Tier | Billing | Notes |
|---|---|---|
| Free Trial | Variable length (7-day organic, 14-day partner referral, 30-day therapist referral) | Full access during trial |
| Premium | Monthly / Annual | Content packs, advanced features |
| Premium+ | Monthly / Annual | Everything in Premium + content filtering, accountability tools |

Target conversion: Free to Premium 5% (stretch 8%), Premium+ 2%. ARPU: $1.50/month. LTV: $90 per paying user.

### Freemium Content (Available to All Users)

- Basic Commitments Pack
- Basic Affirmations Pack (50+ affirmations across 5 categories)
- Basic Devotionals (30-day rotation)
- Basic Prayers Pack (Step Prayers, Serenity Prayer, Lord's Prayer, recovery-focused prayers, daily morning/evening prayers)
- Partner Content (from counselors and organizations)
- Meeting Finder
- Crisis Lines
- Feelings Wheel
- Free Courses
- Curated Music Playlists (via Spotify)
- Video Library (10 free videos)
- 3 Freemium Memory Verse Packs (Identity in Christ, Temptation & Strength, Freedom & Recovery)

### Premium Content (Unlocked Forever When Purchased)

- Additional Commitments Packs
- Additional Affirmation Packs (themed)
- Premium Partner Content
- Premium Devotionals (365-day series)
- Premium Prayer Packs (themed collections)
- Premium Memory Verse Packs (6 packs)
- Premium books available for in-app purchase

### Counselor/Therapist Content Model

- Counselors and partner organizations can publish both freemium and premium content through the Content/Resources System
- Freemium partner content available to all users
- Premium partner content available to users who purchase the relevant pack
- Revenue share agreements with partnered authors and organizations
- Therapist portal is free; revenue comes from client subscriptions
- Therapist referral program: therapists who refer 10+ active paid users receive free personal access to all premium content

---

## 2. Affirmation Packs

**Priority:** P0 (Must-Have)

### Description

Scripture-based affirmations library (50+) with daily delivery, custom creation, and on-demand access.

### Affirmation Structure

Each affirmation includes:
- First-person statement (present tense)
- Scripture reference
- Optional expansion text
- Optional prayer

### Affirmation Packs

| Tier | Pack | Details |
|---|---|---|
| Freemium | Basic Affirmations Pack | 50+ affirmations across 5 categories |
| Premium | Additional themed packs | Unlocked forever when purchased |

### Selection Modes

1. **Individually Chosen** — Manual selection from owned packs
2. **Random Automatic** — System randomly selects from owned packs
3. **Package Mode** — Two sub-modes:
   - **Permanent Package** — Fixed sequence
   - **Day-of-Week Package** — Different affirmations assigned to each day of the week

### Custom Affirmation Creation

Users can create their own affirmations with:
- Statement text
- Scripture reference
- Category/tag
- Display schedule

### Rotation Logic

Weighted algorithm:
- Triggers: 40%
- Favorites: 30%
- Under-served categories: 20%
- Random: 10%

Contextual triggers (e.g., completing an urge log) always override the current rotation mode and deliver a trigger-relevant affirmation.

### Delivery

- Daily push notification at scheduled time
- Integrated into morning flow
- Post-urge log delivery
- On-demand access from the library

---

## 3. Prayer Content

**Priority:** P1

### Prayer Structure

Each prayer in the library includes:
- **Title** — Brief, descriptive name (e.g., "Prayer for Strength Against Temptation")
- **Body** — Full prayer text, written in first person where appropriate
- **Topic tags** — One or more topics for browsing and search
- **Source attribution** — Author name, book/resource title, or "Traditional" / "App Original"
- **Scripture connection** (optional) — Associated verse(s) displayed alongside the prayer

### Freemium Prayers

Available to all users at no cost:

- **Step Prayers** — One prayer for each of the 12 steps, aligned with the spiritual intent of each step
- **Serenity Prayer** — Full version
- **Lord's Prayer** — With optional recovery-focused reflection notes
- **Recovery-Focused Prayers** — Prayers for sobriety, freedom from shame, courage to be honest, surrender, healing from past harm
- **Daily Morning Prayer** — Prayer to start the day with intention and surrender
- **Daily Evening Prayer** — Prayer to close the day with gratitude and reflection

### Premium Prayer Packs (Unlocked Forever When Purchased)

| Pack | Description |
|---|---|
| Temptation & Urges | Prayers for acute temptation, urge surfing, fleeing lust, spiritual warfare |
| Shame & Identity | Prayers for freedom from shame, receiving God's love, reclaiming identity in Christ |
| Marriage Restoration | Prayers for rebuilding trust, healing betrayal wounds, reconciliation |
| Gratitude & Praise | Prayers of thanksgiving, worship, awe, celebration of God's faithfulness |
| Forgiveness | Prayers for forgiving others, forgiving self, receiving God's forgiveness, releasing resentment |
| Fear & Anxiety | Prayers for peace, courage, trust, surrender of control |
| Grief & Loss | Prayers for processing loss (relationships, innocence, time, identity) |
| Prayers from Christian Recovery Authors | Curated prayers from partnered authors and organizations (revenue share) |
| Partner Prayer Packs | Prayers from counselor and partner organization content |

### Library Features

- **Today's Prayer** — Featured prayer at top (rotates daily from owned packs)
- **My Favorites** — Horizontal scroll of favorited prayers
- **My Personal Prayers** — User-written prayers
- **Browse by Topic** — Filter by topic tags (temptation, shame, marriage, gratitude, etc.)
- **Browse by Pack** — View all prayers within a specific pack
- **Browse by Step** — Quick access to step prayers (1-12)
- **Search** — Full-text search across prayer titles and body text
- **Locked content** — Premium prayers shown with lock icon and "Unlock" CTA

### Full-Screen Prayer Mode

- Clean, distraction-free reading view (large serif typography 22pt+, calming background)
- Text-to-speech audio playback with adjustable speed
- Optional silent prayer timer with gentle chime
- Post-prayer prompt to log the session

### Accessibility & Localization

- Text-to-speech for all library and personal prayers
- Dynamic font sizing
- Scripture translations follow user's selected Bible translation (NIV, ESV, NLT, KJV for English; RVR1960, NVI for Spanish)
- All freemium prayers available in English and Spanish at launch
- Premium prayer pack translation follows Content Localization Strategy

---

## 4. Devotionals

**Priority:** P1

### Devotional Structure

Each devotional includes:
- **Title** — Brief, evocative title for the day's reading
- **Scripture passage** — Primary verse(s) in full, with translation noted (NIV default; RVR1960/NVI for Spanish)
- **Reading** — 300-600 word reflection connecting scripture to recovery (warm, pastoral tone)
- **Recovery connection** — 1-2 sentences linking the devotional theme to a practical recovery principle
- **Reflection question** — A single thought-provoking question
- **Prayer** — Short closing prayer (50-100 words)
- **Author attribution** — Name and brief bio (when applicable)

### Content Tiers

#### Freemium — Basic Devotionals

- 30-day rotation of daily devotionals included at no cost
- Topics cover core recovery themes: surrender, identity in Christ, freedom from shame, trusting God's plan, daily strength, forgiveness, hope
- Each devotional is self-contained (start on any day)
- Rotation resets after 30 days; same devotionals cycle until user upgrades or new free content is added

#### Premium — Extended Devotionals (Unlocked Forever When Purchased)

- 365-day devotional series by prominent Christian recovery authors
- Structured as a year-long journey with progressive depth and themes
- Multiple series available (each purchased independently):
  - Recovery-focused series (addiction, temptation, relapse prevention, restoration)
  - Marriage and trust rebuilding series
  - Identity and shame series
  - General spiritual growth series
- New series added over time through content partnerships

#### Partner/Counselor Devotionals

- Counselors and partner organizations publish through the Content/Resources System
- Freemium partner devotionals available to all users
- Premium partner devotionals require purchase of the relevant pack

### Reading Plans

- **Freemium:** 30-day rotation (auto-assigned, restarts after completion)
- **Premium series:** User selects a series and progresses sequentially (Day 1, 2, etc.)
  - Missed days: devotional waits for user — no auto-advance; user can manually skip or catch up
  - Multiple series: one active at a time; switching pauses the current series
- **Custom plan (future):** User selects specific devotionals for a personal reading plan

### Devotional Library

- Today's Devotional (featured at top)
- My Favorites
- My History (reverse chronological with responses)
- Browse by Series (premium), Topic, Author
- Search (full-text across titles, scripture references, and body text)
- Locked content with purchase CTA

### Accessibility & Localization

- Text-to-speech for full devotional playback
- Dynamic font sizing
- Scripture translations: NIV (English default), ESV, NLT, KJV selectable; RVR1960, NVI for Spanish
- All freemium devotionals available in English and Spanish at launch
- Premium devotional translation follows Content Localization Strategy

---

## 5. Memory Verse Packs

**Priority:** P1

### Description

Structured scripture memorization system with verse packs, spaced repetition (modified Leitner system), and interactive quizzing. Each pack contains 10-15 curated verses organized by recovery-relevant themes.

### Freemium Packs

| Pack | Theme | Sample Verses |
|---|---|---|
| Identity in Christ | Who God says I am | 2 Cor 5:17, Eph 2:10, Rom 8:1, Gal 2:20, 1 Pet 2:9 |
| Temptation & Strength | Standing firm when tempted | 1 Cor 10:13, James 4:7, Ps 119:11, Rom 6:14, Eph 6:10-11 |
| Freedom & Recovery | Breaking chains | John 8:36, Gal 5:1, Is 61:1, Rom 8:2, 2 Cor 3:17 |

### Premium Packs (Unlocked Forever When Purchased)

| Pack | Theme | Sample Verses |
|---|---|---|
| Shame & Forgiveness | Freedom from shame | Ps 34:5, Rom 8:1, Is 43:25, 1 John 1:9, Heb 10:17 |
| Marriage & Restoration | Rebuilding trust and intimacy | Eph 5:25, 1 Cor 13:4-7, Col 3:19, Prov 5:18-19 |
| Anxiety & Peace | Calming fear and worry | Phil 4:6-7, Is 26:3, Ps 46:10, Matt 6:34, John 14:27 |
| Purity & Holiness | Living set apart | Ps 51:10, Matt 5:8, 1 Thess 4:3-4, Phil 4:8, 2 Tim 2:22 |
| Hope & Perseverance | Enduring through recovery | Jer 29:11, Rom 5:3-5, Is 40:31, Heb 12:1-2, James 1:2-4 |
| Surrender & Trust | Letting go of control | Prov 3:5-6, Ps 37:5, Matt 11:28-30, Rom 12:1-2 |

### Custom Verses

Users can add any verse to their personal memory list. Custom verses appear in "My Verses" alongside pack verses. User enters the reference; app auto-retrieves the verse text via Bible API in the user's preferred translation.

### Bible Translation Support

- Verses displayed in the user's preferred Bible version (set in Profile > Faith Settings)
- **English:** NIV, ESV, NLT, KJV, NASB, NKJV, CSB, The Message
- **Spanish:** RVR1960, NVI, DHH, LBLA
- **Catholic Spanish:** Biblia Latinoamericana, Biblia de Jerusalen
- "Compare translations" feature available for any verse
- Translation preference synced across all app features

### Memorization System (Spaced Repetition)

Modified Leitner system with 5 boxes:

| Box | Level | Review Frequency |
|---|---|---|
| 1 | New | Daily |
| 2 | Learning | Every 2 days |
| 3 | Reviewing | Every 4 days |
| 4 | Familiar | Weekly |
| 5 | Memorized | Monthly (maintenance) |

Correct quiz answer advances to next box; incorrect sends back to Box 1.

### Quizzing Modes

1. **Fill-in-the-Blank** — Key words removed (2-5 blanks); difficulty adapts based on learning progress
2. **Reference Recall** — Verse text displayed; user identifies book, chapter, verse (multiple choice)
3. **First Letter Prompts** — Only first letter of each word shown; user recites from memory
4. **Audio Recitation** — User records themselves; playback alongside correct text for comparison
5. **Verse of the Day Challenge** — Daily featured verse; timed recall challenge (under 30 seconds)

---

## 6. Recovery Stories

**Priority:** P2

### Content Pipeline

- **Seed content:** Commission 20-30 stories from recovery community leaders, ministry partners, and willing early users before launch
- **Ongoing:** User submissions from users with 90+ days of sobriety
- **Featured partnerships:** Invite prominent Christian recovery voices to contribute
- **Spanish language:** Actively recruit Spanish-speaking story submissions; translate top-performing English stories with cultural adaptation

### Submission Format

Guided structure with word limits:
- My Addiction (categories + free text)
- My Rock Bottom (500 words max)
- My Recovery Journey (1000 words max)
- What Helped Most (200 words max)
- My Faith in Recovery (optional, 500 words max)
- My Message to You (200 words max)

All stories published under randomly generated pseudonyms. Voice recording option available (transcribed for text, audio available for playback).

### Browsing Filters

Addiction type, gender, recovery stage, marital status, faith tradition, language (English, Spanish). "Stories Like Mine" auto-filters based on user profile.

---

## 7. Book Logging & Recommended Reading

**Priority:** P2

### Curated Recommendations by Category

Recommendations personalized based on books already read, recovery stage, addiction type, gender, and faith tradition.

#### Foundational Recovery (Start Here)

- *Out of the Shadows* — Patrick Carnes
- *Unwanted* — Jay Stringer
- *Facing the Shadow* — Patrick Carnes
- *Every Man's Battle* (Revised) — Stephen Arterburn & Fred Stoeker
- *Surfing for God* — Michael John Cusick
- *Finally Free* — Heath Lambert

#### Deeper Recovery Work

- *Don't Call It Love* — Patrick Carnes
- *Healing the Wounds of Sexual Addiction* — Mark Laaser
- *The Body Keeps the Score* — Bessel van der Kolk
- *Contrary to Love* — Patrick Carnes
- *In the Shadows of the Net* — Patrick Carnes
- *Wired for Intimacy* — William Struthers

#### 12-Step & Program Literature

- *Sexaholics Anonymous White Book* — SA
- *Sex Addicts Anonymous Green Book* — SAA
- *Alcoholics Anonymous Big Book* — AA
- *Celebrate Recovery Participant's Guides* — John Baker (8-guide series)
- *A Gentle Path through the Twelve Steps* — Patrick Carnes

#### Faith-Focused Recovery

- *Samson and the Pirate Monks* — Nate Larkin
- *The Purity Principle* — Randy Alcorn
- *Closing the Window* — Tim Chester
- *At the Altar of Sexual Idolatry* — Steve Gallagher
- *L.I.F.E. Guide for Men* — Mark Laaser

#### For Women

- *No Stones* — Marnie Ferree
- *She Has a Name* — Magdalene Hope
- *Worthy of Her Trust* — Jason Martinkus & Stephen Arterburn
- *Beggar's Daughter* — Jessica Harris

#### For Spouses/Partners

- *Beyond Betrayal* — Stephanie Carnes
- *Your Sexually Addicted Spouse* — Barbara Steffens & Marsha Means
- *Shattered Vows* — Debra Laaser
- *Mending a Shattered Heart* — Stefanie Carnes
- *Intimate Deception* — Sheri Keffer

#### For Couples

- *Open Hearts* — Patrick Carnes, Debra Laaser, Mark Laaser
- *Love You, Hate the Porn* — Mark Chamberlain
- *Worthy of Her Trust* — Stephen Arterburn & Jason Martinkus

#### Neuroscience & Understanding Addiction

- *Your Brain on Porn* — Gary Wilson
- *The Porn Myth* — Matt Fradd
- *Fortify* — Fight the New Drug

#### Parenting & Prevention

- *Good Pictures Bad Pictures* — Kristen Jenson (ages 7+)
- *Good Pictures Bad Pictures Jr.* — Kristen Jenson (ages 3-6)
- *Talking to Your Kids About Sex* — Mark Laaser

#### Spanish-Language Editions

- *Fuera de las Sombras* — Patrick Carnes (Out of the Shadows)
- *Cada Batalla del Hombre Joven* — Stephen Arterburn (Every Young Man's Battle)
- *Cada Batalla del Hombre* — Stephen Arterburn & Fred Stoeker (Every Man's Battle)

#### Catholic-Specific

- *The Porn Myth* — Matt Fradd
- *Delivered* — Matt Fradd
- *Theology of the Body for Beginners* — Christopher West
- *Love & Responsibility* — Karol Wojtyla (John Paul II)

### Book Entry Details

Each book entry in the app includes: title, author, brief editorial description (2-3 sentences on why it matters for recovery), applicable tags (stage, topic, gender, role, faith tradition), Amazon/Bookshop.org affiliate link (potential revenue), and "Add to My Bookshelf" button.

### Counselor/Sponsor Integration

- Therapists can assign specific books via the Therapist Portal
- Sponsors can see reading progress and notes (with permission)
- Chapter notes tagged "Discuss with sponsor" or "Discuss with therapist" appear highlighted in respective dashboards

---

## 8. Podcasts

**Priority:** P1

### Description

A curated directory of recovery-related podcasts with deep links to Apple Podcasts and Spotify. Not an in-app player — the app serves as a discovery and launching point.

### Curated Podcast Directory

#### Recovery-Focused

- Pure Desire Podcast (Pure Desire Ministries) — Christian sex addiction recovery
- Porn Free Radio (Matt Dobschuetz) — Practical strategies for quitting pornography
- The Freedom Fight Podcast — Gospel-centered sexual integrity
- Recovered Man (Tim Earp) — Christian men's recovery
- The Betrayed, The Addicted, The Expert (APSATS) — Three perspectives on sex addiction
- Helping Couples Heal (Marnie Breecker & Duane Osterlind) — Couples recovery from betrayal trauma
- Hope Restored (AACC) — Faith-based recovery stories

#### Faith & Recovery Adjacent

- Celebrate Recovery Podcast — Broad Christian recovery
- The Place We Find Ourselves (Adam Young) — Trauma, attachment, and faith
- Theology in the Raw (Preston Sprinkle) — Honest conversations about sexuality and faith
- The Rise (Conquer Series / SoulRefiner) — Men's purity and freedom

#### Mental Health & Wellness

- The Huberman Lab Podcast (Andrew Huberman) — Neuroscience of addiction, habits, sleep
- The Liturgists Podcast — Faith deconstruction and reconstruction
- Therapy Chat (Laura Reagan) — Trauma and mental health education

#### For Partners/Spouses

- Beyond Betrayal Podcast — Resources for betrayed partners
- Bloom for Women Podcast — Betrayal trauma healing

### Browse Categories

Recovery, Faith, Mental Health, Partners, Spanish Language

### Features

- Deep links to Apple Podcasts and Spotify for each show
- Episode recommendations: 3-5 "start here" episodes for key podcasts with direct episode deep links
- New episode alerts (optional, via RSS feed polling)
- Personal notes per podcast or episode
- Listening log (optional, feeds into Growth/Intellectual tracking dimension)
- Community submissions (moderated review)
- Partner podcasts: featured placement for recovery organizations

### Content Pipeline

- Launch with 15-20 curated podcasts with editorial descriptions
- Spanish-language podcasts actively sought and curated separately

---

## 9. External Links

**Priority:** P1

### Description

A curated, organized directory of vetted external resources — the "recovery yellow pages" with editorial context and trust indicators.

### Directory Categories

#### Crisis & Emergency

- 988 Suicide & Crisis Lifeline (call/text 988)
- Crisis Text Line (text HOME to 741741)
- SAMHSA National Helpline (1-800-662-4357)
- National Sexual Assault Hotline (1-800-656-4673)
- Spanish-language crisis lines

#### 12-Step Fellowships

- Sexaholics Anonymous (sa.org)
- Sex Addicts Anonymous (saa-recovery.org)
- Sex and Love Addicts Anonymous (slaafws.org)
- S-Anon (sanon.org) — for partners/families
- Celebrate Recovery (celebraterecovery.com)
- Alcoholics Anonymous (aa.org)

#### Christian Recovery Organizations

- Pure Desire Ministries, Bethesda Workshops, Begin Again Institute, New Life Ministries, Faithful & True, Pure Life Ministries, Setting Captives Free

#### Clinical Resources

- IITAP (iitap.com) — Find a CSAT therapist
- APSATS (apsats.org) — Find a partner trauma therapist
- Psychology Today therapist finder (filtered for sex addiction)

#### Educational

- Fight the New Drug (fightthenewdrug.org)
- Your Brain on Porn (yourbrainonporn.com)
- Covenant Eyes blog

#### For Partners

- Bloom for Women (bloomforwomen.com)
- APSATS partner therapist directory
- S-Anon meeting finder

#### Spanish-Language Resources

- SAA Spanish-language resources page
- Spanish-language crisis lines by country
- Hispanic-serving Christian recovery organizations

### Entry Format

Each entry includes: organization name, URL (deep link), editorial description (2-3 sentences), category tags, trust indicator (verified partner / community-recommended / staff-curated), and "Why this matters for recovery" note.

### Features

- Favorites and recently visited history
- Report broken link
- Partner badge for formal Regal Recovery partnerships
- In-app browser with "Return to Regal Recovery" bar, or external browser (user preference)

---

## 10. Music & Spotify Playlists

### Regal Recovery Official Playlists (Spotify)

| Playlist | Description |
|---|---|
| Recovery Worship | Songs about freedom, redemption, surrender, new beginnings |
| Battle Hymns | Spiritual warfare and strength for temptation |
| Morning Recovery | Start the day with intention and praise |
| Healing & Restoration | Gentle songs for processing grief, shame, and loss |
| Couples Healing | Music for couples in recovery |
| Soaking Prayer | Extended instrumental worship for prayer sessions |
| Recovery en Espanol | Spanish-language worship and recovery music |

### Activity-Specific Suggestions

| Activity | Music Style | Suggested Playlists |
|---|---|---|
| Journaling | Instrumental Worship | "Quiet Time," "Acoustic Worship" |
| Prayer | Ambient / Contemplative | "Soaking Prayer," "Be Still" |
| Devotional Reading | Soft Acoustic / Instrumental | "Quiet Time," "Acoustic Worship" |
| Breathing Exercises | Ambient / Nature Sounds | "Deep Breathing," "Calm" |
| Exercise | Upbeat Worship / Christian Hip Hop | "Workout Worship," "Christian Fitness" |
| Evening Review | Reflective / Calming | "Evening Reflection," "Peaceful Night" |
| Urge Surfing / Emergency | Grounding / Worship | "Battle Music," "Spiritual Warfare Worship" |

---

## 11. Localization

### Supported Languages

**English and Spanish at launch.** Spanish is a first-class experience, not a translation layer.

### Geographic Scope

English and Spanish-speaking regions: US, Canada, UK, Australia, Mexico, and Latin America initially.

### What Needs Translation

All user-facing content requires professional translation with cultural review:

| Content Category | Translation Approach |
|---|---|
| UI strings (~500) | Professional translation with cultural review |
| Onboarding flows | Professional translation |
| Affirmations | Translation by bilingual Christian counselor (culturally adapted, not literal) |
| Scripture | Established Spanish translations (RVR1960 default, NVI, DHH, LBLA, Biblia Latinoamericana, Biblia de Jerusalem) |
| Journal prompts | Professional translation |
| Notifications | Cultural adaptation — warm, familial, faith-resonant register (e.g., "Tu compromiso diario te espera" not "Su compromiso diario esta listo") |
| Error messages | Professional translation |
| Crisis resources | Spanish-language crisis lines by country |
| Legal documents | Professional translation |
| Freemium devotionals | Available in English and Spanish at launch |
| Freemium prayers | Available in English and Spanish at launch |
| Premium content | Follows Content Localization Strategy (phased) |
| Recovery stories | Actively recruit Spanish-speaking submissions; translate top-performing English stories with cultural adaptation |
| Book recommendations | Spanish-language editions curated separately |
| Podcast directory | Spanish-language podcasts actively sought and curated separately |
| External links | Spanish-language resources section |

### Onboarding Language Selection

- Auto-detect device language setting
- Display options: "English" / "Espanol" with flag icons
- If device language is neither English nor Spanish, default to English
- Selection applies immediately; changeable in Settings

### Technical Requirements

- Externalized strings (i18n framework from launch)
- RTL layout support for future language expansion
- Dynamic text sizing for Spanish text expansion (~20-30% longer than English)
- Server-side content delivery by language preference
- Fallback to English when Spanish content is unavailable
- Settings-based language switch
- Local date/time formats
- Currency defaults to user's locale; manual selection available in Settings

### Spanish-Speaking User Persona Context

The "Addict Diego" persona (Spanish-dominant bilingual, Catholic, construction foreman from Mexico) drives key localization requirements:

- **Voice-first input:** Voice-to-text must work well in Mexican Spanish
- **Catholic content track:** Prayers to the saints, Rosary-based meditations, Ignatian Examen, confession preparation, sacramental language
- **Low data consumption mode:** Downloadable content for offline use
- **WhatsApp integration:** Default messaging platform for Spanish-language users
- **Community matching by language** for accountability partners and community features
- **Simple navigation:** Features discoverable in 1-2 taps, large tap targets, icons with text labels
- Recovery terminology reviewed by Spanish-speaking professionals

### Notification Localization

- All notification copy translated into Spanish with cultural adaptation (not literal translation)
- Spanish notifications match the emotional register of Spanish-speaking user personas
- Scripture references in notifications use the user's selected Bible translation
- WhatsApp as default notification platform for Spanish-language users

### Bible Translation Support (Full List)

| Language | Translations |
|---|---|
| English | NIV (default), ESV, NLT, KJV, NASB, NKJV, CSB, The Message |
| Spanish | RVR1960 (default), NVI, DHH, LBLA |
| Catholic Spanish | Biblia Latinoamericana, Biblia de Jerusalem |

---

## 12. Content Licensing Status

| Item | Source / Rights Holder | Type | Licensing Status | Fallback if Licensing Fails |
|---|---|---|---|---|
| FASTER Scale | Michael Dye / The Genesis Process | Clinical tool | Pending | Develop proprietary "Recovery Progression Scale" based on public-domain relapse prevention research |
| Personal Craziness Index (PCI) | Patrick Carnes | Clinical framework | Pending | Rename to "Personal Warning Index" with original user-defined behaviors (concept is generic) |
| SAST-R | Patrick Carnes / IITAP | Validated screening instrument | Pending — likely requires licensing fee | Use public-domain screening instruments (e.g., HBI-19, s-IAT) or develop proprietary screener |
| Arousal Template | Patrick Carnes | Clinical framework | Pending — therapist-recommended tool | Develop guided "Sexual History & Patterns" exercise based on public clinical literature |
| SA White Book | Sexaholics Anonymous | Copyrighted text | Pending — revenue share | Link to external purchase; provide original recovery content |
| AA Big Book | Alcoholics Anonymous World Services | Copyrighted text | Pending — revenue share | Link to external purchase; provide original recovery content |
| 12 Steps text | AA / SA | Copyrighted specific wording | At-risk — exact wording is copyrighted; paraphrased versions are generally permissible | Use paraphrased steps with attribution (common practice in recovery apps) |
| FANOS framework | Doug Weiss / Heart to Heart Counseling | Clinical framework | Pending — widely used in recovery community | Develop proprietary "Couples Connection Check-in" with similar dimensions |
| FITNAP framework | Recovery community (attribution unclear) | Clinical framework | Low risk — widely used without formal licensing | Document origin; develop proprietary variant if challenged |
| Feelings Wheel | Dr. Gloria Willcox (original) | Educational tool | Low risk — widely reproduced; multiple public-domain versions exist | Use public-domain emotion taxonomy or develop original design |
| Celebrate Recovery content | Celebrate Recovery / Saddleback Church | Program materials | Pending — partnership | Reference only; do not reproduce copyrighted materials |
| Pure Desire course content | Pure Desire Ministries | Copyrighted curricula | Pending — partnership | Original content development |
| Bethesda Workshops content | Bethesda Workshops | Copyrighted materials | Pending — partnership | Original content development |
| Bible text (various translations) | Multiple publishers | Copyrighted translations | Varies by translation — API licensing required | Use public-domain translations (KJV, ASV, WEB) as defaults; license popular translations (NIV, ESV, NLT) |
| NextMeeting SA data | NextMeeting / SA | Meeting database | Pending — API access | Manual meeting database with community submissions |
| Barna research data | Barna Group / Pure Desire | Published research | Low risk — citing published studies is permissible | Cite with attribution; do not reproduce full datasets |

### Status Definitions

- **Confirmed:** Licensing agreement in place or content is public domain
- **Pending:** Outreach not yet initiated or in discussion
- **At-risk:** Licensing may be denied, expensive, or legally complex
- **Low risk:** Widely used without formal licensing; risk of challenge is minimal
