# Regal Recovery — Future Features
**Deferred features and architectural enhancements planned for future releases.**

---

## 1. WebKit Content Filter Accountability (Feature 15)

**Original Priority:** P1

**Description:** On-device content filtering and screen accountability system that monitors browsing activity, detects explicit content using AI, and sends accountability reports to the user's designated support contacts. Eliminates the need for a separate accountability product (Covenant Eyes, Ever Accountable) by integrating filtering directly into the recovery platform.

**User Stories:**
- As a **recovering user**, I want the same app that tracks my recovery to also monitor my browsing, so that I don't need to pay for and manage two separate products
- As a **recovering user**, I want explicit content blocked or flagged before I can access it, so that I have a safety net during moments of weakness
- As a **recovering user**, I want my accountability partner to receive browsing reports, so that I have external transparency without having to self-report
- As a **recovering user**, I want the monitoring to be privacy-respecting, so that only genuinely concerning activity is flagged — not every website I visit
- As a **spouse**, I want to receive accountability reports from my partner's device, so that I can see consistent transparency without having to ask or check
- As a **sponsor**, I want to see if my sponsee's browsing patterns are concerning, so that I can address digital triggers proactively

**Acceptance Criteria:**
- **Given** a recovering user has enabled content filtering at the "Warn" level, **When** they navigate to a page classified as explicit by the on-device ML model, **Then** a warning overlay is displayed with a 30-second delay and "Continue" or "Get Help" buttons, and the event is logged for the next accountability report
- **Given** a recovering user has designated an accountability partner, **When** the weekly accountability report is generated on Sunday, **Then** the partner receives a report containing a safety score (0-100), flagged event counts by category, and time-of-day browsing patterns without any specific URLs
- **Given** a recovering user changes their filter level from "Block" to "Monitor Only," **When** they confirm the change, **Then** a notification is queued for all designated accountability contacts with a 24-hour delay before the change takes effect
- **Given** a spouse is set as an accountability contact and instant alerts are enabled, **When** the recovering user accesses explicit content, **Then** the spouse receives an immediate alert containing the flagged category but no URL or screenshot
- **Given** a recovering user is browsing with content filtering active, **When** the on-device ML model classifies any page, **Then** no browsing data, URLs, or screenshots are transmitted to Regal Recovery servers
- **Given** a recovering user uninstalls the app while content filtering is enabled, **When** the uninstall is detected by the system, **Then** all designated accountability contacts are immediately notified that the app has been removed

**Technical Approach:**

The system uses Apple's WebKit Content Filter framework (iOS/macOS) and Android's Accessibility Service / VPN-based DNS filtering to provide on-device content analysis:

