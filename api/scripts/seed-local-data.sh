#!/usr/bin/env bash
# Seed MongoDB with comprehensive test data for Alex (primary test persona)
# Alex: 270-day sober user with realistic recovery data across all collections

set -euo pipefail

echo "Seeding comprehensive test data for Alex..."
echo ""

docker compose exec -T mongodb mongosh regal-recovery --eval '
// Drop database for idempotent seeding
db.dropDatabase();
print("✓ Dropped existing database for fresh seed");
print("");

// =============================================================================
// SECTION 1: USER & CORE PROFILE
// =============================================================================

db.users.insertOne({
  userId: "u_alex",
  tenantId: "DEFAULT",
  createdAt: ISODate("2025-07-04T00:00:00Z"),
  modifiedAt: ISODate("2026-03-31T00:00:00Z"),
  email: "alex@example.com",
  displayName: "Alex",
  role: "User",
  primaryAddictionId: "a_sa",
  preferredLanguage: "en",
  preferredBibleVersion: "ESV",
  timeZone: "America/Chicago",
  emailVerified: true,
  biometricEnabled: true,
  regionId: "us-east-1",
  subscriptionTier: "premium"
});
print("✓ Created user profile for Alex");

db.user_settings.insertOne({
  userId: "u_alex",
  tenantId: "DEFAULT",
  createdAt: ISODate("2025-07-04T00:00:00Z"),
  modifiedAt: ISODate("2026-03-31T00:00:00Z"),
  notificationPreferences: {
    dailyCheckIn: true,
    milestoneReminders: true,
    sponsorMessages: true
  },
  privacySettings: {
    shareStreakWithSponsor: true,
    allowAnalytics: true
  },
  displaySettings: {
    darkMode: true,
    fontSize: "medium"
  },
  securitySettings: {
    biometricEnabled: true,
    sessionTimeout: 30
  }
});
print("✓ Created user settings for Alex");

// =============================================================================
// SECTION 2: ADDICTIONS & STREAKS
// =============================================================================

db.addictions.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-07-04T00:00:00Z"),
    modifiedAt: ISODate("2025-07-04T00:00:00Z"),
    addictionId: "a_sa",
    type: "sex-addiction",
    sobrietyStartDate: "2025-07-04",
    isPrimary: true
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-07-04T00:00:00Z"),
    modifiedAt: ISODate("2025-07-04T00:00:00Z"),
    addictionId: "a_porn",
    type: "pornography",
    sobrietyStartDate: "2025-07-04",
    isPrimary: false
  }
]);
print("✓ Created 2 addiction records (SA primary, porn secondary)");

db.streaks.insertOne({
  userId: "u_alex",
  tenantId: "DEFAULT",
  createdAt: ISODate("2025-07-04T00:00:00Z"),
  modifiedAt: ISODate("2026-03-31T00:00:00Z"),
  addictionId: "a_sa",
  currentStreakDays: 270,
  longestStreakDays: 270,
  sobrietyStartDate: "2025-07-04",
  totalSoberDays: 270
});
print("✓ Created streak record (270 days)");

// =============================================================================
// SECTION 3: MILESTONES
// =============================================================================

db.milestones.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-07-05T12:00:00Z"),
    modifiedAt: ISODate("2025-07-05T12:00:00Z"),
    milestoneId: "m_1d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 1,
    achievedAt: ISODate("2025-07-05T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-07-07T12:00:00Z"),
    modifiedAt: ISODate("2025-07-07T12:00:00Z"),
    milestoneId: "m_3d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 3,
    achievedAt: ISODate("2025-07-07T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-07-11T12:00:00Z"),
    modifiedAt: ISODate("2025-07-11T12:00:00Z"),
    milestoneId: "m_7d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 7,
    achievedAt: ISODate("2025-07-11T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-07-18T12:00:00Z"),
    modifiedAt: ISODate("2025-07-18T12:00:00Z"),
    milestoneId: "m_14d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 14,
    achievedAt: ISODate("2025-07-18T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-07-25T12:00:00Z"),
    modifiedAt: ISODate("2025-07-25T12:00:00Z"),
    milestoneId: "m_21d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 21,
    achievedAt: ISODate("2025-07-25T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-08-03T12:00:00Z"),
    modifiedAt: ISODate("2025-08-03T12:00:00Z"),
    milestoneId: "m_30d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 30,
    achievedAt: ISODate("2025-08-03T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-09-02T12:00:00Z"),
    modifiedAt: ISODate("2025-09-02T12:00:00Z"),
    milestoneId: "m_60d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 60,
    achievedAt: ISODate("2025-09-02T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-10-02T12:00:00Z"),
    modifiedAt: ISODate("2025-10-02T12:00:00Z"),
    milestoneId: "m_90d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 90,
    achievedAt: ISODate("2025-10-02T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-11-01T12:00:00Z"),
    modifiedAt: ISODate("2025-11-01T12:00:00Z"),
    milestoneId: "m_120d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 120,
    achievedAt: ISODate("2025-11-01T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-12-31T12:00:00Z"),
    modifiedAt: ISODate("2025-12-31T12:00:00Z"),
    milestoneId: "m_180d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 180,
    achievedAt: ISODate("2025-12-31T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-30T12:00:00Z"),
    modifiedAt: ISODate("2026-03-30T12:00:00Z"),
    milestoneId: "m_270d",
    addictionId: "a_sa",
    type: "sobriety",
    days: 270,
    achievedAt: ISODate("2026-03-30T12:00:00Z"),
    celebrated: true,
    coinImageUrl: ""
  }
]);
print("✓ Created 11 milestones (1, 3, 7, 14, 21, 30, 60, 90, 120, 180, 270 days)");

