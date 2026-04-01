# Regal Recovery PRD Evaluation and Recommendations

**Evaluation Date:** 2026-03-28
**Documents Evaluated:**
- `01-strategic-prd.md` (Strategic PRD)
- `02-feature-specifications.md` (Feature Specifications)
- `03-technical-architecture.md` (Technical Architecture)
- `04-content-strategy.md` (Content Strategy)

---

## 1. Overall Assessment

This is an exceptionally thorough PRD suite. The depth of persona research, competitive analysis, and feature specification puts it well ahead of most product documents at this stage. The fact-checked competitive data with explicit confidence caveats, the zero-knowledge security architecture, the compassionate UX philosophy, and the content licensing contingency table all demonstrate serious, mature product thinking.

That said, the documents are at a stage where they would benefit from narrowing toward execution. The primary risk is not insufficient thinking -- it is scope. The PRD describes what would take a funded team of 8-12 engineers 2-3 years to build, while the business model targets bootstrapped-to-modest-funding launch economics. The gap between ambition and resource reality is the most important issue to resolve.

---

## 2. Document-by-Document Strengths

### 01-strategic-prd.md

**Strongest elements:**
- Personas are outstanding. The diversity of representation (Alex, Allison, Marcus, Jasmine, Diego) with intersecting dimensions of gender, race, faith tradition, relationship status, and economic status is rare and valuable. The Pain Point Matrix (Section 3.12) is excellent for cross-cutting analysis.
- Competitive analysis (Section 12) is publication-grade. The fact-correction annotations (e.g., Barna 84% vs. previously cited 82%), third-party estimate caveats, and data confidence notes demonstrate intellectual honesty that builds credibility with investors and partners.
- Market sizing follows proper TAM > SAM > SOM discipline with both top-down and bottom-up validation. The search volume and app store data provide concrete demand signals.
- Revenue modeling across conservative/moderate/optimistic scenarios with explicit assumption flags is well-structured.
- The "Marcus Test" for pricing affordability is a clever framework for validating pricing against persona economics.

**Weaknesses:**
- No OMTM is identified. The document lists extensive KPIs (Section 7) but never designates one primary metric. When trade-offs arise (and they will), what single metric decides? Recommendation: Define the OMTM -- likely "Day-90 retention rate" or "average sobriety streak length among active users" -- and explicitly state how every feature contributes to it.
- Section 9 (Development Roadmap) is nearly empty. It references "All features listed in Section 4" with success criteria but provides no phasing, no MVP definition, no sprint/quarter breakdown. For a document this detailed elsewhere, the roadmap is conspicuously absent.
- Section 10 is missing entirely (numbering skips from 9 to 11). Either it was removed during editing or never written. This should be reconciled.
- Business objectives (Section 1.1) mix aspirational ("establish market leadership") with measurable ("50,000 active users") without timeframes. "50,000 active users" by when? Year 1? Year 3? The SOM table in Section 12 suggests Year 1 target is 50K installs (not active users), which is a different metric.
- No explicit discussion of team composition, hiring plan, or resource allocation. The estimated monthly cost of $12-38/month (from 03-technical-architecture.md Section 10.2) suggests a solo or very small team, but this is never addressed strategically.

### 02-feature-specifications.md

**Strongest elements:**
- Feature specifications are remarkably detailed. Features like Post-Mortem Analysis (Activity section), Acting In Behaviors, and the Panic Button with Biometric Awareness show deep domain expertise in addiction recovery workflows.
- User stories are well-formed and acceptance criteria are in Given/When/Then format throughout.
- Edge cases are thoughtfully addressed for most features (e.g., coercive control safeguards in Feature 9, age verification circumvention in Feature 1, accidental relapse logging in Feature 3).
- The emotional safety philosophy is consistent across features -- compassionate messaging, no shame language, growth framing. This is a genuine product differentiator.
- Suicidal ideation detection with on-device-only processing (consistent with zero-knowledge architecture) shows careful ethical thinking.
- The Temptation Timer / Urge Surfing Tool is a particularly well-designed intervention that translates clinical science (urge wave theory) into compelling UX.

