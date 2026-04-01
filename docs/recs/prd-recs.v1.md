# Regal Recovery PRD Analysis and Recommendations

**Document Version:** 1.0
**Analysis Date:** March 28, 2026
**PRD Version Analyzed:** 2.0 (dated March 29, 2026)
**PRD Size:** ~7,900 lines, 30 features, 20+ activities, 5 assessments, 6 tools

---

## 1. Executive Assessment

This is an exceptionally thorough PRD that demonstrates deep domain expertise in addiction recovery, Christian counseling methodologies, and user-centered design. The document is well above average in persona depth, edge case coverage, and emotional intelligence. It reads as though the author has lived in the recovery community and understands the nuances of shame, isolation, gender stigma, cultural barriers, and the specific clinical tools (FASTER Scale, Carnes' arousal template, Redemptive Living) that practitioners actually use.

That said, the PRD has significant structural and strategic issues that would prevent it from being production-ready in its current form. The core tension is that **the document describes a platform that would take 3-5 years and a team of 15-25 engineers to build**, but presents it as a single release with no phased delivery plan.

**Overall Grade: B+** -- Exceptional in depth and user understanding, but needs significant work on scope management, prioritization, JIRA-readiness, and business model validation before it can drive an engineering team.

---

## 2. What Is Strong

### 2.1 Persona Development (Section 3)
The personas are best-in-class. The PRD defines 11 personas across addicts (male/female, single/married, English/Spanish-speaking), spouses (male/female), sponsors (male/female), counselors, and coaches. Each persona includes:
- Realistic demographic detail grounded in specific locations and life circumstances
- Articulated pain points across four dimensions (emotional, practical, spiritual, relational)
- Technology behavior profiles that inform design decisions
- Direct quotes that capture voice and motivation
- Explicit "App Design Implications" sections (Sections 3.9, 3.10, 3.11) that bridge persona insight to feature requirements

**Standout:** The inclusion of Jasmine (3.10, single Black female with love addiction) and Diego (3.11, Spanish-dominant Catholic male) demonstrates an unusual level of inclusivity for recovery tech. The Pain Point Matrix (3.12) is an effective cross-reference.

### 2.2 Edge Case Coverage
Nearly every feature and activity includes a dedicated "Edge Cases" section. These are not perfunctory -- they address real scenarios like:
- Multiple relapses in one day (Feature 3)
- User living inside a geofenced high-risk zone (Feature 24)
- VPN conflicts with content filtering (Feature 15)
- Eating disorder co-addiction safeguards in nutrition tracking (Activity: Nutrition)
- Couples with different subscription tiers or languages (Feature 26)
- User factory-resetting their device during accountability monitoring (Feature 15)

This level of edge case thinking is production-grade and will save significant time during development and QA.

### 2.3 Emotional Intelligence in UX Copy
The PRD consistently defines tone and messaging guidelines for each feature. The philosophy of "celebration, not trivialization" and "acknowledgment, not pressure" (Feature 19, Gamification Design Principles) pervades the document. Specific examples:
- Relapse messaging that avoids shame (Feature 3, Relapse Logging Flow)
- Gratitude framed as worship, not homework (Activity: Gratitude List)
- "Even the calls that don't connect show that you're fighting for your recovery" (Activity: Phone Calls)
- Acting-in behavior tracking framed as growth, not a shame list (Activity: Acting In Behaviors)
- Eating disorder safeguards that eliminate calorie counting, weight tracking, and "good food/bad food" language (Activity: Nutrition)

### 2.4 Security and Privacy Architecture (Section 10.3)
The zero-knowledge architecture is well-thought-out and differentiated:
- User-derived encryption keys with on-device decryption
- Separate encryption for arousal template data with user-held passphrase
- Signal Protocol for messaging
- Cryptographic erasure for deletion
- Ephemeral mode for time-limited entries
- Audit trail with "Who Accessed My Data" screen
- Mandated reporting disclosure that honestly addresses the zero-knowledge constraint

This level of security design is appropriate for the sensitivity of the data and would be a genuine competitive differentiator.

### 2.5 Notification Strategy (Section 4.11)
The 4-tier notification hierarchy with daily caps, intelligent batching, quiet hours, and missed notification policies is one of the most thorough notification frameworks in any PRD. The explicit identification that "a population already managing anxiety, shame, and overwhelm" requires careful notification design shows empathy translated into systems thinking.

### 2.6 Clinical Tool Integration
The inclusion of validated clinical instruments (SAST-R, FASTER Scale, Carnes' arousal template, Personal Craziness Index) alongside structured therapeutic exercises (Redemptive Living's Bow Tie, Backbone, Empathy Mapping, T30/60 journaling) positions this app as a serious clinical companion, not just a habit tracker.

### 2.7 Offline-First Design (Feature 23)
The offline-first architecture with explicit capability tables, pre-download systems, low-data mode, and sync conflict resolution demonstrates understanding of real-world usage constraints -- particularly for Diego (construction worker, metered data) and crisis scenarios where connectivity cannot be guaranteed.

---

## 3. Gaps and Weaknesses

### 3.1 No Phased Delivery Plan / MVP Definition

**This is the most critical gap in the PRD.**

The document defines 30 features, 20+ activities, 6 tools, 5 assessments, a full notification framework, a therapist web portal, multi-tenancy, white-labeling, AR coin viewing, Spotify integration, geofencing, WebKit content filtering, sleep tracking, screen time integration, couples mode, and an AI chatbot -- all as a single release (Section 9.1 "Full Feature Set").

There is no Phase 1 / Phase 2 / Phase 3 breakdown. There is no MVP. There is no "launch with these 8 features and validate before building the rest." The priority labels (P0, P1, P2, P3) exist but are not mapped to delivery phases.

A rough estimate of the scope described:
- **P0 features alone** (Onboarding, Profile, Tracking, DSR, Offline-First, Daily Sobriety Commitment, Affirmations, Urge Logging, Journaling, Breathing Exercises, Relapse Prevention Plan, SAST-R, Notification Strategy) would require 6-9 months for a team of 5-8 engineers
- **All 30 features + activities + tools + assessments** would require 24-36 months for the same team
- The therapist web portal (Feature 17) alone is a separate product

**Recommendation:** Define three release phases:
- **Phase 1 (MVP, 6-9 months):** All P0 features + the most critical P1 features (FASTER Scale, Check-ins, Meetings, Meeting Finder). Target: validate the core value proposition with 1,000 users.
- **Phase 2 (9-18 months):** Remaining P1 features, Community (P2 but essential for retention), Therapist Portal v1, Content Filter v1.
- **Phase 3 (18-36 months):** P2 and P3 features (Geofencing, Couples Mode, AI Chatbot, Spotify, AR coins, White-labeling, Advanced Analytics).

### 3.2 No OMTM (One Metric That Matters) Identified

The PRD defines success metrics across 10 categories (Section 7) with 40+ KPIs but does not identify a single OMTM. For a recovery app, the OMTM should likely be **average sobriety streak length** or **90-day retention rate**, as these directly measure whether the app is achieving its core mission.

Without an OMTM, trade-off decisions during development will lack a clear tiebreaker. When the team debates whether to build the Spotify integration or improve the urge logging flow, the OMTM provides the answer.

**Recommendation:** Define the OMTM as "Average sobriety streak length among users active for 30+ days" and tie every prioritization decision back to it. All other metrics become supporting indicators.

### 3.3 No Business Model Validation

The monetization section is scattered across multiple features rather than consolidated:
- Freemium/premium content tiers mentioned in Feature 4
- Premium+ tier for content filtering in Feature 15
- Therapist portal pricing in Feature 17
- Superbill/LMN generation in Feature 20
- Subscription tiers referenced in FR6.2

But there is no:
- Pricing page definition (what does Free / Premium / Premium+ include, and at what price?)
- Revenue model analysis (what percentage of revenue comes from subscriptions vs. content packs vs. B2B vs. superbills?)
- Unit economics (CAC, LTV, payback period)
- Competitive pricing analysis (Covenant Eyes is $18/mo, Fortify is $39/year, generic meditation apps are $70/year)
- Free tier value ceiling (what is enough to retain users but insufficient to replace paying?)

The stated targets (5% premium conversion, $1.50 ARPU, $90 LTV) in Section 7.5 appear optimistic for a niche faith-based app without substantiation.

**Recommendation:** Add a dedicated Business Model section that:
1. Defines exact tier pricing and feature mapping
2. Models revenue under conservative, moderate, and optimistic scenarios
3. Validates the "unlocked forever when purchased" model for content packs against subscription economics
4. Addresses the tension between "affordable for Marcus (Section 3.9, apprentice's income)" and sustainable revenue

### 3.4 User Stories Lack Acceptance Criteria in Given/When/Then Format

Most features include user stories in "As a [user], I want [goal], so that [benefit]" format, which is good. However, almost none include formal acceptance criteria in Given/When/Then format. The "Conditions of Satisfaction" are expressed as prose descriptions and summary bullets rather than testable statements.

For example, Feature 1 (Onboarding) has detailed user stories and flow descriptions but the success criteria ("Fast Track completion rate: 95%+") are outcome metrics, not acceptance criteria for individual stories.

**Recommendation:** For every P0 and P1 user story, add explicit Given/When/Then conditions of satisfaction. Example for the onboarding story "As a new user, I want to start using the app as quickly as possible":
- Given I am a new user launching the app for the first time, When I complete the Fast Track onboarding, Then I arrive at the Dashboard in under 2 minutes
- Given I am on the Welcome Screen, When I tap "Need help right now?", Then the Emergency Tools overlay opens without requiring account creation
- Given I am in Step 4 (Core Setup), When I leave the sobriety date blank, Then the system defaults to today's date

### 3.5 No Story Point Estimates or Sprint-Level Decomposition

The PRD does not include story point estimates, sprint assignments, or work breakdown structures for any feature. Section 9 (Development Roadmap) contains only a single entry: "Full Feature Set" with success criteria. There is no sprint-by-sprint plan, no velocity assumptions, no dependency map between features.

**Recommendation:** For Phase 1 (MVP), decompose each P0 feature into user stories with Fibonacci story point estimates. Map the first two sprints in detail and stub the remaining sprints with story titles. Identify cross-feature dependencies (e.g., Tracking System must precede Analytics Dashboard; Profile must precede Community permissions).

### 3.6 Missing MoSCoW Categorization at the Requirement Level

The PRD assigns priority labels (P0-P3) at the feature level but does not apply MoSCoW categorization to individual requirements within features. For example, Feature 19 (Achievement System) is P1, but within it, the AR coin viewing with ARKit/ARCore is clearly a "Could have" while the basic milestone badge is a "Must have." Without sub-feature MoSCoW, the team cannot make scope cuts within a feature when sprint capacity is constrained.

**Recommendation:** Within each P0 and P1 feature, apply MoSCoW labels to individual capabilities. This enables the team to ship a feature's "Must have" requirements in Sprint N and defer "Should have" and "Could have" items to later sprints without holding the entire feature.

### 3.7 No Competitive Analysis Section

The PRD mentions Covenant Eyes (Feature 15) and refers to fragmented tools as a pain point, but does not include a formal competitive analysis. Key competitors that should be evaluated:
- **Fortify** (pornography recovery app, secular/scientific)
- **Covenant Eyes** (accountability software)
- **Ever Accountable** (screen accountability)
- **Pure Desire** (Christian recovery app)
- **Brainbuddy** (porn addiction recovery)
- **rTribe** (accountability app)
- **Nomo** (sobriety tracker)
- **I Am Sober** (sobriety counter)
- **Celebrate Recovery app**

**Recommendation:** Add a competitive analysis matrix showing: target audience, feature set, pricing, faith integration, clinical depth, platform coverage, and key differentiators. Identify Regal Recovery's unique value proposition relative to each competitor explicitly.

---

## 4. Structural Recommendations

### 4.1 Add a Document Hierarchy Map

At 7,900 lines, this PRD is difficult to navigate. The nesting of Features > Activities > Sub-Activities > Tools > Assessments creates ambiguity about what constitutes a "feature" in JIRA terms.

**Recommendation:** Add a visual hierarchy map at the beginning of Section 4:
```
Epic: Regal Recovery MVP
  Feature: Onboarding & Profile Setup
    Story: Fast Track account creation
    Story: Deferred profile completion
  Feature: Tracking System
    Story: Sobriety streak tracking
    Story: Multi-addiction tracking
  Feature: Daily Sobriety Commitment (Activity)
    Story: Morning commitment flow
    Story: Evening review flow
```

This makes the JIRA mapping explicit and eliminates the ambiguity between "Feature" (the PRD section type) and "Feature" (the JIRA work item type).

### 4.2 Separate the PRD into Multiple Documents

A single 7,900-line PRD violates the principle that PRDs should be consumable by the entire team. Consider splitting into:
1. **Strategic PRD** (Sections 1-3, 7-9, 11): Problem statement, personas, success metrics, roadmap, next steps
2. **Feature Specifications** (Section 4, one document per feature or feature group): Detailed requirements, user stories, edge cases
3. **Technical Architecture** (Sections 5, 10): Functional/non-functional requirements, security, infrastructure
4. **Content Strategy** (extracted from Sections 4.3-4.4): Content tiers, localization, recommended reading, podcast directory

### 4.3 Consolidate Redundant Activity Definitions

Several activities have overlapping scope that creates confusion:
- **Emotional Journaling** appears both as a standalone activity (Section 4.3) and as a Redemptive Living sub-activity (Section 4.3, Partner Activities). The PRD acknowledges this ("tagged as standalone when completed through the main Emotional Journaling activity") but the dual definition creates implementation ambiguity.
- **Person Check-ins** vs. **Phone Calls** vs. **Spouse Check-in Preparation** have three separate detailed specifications that describe adjacent behaviors. The PRD includes a "Relationship to Other Activities" section in Person Check-ins, but the cross-references add complexity.

**Recommendation:** Create a single "Activity Relationship Map" showing how activities relate, which ones share data models, and which can be consolidated at the implementation level even if they remain distinct in the UI.

---

## 5. Content Recommendations

### 5.1 Missing User Stories

The following scenarios are implied by the personas but lack explicit user stories:

1. **User who has never attended a 12-step meeting** -- Marcus (3.9) is pre-sponsor. Stories needed for: discovering what meetings exist, understanding meeting etiquette, finding online-only options for privacy.

2. **User transitioning between recovery stages** -- No stories address what happens when a user moves from Early Recovery to Active Recovery. Does the app adapt content? Do achievements reset? Do risk thresholds change?

3. **User who relapses after extended sobriety** -- The relapse logging flow exists, but there are no stories for the emotional journey of losing a 6-month streak. The compassionate messaging is mentioned but not specified as testable acceptance criteria.

4. **User whose support person is abusive or controlling** -- The spouse permissions system assumes healthy intent. What if a spouse demands full access as a condition of staying in the marriage? What safeguards exist against weaponizing accountability data?

5. **User experiencing suicidal ideation** -- The Crisis Disclosure Protocol (5.3) mentions keyword detection but no user stories exist for the flow from detection to intervention. This is a critical safety gap.

6. **User who is a minor (under 18) who lies about age** -- Age verification (10.3.1) blocks under-18 users, but no story addresses what happens if age fraud is detected post-registration.

7. **Therapist who loses their license** -- Feature 17 (Therapist Portal) does not address credential verification or revocation.

### 5.2 Missing Edge Cases

- **Feature 18 (Recovery Health Score):** What happens when a user game-plays the score by completing minimal actions that maximize the score without genuine engagement? The score composition relies heavily on engagement metrics (25%) which can be gamed.

- **Feature 8 (AI Chatbot):** What happens when the AI generates a theologically incorrect response? Who reviews the AI's output? What denominational framework governs its responses? A Catholic user and an evangelical user may need very different pastoral guidance.

- **Feature 22 (Messaging Integrations):** What happens when deep links break due to messaging app updates? The WhatsApp, Signal, and Telegram URL schemes are not guaranteed to be stable.

- **Activity: Daily Sobriety Commitment:** The morning commitment questions (Section 4.3) are SA-specific ("abstaining from sex with yourself or anyone other than your spouse"). What about users whose primary addiction is not sexual (the app supports gambling, substance use, etc.)? The questions need addiction-specific variants.

### 5.3 Content Licensing Risks

The PRD explicitly acknowledges the SAST-R licensing requirement (Section 4.10) but does not address licensing for:
- **FASTER Scale:** Created by Michael Dye. Is commercial use permitted?
- **Personal Craziness Index:** From Patrick Carnes. Same licensing question.
- **Redemptive Living exercises:** These are partner-provided content. Is a licensing agreement in place?
- **3 Circles Tool:** Common in SA but potentially trademarked.
- **Recommended reading list:** Affiliate links to Amazon/Bookshop.org are mentioned. Ensure compliance with FTC disclosure requirements.

**Recommendation:** Add a "Content Licensing Status" table listing every third-party clinical tool, its source, licensing status (confirmed/pending/at-risk), and fallback if licensing fails.

---

## 6. Prioritization Concerns

### 6.1 P1 Features That Should Be P0

- **FASTER Scale (Activity, currently P1):** This is referenced by at least 10 other features (Recovery Health Score, Post-Mortem Analysis, Content Trigger Log, Screen Time, Sleep Tracking, Analytics Dashboard, Therapist Portal, and multiple correlation insights). It is a foundational data source. It should be P0.

- **Recovery Check-ins (Activity, currently P1):** The check-in score is a primary input to the Recovery Health Score and Analytics Dashboard. Daily check-ins are one of the most common commitments. Should be P0.

- **Meeting Finder (Feature 21, currently P1):** For users like Marcus (no sponsor, no therapist, relying on Celebrate Recovery), the meeting finder is a critical first-week value driver. Consider P0 for a basic version.

### 6.2 P1 Features That Should Be P2 or P3

- **Spotify Integration (Feature 30, P2):** This is a nice-to-have that adds significant implementation complexity (Spotify SDK, OAuth, playback control, playlist management). It should be P3.

- **Sleep Tracking Integration (Feature 27, P1):** While sleep correlation is valuable, it requires health API integration and 14+ days of data before providing any insight. This is a retention feature, not an acquisition or activation feature. Should be P2.

- **Screen Time Integration (Feature 25, P1):** Same reasoning as sleep tracking. These APIs are also platform-specific and subject to OS restrictions that may change. Should be P2.

- **Content Trigger Log (Feature 28, P1):** This depends on Feature 15 (Content Filter), which is Premium+ only. A feature that depends on a premium-only feature should not be P1. Should be P2, launching alongside or after the content filter.

- **Panic Button with Biometric Awareness (Feature 16, P1):** The camera-based facial expression analysis is novel but technically complex and potentially uncomfortable for users. The basic panic button (motivations, breathing, sponsor call) should be P0; the biometric awareness layer should be P2 or P3.

### 6.3 P0 Features That Are Oversized

- **Feature 23 (Offline-First, P0):** Offline-first is correctly P0, but the Low Data Mode, content pre-download system, and storage management UI described are P1-level polish. The P0 version should be: core features work offline, data syncs when connected. The bandwidth optimization and storage management can come later.

- **Feature 1 (Onboarding, P0):** The deferred profile completion strategy with 12+ contextual triggers, gamification (progress ring, 80% celebration, 100% badge), and role-based onboarding variants is extensively specified. The P0 onboarding should be the Fast Track flow only. Deferred completion and gamification are P1.

---

## 7. Technical Feasibility Concerns

### 7.1 Zero-Knowledge Architecture Implications

The zero-knowledge encryption architecture (10.3.2) is admirable but creates significant technical constraints that are not fully addressed:

1. **Server-side search is impossible.** The PRD specifies full-text search across journals, gratitude entries, prayer notes, and devotional reflections. All of this must be client-side only, which means:
   - Search performance degrades with data volume
   - Cross-device search requires full data download
   - The AI chatbot cannot access historical user data without on-device decryption
   - The therapist portal cannot display journal content -- it must stream from the client device or re-encrypt for the therapist's key

2. **Analytics are limited.** The PRD specifies correlation insights ("On days you exercise, your urge frequency is X% lower"). If urge log notes are zero-knowledge encrypted but the urge metadata (timestamp, intensity, trigger category) is field-level encrypted with KMS, the server can compute correlations on structured data but not on free-text content. This distinction needs to be explicit in the PRD.

3. **Key recovery is fragile.** If a user loses their recovery passphrase and their device, all encrypted data is permanently lost. For a population managing crisis and potentially unstable housing (like Marcus), this is a real risk. Consider a secure key escrow option (e.g., split key with two trusted contacts).

**Recommendation:** Add a "Zero-Knowledge Constraints" section that explicitly lists what becomes impossible or limited under this architecture, and confirm the team accepts these trade-offs.

### 7.2 WebKit Content Filter Feasibility (Feature 15)

The content filtering feature aspires to replace Covenant Eyes, but the technical approach has platform-specific challenges:

- **iOS:** Apple's Content Blocker API (WebKit Content Rule Lists) works only in Safari. The Network Extension framework for DNS filtering requires an MDM profile or explicit VPN configuration. Apple has been increasingly restrictive about VPN-based content filtering apps. App Store review rejection is a real risk.
- **Android:** VPN-based DNS filtering (as described) works but conflicts with corporate VPNs and other VPN-based apps. The Accessibility Service approach has been deprecated by Google for non-accessibility uses; apps using it for monitoring face Play Store removal.
- **On-device ML for content classification** is feasible but requires substantial training data and ongoing model updates. False positive rates for art, medical content, and news imagery will be high initially.

**Recommendation:** Treat Feature 15 as a separate product with its own technical feasibility study. Do not include it in the MVP. Consider partnering with Covenant Eyes or Ever Accountable via API integration before building a proprietary solution.

### 7.3 AI Chatbot Complexity (Feature 8)

The Recovery Agent described is not a simple chatbot -- it is a full conversational interface to every app feature with:
- Read access to all user recovery data
- Write access to submit entries on behalf of the user
- Guided walkthroughs of complex multi-step tools (FASTER Scale, Post-Mortem, Relapse Prevention Plan)
- Proactive recommendations based on behavioral patterns
- Crisis detection and escalation
- Zero-knowledge interaction (on-device decryption for context)

This is essentially a vertical AI agent platform. Building it well requires:
- Fine-tuned LLM with recovery-domain knowledge and theological guardrails
- Function calling / tool-use architecture for data entry
- Robust prompt engineering to prevent harmful advice
- Extensive testing across denominations (Catholic vs. evangelical vs. non-denominational)
- Ongoing monitoring and human review of conversation quality

**Recommendation:** The AI chatbot should be P3 (it is currently P3, which is correct). The PRD should also define a simpler "v0.5" chatbot that provides encouragement and crisis escalation only, without data entry capabilities, as a P2 stepping stone.

### 7.4 Multi-Tenancy and White-Labeling Complexity

Features 10 (Branding) and 11 (Tenancy) describe a full multi-tenant SaaS platform with white-labeling. This is architecturally significant:
- Tenant-isolated encryption keys (10.3.10)
- Configurable branding (name, logo, colors, splash screen)
- Tenant-specific content libraries
- Aggregate-only admin dashboards

Building multi-tenancy from Day 1 adds complexity to every feature. If the B2B channel is not validated, this investment may be premature.

**Recommendation:** Design for multi-tenancy at the data model level (partition keys, tenant context) but defer the admin portal, white-labeling UI, and tenant provisioning tooling to Phase 2. Validate B2B demand with 2-3 manual pilots first.

---

## 8. Security and Privacy Recommendations

### 8.1 HIPAA Compliance Gap

The PRD mentions "HIPAA-adjacent data handling practices from launch; full HIPAA compliance targeted for Phase 2" (Feature 17). However:
- The therapist portal stores session notes, client crisis alerts, and clinical assignments
- Therapists using the portal to manage clients creates a Business Associate relationship under HIPAA
- A data breach affecting therapist-client data without a BAA (Business Associate Agreement) exposes both Regal Recovery and the therapist to legal liability

**Recommendation:** Either achieve HIPAA compliance before launching the therapist portal, or clearly disclaim that the platform is not HIPAA-compliant and restrict the portal to non-clinical use (no session notes, no clinical assignments, summary data only). Do not launch in a gray area.

### 8.2 Biometric Data Regulations

Feature 16 (Panic Button with Biometric Awareness) processes facial expression data via on-device ML. Even though no data leaves the device:
- Illinois BIPA (Biometric Information Privacy Act) requires informed consent before collecting biometric identifiers
- Texas and Washington have similar laws
- The EU GDPR classifies biometric data as "special category" requiring explicit consent

The PRD mentions opt-in consent but does not address jurisdiction-specific biometric privacy laws.

**Recommendation:** Add a biometric data compliance section. Ensure the consent flow meets BIPA requirements (written release, purpose disclosure, retention schedule, destruction timeline). Consider disabling the feature in jurisdictions with strict biometric laws until compliance is confirmed.

### 8.3 Minors and Vulnerable Populations

The 18+ age gate (10.3.1) is appropriate but:
- No verification mechanism beyond self-reported birth year is described
- The recommended reading list includes "Good Pictures Bad Pictures" (ages 7+) and "Good Pictures Bad Pictures Jr." (ages 3-6), which are parenting books -- but their presence in the app could be used to argue the app targets minors
- The crisis disclosure protocol (5.3) mentions suicidal ideation detection but does not address protocols specific to minors who bypass the age gate

**Recommendation:** Remove youth-targeted content (children's books) from the in-app reading list -- recommend these through external links only. Add a disclaimer that the app is not designed for minors. Consider whether the content filter feature (Feature 15) could be marketed for family use and, if so, develop a separate minor-appropriate mode.

### 8.4 Domestic Violence and Coercive Control Safeguards

The accountability features (content filter reports to spouse, geofence alerts to sponsor, data sharing permissions) could be weaponized in coercive relationships. A controlling spouse could demand full access, geofence alerts, and content filter reports as conditions for staying in the marriage.

The PRD does not address:
- How to detect potential coercive use of accountability features
- A "safety mode" that allows a user to appear compliant while secretly restricting data sharing
- Resources for domestic violence or coercive control
- Training for moderators on recognizing coercive patterns in support requests

**Recommendation:** Add a "Safety and Coercion Safeguards" section. At minimum:
1. Include domestic violence resources in the External Links directory
2. Add a subtle, non-obvious access point to DV resources within the app (not labeled as such -- similar to how some apps use a discrete "X" button)
3. Allow a user to set a "safety contact" who is notified if the user's data sharing permissions are changed by another party
4. Train moderation staff on coercive control indicators

---

## 9. Business Model and Monetization Feedback

### 9.1 The "Unlocked Forever" Content Model Is Risky

The PRD states that premium content packs (affirmations, devotionals, prayers, verse packs) are "unlocked forever when purchased." This creates a one-time revenue event from each content sale while requiring ongoing hosting, delivery, and maintenance costs.

- If the average user buys 3 content packs at $4.99 each over their lifetime, that is $14.97 in content revenue vs. a subscription model that could generate $120+/year
- The "unlocked forever" model is user-friendly but creates a CAC payback problem for a niche app
- Content packs compete with subscription tier value -- if the best content is available a la carte, why subscribe?

**Recommendation:** Consider making all content part of the subscription tiers rather than a la carte purchases. This simplifies the monetization model, increases LTV, and aligns with industry norms. If a la carte is retained, ensure the subscription tier includes all content so that subscribing is always the better deal.

### 9.2 The Therapist Portal as a Growth Channel

Feature 17 correctly identifies therapist referrals as a B2B2C growth channel. However:
- The portal is free to therapists -- there is no direct revenue
- The 30-day free trial for therapist-referred clients is generous but may attract low-intent users
- The referral program (10+ active paid users = free personal access) has a high threshold

The therapist portal is a significant engineering investment. Its ROI depends entirely on whether therapists actually recommend the app to clients and whether those clients convert to paid.

**Recommendation:** Before building the full portal, validate demand with a lightweight version:
1. Create a simple therapist landing page with "Recommend to your clients" CTA
2. Provide therapists with a referral code that gives their clients a free trial
3. Track referral-to-conversion rates
4. Build the full portal only after validating that therapist referrals convert at 2x+ the organic rate

### 9.3 Superbill/LMN Revenue Potential

Feature 20 (Superbill and LMN Generation) is creative and potentially high-value:
- HSA/FSA reimbursement reduces effective subscription cost by 20-35%
- This removes a price objection for users like Marcus (financial barriers)
- The LMN generation via telehealth partner ($29.99 one-time for Premium, free for Premium+) creates a direct revenue event and a compelling Premium+ value prop

However, the feature requires:
- A licensed telehealth partner willing to sign LMNs at scale
- Correct CPT and ICD-10 coding reviewed by a medical billing specialist
- Ongoing compliance as insurance regulations change
- Liability coverage for billing accuracy

**Recommendation:** This feature has strong differentiation potential. Validate the telehealth partnership early. If feasible, consider making this a launch feature for Premium+ rather than a Phase 2 add-on.

---

## 10. Competitive Positioning Observations

### 10.1 Unique Strengths vs. Competition

| Differentiator | Regal Recovery | Fortify | Covenant Eyes | I Am Sober | Pure Desire |
|---|---|---|---|---|---|
| Clinical depth (FASTER, PCI, Post-Mortem) | Deep | Moderate | None | None | Moderate |
| Christian faith integration | Core | None | Light | None | Core |
| Spanish language (first-class) | Yes | No | No | Partial | No |
| Female-focused content | Yes | Minimal | No | Gender-neutral | Minimal |
| Couples/spouse features | Extensive | None | Basic | None | Basic |
| Therapist portal | Yes | No | No | No | No |
| Zero-knowledge privacy | Yes | No | No | N/A | No |
| Accountability software | Planned | No | Core product | No | No |
| Multi-addiction tracking | Yes | Porn only | Porn only | Any addiction | Sex addiction |

### 10.2 Positioning Risk

The breadth of features creates a "Swiss Army knife" positioning risk. Regal Recovery tries to be:
- A sobriety tracker (competing with I Am Sober, Nomo)
- An accountability tool (competing with Covenant Eyes, Ever Accountable)
- A recovery curriculum (competing with Fortify, Pure Desire)
- A therapist platform (competing with practice management tools)
- A couples counseling tool (competing with couples therapy apps)
- A devotional app (competing with YouVersion, Pray.com)
- A music integration (competing with nothing -- because no one needs this in a recovery app)

**Recommendation:** Lead positioning with the unique clinical + faith integration. The tagline should communicate: "The recovery tool your therapist wishes existed." Emphasize the FASTER Scale, Post-Mortem Analysis, Redemptive Living integration, and therapist coordination -- these are capabilities no competitor offers. De-emphasize features like Spotify integration, book logging, and nutrition tracking in marketing, even if they exist in the app.

---

## 11. Recommendations for the Next Iteration

### 11.1 Critical (Do Before Engineering Starts)

1. **Define the MVP.** Extract P0 features into a Phase 1 release plan with sprint-level decomposition. Everything else goes into Phase 2+.
2. **Identify the OMTM.** Choose one metric and make every trade-off decision against it.
3. **Write acceptance criteria.** Every P0 user story needs Given/When/Then conditions of satisfaction.
4. **Resolve HIPAA positioning.** Decide whether the therapist portal launches with HIPAA compliance or without clinical features.
5. **Validate the content filter feasibility.** Commission a technical spike on iOS Network Extension and Android VPN-based filtering before committing Feature 15 to any phase.
6. **Create a content licensing tracker.** Confirm licensing status for FASTER Scale, PCI, SAST-R, 3 Circles, and Redemptive Living before building features that depend on them.

### 11.2 Important (Do During Phase 1 Development)

7. **Add a competitive analysis section.** Know exactly what Fortify, Covenant Eyes, and Pure Desire offer.
8. **Define the pricing page.** Exact pricing, tier feature mapping, and free trial lengths.
9. **Design the data model.** The relationships between activities, tracking, analytics, and the recovery health score need a formal data model before implementation.
10. **Conduct theological review.** Engage a small advisory board (Catholic, evangelical, non-denominational) to review devotional content, prayer language, and AI chatbot theological guardrails.
11. **Add coercive control safeguards.** Address the domestic violence risk before launching accountability features.
12. **Plan the content pipeline.** The app launches with 50+ affirmations, 30+ devotionals, 12 step prayers, 50+ journal prompts, and 20-30 recovery stories. Who writes this? What is the timeline? What is the budget?

### 11.3 Valuable (Do Before Phase 2)

13. **User test the onboarding flow.** The Fast Track is well-designed on paper but needs validation with real users in crisis.
14. **Validate B2B demand.** Talk to 10 ministry leaders and 10 therapists before building white-labeling or the full therapist portal.
15. **Commission a security audit.** The zero-knowledge architecture is novel and needs third-party validation before launch.
16. **Build an analytics framework.** The correlation insights described throughout the PRD require a sophisticated analytics engine. Spec this as a separate technical design document.
17. **Define the AI chatbot v0.5.** If the full Recovery Agent is P3, what is the minimal chatbot experience for P2?

### 11.4 Nice-to-Have (Park for Later)

18. AR coin viewing (Feature 19) -- interesting but non-essential
19. Physical coin ordering partnership (Feature 19) -- future revenue opportunity
20. Smart TV content filtering (Feature 15, Phase 3) -- stretch goal
21. WhatsApp Business API integration (Feature 22) -- deep links are sufficient for MVP
22. Word cloud in gratitude insights (Activity: Gratitude List) -- polish feature

---

## 12. Summary

This PRD is the work of someone who deeply understands the recovery community, the clinical tools, the faith dimension, and the user experience challenges of building for a vulnerable population. The emotional intelligence, edge case thinking, and security architecture are genuinely impressive.

The path to production-readiness requires three things:

1. **Ruthless scope reduction** -- define an MVP that can ship in 6-9 months and validate the core hypothesis
2. **Engineering-ready specificity** -- acceptance criteria, story points, sprint plans, and a data model
3. **Business model rigor** -- pricing, unit economics, and competitive positioning that can sustain the mission

The foundation is strong. The next iteration should focus on making this document actionable for a development team while preserving the empathy and depth that make it exceptional.