// =============================================================================
// SECTION 4: DAILY ACTIVITIES (CHECK-INS, URGES, JOURNALS, MEETINGS, PRAYERS, EXERCISES)
// =============================================================================

db.check_ins.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-27T08:00:00Z"),
    modifiedAt: ISODate("2026-03-27T08:00:00Z"),
    checkInId: "ci_1",
    type: "daily",
    responses: {
      mood: 7,
      sleptWell: true,
      prayedToday: true,
      calledSponsor: false,
      attendedMeeting: false
    },
    score: 7,
    colorCode: "green"
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-28T08:15:00Z"),
    modifiedAt: ISODate("2026-03-28T08:15:00Z"),
    checkInId: "ci_2",
    type: "daily",
    responses: {
      mood: 6,
      sleptWell: false,
      prayedToday: true,
      calledSponsor: true,
      attendedMeeting: false
    },
    score: 6,
    colorCode: "yellow"
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-29T08:30:00Z"),
    modifiedAt: ISODate("2026-03-29T08:30:00Z"),
    checkInId: "ci_3",
    type: "daily",
    responses: {
      mood: 8,
      sleptWell: true,
      prayedToday: true,
      calledSponsor: true,
      attendedMeeting: false
    },
    score: 8,
    colorCode: "green"
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-30T08:00:00Z"),
    modifiedAt: ISODate("2026-03-30T08:00:00Z"),
    checkInId: "ci_4",
    type: "daily",
    responses: {
      mood: 9,
      sleptWell: true,
      prayedToday: true,
      calledSponsor: true,
      attendedMeeting: true
    },
    score: 9,
    colorCode: "green"
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-31T08:00:00Z"),
    modifiedAt: ISODate("2026-03-31T08:00:00Z"),
    checkInId: "ci_5",
    type: "daily",
    responses: {
      mood: 7,
      sleptWell: true,
      prayedToday: true,
      calledSponsor: false,
      attendedMeeting: false
    },
    score: 7,
    colorCode: "green"
  }
]);
print("✓ Created 5 daily check-ins (last 5 days)");

db.urges.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-05T22:30:00Z"),
    modifiedAt: ISODate("2026-03-05T22:30:00Z"),
    urgeId: "ur_1",
    addictionId: "a_sa",
    intensity: 6,
    triggers: ["stress", "loneliness"],
    notes: "Tough day at work. Took a walk and called my sponsor instead.",
    sobrietyMaintained: true,
    durationMinutes: 15
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-15T21:00:00Z"),
    modifiedAt: ISODate("2026-03-15T21:00:00Z"),
    urgeId: "ur_2",
    addictionId: "a_sa",
    intensity: 4,
    triggers: ["boredom", "idle-time"],
    notes: "Evening at home alone. Did push-ups and read scripture.",
    sobrietyMaintained: true,
    durationMinutes: 10
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-28T14:30:00Z"),
    modifiedAt: ISODate("2026-03-28T14:30:00Z"),
    urgeId: "ur_3",
    addictionId: "a_porn",
    intensity: 5,
    triggers: ["internet-browsing", "stress"],
    notes: "Closed browser immediately and went for a run. Victory!",
    sobrietyMaintained: true,
    durationMinutes: 8
  }
]);
print("✓ Created 3 urge logs (all sobriety maintained)");

db.journals.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-20T07:00:00Z"),
    modifiedAt: ISODate("2026-03-20T07:00:00Z"),
    entryId: "j_1",
    mode: "free-form",
    content: "Today I am reflecting on how far I have come. 260 days ago I could not imagine being here. God has been faithful through every struggle. The 3 circles exercise helped me see my boundaries more clearly.",
    emotionalTags: ["grateful", "hopeful", "peaceful"],
    prompt: "",
    isEphemeral: false
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-30T07:15:00Z"),
    modifiedAt: ISODate("2026-03-30T07:15:00Z"),
    entryId: "j_2",
    mode: "prompted",
    content: "The hardest part of my day was resisting the urge to isolate when I felt stressed. I am most grateful for my sponsor Marcus who picked up the phone at 9pm and talked me through it.",
    emotionalTags: ["grateful", "challenged"],
    prompt: "What am I most grateful for today, and what was the hardest part of my day?",
    isEphemeral: false
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-04-01T06:45:00Z"),
    modifiedAt: ISODate("2026-04-01T06:45:00Z"),
    entryId: "j_3",
    mode: "free-form",
    content: "Processing some shame today from past actions. Writing this down to let it go. God has forgiven me and I am choosing to forgive myself.",
    emotionalTags: ["processing", "shame", "healing"],
    prompt: "",
    isEphemeral: true,
    ephemeralDeleteAt: ISODate("2026-04-08T06:45:00Z"),
    expiresAt: ISODate("2026-04-08T06:45:00Z")
  }
]);
print("✓ Created 3 journal entries (1 ephemeral)");