**Weaknesses:**
- The document is enormous (3000+ lines). While thoroughness is valuable, a development team would struggle to navigate this without an index, feature dependency map, or sprint assignment structure. Recommendation: Add a feature dependency graph showing which features block which others, and a suggested build order.
- Priority assignments need review (see Section 5 below for detailed analysis).
- Several features have no user stories or acceptance criteria -- they are described as "Summary" only. These include: Feature 6 (Analytics Dashboard), Feature 7 (Premium Advanced Analytics), Feature 10 (Branding), Feature 11 (Tenancy), Feature 12 (DSR), Feature 13 (Data Backup). These need to be brought to the same standard as the other features before development.
- The Activity sections after the main Feature sections (starting at Section 4.3) have inconsistent depth. Some activities (Post-Mortem Analysis, Acting In Behaviors, Financial Tracker, Weekly/Daily Goals, Meetings Attended) are extremely detailed. Others are brief summaries. Activities that are marked P0 but lack full specifications include: several of the remaining activities not fully visible in my review. These need to be completed.
- Feature 15 (WebKit Content Filter) is marked P1 but depends on platform-specific APIs (WebKit Content Rule List, Network Extension, Android VPN) that have significant implementation complexity and App Store review risk. Apple has historically been restrictive about Network Extension and VPN entitlements for non-MDM apps. This feature should be flagged as high technical risk.
- Feature 16 (Panic Button with Biometric Awareness) -- the facial expression analysis via on-device ML is technically ambitious. Training a model to reliably detect "stress markers" and "pre-urge states" from facial expressions is a research-grade ML challenge, not a standard engineering task. The P2 designation for the biometric layer is appropriate, but the document should acknowledge that this may require significant R&D or a third-party ML model.

### 03-technical-architecture.md

**Strongest elements:**
- The zero-knowledge architecture (Section 10.3.2) is exceptionally well-specified. The scope definition (which content is encrypted, which is not), key management strategy, and implications (no server-side search) demonstrate genuine understanding of the engineering trade-offs.
- The offline-first conflict resolution strategy (FR4.3) is domain-specific and thoughtful -- "most conservative value wins" for sobriety dates and "union merge" for urge logs show awareness of the recovery context.
- Security architecture has 14 subsections covering authentication, E2E messaging, key management, secure delete, ephemeral mode, data minimization, audit trails, analytics privacy, tenant isolation, backup architecture, incident response, data residency, and mandated reporting. This is comprehensive.
- The mandated reporting section (10.3.14) addresses a genuinely difficult legal question with a clear, defensible position rooted in the zero-knowledge architecture.
- Cost estimate of $12-38/month post-free-tier for AWS serverless is realistic for early-stage traffic.

**Weaknesses:**
- No data model or schema is provided. For a DynamoDB-based architecture, the access patterns and partition key design are critical to get right early. The document should include at least a high-level entity-relationship diagram and the primary access patterns.
- No API specification. Even a high-level API surface (endpoints, request/response shapes, authentication flow) would significantly accelerate development.
- The technology stack table mentions "Go (preferred), Node.js (acceptable)" for Lambda functions but provides no guidance on when to use which. This will create inconsistency if multiple developers are involved.
- NFR scalability targets (500,000 concurrent users, 10,000 writes/second) are orders of magnitude beyond what the business plan projects for Year 3 (~42K paying subscribers in the optimistic case). While it is good to design for scale, these targets could drive premature optimization. Recommendation: Define target scalability for launch vs. Year 1 vs. Year 3, and note which NFRs are aspirational vs. required.
- The Content Moderation Plan (Section 5.3) describes community content moderation but does not address custom affirmation review or recovery story moderation in technical terms (queue structure, ML-assisted screening, moderator tooling). The content strategy document describes moderation requirements, but the technical architecture does not specify how to build them.
- No CI/CD pipeline specification beyond "GitHub Actions." For a Flutter + Go + AWS CDK stack, the build, test, and deployment pipeline deserves more detail.
- HIPAA compliance is mentioned as "targeted for Phase 2" for the Therapist Portal, but the document does not specify what changes are required to achieve HIPAA compliance or what the gap analysis looks like. This is a critical dependency for the B2B2C therapist channel.

### 04-content-strategy.md

