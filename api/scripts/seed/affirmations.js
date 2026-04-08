// scripts/seed/affirmations.js
// MongoDB seed script for Affirmation Packs
//
// Usage: mongosh < scripts/seed/affirmations.js
// Or: mongosh --eval "load('scripts/seed/affirmations.js')"

const db = connect("mongodb://localhost:27017/regalrecovery");

print("Seeding affirmation pack: pack_basic_affirmations...");

// Load the JSON content file
const packData = JSON.parse(cat("../../content/affirmations/affirmations-pack-basic.json"));

// 1. Upsert pack metadata document
db.affirmations.updateOne(
  { PK: "PACK#pack_basic_affirmations", SK: "META" },
  {
    $set: {
      PK: "PACK#pack_basic_affirmations",
      SK: "META",
      EntityType: "AFFIRMATION_PACK",
      TenantId: "SYSTEM",
      CreatedAt: new Date("2026-01-01T00:00:00Z"),
      ModifiedAt: new Date(),
      packId: packData.packId,
      name: packData.name,
      description: packData.description,
      tier: packData.tier,
      price: 0,
      affirmationCount: packData.affirmations.length,
      categories: [...new Set(packData.affirmations.map(a => a.category))],
      language: packData.language,
      version: packData.version
    }
  },
  { upsert: true }
);

print(`Pack metadata inserted. Affirmation count: ${packData.affirmations.length}`);

// 2. Upsert each affirmation document
let inserted = 0;
for (const aff of packData.affirmations) {
  db.affirmations.updateOne(
    { PK: "PACK#pack_basic_affirmations", SK: `AFFIRMATION#${aff.affirmationId}` },
    {
      $set: {
        PK: "PACK#pack_basic_affirmations",
        SK: `AFFIRMATION#${aff.affirmationId}`,
        EntityType: "AFFIRMATION",
        TenantId: "SYSTEM",
        CreatedAt: new Date("2026-01-01T00:00:00Z"),
        ModifiedAt: new Date(),
        affirmationId: aff.affirmationId,
        statement: aff.statement,
        scriptureReference: aff.scriptureReference,
        scriptureText: aff.scriptureText || null,
        expansion: aff.expansion || null,
        prayer: aff.prayer || null,
        category: aff.category,
        level: aff.level,
        language: "en",
        tags: aff.tags || [],
        sortOrder: aff.sortOrder
      }
    },
    { upsert: true }
  );
  inserted++;
}

print(`Seeded ${inserted} affirmations.`);

// 3. Create indexes
print("Creating indexes...");

db.affirmations.createIndex(
  { PK: 1, SK: 1 },
  { unique: true, name: "pk_sk_unique" }
);

db.affirmations.createIndex(
  { PK: 1, category: 1 },
  { name: "pk_category" }
);

db.affirmations.createIndex(
  { PK: 1, level: 1 },
  { name: "pk_level" }
);

db.affirmations.createIndex(
  { statement: "text", tags: "text" },
  { name: "statement_tags_text_search", default_language: "english" }
);

db.affirmations.createIndex(
  { TenantId: 1 },
  { name: "tenantId" }
);

// Read history indexes
db.affirmationReads.createIndex(
  { PK: 1, SK: 1 },
  { unique: true, name: "pk_sk_unique" }
);

db.affirmationReads.createIndex(
  { PK: 1, calendarDate: 1 },
  { name: "pk_calendarDate" }
);

print("Indexes created.");

// 4. Validate seed data
const packMeta = db.affirmations.findOne({ PK: "PACK#pack_basic_affirmations", SK: "META" });
const affCount = db.affirmations.countDocuments({ PK: "PACK#pack_basic_affirmations", EntityType: "AFFIRMATION" });
const categories = db.affirmations.distinct("category", { PK: "PACK#pack_basic_affirmations", EntityType: "AFFIRMATION" });
const levels = db.affirmations.distinct("level", { PK: "PACK#pack_basic_affirmations", EntityType: "AFFIRMATION" });

print("\n=== Seed Validation ===");
print(`Pack: ${packMeta.name}`);
print(`Total affirmations: ${affCount}`);
print(`Categories: ${categories.join(", ")}`);
print(`Levels: ${levels.join(", ")}`);

// Category distribution
for (const cat of categories) {
  const count = db.affirmations.countDocuments({ PK: "PACK#pack_basic_affirmations", EntityType: "AFFIRMATION", category: cat });
  print(`  ${cat}: ${count}`);
}

// Level distribution
for (const lvl of levels) {
  const count = db.affirmations.countDocuments({ PK: "PACK#pack_basic_affirmations", EntityType: "AFFIRMATION", level: lvl });
  print(`  Level ${lvl}: ${count}`);
}

print("\nSeed complete.");