db.meetings.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-25T19:00:00Z"),
    modifiedAt: ISODate("2026-03-25T19:00:00Z"),
    meetingId: "mt_1",
    meetingType: "SA",
    name: "Tuesday Night SA Group",
    location: "Community Church, Room 203",
    notes: "Good meeting. Shared my story about hitting 270 days. Got a lot of encouragement from the group.",
    durationMinutes: 90
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-30T10:00:00Z"),
    modifiedAt: ISODate("2026-03-30T10:00:00Z"),
    meetingId: "mt_2",
    meetingType: "SA",
    name: "Sunday Morning SA Step Study",
    location: "Community Church, Room 203",
    notes: "Working through Step 4. Tough but necessary work. Grateful for the accountability.",
    durationMinutes: 75
  }
]);
print("✓ Created 2 meeting attendance logs");

db.prayers.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-31T06:30:00Z"),
    modifiedAt: ISODate("2026-03-31T06:30:00Z"),
    prayerId: "pr_1",
    prayerType: "morning",
    content: "Lord, guide me through this day. Give me strength to resist temptation and wisdom to see Your hand in my recovery. Thank you for 270 days of sobriety.",
    durationMinutes: 10,
    isEphemeral: false
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-04-01T21:00:00Z"),
    modifiedAt: ISODate("2026-04-01T21:00:00Z"),
    prayerId: "pr_2",
    prayerType: "evening",
    content: "Thank you God for another day of freedom. I surrender my shame and fear to you.",
    durationMinutes: 5,
    isEphemeral: false
  }
]);
print("✓ Created 2 prayer logs");

db.exercises.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-30T06:00:00Z"),
    modifiedAt: ISODate("2026-03-30T06:00:00Z"),
    exerciseId: "ex_1",
    type: "running",
    durationMinutes: 30,
    calories: 300,
    source: "manual"
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-28T17:00:00Z"),
    modifiedAt: ISODate("2026-03-28T17:00:00Z"),
    exerciseId: "ex_2",
    type: "strength-training",
    durationMinutes: 45,
    calories: 250,
    source: "manual"
  }
]);
print("✓ Created 2 exercise logs");

// =============================================================================
// SECTION 5: CALENDAR ACTIVITIES (UNIFIED VIEW)
// =============================================================================

db.activities.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-31T08:00:00Z"),
    modifiedAt: ISODate("2026-03-31T08:00:00Z"),
    activityType: "check-in",
    summary: {
      score: 7,
      colorCode: "green"
    },
    sourceKey: "ci_5",
    date: "2026-03-31",
    timestamp: ISODate("2026-03-31T08:00:00Z")
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-30T07:15:00Z"),
    modifiedAt: ISODate("2026-03-30T07:15:00Z"),
    activityType: "journal",
    summary: {
      mode: "prompted",
      emotionalTags: ["grateful", "challenged"]
    },
    sourceKey: "j_2",
    date: "2026-03-30",
    timestamp: ISODate("2026-03-30T07:15:00Z")
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-30T10:00:00Z"),
    modifiedAt: ISODate("2026-03-30T10:00:00Z"),
    activityType: "meeting",
    summary: {
      meetingType: "SA",
      name: "Sunday Morning SA Step Study"
    },
    sourceKey: "mt_2",
    date: "2026-03-30",
    timestamp: ISODate("2026-03-30T10:00:00Z")
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-30T06:00:00Z"),
    modifiedAt: ISODate("2026-03-30T06:00:00Z"),
    activityType: "exercise",
    summary: {
      type: "running",
      durationMinutes: 30
    },
    sourceKey: "ex_1",
    date: "2026-03-30",
    timestamp: ISODate("2026-03-30T06:00:00Z")
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-03-31T06:30:00Z"),
    modifiedAt: ISODate("2026-03-31T06:30:00Z"),
    activityType: "prayer",
    summary: {
      prayerType: "morning",
      durationMinutes: 10
    },
    sourceKey: "pr_1",
    date: "2026-03-31",
    timestamp: ISODate("2026-03-31T06:30:00Z")
  }
]);
print("✓ Created 5 calendar activity entries");

// =============================================================================
// SECTION 6: SUPPORT NETWORK
// =============================================================================

