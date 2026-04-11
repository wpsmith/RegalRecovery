#!/usr/bin/env bash
# Create MongoDB collections and indexes for local development

set -euo pipefail

DATABASE_NAME="regal-recovery"
MONGO_URI="mongodb://localhost:27017"

echo "Creating MongoDB collections and indexes for: $DATABASE_NAME"

# Connect to MongoDB and create indexes
mongosh "$MONGO_URI/$DATABASE_NAME" --eval '
db.users.createIndex({ "PK": 1, "SK": 1 }, { unique: true, name: "pk_sk_unique" });
db.users.createIndex({ "GSI1PK": 1, "GSI1SK": 1 }, { name: "gsi1_index" });
db.users.createIndex({ "GSI2PK": 1, "GSI2SK": 1 }, { name: "gsi2_index" });
db.users.createIndex({ "EntityType": 1 }, { name: "entity_type_index" });
db.users.createIndex({ "TenantId": 1 }, { name: "tenant_id_index" });

db.tracking.createIndex({ "PK": 1, "SK": 1 }, { unique: true, name: "pk_sk_unique" });
db.tracking.createIndex({ "GSI1PK": 1, "GSI1SK": 1 }, { name: "gsi1_index" });
db.tracking.createIndex({ "GSI2PK": 1, "GSI2SK": 1 }, { name: "gsi2_index" });
db.tracking.createIndex({ "EntityType": 1 }, { name: "entity_type_index" });
db.tracking.createIndex({ "TenantId": 1 }, { name: "tenant_id_index" });

db.activities.createIndex({ "PK": 1, "SK": 1 }, { unique: true, name: "pk_sk_unique" });
db.activities.createIndex({ "GSI1PK": 1, "GSI1SK": 1 }, { name: "gsi1_index" });
db.activities.createIndex({ "GSI2PK": 1, "GSI2SK": 1 }, { name: "gsi2_index" });
db.activities.createIndex({ "EntityType": 1 }, { name: "entity_type_index" });
db.activities.createIndex({ "TenantId": 1 }, { name: "tenant_id_index" });

db.content.createIndex({ "PK": 1, "SK": 1 }, { unique: true, name: "pk_sk_unique" });
db.content.createIndex({ "EntityType": 1 }, { name: "entity_type_index" });
db.content.createIndex({ "TenantId": 1 }, { name: "tenant_id_index" });

db.goals.createIndex({ "PK": 1, "SK": 1 }, { unique: true, name: "pk_sk_unique" });
db.goals.createIndex({ "EntityType": 1 }, { name: "entity_type_index" });
db.goals.createIndex({ "TenantId": 1 }, { name: "tenant_id_index" });

db.commitments.createIndex({ "PK": 1, "SK": 1 }, { unique: true, name: "pk_sk_unique" });
db.commitments.createIndex({ "EntityType": 1 }, { name: "entity_type_index" });
db.commitments.createIndex({ "TenantId": 1 }, { name: "tenant_id_index" });

db.support.createIndex({ "PK": 1, "SK": 1 }, { unique: true, name: "pk_sk_unique" });
db.support.createIndex({ "GSI1PK": 1, "GSI1SK": 1 }, { name: "gsi1_index" });
db.support.createIndex({ "GSI2PK": 1, "GSI2SK": 1 }, { name: "gsi2_index" });
db.support.createIndex({ "EntityType": 1 }, { name: "entity_type_index" });
db.support.createIndex({ "TenantId": 1 }, { name: "tenant_id_index" });

db.sessions.createIndex({ "PK": 1, "SK": 1 }, { unique: true, name: "pk_sk_unique" });
db.sessions.createIndex({ "GSI1PK": 1, "GSI1SK": 1 }, { name: "gsi1_index" });
db.sessions.createIndex({ "EntityType": 1 }, { name: "entity_type_index" });
db.sessions.createIndex({ "TenantId": 1 }, { name: "tenant_id_index" });
db.sessions.createIndex({ "expiresAt": 1 }, { expireAfterSeconds: 0, name: "ttl_index" });

print("✓ All collections and indexes created successfully");
'

echo "MongoDB collections and indexes are ready"
