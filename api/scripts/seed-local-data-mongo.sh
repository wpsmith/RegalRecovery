#!/usr/bin/env bash
# Seed MongoDB database with test data for Alex (primary test persona)

set -euo pipefail

DATABASE_NAME="regal-recovery"
MONGO_URI="mongodb://localhost:27017"

echo "Seeding test data for Alex..."

# Connect to MongoDB and insert test data
mongosh "$MONGO_URI/$DATABASE_NAME" --eval '
// User profile
db.users.insertOne({
  "PK": "USER#u_alex",
  "SK": "PROFILE",
  "EntityType": "USER",
  "GSI1PK": "EMAIL#alex@example.com",
  "GSI1SK": "USER#u_alex",
  "GSI2PK": "TENANT#DEFAULT",
  "GSI2SK": "USER#u_alex",
  "TenantId": "DEFAULT",
  "CreatedAt": "2025-07-04T00:00:00Z",
  "ModifiedAt": "2026-03-31T00:00:00Z",
  "email": "alex@example.com",
  "displayName": "Alex",
  "role": "User",
  "preferredLanguage": "en",
  "preferredBibleVersion": "ESV",
  "timeZone": "America/Chicago",
  "emailVerified": true,
  "biometricEnabled": true,
  "regionId": "us-east-1",
  "subscriptionTier": "premium"
});
print("✓ Created user profile for Alex");

// User settings
db.users.insertOne({
  "PK": "USER#u_alex",
  "SK": "SETTINGS",
  "EntityType": "SETTINGS",
  "TenantId": "DEFAULT",
  "CreatedAt": "2025-07-04T00:00:00Z",
  "ModifiedAt": "2026-03-31T00:00:00Z"
});
print("✓ Created user settings for Alex");

// Sex Addiction (SA) record
db.users.insertOne({
  "PK": "USER#u_alex",
  "SK": "ADDICTION#a_sa",
  "EntityType": "ADDICTION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2025-07-04T00:00:00Z",
  "ModifiedAt": "2025-07-04T00:00:00Z",
  "addictionId": "a_sa",
  "type": "sex-addiction",
  "sobrietyStartDate": "2025-07-04",
  "isPrimary": true
});
print("✓ Created Sex Addiction record");

// Pornography addiction record
db.users.insertOne({
  "PK": "USER#u_alex",
  "SK": "ADDICTION#a_porn",
  "EntityType": "ADDICTION",
  "TenantId": "DEFAULT",
  "CreatedAt": "2025-07-04T00:00:00Z",
  "ModifiedAt": "2025-07-04T00:00:00Z",
  "addictionId": "a_porn",
  "type": "pornography",
  "sobrietyStartDate": "2025-07-04",
  "isPrimary": false
});
print("✓ Created Pornography addiction record");

// Current streak
db.tracking.insertOne({
  "PK": "USER#u_alex",
  "SK": "STREAK#a_sa",
  "EntityType": "STREAK",
  "TenantId": "DEFAULT",
  "CreatedAt": "2025-07-04T00:00:00Z",
  "ModifiedAt": "2026-03-31T00:00:00Z",
  "addictionId": "a_sa",
  "currentStreakDays": 270,
  "longestStreakDays": 270,
  "sobrietyStartDate": "2025-07-04",
  "totalSoberDays": 270
});
print("✓ Created streak record (270 days)");

'

echo ""
echo "✅ Seed complete. Test user Alex (u_alex) is ready."
echo "   Email: alex@example.com"
echo "   Sobriety date: 2025-07-04"
echo "   Current streak: 270 days"