db.support_contacts.insertOne({
  userId: "u_alex",
  tenantId: "DEFAULT",
  createdAt: ISODate("2025-07-10T10:00:00Z"),
  modifiedAt: ISODate("2025-07-10T10:00:00Z"),
  contactId: "sc_1",
  contactUserId: "u_marcus",
  role: "sponsor",
  displayName: "Marcus",
  email: "marcus@example.com",
  status: "accepted",
  invitedAt: ISODate("2025-07-10T10:00:00Z"),
  acceptedAt: ISODate("2025-07-10T10:30:00Z")
});
print("✓ Created support contact (Marcus as sponsor)");

db.permissions.insertOne({
  userId: "u_alex",
  tenantId: "DEFAULT",
  createdAt: ISODate("2025-07-10T10:30:00Z"),
  modifiedAt: ISODate("2025-07-10T10:30:00Z"),
  permissionId: "perm_1",
  contactId: "sc_1",
  contactUserId: "u_marcus",
  dataCategory: "streaks",
  accessLevel: "read",
  grantedAt: ISODate("2025-07-10T10:30:00Z")
});
print("✓ Created permission for sponsor (read streaks)");

// =============================================================================
// SECTION 7: AUTHENTICATION
// =============================================================================

db.sessions.insertOne({
  userId: "u_alex",
  tenantId: "DEFAULT",
  createdAt: ISODate("2026-03-31T08:00:00Z"),
  modifiedAt: ISODate("2026-03-31T08:00:00Z"),
  sessionId: "sess_1",
  deviceId: "dev_iphone_alex",
  ipAddress: "127.0.0.1",
  userAgent: "RegalRecovery/1.0 iOS/18.0",
  expiresAt: ISODate("2026-04-10T08:00:00Z")
});
print("✓ Created active session");

// =============================================================================
// SECTION 8: COMMITMENTS & GOALS
// =============================================================================

db.commitments.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-07-10T00:00:00Z"),
    modifiedAt: ISODate("2026-03-31T00:00:00Z"),
    commitmentId: "cmt_1",
    title: "Call sponsor daily",
    frequency: "daily",
    category: "accountability",
    isActive: true,
    currentStreakDays: 14,
    lastCompletedAt: ISODate("2026-03-31T20:00:00Z"),
    totalCompletions: 200
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-07-10T00:00:00Z"),
    modifiedAt: ISODate("2026-03-31T06:30:00Z"),
    commitmentId: "cmt_2",
    title: "Morning prayer",
    frequency: "daily",
    category: "spiritual",
    isActive: true,
    currentStreakDays: 180,
    lastCompletedAt: ISODate("2026-03-31T06:30:00Z"),
    totalCompletions: 240
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-07-15T00:00:00Z"),
    modifiedAt: ISODate("2026-03-30T10:00:00Z"),
    commitmentId: "cmt_3",
    title: "Attend SA meeting",
    frequency: "weekly",
    category: "meetings",
    isActive: true,
    currentStreakDays: 35,
    lastCompletedAt: ISODate("2026-03-30T10:00:00Z"),
    totalCompletions: 38
  }
]);
print("✓ Created 3 active commitments");

db.goals.insertMany([
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2025-10-01T00:00:00Z"),
    modifiedAt: ISODate("2026-03-15T00:00:00Z"),
    goalId: "g_1",
    title: "Complete Step 4 Inventory",
    description: "Write a thorough moral inventory of character defects and people harmed",
    targetDate: "2026-06-01",
    category: "step-work",
    status: "in-progress",
    progressPercent: 60,
    milestones: [
      { title: "List character defects", completed: true },
      { title: "List people harmed", completed: true },
      { title: "Write full narrative", completed: false },
      { title: "Review with sponsor", completed: false }
    ]
  },
  {
    userId: "u_alex",
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-02-01T00:00:00Z"),
    goalId: "g_2",
    title: "Reach 365 days of sobriety",
    description: "Celebrate one full year of freedom from sex addiction",
    targetDate: "2026-07-04",
    category: "sobriety",
    status: "in-progress",
    progressPercent: 74,
    milestones: [
      { title: "90 days", completed: true },
      { title: "180 days", completed: true },
      { title: "270 days", completed: true },
      { title: "365 days", completed: false }
    ]
  }
]);
print("✓ Created 2 goals");

// =============================================================================
// SECTION 9: CONTENT LIBRARY (AFFIRMATIONS, DEVOTIONALS, PROMPTS)
// =============================================================================

db.affirmation_packs.insertOne({
  tenantId: "DEFAULT",
  createdAt: ISODate("2026-01-01T00:00:00Z"),
  modifiedAt: ISODate("2026-01-01T00:00:00Z"),
  packId: "pack_christian",
  name: "Christian Affirmations",
  description: "44 biblical affirmations for daily recovery",
  tier: "free",
  price: 0,
  affirmationCount: 44,
  category: "christian"
});
print("✓ Created affirmation pack: Christian Affirmations");