**Strongest elements:**
- Content tiers are clearly defined with a logical freemium/premium split.
- The affirmation rotation logic (triggers 40%, favorites 30%, under-served 20%, random 10%) with contextual override is a thoughtful algorithmic design.
- Memory verse packs with a modified Leitner spaced repetition system and 5 quiz modes show genuine investment in the learning experience.
- The content licensing status table (Section 12) with fallback strategies for each item demonstrates proactive risk management. This is one of the most valuable sections across all four documents.
- Bible translation support is comprehensive (8 English, 4+ Spanish, Catholic-specific Spanish options).
- The localization section properly addresses cultural adaptation vs. literal translation, with specific callouts for notification register in Spanish.

**Weaknesses:**
- No content production timeline or volume estimates. How many affirmations need to be written before launch? How many devotionals? Who writes them? What is the cost? The licensing table identifies external content, but the original content creation plan is absent.
- Recovery Stories (Section 6) requires 20-30 seed stories before launch and a moderation pipeline, but there is no estimate of moderation effort or volunteer/staff requirements.
- The book recommendation list (Section 7) is extensive but includes no verification that affiliate link programs exist for all listed retailers, or what the expected affiliate revenue contribution is.
- Podcast directory (Section 8) lists specific shows but does not address the maintenance burden of keeping external links and RSS feeds current. Some of the listed podcasts may become inactive.
- Music/Spotify playlists (Section 10) assume Regal Recovery will create and maintain official Spotify playlists, but there is no owner identified for ongoing playlist curation.
- The content strategy does not address content versioning or how content updates are pushed to users who have downloaded content for offline use.

---

## 3. Cross-Document Consistency

### Positive Consistency

- The four-document structure with cross-references at the top of each file works well.
- Feature numbering (Feature 1-30) is consistent between the strategic PRD (Section 4) and the feature specifications document.
- The content licensing table appears identically in both `01-strategic-prd.md` (Section 8.5) and `04-content-strategy.md` (Section 12). While redundancy is usually a maintenance risk, the licensing table is important enough that having it in both locations is defensible. However, if one is updated and the other is not, inconsistency will arise quickly.
- Privacy architecture is consistent: zero-knowledge scope, encryption approach, and audit trail requirements match across the technical architecture and feature specifications.
- Subscription tiers and pricing are consistent between the strategic PRD (Section 12.5) and content strategy (Section 1).
- Bible translation support is consistent across Feature 2 (Profile Management), Feature 4 (Content/Resources), and the content strategy document.

### Inconsistencies Found

1. **Free Trial terminology.** The strategic PRD (Section 12.5) describes "Free Trial" as one of the subscription tiers with variable lengths (7-day organic, 14-day partner, 30-day therapist). However, the content strategy (Section 1) lists "Free Trial" as a tier alongside Premium and Premium+. The feature specifications (Feature 4 acceptance criteria) mention "a free account" as distinct from a trial. The distinction between "Free tier" (permanent, limited features), "Free Trial" (time-limited, full features), and the various trial lengths needs to be clarified in a single canonical location. Currently, a developer reading Feature 4 might interpret "free account" as a permanent free tier, while the pricing table suggests all free access is trial-based.

2. **Financial Tracker privacy defaults.** Feature 9 (Community) states role defaults: "Accountability Partner/Sponsor see all except journal and financial." But the Financial Tracker activity states: "Spouse/Counselor/Coach can view by default; Accountability Partner/Sponsor can view by default." These contradict each other. The Financial Tracker should align with the Community permission defaults where AP/Sponsor cannot see financial data by default.

3. **Content Filter priority.** Feature 15 (WebKit Content Filter) is marked P1 in the feature specifications. But the strategic PRD's competitive positioning repeatedly emphasizes that Regal Recovery will "integrate filtering directly into the recovery platform" and uses this as a key differentiator against Covenant Eyes. If content filtering is genuinely a competitive differentiator, it should be P0 for the launch that includes Premium+ tier. If it is P1, the competitive positioning claims need to be softened. Currently the documents send mixed signals about whether content filtering is a launch feature or a post-launch addition.

4. **Recovery Health Score inputs.** Feature 18 defines the score composition with 5 weighted dimensions. The Feature 3 (Tracking System) acceptance criteria mention "recovery stages" that change content recommendations and check-in questions. But the Recovery Health Score does not reference recovery stages at all. These two concepts (stage-based adaptation and the health score) appear to operate independently when they should be integrated.