- **iOS:** WebKit Content Rule List API for Safari content blocking + Managed App Configuration for enterprise/MDM deployment. Screen Time API integration for usage reports. Network Extension framework for DNS-level filtering across all browsers.
- **Android:** VPN-based local DNS filtering (similar to Covenant Eyes' approach) that routes DNS queries through an on-device filter. Accessibility Service for in-app content detection.
- **On-device AI classification:** Lightweight ML model (CoreML on iOS, TensorFlow Lite on Android) trained to classify web content as safe/risky/explicit. Classification happens entirely on-device — no screenshots or browsing data sent to servers.
- **Accountability reports:** Weekly digest sent to designated accountability contacts showing: categories of flagged content (not URLs — preserving privacy for non-concerning browsing), time spent in risky categories, overall "safety score" for the week, and alerts for any explicit content access attempts.

**Filter Levels:**

| Level | Behavior | Use Case |
|---|---|---|
| Monitor Only | Content classified but not blocked; accountability report generated | Users who want transparency without restriction |
| Warn | Content classified; warning overlay shown with 30-second delay and "Continue" or "Get Help" buttons; activity logged and reported | Users who want friction, not hard blocks |
| Block | Explicit content blocked entirely; blocked attempt logged and reported | Users who want maximum protection |

Users select their filter level during setup. Accountability partners can request a minimum filter level (e.g., sponsor requests "Warn" or higher). Changes to filter level trigger a notification to accountability contacts with a 24-hour delay (preventing quick toggle-off-toggle-on circumvention).

**Accountability Report Content:**

- **Weekly Report (default):** Sent every Sunday to designated contacts
  - Overall safety score (0-100)
  - Number of flagged events by category (explicit, suggestive, risky)
  - Time-of-day pattern for browsing (without specific sites)
  - Any blocked access attempts
  - Any filter level changes
- **Instant Alert (optional, configurable):** Sent immediately when explicit content is accessed or blocking is circumvented
- **Monthly Summary:** Trend of weekly scores over the past month

**Privacy Safeguards:**

- All content classification happens on-device — no browsing data is transmitted to Regal Recovery servers
- Accountability reports show categories and patterns, not specific URLs or page content
- Non-explicit browsing (news, shopping, email, social media) is never included in reports
- Users can designate "private windows" for sensitive but non-concerning activities (banking, medical) that are excluded from classification
- Filter cannot be silently disabled — any change triggers a delayed notification to accountability contacts
- If user uninstalls the app, accountability contacts are immediately notified

**Device Coverage:**

- **Phase 1 (Launch):** iOS Safari + DNS-level filtering for all iOS browsers. Android VPN-based DNS filtering for all browsers.
- **Phase 2:** macOS Safari extension. Windows browser extensions (Chrome, Edge, Firefox).
- **Phase 3:** Smart TV and streaming device filtering (Roku, Fire TV, Apple TV) — stretch goal.

**Integration Points:**

- Accountability reports feed into the Analytics Dashboard (correlating browsing patterns with urge logs, mood data, and FASTER Scale results)
- Blocked content attempts auto-generate an urge log entry prompt: "We blocked a site for you. Would you like to log this as an urge?"
- Filter status visible in sponsor/counselor dashboard
- Content filter data included in the Recovery Health Score

**Pricing:**

- Content filtering included in **Premium+ tier** (not available in Free Trial or Premium tiers)
- This positions Premium+ as the top tier that replaces Covenant Eyes ($18/month) while offering dramatically more recovery functionality
- Standalone accountability products cost $9-$18/month; bundling this into Premium+ makes the tier an obvious value proposition

**Edge Cases:**

- VPN conflicts (user already runs a VPN for work) → Allow VPN passthrough mode with DNS filtering only
- User factory-resets device → Filter removed; accountability contacts notified immediately
- Multiple user profiles on shared device → Filter applies to the enrolled user's profile only
- False positives (medical content, art, news imagery) → "Report false positive" button on block/warn screen; ML model retrained from aggregated anonymized reports
- Offline browsing → Classification queued; report generated when connection restored

**Rationale for Deferral:** This feature requires significant platform-specific expertise (WebKit Content Rule List API, Network Extensions, Android VPN services, Accessibility Services), on-device ML model training, and rigorous cross-browser testing. It also introduces complex app review considerations on both iOS and Android. Deferring allows the core recovery platform to launch and stabilize first.

**Prerequisites for Implementation:**
- Stable core platform with established user base
- On-device ML model trained on content classification dataset
- Apple and Google app review approval for content filter capabilities (Network Extension entitlement on iOS)
- Premium+ subscription tier active with sufficient subscriber base to justify development investment
- Content Trigger Log (Feature 28) should launch alongside or after this feature

---

## 2. Zero-Knowledge Architecture + AI Agent Integration (Feature 8 + Section 10.3.2)

**Description:** Full zero-knowledge encryption for AI Agent (Recovery Chatbot) conversations, where all chatbot interactions are encrypted with user-derived keys and LLM inference happens entirely on-device, ensuring the server never has access to conversation content.

**Current State:** The AI Agent (Feature 8) specifies that "Agent conversations are E2E encrypted like messaging" and that "decryption happens on-device; the agent receives only the decrypted context necessary for the current conversation turn." However, practical implementation of fully zero-knowledge AI conversations requires client-side LLM inference, which is not yet feasible for the quality level needed.

**Full Zero-Knowledge AI Architecture (Deferred):**
- On-device LLM inference so that conversation content never leaves the device in plaintext
- User-derived encryption keys for all stored conversation history
- No server-side processing of conversation content
- Agent context retrieval via on-device decryption only

**Rationale for Deferral:** Current LLM inference requires server-side processing for acceptable response quality and latency. Running a sufficiently capable model entirely on-device is not practical with current mobile hardware. Sending conversation content to a server for inference — even temporarily — breaks the zero-knowledge guarantee. Rather than compromise on either AI quality or the ZK promise, the initial release will use standard encryption (TLS + at-rest) for chatbot conversations with user-explicit data sharing, and the full zero-knowledge chatbot architecture will be implemented when client-side LLM inference becomes practical.

**Prerequisites for Implementation:**
- On-device LLM inference with acceptable quality (requires advances in mobile AI hardware and model compression)
- Efficient on-device model that can handle recovery-domain conversations with theological accuracy
- Device hardware capable of running inference without significant battery drain or latency
- Established conversation encryption protocol that integrates with the existing zero-knowledge key management

---

## 3. Credential Verification & Revocation for Therapist Portal (Feature 17)

**Description:** Automated verification of therapist credentials (license number, issuing state/board, license type) against licensing board databases during portal registration, with ongoing periodic re-verification and automatic access revocation when credentials expire or are revoked.

**User Stories:**
- As a **platform administrator**, I want therapist credentials verified during portal registration, so that only licensed professionals access client data
- As a **client**, I want to be notified if my therapist's portal access is revoked, so that I know my data is no longer being viewed

**Acceptance Criteria:**
- **Given** a therapist registers for the portal, **When** they submit their professional credentials (license number, issuing state/board, license type), **Then** the system verifies the credentials against the relevant licensing board database before granting portal access, and the therapist cannot view any client data until verification is complete
- **Given** a therapist's license is revoked or expires, **When** the credential verification system detects the change (via periodic re-verification or manual report), **Then** the therapist's portal access is suspended immediately, all connected clients receive a notification that their therapist's access has been revoked, and the therapist loses access to all client data
- **Given** a client is notified that their therapist's portal access was revoked, **When** they view the notification, **Then** they see a clear explanation that the therapist can no longer view their data, and an option to reconnect if/when the therapist is re-licensed

**Edge Cases:**
- Therapist license is revoked or expires → Therapist portal access suspended immediately; all connected clients notified; therapist loses access to all client data; client can choose to reconnect if/when therapist is re-licensed.

**Rationale for Deferral:** Automated credential verification requires integration with 50+ state licensing board databases (each with different APIs, data formats, and access requirements). Many boards do not offer programmatic access, requiring manual verification workflows or third-party verification services (e.g., Verisys, NPDB). Building this for launch would significantly delay the Therapist Portal. Manual verification during onboarding provides adequate safety for the initial launch.

**Prerequisites for Implementation:**
- Third-party credential verification service integration (e.g., Verisys, NPDB, or similar)
- OR custom integrations with state licensing board APIs where available
- Manual verification workflow for boards without API access
- Periodic re-verification scheduling system
- Notification infrastructure for credential status changes

---

## 4. Signal Protocol for Messaging (Section 10.3.3)

**Description:** End-to-end encryption for all in-app messaging using Signal Protocol (Double Ratchet) or equivalent, providing forward secrecy and post-compromise security for conversations between users and their support network (spouse, sponsor, accountability partner, coach, counselor).

**Full Specification (Deferred):**
- All in-app messages between user and support network are end-to-end encrypted
- Uses Signal Protocol (Double Ratchet) or equivalent for forward secrecy and post-compromise security
- Message content unreadable by Regal Recovery servers at all times
- Key exchange occurs when support contact is added; re-keying on device change
- Message metadata (timestamps, sender/receiver IDs) is stored server-side for delivery; message content is not

**Rationale for Deferral:** Signal Protocol implementation requires significant cryptographic engineering expertise, careful key management (especially around multi-device support and key exchange), and thorough security auditing. The messaging feature itself needs to mature and prove product-market fit before investing in the cryptographic infrastructure. Initial messaging will use standard TLS encryption with server-side encrypted storage, which provides strong security for the initial release.

**Prerequisites for Implementation:**
- Mature messaging feature with established usage patterns
- Cryptographic engineering review and protocol selection
- Multi-device key synchronization design
- Key exchange UX for support contact onboarding
- Third-party security audit of the E2E implementation
- Device change and key recovery workflows

---

## 5. Key Recovery via User-Held Passphrase (Section 10.3.2)

**Description:** During onboarding, the system generates a recovery passphrase that the user stores offline. This passphrase can be used to recover the user-derived encryption key if the device is lost or replaced, ensuring continuity of access to zero-knowledge encrypted content.

**Rationale for Deferral:** The passphrase-based key recovery mechanism adds complexity to the onboarding flow at a critical moment (when users are often in crisis and need speed-to-value). It also introduces UX challenges around passphrase storage, user education, and the consequences of passphrase loss. Initial implementation will use device keychain only with standard account recovery, which covers the majority of use cases (same device, device upgrade via backup restore). Passphrase-based recovery will be added when the zero-knowledge architecture matures.

**Prerequisites for Implementation:**
- Stable zero-knowledge encryption architecture in production
- User education flow for passphrase generation and offline storage
- Passphrase-to-key derivation implementation (e.g., PBKDF2/Argon2)
- Recovery flow UX for new device setup with passphrase entry
- Testing for edge cases: passphrase loss, partial recovery, multi-device scenarios

---

## 6. Separate Passphrase for Arousal Template (Section 10.3.4)

**Description:** The arousal template receives an additional encryption layer using a separate user-specific key derived from a user passphrase that is not stored anywhere. If the passphrase is lost, arousal template data is irrecoverable by design, providing the highest privacy tier for this clinically sensitive data.

**Rationale for Deferral:** This feature depends on the passphrase-based key recovery infrastructure (see item 5 above) and adds another passphrase for users to manage. The UX burden of two separate passphrases (one for general ZK recovery, one for arousal template) is high and risks user confusion or data loss. Initial implementation will use the same field-level encryption as other sensitive data, which still provides strong protection. The separate passphrase will be added when the broader passphrase infrastructure is in place and user feedback confirms demand for this additional layer.

**Prerequisites for Implementation:**
- Passphrase-based key infrastructure from item 5 above
- Separate key derivation path for arousal template passphrase
- Clear UX distinguishing the two passphrases and their purposes
- Explicit user consent and education about irrecoverability
- Therapist Portal integration (therapist should understand the implications when recommending the arousal template tool)

---

## 7. Per-User KMS Customer Managed Keys (Section 10.3.4)

**Description:** Each user receives their own AWS KMS Customer Managed Key (CMK) for field-level encryption of structured sensitive data (sobriety dates, relapse history, PCI scores, FASTER Scale results, mood ratings), providing the strongest possible isolation between users' encrypted data.

**Rationale for Deferral:** AWS KMS charges $1/key/month for each CMK. At scale (e.g., 50,000 users), this represents $50,000/month in KMS costs alone — a significant expense for a startup. Per-user CMKs add defense-in-depth (compromising one key only exposes one user's data) but are not necessary for launch security posture.

**Prerequisites for Implementation:**
- User base exceeding 10,000 (where the security benefit justifies the cost)
- Revenue sufficient to absorb ~$1/user/month in KMS costs
- Key lifecycle management automation (creation, rotation, destruction at scale)
- Migration plan to per-user keys without data loss or downtime
- Cost optimization analysis (e.g., KMS key aliasing, multi-region key strategies)

---

## 8. Field-Level Encryption (Section 10.3.2 / 10.3.4)

**Description:** Encrypt specific sensitive fields (sobriety dates, relapse history, PCI scores, FASTER Scale results, mood ratings) individually within DynamoDB records using AWS KMS, so that even direct database access or backup leaks expose only ciphertext for those fields while non-sensitive fields remain queryable.

**Rationale for Deferral:** Field-level encryption prevents server-side queries against encrypted fields, which complicates features like Recovery Health Score, Analytics Dashboard, and Therapist Portal that need to aggregate or trend sensitive data. DynamoDB's automatic AES-256 server-side encryption already protects against the primary launch-stage threats (disk theft, unauthorized AWS access, backup leaks). Field-level encryption adds value when protecting against compromised application-layer access — a threat that matters more at scale with a larger team.

**Prerequisites for Implementation:**
- Core features (Recovery Health Score, Analytics, Therapist Portal) stable and shipped
- Clear threat model justifying field-level encryption beyond server-side encryption
- Application-layer decrypt-then-process patterns built into data access layer
- Performance testing to validate acceptable latency with KMS decrypt calls on hot paths
- Migration tooling to encrypt existing plaintext fields in-place