db.affirmations.insertMany([
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    affirmationId: "aff_1",
    packId: "pack_christian",
    statement: "I am fearfully and wonderfully made.",
    scriptureReference: "Psalm 139:14",
    category: "christian",
    language: "en"
  },
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    affirmationId: "aff_2",
    packId: "pack_christian",
    statement: "I can do all things through Christ who strengthens me.",
    scriptureReference: "Philippians 4:13",
    category: "christian",
    language: "en"
  },
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    affirmationId: "aff_3",
    packId: "pack_christian",
    statement: "The Lord is my shepherd; I shall not want.",
    scriptureReference: "Psalm 23:1",
    category: "christian",
    language: "en"
  },
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    affirmationId: "aff_4",
    packId: "pack_christian",
    statement: "God is my refuge and strength, an ever-present help in trouble.",
    scriptureReference: "Psalm 46:1",
    category: "christian",
    language: "en"
  },
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    affirmationId: "aff_5",
    packId: "pack_christian",
    statement: "I am a new creation in Christ; the old has passed away.",
    scriptureReference: "2 Corinthians 5:17",
    category: "christian",
    language: "en"
  }
]);
print("✓ Created 5 Christian affirmations");

db.devotionals.insertMany([
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    day: 1,
    title: "A New Beginning",
    scripture: "2 Corinthians 5:17",
    scriptureText: "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!",
    reflection: "Every day in recovery is a fresh start. God does not define us by our past failures but by His redeeming love. Today, choose to walk in newness of life, knowing that your identity is secure in Christ."
  },
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    day: 2,
    title: "Strength for the Journey",
    scripture: "Isaiah 40:31",
    scriptureText: "But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.",
    reflection: "Recovery requires daily surrender. When we place our hope in the Lord, He renews us. The journey may be long, but His strength is sufficient for each step."
  },
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    day: 3,
    title: "Freedom from Shame",
    scripture: "Romans 8:1",
    scriptureText: "Therefore, there is now no condemnation for those who are in Christ Jesus.",
    reflection: "Shame is the enemy of recovery. God has removed our condemnation through Jesus. Do not let the accuser tell you that you are defined by your past. You are free."
  }
]);
print("✓ Created 3 devotional days");

db.prompts.insertMany([
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    promptId: "prompt_1",
    text: "What am I most grateful for today, and what was the hardest part of my day?",
    category: "daily",
    tags: [],
    order: 1
  },
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    promptId: "prompt_2",
    text: "What triggers did I encounter today, and how did I respond? What could I do differently next time?",
    category: "sobriety",
    tags: ["FASTER", "triggers"],
    order: 2
  },
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    promptId: "prompt_3",
    text: "What emotions am I experiencing right now? Where do I feel them in my body?",
    category: "emotional",
    tags: ["FANOS/FITNAP", "emotional-awareness"],
    order: 3
  },
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    promptId: "prompt_4",
    text: "What relationship brought me joy today? What relationship challenged me?",
    category: "relationships",
    tags: [],
    order: 4
  },
  {
    tenantId: "DEFAULT",
    createdAt: ISODate("2026-01-01T00:00:00Z"),
    modifiedAt: ISODate("2026-01-01T00:00:00Z"),
    promptId: "prompt_5",
    text: "How did I experience God today? Where did I see His hand at work?",
    category: "spiritual",
    tags: ["12-Step"],
    order: 5
  }
]);
print("✓ Created 5 journal prompts");

// =============================================================================
// SECTION 11: TIME JOURNAL (7 days of T-60 entries for Alex)
// =============================================================================

// Helper: generate ISO dates relative to "today" (2026-04-06)
var tjBaseDate = new Date("2026-04-06T00:00:00Z");
function tjDate(daysAgo) {
  var d = new Date(tjBaseDate);
  d.setUTCDate(d.getUTCDate() - daysAgo);
  return d.toISOString().slice(0, 10);
}
function tjISO(dateStr, timeStr) {
  return ISODate(dateStr + "T" + timeStr + "Z");
}

// Day 1 (6 days ago): 100% complete, all 24 slots filled
var day1Date = tjDate(6);
var day1Entries = [];
for (var h = 0; h < 24; h++) {
  var slot = (h < 10 ? "0" + h : "" + h) + ":00:00";
  var slotEnd = (h + 1 < 10 ? "0" + (h+1) : "" + (h+1 === 24 ? "00" : h+1)) + ":00:00";
  var isSleep = (h >= 22 || h < 6);
  var activity = isSleep ? "Sleeping" : (h < 9 ? "Morning routine" : (h < 12 ? "Work" : (h < 13 ? "Lunch" : (h < 17 ? "Work" : (h < 19 ? "Exercise/Dinner" : "Evening/Family")))));
  day1Entries.push({
    entryId: "tj_d1_" + h,
    userId: "u_alex",
    tenantId: "DEFAULT",
    entityType: "TimeJournalEntry",
    date: day1Date,
    slotStart: slot,
    slotEnd: slotEnd,
    mode: "t60",
    activity: activity,
    sleepFlag: isSleep,
    retroactive: false,
    autoFilled: isSleep,
    autoFillSource: isSleep ? "sleep-schedule" : null,
    createdAt: tjISO(day1Date, slot),
    modifiedAt: tjISO(day1Date, slot)
  });
}
db.timeJournalEntries.insertMany(day1Entries);
print("  Created Day 1 (" + day1Date + "): 24/24 slots filled (100%)");