5. **Offline scope discrepancy.** Feature 23 (Offline-First) is marked P0 and states "All core recovery functionality works offline." The table in Feature 23 lists "Community Messaging" as having offline capability ("Read cached messages; new messages queued for sync"). But Feature 9 (Community) does not mention offline behavior at all. The offline capability of community features should be defined in Feature 9 or cross-referenced clearly.

6. **ARPU inconsistency.** The content strategy (Section 1) states "ARPU: $1.50/month" while the strategic PRD's revenue modeling (Section 12.5) calculates Year 3 blended ARPU at $87-$164/year ($7.25-$13.67/month). The $1.50/month figure appears to be ARPU across ALL users (including free), while the revenue modeling calculates ARPU for paying users only. This should be clarified to avoid confusion.

7. **Notification Strategy.** The strategic PRD (Section 4) references "Section 4.11" for the Notification Strategy. The feature specifications document describes notification behavior within individual features but the centralized Notification Strategy section (4.11) was not visible in the portions I reviewed. If it exists, it should be easier to find. If it does not exist as a consolidated section, it needs to be written -- currently, notification behavior is scattered across 15+ features with no single source of truth for priority hierarchy, daily caps, or quiet hours.

---

## 4. Structural Recommendations

### 4.1 Add an MVP Definition

The most critical missing piece across all four documents is an explicit MVP definition. The documents describe 30 features, 29 activities, 5 assessment tools, and a notification strategy. No development team can build all of this simultaneously. The documents need a clear "Version 1.0" scope that identifies the minimum feature set required to:
- Validate the core business hypothesis
- Deliver value to early users
- Generate initial revenue
- Test the therapist referral channel

**Recommended MVP scope (suggested):**
- Feature 1 (Onboarding, P0 Fast Track only)
- Feature 2 (Profile Management)
- Feature 3 (Tracking System)
- Feature 12 (Data Subject Rights)
- Feature 21 (Meeting Finder, basic)
- Feature 23 (Offline-First, core scope)
- Activity: Daily Sobriety Commitment
- Activity: Christian Affirmations (basic pack)
- Activity: Urge Logging & Emergency Tools
- Activity: Journaling/Jotting
- Activity: Recovery Check-ins
- Activity: FASTER Scale
- Basic content (freemium affirmations, devotionals, prayers)
- Basic notifications (morning/evening commitment, milestone celebrations)

This would deliver the "digital recovery companion" core value proposition in a buildable scope. Features like the Therapist Portal (Feature 17), Content Filter (Feature 15), Couples Mode (Feature 26), Community (Feature 9), and the AI Agent (Feature 8) would follow in subsequent releases.

### 4.2 Add a Feature Dependency Map

Several features have implicit dependencies that are not documented:
- Feature 18 (Recovery Health Score) depends on Features 3, 5, 6, and most activities
- Feature 28 (Content Trigger Log) depends on Feature 15 (Content Filter)
- Feature 26 (Couples Mode) depends on Feature 9 (Community permissions)
- Feature 7 (Premium Advanced Analytics) depends on Feature 6 (Analytics Dashboard)
- Feature 20 (Superbill/LMN) depends on establishing a clinical partner entity

A visual dependency graph would help the development team plan build order and identify critical path items.

### 4.3 Consolidate or Split the Feature Specifications Document

At 3000+ lines, `02-feature-specifications.md` is too large for practical use. Consider splitting it into:
- `02a-core-features.md` (Features 1-5, P0/P1 features)
- `02b-platform-features.md` (Features 6-17, platform capabilities)
- `02c-advanced-features.md` (Features 18-30, P2/P3 features)
- `02d-activities.md` (All activities)
- `02e-assessments-and-notifications.md` (Assessment tools and notification strategy)

Alternatively, maintain the single file but add a comprehensive table of contents with line-anchored links.

### 4.4 Standardize Feature Specification Depth

Features 10 (Branding), 11 (Tenancy), 12 (DSR), and 13 (Data Backup) have "Summary" descriptions without user stories or acceptance criteria. These should be brought to the same standard as other features before entering development. Features 6 and 7 (Analytics Dashboards) also lack acceptance criteria.

---

## 5. Prioritization Assessment

