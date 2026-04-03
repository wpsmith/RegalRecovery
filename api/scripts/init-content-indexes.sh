#!/usr/bin/env bash
# Create MongoDB indexes for regal-recovery-content database
set -euo pipefail

echo "Creating indexes in database: regal-recovery-content"

docker compose exec -T mongodb mongosh regal-recovery-content --eval '
db.feature_abouts.createIndex({ slug: 1 }, { unique: true });
db.feature_abouts.createIndex({ category: 1, sortOrder: 1 });
db.feature_abouts.createIndex({ status: 1 });

db.affirmation_packs.createIndex({ packId: 1 }, { unique: true });
db.affirmation_packs.createIndex({ tier: 1 });
db.affirmation_packs.createIndex({ status: 1 });

db.affirmations.createIndex({ affirmationId: 1 }, { unique: true });
db.affirmations.createIndex({ packId: 1, sortOrder: 1 });

db.devotional_packs.createIndex({ packId: 1 }, { unique: true });
db.devotional_packs.createIndex({ tier: 1 });
db.devotional_packs.createIndex({ status: 1 });

db.devotionals.createIndex({ devotionalId: 1 }, { unique: true });
db.devotionals.createIndex({ packId: 1, day: 1 }, { unique: true });

db.journal_prompts.createIndex({ promptId: 1 }, { unique: true });
db.journal_prompts.createIndex({ category: 1, sortOrder: 1 });
db.journal_prompts.createIndex({ tags: 1 });

db.glossary_terms.createIndex({ termId: 1 }, { unique: true });
db.glossary_terms.createIndex({ term: 1 }, { unique: true });

db.evening_review_questions.createIndex({ questionId: 1 }, { unique: true });
db.evening_review_questions.createIndex({ dimension: 1, sortOrder: 1 });

db.acting_in_behaviors.createIndex({ behaviorId: 1 }, { unique: true });

db.needs.createIndex({ needId: 1 }, { unique: true });

db.sobriety_reset_messages.createIndex({ messageId: 1 }, { unique: true });

db.themes.createIndex({ themeId: 1 }, { unique: true });
db.themes.createIndex({ tier: 1 });
db.themes.createIndex({ status: 1 });

print("All content indexes created successfully");
'

echo "Content indexes created successfully"