// Day 1 aggregate
db.timeJournalDays.insertOne({
  dayId: "tjd_d1",
  userId: "u_alex",
  tenantId: "DEFAULT",
  entityType: "TimeJournalDay",
  date: day1Date,
  mode: "t60",
  totalSlots: 24,
  filledSlots: 24,
  completionScore: 1.0,
  status: "completed",
  overdueSlotCount: 0,
  streakEligible: true,
  lastUpdatedAt: tjISO(day1Date, "23:59:00"),
  createdAt: tjISO(day1Date, "00:00:00"),
  modifiedAt: tjISO(day1Date, "23:59:00")
});

// Day 2 (5 days ago): 92% complete, 22 of 24 slots
var day2Date = tjDate(5);
var day2Entries = [];
for (var h = 0; h < 24; h++) {
  if (h === 14 || h === 15) continue; // skip 2 afternoon slots
  var slot = (h < 10 ? "0" + h : "" + h) + ":00:00";
  var slotEnd = (h + 1 < 10 ? "0" + (h+1) : "" + (h+1 === 24 ? "00" : h+1)) + ":00:00";
  var isSleep = (h >= 22 || h < 6);
  day2Entries.push({
    entryId: "tj_d2_" + h,
    userId: "u_alex",
    tenantId: "DEFAULT",
    entityType: "TimeJournalEntry",
    date: day2Date,
    slotStart: slot,
    slotEnd: slotEnd,
    mode: "t60",
    activity: isSleep ? "Sleeping" : "Various activities",
    sleepFlag: isSleep,
    retroactive: false,
    autoFilled: isSleep,
    autoFillSource: isSleep ? "sleep-schedule" : null,
    createdAt: tjISO(day2Date, slot),
    modifiedAt: tjISO(day2Date, slot)
  });
}
db.timeJournalEntries.insertMany(day2Entries);
print("  Created Day 2 (" + day2Date + "): 22/24 slots filled (92%)");

db.timeJournalDays.insertOne({
  dayId: "tjd_d2",
  userId: "u_alex",
  tenantId: "DEFAULT",
  entityType: "TimeJournalDay",
  date: day2Date,
  mode: "t60",
  totalSlots: 24,
  filledSlots: 22,
  completionScore: 22.0/24.0,
  status: "completed",
  overdueSlotCount: 2,
  streakEligible: true,
  lastUpdatedAt: tjISO(day2Date, "23:59:00"),
  createdAt: tjISO(day2Date, "00:00:00"),
  modifiedAt: tjISO(day2Date, "23:59:00")
});

// Day 3 (4 days ago): 85% with 2 retroactive entries, 20 of 24 slots
var day3Date = tjDate(4);
var day3Entries = [];
for (var h = 0; h < 24; h++) {
  if (h === 10 || h === 11 || h === 16 || h === 20) continue; // skip 4 slots
  var slot = (h < 10 ? "0" + h : "" + h) + ":00:00";
  var slotEnd = (h + 1 < 10 ? "0" + (h+1) : "" + (h+1 === 24 ? "00" : h+1)) + ":00:00";
  var isSleep = (h >= 22 || h < 6);
  var isRetro = (h === 9 || h === 17); // 2 retroactive entries
  day3Entries.push({
    entryId: "tj_d3_" + h,
    userId: "u_alex",
    tenantId: "DEFAULT",
    entityType: "TimeJournalEntry",
    date: day3Date,
    slotStart: slot,
    slotEnd: slotEnd,
    mode: "t60",
    activity: isSleep ? "Sleeping" : "Various activities",
    sleepFlag: isSleep,
    retroactive: isRetro,
    retroactiveTimestamp: isRetro ? tjISO(day3Date, "22:00:00") : null,
    autoFilled: isSleep,
    autoFillSource: isSleep ? "sleep-schedule" : null,
    createdAt: isRetro ? tjISO(day3Date, "22:00:00") : tjISO(day3Date, slot),
    modifiedAt: isRetro ? tjISO(day3Date, "22:00:00") : tjISO(day3Date, slot)
  });
}
db.timeJournalEntries.insertMany(day3Entries);
print("  Created Day 3 (" + day3Date + "): 20/24 slots filled (83%), 2 retroactive");