### Priority Assignments That Appear Sound

| Feature | Priority | Assessment |
|---------|----------|------------|
| Feature 1: Onboarding | P0 | Correct -- no app without onboarding |
| Feature 2: Profile Management | P0 | Correct -- foundational |
| Feature 3: Tracking System | P0 | Correct -- core value proposition |
| Feature 12: Data Subject Rights | P0 | Correct -- legal requirement |
| Feature 21: Meeting Finder | P0 | Correct -- high first-week value for users without support networks |
| Feature 23: Offline-First (core) | P0 | Correct -- users in crisis need offline access |
| Activity: Daily Sobriety Commitment | P0 | Correct -- primary daily engagement loop |
| Activity: Affirmations | P0 | Correct -- daily value delivery |
| Activity: Urge Logging | P0 | Correct -- crisis intervention |
| Activity: Journaling | P0 | Correct -- core recovery tool |
| Activity: FASTER Scale | P0 | Correct -- foundational clinical tool referenced by 10+ features |
| Feature 8: Recovery Agent | P3 | Correct -- AI is complex, not essential for MVP |
| Feature 30: Spotify Integration | P3 | Correct -- nice-to-have with significant SDK complexity |

### Priority Assignments That Need Reconsideration

| Feature | Current Priority | Recommended | Rationale |
|---------|-----------------|-------------|-----------|
| Feature 4: Content/Resources System | P1 | P0 | Without content delivery infrastructure, affirmations, devotionals, and prayers cannot be served. This is a platform dependency, not a standalone feature. |
| Feature 5: Commitments System | P1 | P0 | The Daily Sobriety Commitment (P0 activity) depends on the Commitments System. If the activity is P0, the system must also be P0. |
| Feature 15: WebKit Content Filter | P1 | P2 | This is a high-risk, high-complexity feature with App Store review uncertainty. Building it before validating core recovery tools is premature. The competitive positioning against Covenant Eyes should not drive a P1 priority for a feature that may require 3-6 months of platform-specific engineering. |
| Feature 17: Therapist Portal | P1 | P1 (but Phase 2) | The therapist portal is the B2B2C growth engine, but it is a web application in addition to the mobile app. Building it alongside the mobile MVP would split development resources. Recommend building it as the first post-MVP feature. |
| Feature 18: Recovery Health Score | P1 | P2 | The score requires 7+ days of data and depends on multiple input features. It provides value only after users have established habits. It cannot deliver value in the first weeks and should follow the features it depends on. |
| Feature 19: Achievement System | P1 | P2 | Gamification is a retention feature, not an acquisition or activation feature. Basic milestone celebrations (part of Feature 3) are sufficient for MVP. The full achievement system, AR coin viewing, and digital sobriety coins can follow. |
| Activity: Guided 12 Step Work | P2 | P1 | Step work is a primary recovery activity for the target audience. While P2 is defensible for MVP, it should be early in the post-MVP roadmap. |
| Activity: PCI | P2 | P2 (confirm licensing first) | PCI is marked P2 and depends on licensing from Patrick Carnes. The licensing status is "Pending." PCI should not be scheduled for development until licensing is confirmed or the fallback "Personal Warning Index" is specified in detail. |

### Priority Gaps

The following items have no explicit priority assignment:
- Assessment Tools (Family Impact, Denial, Addiction Severity, Relationship Health, SAST-R) -- these are listed in the feature overview but not individually prioritized
- Notification Strategy -- the overall notification architecture is not prioritized as a deliverable
- B2B Tenancy and White-Labeling (Features 10, 11) -- marked P2, which is appropriate, but the Year 3 revenue model includes white-label revenue. If white-labeling is a Year 3 revenue target, the architecture must support it from the beginning even if the UI is not built until P2.

---

## 6. Technical Feasibility Concerns

### High Risk

1. **WebKit Content Filter (Feature 15).** Apple's Network Extension entitlement requires justification during App Store review. VPN-based DNS filtering on Android competes with corporate VPNs. The on-device ML model for content classification requires training data, ongoing model updates, and device-specific optimization. This feature alone could consume 3-6 months of a senior engineer's time. The feature specification acknowledges some of this but underestimates the App Store review risk.

