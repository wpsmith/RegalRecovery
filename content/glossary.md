# Recovery Terminology Glossary
**Developer Reference** | See also: [Strategic PRD](01-strategic-prd.md) · [Feature Specifications](02-feature-specifications.md)

This glossary defines recovery-specific terminology used throughout the Regal Recovery codebase and product documentation. Definitions are written for developers, not end users.

---

### FASTER Scale
A relapse-awareness tool developed by Michael Dye that maps six progressive stages leading to relapse. Each letter represents a stage: **F**orgetting Priorities, **A**nxiety, **S**peeding Up, **T**icked Off, **E**xhausted, **R**elapse. Users self-assess which stage they are currently in. The earlier someone identifies their position on the scale, the more effectively they can intervene before reaching relapse.

### FANOS
A structured couples check-in framework used in recovery communication. Each letter represents a topic area: **F**eelings, **A**ffirmations, **N**eeds, **O**wnership, **S**obriety. Partners take turns sharing in each category to foster honest, non-confrontational dialogue. The app supports guided FANOS check-ins as a spouse communication activity.

### FITNAP
An alternative structured check-in framework for couples or accountability conversations. Each letter represents: **F**eelings, **I**ntimacy, **T**riggers, **N**eeds, **A**ffirmations, **P**rayer. Similar in purpose to FANOS but with a different emphasis that includes explicit discussion of triggers and a spiritual component. The app supports both FANOS and FITNAP as configurable check-in formats.

### 3 Circles
A boundary-setting tool from 12-step recovery where behaviors are categorized into three concentric circles. The **inner circle (red)** contains bottom-line behaviors that constitute a break in sobriety (acting out). The **middle circle (yellow)** contains warning behaviors and slippery situations that often precede relapse. The **outer circle (green)** contains healthy behaviors and coping strategies that support recovery. Users define their own circles during onboarding and can update them over time.

### PCI (Personal Craziness Index)
A self-assessment tool created by Patrick Carnes that measures overall life manageability across multiple behavioral dimensions (e.g., sleep, nutrition, exercise, isolation, work habits). Users rate themselves on a set of indicators; a rising PCI score signals that life is becoming unmanageable, which historically correlates with increased relapse risk. The app tracks PCI scores over time and surfaces trend data in the Analytics Dashboard.

### SAST-R (Sexual Addiction Screening Test - Revised)
A validated clinical screening instrument used to assess the likelihood of sexual addiction. It measures behavioral patterns across multiple dimensions including preoccupation, loss of control, relationship disturbance, and affect disturbance. The app references SAST-R for initial assessment purposes but does not provide clinical diagnosis; users are directed to a CSAT for formal evaluation.

### SA vs SAA
**Sexaholics Anonymous (SA)** and **Sex Addicts Anonymous (SAA)** are both 12-step fellowships for sexual addiction recovery, but they differ in their sobriety definitions. SA defines sobriety strictly as no sex with self or anyone other than one's spouse (opposite-sex, married partner). SAA allows members to define their own inner-circle behaviors. Regal Recovery supports SA's sobriety definition for 12-step tracking; the app's sobriety tracker and relapse logic follow SA's definition exclusively.

### Celebrate Recovery
A Christ-centered 12-step recovery program that operates within churches and addresses a broad range of hurts, habits, and hang-ups (not limited to sexual addiction). The app supports users who participate in Celebrate Recovery by offering compatible tracking, devotionals, and step-work features, but the primary recovery framework is SA-aligned.

### CSAT (Certified Sex Addiction Therapist)
A clinical credential for therapists specializing in sexual addiction treatment, certified through the International Institute for Trauma and Addiction Professionals (IITAP). In the app, "counselor" roles in the Community feature may include CSATs. The export/report features are designed with CSAT sessions in mind as a primary use case.

### Acting In
Subtle, internalized addiction behaviors that occur within relationships, as opposed to "acting out" (overt addictive behaviors). Examples include emotional withdrawal, fantasy without external action, objectification of a partner, or dishonesty by omission. The app tracks Acting In behaviors as a separate activity category because they are often overlooked but are significant relapse indicators.

### Sobriety Definition (SA)
In Sexaholics Anonymous, sobriety is defined as no sex with self and no sex with anyone other than one's spouse (within the context of a heterosexual marriage). This is the strictest sobriety definition among sex addiction fellowships. The app's sobriety tracker, streak calculations, and relapse logging all follow this definition. A relapse resets the sobriety counter to zero.

### Arousal Template
A framework developed by Patrick Carnes that describes the constellation of thoughts, feelings, situations, and imagery that form an individual's sexual arousal patterns. Understanding one's arousal template is a key part of recovery therapy. In the app, arousal template data is treated as the highest privacy tier with separate encryption; even the Recovery Agent cannot access it.

### 12 Steps
The foundational framework of SA (and AA) recovery, consisting of twelve sequential steps that guide a person from admitting powerlessness through spiritual awakening and service to others. The steps include admission of powerlessness (Step 1), belief in a higher power (Steps 2-3), moral inventory (Steps 4-5), character defect work (Steps 6-7), making amends (Steps 8-9), and ongoing maintenance and service (Steps 10-12). The app supports step work tracking and journaling for each step.

### Betrayal Trauma
The psychological and emotional trauma experienced by partners and spouses of individuals with sexual addiction when they discover the addictive behavior. Symptoms often mirror PTSD and include hypervigilance, emotional dysregulation, and trust rupture. The app provides partner-specific features including betrayal trauma resources, spouse journaling, and support group finders under the Community feature.

### Recovery Health Score
The app's proprietary composite score ranging from 0-100 that provides a holistic measure of a user's recovery wellness. The score is calculated from multiple inputs including sobriety streak status, activity completion rates, check-in consistency, PCI trends, and community engagement. It is designed to give users a single at-a-glance indicator of their overall recovery trajectory. The algorithm and weighting are internal to the app.

### Integrity Inventory
The app's daily self-assessment tool that evaluates honesty and transparency across five dimensions of a user's life. Users rate themselves in each dimension, and the results feed into the Recovery Health Score and are tracked over time. The Integrity Inventory is designed to surface subtle patterns of dishonesty or compartmentalization that often precede relapse.

### Ephemeral Mode
A privacy feature that allows users to create journal entries or log activities that are automatically deleted after a configurable time period. Ephemeral entries are never included in backups or data exports. This feature exists for users who want to process sensitive thoughts without creating a permanent record, reducing anxiety about data exposure.

### Zero-Knowledge Architecture (Future Enhancement)
A security model where the server stores user data in encrypted form but never possesses the decryption keys. All encryption and decryption happens on the user's device. This means that even if the server is compromised, user content (journal entries, urge logs, check-in data) cannot be read by the server operator or any attacker. **This is a planned future enhancement.** The initial launch uses server-side AES-256 encryption at rest with TLS in transit. See [Future Features](05-future-features.md) for the full ZK specification.