db.timeJournalDays.insertOne({
  dayId: "tjd_d3",
  userId: "u_alex",
  tenantId: "DEFAULT",
  entityType: "TimeJournalDay",
  date: day3Date,
  mode: "t60",
  totalSlots: 24,
  filledSlots: 20,
  completionScore: 20.0/24.0,
  status: "completed",
  overdueSlotCount: 4,
  streakEligible: true,
  lastUpdatedAt: tjISO(day3Date, "23:59:00"),
  createdAt: tjISO(day3Date, "00:00:00"),
  modifiedAt: tjISO(day3Date, "23:59:00")
});

// Day 4 (3 days ago): 96% complete, 23 of 24 slots
var day4Date = tjDate(3);
var day4Entries = [];
for (var h = 0; h < 24; h++) {
  if (h === 13) continue; // skip 1 slot
  var slot = (h < 10 ? "0" + h : "" + h) + ":00:00";
  var slotEnd = (h + 1 < 10 ? "0" + (h+1) : "" + (h+1 === 24 ? "00" : h+1)) + ":00:00";
  var isSleep = (h >= 22 || h < 6);
  day4Entries.push({
    entryId: "tj_d4_" + h,
    userId: "u_alex",
    tenantId: "DEFAULT",
    entityType: "TimeJournalEntry",
    date: day4Date,
    slotStart: slot,
    slotEnd: slotEnd,
    mode: "t60",
    activity: isSleep ? "Sleeping" : "Various activities",
    sleepFlag: isSleep,
    retroactive: false,
    autoFilled: isSleep,
    autoFillSource: isSleep ? "sleep-schedule" : null,
    createdAt: tjISO(day4Date, slot),
    modifiedAt: tjISO(day4Date, slot)
  });
}
db.timeJournalEntries.insertMany(day4Entries);
print("  Created Day 4 (" + day4Date + "): 23/24 slots filled (96%)");

db.timeJournalDays.insertOne({
  dayId: "tjd_d4",
  userId: "u_alex",
  tenantId: "DEFAULT",
  entityType: "TimeJournalDay",
  date: day4Date,
  mode: "t60",
  totalSlots: 24,
  filledSlots: 23,
  completionScore: 23.0/24.0,
  status: "completed",
  overdueSlotCount: 1,
  streakEligible: true,
  lastUpdatedAt: tjISO(day4Date, "23:59:00"),
  createdAt: tjISO(day4Date, "00:00:00"),
  modifiedAt: tjISO(day4Date, "23:59:00")
});

// Day 5 (2 days ago): 100% complete
var day5Date = tjDate(2);
var day5Entries = [];
for (var h = 0; h < 24; h++) {
  var slot = (h < 10 ? "0" + h : "" + h) + ":00:00";
  var slotEnd = (h + 1 < 10 ? "0" + (h+1) : "" + (h+1 === 24 ? "00" : h+1)) + ":00:00";
  var isSleep = (h >= 22 || h < 6);
  day5Entries.push({
    entryId: "tj_d5_" + h,
    userId: "u_alex",
    tenantId: "DEFAULT",
    entityType: "TimeJournalEntry",
    date: day5Date,
    slotStart: slot,
    slotEnd: slotEnd,
    mode: "t60",
    activity: isSleep ? "Sleeping" : "Various activities",
    sleepFlag: isSleep,
    retroactive: false,
    autoFilled: isSleep,
    autoFillSource: isSleep ? "sleep-schedule" : null,
    createdAt: tjISO(day5Date, slot),
    modifiedAt: tjISO(day5Date, slot)
  });
}
db.timeJournalEntries.insertMany(day5Entries);
print("  Created Day 5 (" + day5Date + "): 24/24 slots filled (100%)");

db.timeJournalDays.insertOne({
  dayId: "tjd_d5",
  userId: "u_alex",
  tenantId: "DEFAULT",
  entityType: "TimeJournalDay",
  date: day5Date,
  mode: "t60",
  totalSlots: 24,
  filledSlots: 24,
  completionScore: 1.0,
  status: "completed",
  overdueSlotCount: 0,
  streakEligible: true,
  lastUpdatedAt: tjISO(day5Date, "23:59:00"),
  createdAt: tjISO(day5Date, "00:00:00"),
  modifiedAt: tjISO(day5Date, "23:59:00")
});

// Day 6 (yesterday): 88% complete, 21 of 24 slots
var day6Date = tjDate(1);
var day6Entries = [];
for (var h = 0; h < 24; h++) {
  if (h === 12 || h === 18 || h === 21) continue; // skip 3 slots
  var slot = (h < 10 ? "0" + h : "" + h) + ":00:00";
  var slotEnd = (h + 1 < 10 ? "0" + (h+1) : "" + (h+1 === 24 ? "00" : h+1)) + ":00:00";
  var isSleep = (h >= 22 || h < 6);
  day6Entries.push({
    entryId: "tj_d6_" + h,
    userId: "u_alex",
    tenantId: "DEFAULT",
    entityType: "TimeJournalEntry",
    date: day6Date,
    slotStart: slot,
    slotEnd: slotEnd,
    mode: "t60",
    activity: isSleep ? "Sleeping" : "Various activities",
    sleepFlag: isSleep,
    retroactive: false,
    autoFilled: isSleep,
    autoFillSource: isSleep ? "sleep-schedule" : null,
    createdAt: tjISO(day6Date, slot),
    modifiedAt: tjISO(day6Date, slot)
  });
}
db.timeJournalEntries.insertMany(day6Entries);
print("  Created Day 6 (" + day6Date + "): 21/24 slots filled (88%)");