2. **Facial Expression ML for Panic Button (Feature 16).** Training a model to detect "pre-urge states" from facial expressions is a novel ML application without established benchmarks. The fallback to text-based intervention is well-designed, but the document should be explicit that the biometric learning feature (P2) is speculative and may not achieve clinical reliability.

3. **Zero-Knowledge Architecture + AI Agent (Feature 8 + Section 10.3.2).** The AI Agent needs access to user recovery data to provide personalized responses. The zero-knowledge architecture encrypts all user-generated text on-device. The document states "decryption happens on-device; the agent receives only the decrypted context necessary for the current conversation turn." This implies the LLM runs on-device (significant model size and performance constraints) or that decrypted data is sent to a server-side LLM (which violates zero-knowledge for the duration of the API call). This architectural tension needs explicit resolution. Options: (a) on-device small language model, (b) server-side LLM with ephemeral processing and explicit user consent per interaction, (c) hybrid approach. Each has trade-offs that should be documented.

4. **Signal Protocol for Messaging (Section 10.3.3).** Implementing Signal Protocol (Double Ratchet) correctly is notoriously difficult. Most teams use libsignal-protocol rather than implementing from scratch. The document should specify whether this will be a library integration or custom implementation, and budget accordingly.

### Medium Risk

5. **Credential Verification for Therapist Portal (Feature 17).** Automated license verification against state licensing board databases is not standardized. Each state has different APIs (or none). This is typically handled by third-party credentialing services (e.g., CAQH, Medallion) at significant per-verification cost. The document should specify the verification approach and cost model.

6. **Jurisdiction-Aware Data Residency (Section 10.3.13).** Running multi-region DynamoDB with per-user data residency is architecturally complex. DynamoDB Global Tables replicate data across regions; keeping specific user data in specific regions requires custom routing logic. This is achievable but adds significant operational complexity and cost. For a pre-revenue app, a single-region architecture with plans for multi-region would be more pragmatic.

7. **Apple Health / Google Fit integration** for sleep and exercise data requires ongoing maintenance as APIs evolve. Health Connect on Android (replacing Google Fit) is still maturing. The data minimization approach (Section 10.3.7) is well-specified, but the integration maintenance burden should be acknowledged.

### Low Risk (Well-Managed)

8. **Offline-first with DynamoDB sync** -- the conflict resolution strategy (FR4.3) is well-designed and domain-appropriate. The "union merge" for recovery data and "most conservative value" for sobriety dates are correct choices.

9. **Flutter + Go Lambda** -- this is a proven stack for this type of application. Flutter's single-codebase approach is well-suited for the iOS/Android/Web target.

---

## 7. Security and Privacy Assessment

### Strengths

The security architecture is genuinely impressive for a pre-launch product document:

- **Zero-knowledge scope is well-defined.** The explicit list of what is and is not encrypted (Section 10.3.2) avoids the common trap of claiming "zero-knowledge" without specifying the boundary. The acknowledgment that server-side search is impossible is honest and important.
- **Cryptographic erasure** for account deletion and ephemeral mode is the right approach and goes beyond what most apps offer.
- **Audit trail** with user-visible "Who Accessed My Data" screen demonstrates genuine user empowerment.
- **QUITTR breach** is used effectively as a cautionary tale that justifies the privacy-first architecture.
- **Screenshot prevention** on sensitive screens using platform APIs is a thoughtful detail for this user population.
- **Biometric app lock** separate from device unlock adds a meaningful security layer for shared-device scenarios.

### Concerns

1. **Key recovery via passphrase.** Section 10.3.2 states: "Key recovery via a user-held recovery passphrase generated during onboarding (stored offline by user)." This is the right design, but the user experience risk is high. If users lose their recovery passphrase, all their encrypted data is irrecoverable -- by design. The onboarding flow should make this consequence extremely clear and prompt the user to store the passphrase securely. The document should specify how the passphrase is presented (printable PDF? QR code? plain text?) and what UX safeguards prevent users from skipping this step.

2. **Arousal Template separate passphrase.** Section 10.3.4 describes an additional layer with a "separate user-specific key derived from a user passphrase, not stored anywhere." This means users have two passphrases to manage (one for general recovery, one for arousal template). The UX burden of managing two separate passphrases should be acknowledged and mitigated.

