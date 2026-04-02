#!/usr/bin/env bash
# Seed DynamoDB table with test data for Alex (primary test persona)

set -euo pipefail

TABLE_NAME="regal-recovery"
ENDPOINT_URL="http://localhost:4566"

echo "Seeding test data for Alex..."

# User profile item
aws --endpoint-url "$ENDPOINT_URL" --region us-east-1 --no-cli-pager dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "USER#u_alex"},
    "SK": {"S": "PROFILE"},
    "EntityType": {"S": "USER"},
    "GSI1PK": {"S": "EMAIL#alex@example.com"},
    "GSI1SK": {"S": "USER#u_alex"},
    "GSI2PK": {"S": "TENANT#DEFAULT"},
    "GSI2SK": {"S": "USER#u_alex"},
    "TenantId": {"S": "DEFAULT"},
    "CreatedAt": {"S": "2025-07-04T00:00:00Z"},
    "ModifiedAt": {"S": "2026-03-31T00:00:00Z"},
    "email": {"S": "alex@example.com"},
    "displayName": {"S": "Alex"},
    "role": {"S": "User"},
    "preferredLanguage": {"S": "en"},
    "preferredBibleVersion": {"S": "ESV"},
    "timeZone": {"S": "America/Chicago"},
    "emailVerified": {"BOOL": true},
    "biometricEnabled": {"BOOL": true},
    "regionId": {"S": "us-east-1"},
    "subscriptionTier": {"S": "premium"}
  }'

echo "✓ Created user profile for Alex"

# User settings
aws --endpoint-url "$ENDPOINT_URL" --region us-east-1 --no-cli-pager dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "USER#u_alex"},
    "SK": {"S": "SETTINGS"},
    "EntityType": {"S": "SETTINGS"},
    "TenantId": {"S": "DEFAULT"},
    "CreatedAt": {"S": "2025-07-04T00:00:00Z"},
    "ModifiedAt": {"S": "2026-03-31T00:00:00Z"}
  }'

echo "✓ Created user settings for Alex"

# Sex Addiction (SA) record
aws --endpoint-url "$ENDPOINT_URL" --region us-east-1 --no-cli-pager dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "USER#u_alex"},
    "SK": {"S": "ADDICTION#a_sa"},
    "EntityType": {"S": "ADDICTION"},
    "TenantId": {"S": "DEFAULT"},
    "CreatedAt": {"S": "2025-07-04T00:00:00Z"},
    "ModifiedAt": {"S": "2025-07-04T00:00:00Z"},
    "addictionId": {"S": "a_sa"},
    "type": {"S": "sex-addiction"},
    "sobrietyStartDate": {"S": "2025-07-04"},
    "isPrimary": {"BOOL": true}
  }'

echo "✓ Created Sex Addiction record"

# Pornography addiction record
aws --endpoint-url "$ENDPOINT_URL" --region us-east-1 --no-cli-pager dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "USER#u_alex"},
    "SK": {"S": "ADDICTION#a_porn"},
    "EntityType": {"S": "ADDICTION"},
    "TenantId": {"S": "DEFAULT"},
    "CreatedAt": {"S": "2025-07-04T00:00:00Z"},
    "ModifiedAt": {"S": "2025-07-04T00:00:00Z"},
    "addictionId": {"S": "a_porn"},
    "type": {"S": "pornography"},
    "sobrietyStartDate": {"S": "2025-07-04"},
    "isPrimary": {"BOOL": false}
  }'

echo "✓ Created Pornography addiction record"

# Current streak
aws --endpoint-url "$ENDPOINT_URL" --region us-east-1 --no-cli-pager dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "USER#u_alex"},
    "SK": {"S": "STREAK#a_sa"},
    "EntityType": {"S": "STREAK"},
    "TenantId": {"S": "DEFAULT"},
    "CreatedAt": {"S": "2025-07-04T00:00:00Z"},
    "ModifiedAt": {"S": "2026-03-31T00:00:00Z"},
    "addictionId": {"S": "a_sa"},
    "currentStreakDays": {"N": "270"},
    "longestStreakDays": {"N": "270"},
    "sobrietyStartDate": {"S": "2025-07-04"},
    "totalSoberDays": {"N": "270"}
  }'

echo "✓ Created streak record (270 days)"

# Feature flag: tracking enabled
aws --endpoint-url "$ENDPOINT_URL" --region us-east-1 --no-cli-pager dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "FLAGS"},
    "SK": {"S": "feature.tracking"},
    "EntityType": {"S": "FEATURE_FLAG"},
    "TenantId": {"S": "SYSTEM"},
    "CreatedAt": {"S": "2026-01-01T00:00:00Z"},
    "ModifiedAt": {"S": "2026-03-31T00:00:00Z"},
    "enabled": {"BOOL": true},
    "rolloutPercentage": {"N": "100"},
    "description": {"S": "Streak and milestone tracking"}
  }'

echo "✓ Created feature flag: feature.tracking"

# Feature flag: activities enabled
aws --endpoint-url "$ENDPOINT_URL" --region us-east-1 --no-cli-pager dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "FLAGS"},
    "SK": {"S": "feature.activities"},
    "EntityType": {"S": "FEATURE_FLAG"},
    "TenantId": {"S": "SYSTEM"},
    "CreatedAt": {"S": "2026-01-01T00:00:00Z"},
    "ModifiedAt": {"S": "2026-03-31T00:00:00Z"},
    "enabled": {"BOOL": true},
    "rolloutPercentage": {"N": "100"},
    "description": {"S": "Activity logging (check-ins, urges, journals)"}
  }'

echo "✓ Created feature flag: feature.activities"

# Feature flag: recovery-agent (partially rolled out)
aws --endpoint-url "$ENDPOINT_URL" --region us-east-1 --no-cli-pager dynamodb put-item \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "FLAGS"},
    "SK": {"S": "feature.recovery-agent"},
    "EntityType": {"S": "FEATURE_FLAG"},
    "TenantId": {"S": "SYSTEM"},
    "CreatedAt": {"S": "2026-01-01T00:00:00Z"},
    "ModifiedAt": {"S": "2026-03-31T00:00:00Z"},
    "enabled": {"BOOL": true},
    "rolloutPercentage": {"N": "50"},
    "description": {"S": "AI-powered Recovery Agent"}
  }'

echo "✓ Created feature flag: feature.recovery-agent"

echo ""
echo "✅ Seed complete. Test user Alex (u_alex) is ready."
echo "   Email: alex@example.com"
echo "   Sobriety date: 2025-07-04"
echo "   Current streak: 270 days"
