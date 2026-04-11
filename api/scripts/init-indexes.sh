#!/usr/bin/env bash
# Create MongoDB indexes for local development

set -euo pipefail

echo "Creating indexes in database: regal-recovery"

docker compose exec -T mongodb mongosh regal-recovery --eval '
// Users
db.users.createIndex({ userId: 1, tenantId: 1 }, { unique: true });
db.users.createIndex({ email: 1 }, { unique: true });

// User Settings
db.user_settings.createIndex({ userId: 1, tenantId: 1 }, { unique: true });

// Addictions
db.addictions.createIndex({ userId: 1, tenantId: 1 });
db.addictions.createIndex({ userId: 1, addictionId: 1 }, { unique: true });

// Streaks
db.streaks.createIndex({ userId: 1, addictionId: 1 }, { unique: true });

// Milestones
db.milestones.createIndex({ userId: 1, addictionId: 1 });
db.milestones.createIndex({ userId: 1, addictionId: 1, days: 1 }, { unique: true });

// Relapses
db.relapses.createIndex({ userId: 1, createdAt: -1 });

// Check-ins
db.check_ins.createIndex({ userId: 1, createdAt: -1 });

// Urges
db.urges.createIndex({ userId: 1, createdAt: -1 });

// Journals (with TTL for ephemeral entries)
db.journals.createIndex({ userId: 1, createdAt: -1 });
db.journals.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Meetings
db.meetings.createIndex({ userId: 1, createdAt: -1 });

// Prayers (with TTL for ephemeral entries)
db.prayers.createIndex({ userId: 1, createdAt: -1 });
db.prayers.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Exercises
db.exercises.createIndex({ userId: 1, createdAt: -1 });

// Activities (calendar view)
db.activities.createIndex({ userId: 1, date: 1 });
db.activities.createIndex({ userId: 1, date: 1, activityType: 1 });

// Support Contacts
db.support_contacts.createIndex({ userId: 1 });
db.support_contacts.createIndex({ userId: 1, contactId: 1 }, { unique: true });

// Permissions
db.permissions.createIndex({ userId: 1 });
db.permissions.createIndex({ userId: 1, contactId: 1 });
db.permissions.createIndex({ userId: 1, contactId: 1, dataCategory: 1 }, { unique: true });

// Affirmation Packs
db.affirmation_packs.createIndex({ packId: 1 }, { unique: true });

// Affirmations
db.affirmations.createIndex({ packId: 1 });

// Devotionals
db.devotionals.createIndex({ day: 1 }, { unique: true });

// Prompts
db.prompts.createIndex({ category: 1 });

// Commitments
db.commitments.createIndex({ userId: 1 });
db.commitments.createIndex({ userId: 1, commitmentId: 1 }, { unique: true });

// Goals
db.goals.createIndex({ userId: 1 });
db.goals.createIndex({ userId: 1, goalId: 1 }, { unique: true });

// Sessions (with TTL)
db.sessions.createIndex({ sessionId: 1 }, { unique: true });
db.sessions.createIndex({ userId: 1 });
db.sessions.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Time Journal Entries
db.timeJournalEntries.createIndex({ userId: 1, date: 1 });
db.timeJournalEntries.createIndex({ userId: 1, date: 1, slotStart: 1 }, { unique: true });
db.timeJournalEntries.createIndex({ userId: 1, createdAt: -1 });
db.timeJournalEntries.createIndex({ tenantId: 1, userId: 1 });

// Time Journal Days (daily aggregates)
db.timeJournalDays.createIndex({ userId: 1, date: -1 }, { unique: true });
db.timeJournalDays.createIndex({ userId: 1, status: 1, date: -1 });
db.timeJournalDays.createIndex({ userId: 1, streakEligible: 1, date: -1 });
db.timeJournalDays.createIndex({ tenantId: 1, userId: 1 });

print("All indexes created successfully");
'

echo "Indexes created successfully"