3. **Differential privacy for analytics** (Section 10.3.9) is mentioned but not specified. What epsilon value? What noise mechanism? "Differential privacy techniques" is a marketing claim without implementation detail. Either specify the mechanism or soften the claim to "privacy-preserving analytics with data aggregation."

4. **Per-user KMS CMKs** (Section 10.3.4) at scale could be expensive. AWS KMS charges $1/month per CMK. At 50,000 users, that is $50,000/month in KMS costs alone, far exceeding the $12-38/month infrastructure estimate. The architecture should specify whether these are truly per-user CMKs or whether a different key hierarchy (e.g., per-user data keys encrypted by a shared CMK) is used. AWS KMS allows generating data keys from a CMK, which is the more practical pattern.

5. **No HIPAA BAA mentioned.** The Therapist Portal targets licensed professionals viewing patient data. While the document notes "HIPAA-adjacent" practices for launch, it should acknowledge that a Business Associate Agreement with AWS (free to establish) is a prerequisite if any PHI transits the system. This should be a Day 1 requirement, not Phase 2.

---

## 8. Business Model and Monetization Feedback

### Strengths

- The freemium model with generous free tier is the right call for a stigma-heavy category. The "7-day journaling history limit" as a loss-aversion conversion lever is particularly clever.
- Variable trial lengths by referral source is smart segmentation.
- "Unlocked forever" content packs build trust in a user population that has been burned by aggressive monetization (QUITTR).
- Geographic pricing with PPP adjustment for Latin America is necessary for the Spanish-language market.
- The B2B2C therapist channel analysis is strong. The observation that only 2,000-3,000 CSATs exist in the U.S. with no standard recommended app identifies a genuine "formulary" opportunity.

### Concerns

1. **Revenue projections vs. development cost.** The conservative Year 1 D2C revenue is $45,400. Even the moderate scenario is $192,000. A development team capable of building the MVP described in these documents (Flutter app + Go backend + DynamoDB + zero-knowledge encryption + offline sync + content management) would cost $300K-$600K/year in salary alone. The business model needs to address pre-revenue funding, personal runway, or a phased development approach that generates revenue earlier.

2. **Content pack economics.** The "unlocked forever" model means content pack revenue is a one-time event per user per pack. The revenue modeling shows content packs as 20-26% of revenue, but this revenue does not recur. As the user base matures, content pack revenue will plateau while subscription revenue continues to grow. This is fine strategically but should be modeled explicitly in Year 3+ projections.

3. **Church licensing pricing.** $99/month for 15 users ($6.60/user/month) and $299/month for unlimited users are aggressive prices. Most churches have tight budgets and will compare this to free alternatives (Celebrate Recovery materials, Setting Captives Free). The value proposition for churches needs to be articulated separately from the individual user value prop.

4. **Founding Members offer.** "First 1,000 users get unlimited free Premium+ forever" is generous for building the review base, but it creates a permanent cohort of non-paying users who consume support resources and server costs. Consider capping at 200-500, or offering "lifetime Premium" (not Premium+) to reduce the ongoing cost of the commitment.

5. **App Store fees.** The revenue modeling uses blended 20-25% App Store fees. Apple charges 30% for the first year of a subscription and 15% thereafter (Small Business Program). Google charges 15% for the first $1M. The blended rate should be modeled more precisely by year, since Year 1 revenue will be mostly at 30% (new subscribers), while Year 3 will have more renewals at 15%.

---

## 9. Competitive Positioning Observations

### Strengths

- The 2x2 positioning matrix (Secular vs. Christian / Accountability vs. Recovery) clearly shows the open quadrant Regal Recovery targets.
- The competitor-by-competitor value propositions are sharp and specific.
- The QUITTR data breach is used effectively to justify the zero-knowledge architecture.
- The observation that Covenant Eyes' $23-27M ARR proves the Christian accountability niche alone can sustain a significant business is a strong data point.

### Concerns

1. **Feature completeness as differentiator vs. risk.** The document states: "Regal Recovery's comprehensive feature set...would represent the most feature-complete product in the market." While this is true on paper, feature completeness at launch is also the most common cause of failed product launches. The critical question identified in the document itself -- "whether the breadth of features creates a cohesive user experience or a cluttered one" -- deserves more attention. Progressive disclosure is mentioned in onboarding but not systematically applied to the feature set.