db.timeJournalDays.insertOne({
  dayId: "tjd_d6",
  userId: "u_alex",
  tenantId: "DEFAULT",
  entityType: "TimeJournalDay",
  date: day6Date,
  mode: "t60",
  totalSlots: 24,
  filledSlots: 21,
  completionScore: 21.0/24.0,
  status: "completed",
  overdueSlotCount: 3,
  streakEligible: true,
  lastUpdatedAt: tjISO(day6Date, "23:59:00"),
  createdAt: tjISO(day6Date, "00:00:00"),
  modifiedAt: tjISO(day6Date, "23:59:00")
});

// Day 7 (today): in-progress, 8 of 24 filled (sleep + morning hours)
var day7Date = tjDate(0);
var day7Entries = [];
// Sleep slots: 00-05, morning: 06, 07
for (var h = 0; h < 8; h++) {
  var slot = (h < 10 ? "0" + h : "" + h) + ":00:00";
  var slotEnd = (h + 1 < 10 ? "0" + (h+1) : "" + (h+1)) + ":00:00";
  var isSleep = (h < 6);
  var activity = isSleep ? "Sleeping" : (h === 6 ? "Morning prayer & devotional" : "Breakfast & check-in");
  day7Entries.push({
    entryId: "tj_d7_" + h,
    userId: "u_alex",
    tenantId: "DEFAULT",
    entityType: "TimeJournalEntry",
    date: day7Date,
    slotStart: slot,
    slotEnd: slotEnd,
    mode: "t60",
    activity: activity,
    people: h === 7 ? [{ name: "Sarah", gender: "female" }] : [],
    emotions: h === 6 ? [{ name: "peaceful", intensity: 7 }, { name: "grateful", intensity: 8 }] : [],
    sleepFlag: isSleep,
    retroactive: false,
    autoFilled: isSleep,
    autoFillSource: isSleep ? "sleep-schedule" : null,
    createdAt: tjISO(day7Date, slot),
    modifiedAt: tjISO(day7Date, slot)
  });
}
db.timeJournalEntries.insertMany(day7Entries);
print("  Created Day 7 (" + day7Date + "): 8/24 slots filled (in-progress)");

db.timeJournalDays.insertOne({
  dayId: "tjd_d7",
  userId: "u_alex",
  tenantId: "DEFAULT",
  entityType: "TimeJournalDay",
  date: day7Date,
  mode: "t60",
  totalSlots: 24,
  filledSlots: 8,
  completionScore: 8.0/24.0,
  status: "inProgress",
  overdueSlotCount: 0,
  streakEligible: false,
  lastUpdatedAt: tjISO(day7Date, "08:00:00"),
  createdAt: tjISO(day7Date, "00:00:00"),
  modifiedAt: tjISO(day7Date, "08:00:00")
});

print("  Created 7 time journal day aggregates");
print("  Total time journal entries: " + db.timeJournalEntries.countDocuments({ userId: "u_alex" }));
print("  Total time journal days: " + db.timeJournalDays.countDocuments({ userId: "u_alex" }));

print("");
print("=============================================================================");
print("SEED COMPLETE - ALL COLLECTIONS POPULATED");
print("=============================================================================");
print("");
print("User Profile:");
print("  - UserID: u_alex");
print("  - Email: alex@example.com");
print("  - Sobriety Start: 2025-07-04");
print("  - Current Streak: 270 days");
print("  - Tier: premium");
print("");
print("Data Summary:");
print("  - Users: 1");
print("  - Addictions: 2 (SA primary, porn secondary)");
print("  - Streaks: 1");
print("  - Milestones: 11");
print("  - Check-ins: 5");
print("  - Urges: 3");
print("  - Journals: 3 (1 ephemeral)");
print("  - Meetings: 2");
print("  - Prayers: 2");
print("  - Exercises: 2");
print("  - Calendar Activities: 5");
print("  - Support Contacts: 1 (Marcus as sponsor)");
print("  - Permissions: 1");
print("  - Sessions: 1");
print("  - Commitments: 3");
print("  - Goals: 2");
print("  - Feature Flags: 16");
print("  - Affirmation Packs: 1");
print("  - Affirmations: 5");
print("  - Devotionals: 3");
print("  - Prompts: 5");
print("");
print("All collections seeded with realistic data for Alex persona.");
'

echo ""
echo "Seed script complete! Run 'make local-up' to apply."