2. **Covenant Eyes rebrand to "Victory Shield."** This is noted in the competitive analysis. The rebrand may indicate Covenant Eyes is investing in broadening beyond accountability-only. Monitor whether Victory Shield adds recovery tools that would narrow Regal Recovery's differentiator.

3. **Relay's Y Combinator backing.** Relay has institutional funding and is growing. The competitive analysis correctly notes Relay's strengths, but the response -- "Regal Recovery provides the comprehensive individual toolkit that supports the other 167 hours between group sessions" -- is positioning, not a moat. If Relay adds individual tools, this positioning erodes. The true moat is the Christian integration + couples tools + therapist portal combination.

4. **Fortify's PaxAI.** Fortify has a shipping AI recovery coach. Regal Recovery's Recovery Agent (Feature 8) is P3. If AI-powered recovery coaching becomes table stakes (which the market is trending toward), Regal Recovery will be behind on this dimension unless it is reprioritized.

---

## 10. What Is Needed to Make This Production-Ready

### Critical (Must Address Before Development Starts)

1. **Define the MVP scope.** Choose 8-12 features/activities that constitute the launch product. Everything else goes on a post-launch roadmap with tentative timelines.

2. **Define the OMTM.** Pick one metric. Recommendation: Day-30 retention rate (for early validation) transitioning to Day-90 retention rate (for long-term measurement).

3. **Create a development roadmap with time estimates.** The PRD describes what to build but not when or how long. Break the MVP into 4-6 sprints with deliverables per sprint.

4. **Resolve the AI Agent + Zero-Knowledge tension.** Document the architectural approach for providing personalized AI responses while maintaining zero-knowledge encryption. This affects core architecture decisions.

5. **Address the KMS cost model.** Per-user CMKs at scale will exceed infrastructure budget by orders of magnitude. Design the key hierarchy before writing code.

6. **Resolve the Free Tier vs. Free Trial ambiguity.** Is there a permanent free tier or only a time-limited trial? The answer affects feature gating, database schema (subscription state machine), and the conversion funnel.

7. **Initiate content licensing outreach.** Multiple P0 features depend on licensed content (FASTER Scale, 12 Steps text). Licensing timelines are unpredictable. Start outreach immediately and design fallback implementations in parallel.

### Important (Should Address Before Beta)

8. **Design the data model and primary access patterns** for DynamoDB. This is an architectural decision that is expensive to change later.

9. **Specify the notification strategy** as a single, consolidated document with priority hierarchy, daily caps, quiet hours, and per-feature notification types.

10. **Write acceptance criteria for Features 6, 7, 10, 11, 12, 13.** These features currently have "Summary" descriptions only.

11. **Conduct a technical spike on the Content Filter (Feature 15)** to validate App Store feasibility before committing to it as a competitive differentiator.

12. **Establish a content production plan** with volume targets, writers/translators, review pipeline, and costs for the launch content set.

13. **Define the therapist credential verification approach** with cost model and provider selection.

### Nice to Have (Can Address During or After Beta)

14. Add wireframes or high-fidelity mockups linked from feature specifications.

15. Build a glossary of recovery terminology for the development team (FASTER Scale stages, FANOS/FITNAP frameworks, 3 Circles, etc.).

16. Create a privacy impact assessment document that consolidates all privacy decisions into a single reference.

17. Develop a content style guide for notification copy, error messages, and compassionate messaging patterns.

---

## 11. Summary

This PRD suite demonstrates exceptional domain expertise, research rigor, and product vision. The personas are among the best I have seen -- deeply empathetic, diverse, and actionable. The competitive analysis is fact-checked and honest. The security architecture is genuinely thoughtful. The feature specifications show deep understanding of addiction recovery workflows.

The primary risk is not quality of thinking -- it is scope management. The documents describe a product that would take a well-funded team years to build. The most valuable next step is to ruthlessly scope the MVP, define the OMTM, create a development roadmap, and resolve the handful of architectural tensions (AI + zero-knowledge, KMS cost model, free tier vs. trial) that would block the first sprint.

The product concept is sound, the market opportunity is real, and the competitive positioning is defensible. What is needed now is the discipline to ship a smaller version of this vision and validate it with real users before building the full platform.
