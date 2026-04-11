#!/bin/bash
# seed-affirmations-library.sh
# Seeds the affirmationsLibrary collection with 220 clinically tagged affirmations.
#
# Each affirmation is tagged per the Affirmations PRD:
#   - level 1-4 (Permission, Process, Tempered Identity, Full Identity)
#   - coreBeliefs 1-4 (Carnes' four core beliefs)
#   - category (10 clinical categories)
#   - track (standard or faith-based)
#   - recoveryStage (early, middle, established)
#
# Usage:
#   ./api/scripts/seed-affirmations-library.sh
#   MONGO_URI=mongodb://prod:27017 DB_NAME=rr ./api/scripts/seed-affirmations-library.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use environment variable or default
MONGO_URI="${MONGO_URI:-mongodb://localhost:27017}"
DB_NAME="${DB_NAME:-regalrecovery}"

mongosh "$MONGO_URI/$DB_NAME" <<'MONGOSCRIPT'
// Clear existing library data
db.affirmationsLibrary.deleteMany({});

const now = ISODate("2026-01-15T00:00:00Z");

db.affirmationsLibrary.insertMany([

  // ============================================================================
  // CATEGORY: self-worth (30+ affirmations)
  // Core Belief 1: I am basically a bad, unworthy person
  // Levels: 1-4
  // ============================================================================

  // -- self-worth: Level 1 (Permission) --
  { affirmationId: "aff_lib_sw001", text: "It is OK for me to take up space in this world.", level: 1, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "early", readingLevel: 4, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw002", text: "It is OK for me to feel good about myself today.", level: 1, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "early", readingLevel: 4, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw003", text: "It is OK for me to accept kind words from others.", level: 1, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw004", text: "It is OK for me to rest without feeling guilty.", level: 1, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw005", text: "It is OK for me to treat myself with the same kindness I give others.", level: 1, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw006", text: "It is OK for me to believe that my Higher Power sees me as worthy.", level: 1, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // -- self-worth: Level 2 (Process) --
  { affirmationId: "aff_lib_sw007", text: "I am learning to see myself with honesty and compassion.", level: 2, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw008", text: "I am working to replace shame with self-respect.", level: 2, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw009", text: "I am building a life I feel good about, one day at a time.", level: 2, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw010", text: "I am discovering the person I truly am underneath my addiction.", level: 2, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw011", text: "I am growing in my understanding of how God as I understand God sees me.", level: 2, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw012", text: "I am learning to trust that my Higher Power's love does not depend on my perfection.", level: 2, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // -- self-worth: Level 3 (Tempered Identity) --
  { affirmationId: "aff_lib_sw013", text: "I have made mistakes, but my mistakes are not my identity.", level: 3, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw014", text: "I have done things I regret, and I am still deserving of compassion.", level: 3, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw015", text: "I have struggled, and that struggle has given me strength I did not know I had.", level: 3, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw016", text: "I have fallen short, but I am created with purpose by a loving Higher Power.", level: 3, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw017", text: "I have sinned, and I am still embraced by grace.", level: 3, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "middle", readingLevel: 5, active: true, createdAt: now, updatedAt: now },

  // -- self-worth: Level 4 (Full Identity) --
  { affirmationId: "aff_lib_sw018", text: "I am a person of inherent worth and dignity.", level: 4, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw019", text: "I am enough, exactly as I am today.", level: 4, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "established", readingLevel: 3, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw020", text: "I am worthy of the good things that come into my life.", level: 4, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw021", text: "I am valuable, and my presence matters to the people around me.", level: 4, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw022", text: "I am fearfully and wonderfully made by my Higher Power.", level: 4, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw023", text: "I am God's workmanship, created for good purpose.", level: 4, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw024", text: "I am a beloved child of my Higher Power, free from condemnation.", level: 4, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw025", text: "I am complete, and my worth is not determined by my past.", level: 4, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw026", text: "I am deserving of respect, starting with my own.", level: 4, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw027", text: "It is OK for me to stand tall and be proud of my recovery.", level: 1, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw028", text: "I am learning that I deserve to be treated well, by myself and by others.", level: 2, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw029", text: "I am rooted in the love of my Higher Power, and nothing can separate me from it.", level: 4, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw030", text: "I have caused harm, and I am still worthy of healing.", level: 3, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "middle", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw031", text: "I am growing into the person I choose to be.", level: 2, coreBeliefs: [1], category: "self-worth", track: "standard", recoveryStage: "middle", readingLevel: 5, active: true, createdAt: now, updatedAt: now },

  // ============================================================================
  // CATEGORY: shame-resilience (25+ affirmations)
  // Core Belief 1: I am basically a bad, unworthy person
  // Levels: 1-3
  // ============================================================================

  // -- shame-resilience: Level 1 (Permission) --
  { affirmationId: "aff_lib_sr001", text: "It is OK for me to feel shame without letting it define me.", level: 1, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr002", text: "It is OK for me to talk about my shame with someone I trust.", level: 1, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr003", text: "It is OK for me to set down the weight of shame today.", level: 1, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr004", text: "It is OK for me to bring my shame into the light of my Higher Power's grace.", level: 1, coreBeliefs: [1], category: "shame-resilience", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr005", text: "It is OK for me to accept forgiveness, even when shame says I cannot.", level: 1, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr006", text: "It is OK for me to let go of secrets that keep me stuck.", level: 1, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },

  // -- shame-resilience: Level 2 (Process) --
  { affirmationId: "aff_lib_sr007", text: "I am learning to separate who I am from what I have done.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr008", text: "I am building the courage to be honest about my struggles.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr009", text: "I am choosing to respond to shame with self-compassion instead of hiding.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr010", text: "I am working my recovery with honesty, and that takes real courage.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr011", text: "I am discovering that my Higher Power's grace is bigger than my shame.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr012", text: "I am learning that sharing my story weakens shame's hold on me.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr013", text: "I am growing stronger each time I choose truth over secrecy.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr014", text: "I am finding freedom as I release the guilt and shame I have carried.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // -- shame-resilience: Level 3 (Tempered Identity) --
  { affirmationId: "aff_lib_sr015", text: "I have done things that brought shame, but I am choosing a different path.", level: 3, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr016", text: "I have carried shame for a long time, and today I choose to set it down.", level: 3, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr017", text: "I have felt broken, and I am learning that broken places can heal.", level: 3, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr018", text: "I have hidden parts of myself in shame, and today I bring them into the open.", level: 3, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr019", text: "I have been weighed down by guilt, but my Higher Power offers me a fresh start.", level: 3, coreBeliefs: [1], category: "shame-resilience", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr020", text: "I have failed, and I am still held by grace.", level: 3, coreBeliefs: [1], category: "shame-resilience", track: "faith-based", recoveryStage: "middle", readingLevel: 4, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr021", text: "I have lived in secrecy, and I am choosing openness one step at a time.", level: 3, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr022", text: "I am learning that vulnerability is a sign of strength, not weakness.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr023", text: "It is OK for me to forgive myself, even when it feels undeserved.", level: 1, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr024", text: "I have felt unforgivable, and yet forgiveness is available to me right now.", level: 3, coreBeliefs: [1], category: "shame-resilience", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr025", text: "I am working through shame by being honest with my sponsor and my group.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // ============================================================================
  // CATEGORY: healthy-relationships (25+ affirmations)
  // Core Belief 2: No one would love me as I am
  // Levels: 2-4
  // ============================================================================

  // -- healthy-relationships: Level 2 (Process) --
  { affirmationId: "aff_lib_hr001", text: "I am learning how to show up honestly in my relationships.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr002", text: "I am practicing being present with the people I care about.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr003", text: "I am building trust by keeping my word, one promise at a time.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr004", text: "I am developing the courage to be vulnerable with safe people.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr005", text: "I am learning to let my Higher Power guide me toward healthy connections.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr006", text: "I am growing in my ability to listen with patience and care.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr007", text: "I am working to repair the trust I have broken, without rushing the process.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },

  // -- healthy-relationships: Level 3 (Tempered Identity) --
  { affirmationId: "aff_lib_hr008", text: "I have hurt people I love, and I am committed to making amends.", level: 3, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr009", text: "I have been dishonest in relationships, and I choose honesty today.", level: 3, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr010", text: "I have struggled with intimacy, and I am learning what real closeness looks like.", level: 3, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr011", text: "I have feared rejection, and I am choosing connection anyway.", level: 3, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr012", text: "I have broken trust, and I am rebuilding it through consistent action.", level: 3, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr013", text: "I have damaged relationships, and my Higher Power is helping me restore them.", level: 3, coreBeliefs: [2], category: "healthy-relationships", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr014", text: "I have pushed people away, and I am learning to let them in.", level: 3, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 5, active: true, createdAt: now, updatedAt: now },

  // -- healthy-relationships: Level 4 (Full Identity) --
  { affirmationId: "aff_lib_hr015", text: "I am capable of deep, honest, loving relationships.", level: 4, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr016", text: "I am a trustworthy partner, friend, and family member.", level: 4, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr017", text: "I am someone who shows up with integrity in my relationships.", level: 4, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr018", text: "I am lovable, even in my imperfection.", level: 4, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "established", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr019", text: "I am loved with a love that does not depend on my performance.", level: 4, coreBeliefs: [2], category: "healthy-relationships", track: "faith-based", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr020", text: "I am a person who gives and receives love freely.", level: 4, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "established", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr021", text: "I am worthy of being known fully and loved anyway.", level: 4, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr022", text: "I am created for connection, and my Higher Power walks with me as I heal my relationships.", level: 4, coreBeliefs: [2], category: "healthy-relationships", track: "faith-based", recoveryStage: "established", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr023", text: "I am practicing healthy boundaries because I respect myself and others.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr024", text: "I have been afraid to be truly seen, and today I choose to show up as I am.", level: 3, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr025", text: "I am learning to love others without losing myself.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "standard", recoveryStage: "middle", readingLevel: 5, active: true, createdAt: now, updatedAt: now },

  // ============================================================================
  // CATEGORY: connection (20+ affirmations)
  // Core Belief 3: My needs are never going to be met if I have to depend on others
  // Levels: 1-3
  // ============================================================================

  // -- connection: Level 1 (Permission) --
  { affirmationId: "aff_lib_cn001", text: "It is OK for me to ask for help when I need it.", level: 1, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "early", readingLevel: 4, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn002", text: "It is OK for me to talk to others about what I think and feel.", level: 1, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn003", text: "It is OK for me to depend on others sometimes.", level: 1, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "early", readingLevel: 4, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn004", text: "It is OK for me to let someone know I am struggling.", level: 1, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn005", text: "It is OK for me to reach out to my Higher Power when I feel alone.", level: 1, coreBeliefs: [3], category: "connection", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn006", text: "It is OK for me to trust that my Higher Power hears me.", level: 1, coreBeliefs: [3], category: "connection", track: "faith-based", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },

  // -- connection: Level 2 (Process) --
  { affirmationId: "aff_lib_cn007", text: "I am learning that isolation feeds my addiction, and connection heals it.", level: 2, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "early", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn008", text: "I am practicing reaching out before I reach a breaking point.", level: 2, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn009", text: "I am growing in my ability to accept support from my recovery community.", level: 2, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn010", text: "I am finding that my needs matter and can be met in healthy ways.", level: 2, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn011", text: "I am building a life where I belong, one honest conversation at a time.", level: 2, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn012", text: "I am growing closer to my Higher Power through prayer and honest sharing.", level: 2, coreBeliefs: [3], category: "connection", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // -- connection: Level 3 (Tempered Identity) --
  { affirmationId: "aff_lib_cn013", text: "I have lived in isolation, and I am choosing community today.", level: 3, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn014", text: "I have believed my needs did not matter, and today I know they do.", level: 3, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn015", text: "I have been afraid to need people, and I am learning that need is human.", level: 3, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn016", text: "I have felt alone, and I know now that my Higher Power is always with me.", level: 3, coreBeliefs: [3], category: "connection", track: "faith-based", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn017", text: "I have shut people out, and I am opening the door to real connection.", level: 3, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn018", text: "I have told myself nobody cares, and my recovery community proves otherwise.", level: 3, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn019", text: "It is OK for me to call my sponsor when I feel overwhelmed.", level: 1, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn020", text: "I am learning that being part of a faith community gives me strength I cannot find alone.", level: 2, coreBeliefs: [3], category: "connection", track: "faith-based", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn021", text: "I have tried to do everything alone, and I am choosing a better way.", level: 3, coreBeliefs: [3], category: "connection", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // ============================================================================
  // CATEGORY: emotional-regulation (20+ affirmations)
  // Core Beliefs 1, 3
  // Levels: 1-3
  // ============================================================================

  // -- emotional-regulation: Level 1 (Permission) --
  { affirmationId: "aff_lib_er001", text: "It is OK for me to feel my emotions without acting on them.", level: 1, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er002", text: "It is OK for me to sit with discomfort and let it pass.", level: 1, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er003", text: "It is OK for me to feel angry, sad, or afraid without numbing out.", level: 1, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er004", text: "It is OK for me to pause before I react.", level: 1, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "early", readingLevel: 4, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er005", text: "It is OK for me to bring my pain to my Higher Power instead of hiding from it.", level: 1, coreBeliefs: [1, 3], category: "emotional-regulation", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // -- emotional-regulation: Level 2 (Process) --
  { affirmationId: "aff_lib_er006", text: "I am learning to name my feelings so they have less power over me.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er007", text: "I am building healthier ways to handle stress and pain.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er008", text: "I am choosing to face difficult feelings instead of escaping them.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er009", text: "I am practicing patience with myself when emotions feel overwhelming.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "early", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er010", text: "I am learning that feelings are information, not commands.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er011", text: "I am trusting my Higher Power to carry what I cannot hold alone.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er012", text: "I am growing in my ability to respond rather than react.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // -- emotional-regulation: Level 3 (Tempered Identity) --
  { affirmationId: "aff_lib_er013", text: "I have used my addiction to avoid pain, and I am finding better ways to cope.", level: 3, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er014", text: "I have been controlled by my emotions, and I am reclaiming that power.", level: 3, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er015", text: "I have numbed myself to avoid feeling, and today I choose to feel.", level: 3, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er016", text: "I have handed my pain to my Higher Power, and I trust the process of healing.", level: 3, coreBeliefs: [1, 3], category: "emotional-regulation", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er017", text: "I have run from my feelings, and now I face them with courage.", level: 3, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "middle", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er018", text: "It is OK for me to cry, to grieve, and to let my heart soften.", level: 1, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er019", text: "I am finding that my Higher Power gives me a spirit of power, love, and a sound mind.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "faith-based", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er020", text: "I am developing tools to manage my emotions in healthy ways.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // ============================================================================
  // CATEGORY: purpose-meaning (20+ affirmations)
  // Core Belief 4: Sex is my most important need
  // Levels: 2-4
  // ============================================================================

  // -- purpose-meaning: Level 2 (Process) --
  { affirmationId: "aff_lib_pm001", text: "I am discovering that my life has meaning beyond my addiction.", level: 2, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm002", text: "I am learning what truly matters to me, apart from old patterns.", level: 2, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm003", text: "I am building a life worth living, one choice at a time.", level: 2, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm004", text: "I am exploring the interests and passions that my addiction buried.", level: 2, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm005", text: "I am working to align my daily actions with my deepest values.", level: 2, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm006", text: "I am seeking the purpose my Higher Power has placed in my heart.", level: 2, coreBeliefs: [4], category: "purpose-meaning", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm007", text: "I am learning to use my time and energy for things that give real meaning.", level: 2, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // -- purpose-meaning: Level 3 (Tempered Identity) --
  { affirmationId: "aff_lib_pm008", text: "I have wasted years on my addiction, and today I choose to invest in my future.", level: 3, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm009", text: "I have lost my way, and I am finding a new direction.", level: 3, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "middle", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm010", text: "I have let my addiction steal my purpose, and I am taking it back.", level: 3, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm011", text: "I have wandered far, and my Higher Power has plans filled with hope for me.", level: 3, coreBeliefs: [4], category: "purpose-meaning", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm012", text: "I have missed out on meaningful experiences, and I am present for them now.", level: 3, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // -- purpose-meaning: Level 4 (Full Identity) --
  { affirmationId: "aff_lib_pm013", text: "I am a person with gifts to share and a purpose to fulfill.", level: 4, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm014", text: "I am here for a reason, and my recovery is part of that reason.", level: 4, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm015", text: "I am driven by my values, not by compulsion.", level: 4, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm016", text: "I am a man of purpose, and my life reflects what I truly believe.", level: 4, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm017", text: "I am created for good works, and my Higher Power is guiding me toward them.", level: 4, coreBeliefs: [4], category: "purpose-meaning", track: "faith-based", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm018", text: "I am living proof that recovery gives life meaning.", level: 4, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "established", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm019", text: "I am a vessel of my Higher Power's purpose, and I walk in faith today.", level: 4, coreBeliefs: [4], category: "purpose-meaning", track: "faith-based", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm020", text: "I am rediscovering joy in the simple, meaningful parts of life.", level: 2, coreBeliefs: [4], category: "purpose-meaning", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // ============================================================================
  // CATEGORY: integrity-honesty (20+ affirmations)
  // Core Beliefs 1, 2
  // Levels: 2-4
  // ============================================================================

  // -- integrity-honesty: Level 2 (Process) --
  { affirmationId: "aff_lib_ih001", text: "I am practicing honesty in the small things, so I can be trusted with the big things.", level: 2, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih002", text: "I am choosing to tell the truth, even when it feels risky.", level: 2, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih003", text: "I am learning that honesty is the foundation of my recovery.", level: 2, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih004", text: "I am working to make my actions match my words.", level: 2, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih005", text: "I am building a life of integrity, even when nobody is watching.", level: 2, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih006", text: "I am walking in the light of truth, guided by my Higher Power.", level: 2, coreBeliefs: [1, 2], category: "integrity-honesty", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih007", text: "I am developing the discipline to live according to my values.", level: 2, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },

  // -- integrity-honesty: Level 3 (Tempered Identity) --
  { affirmationId: "aff_lib_ih008", text: "I have been dishonest, and I am choosing to live with transparency.", level: 3, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih009", text: "I have broken promises, and today I keep my commitments.", level: 3, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih010", text: "I have lived a double life, and I am choosing one honest life.", level: 3, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih011", text: "I have deceived people I love, and I am making amends through honest living.", level: 3, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih012", text: "I have hidden behind lies, and my Higher Power is helping me live in truth.", level: 3, coreBeliefs: [1, 2], category: "integrity-honesty", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih013", text: "I have let others down, and I am committed to being someone they can count on.", level: 3, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },

  // -- integrity-honesty: Level 4 (Full Identity) --
  { affirmationId: "aff_lib_ih014", text: "I am a person of integrity who lives honestly.", level: 4, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih015", text: "I am honest with myself and with others, and that honesty sets me free.", level: 4, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih016", text: "I am trustworthy because I choose truth every day.", level: 4, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "established", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih017", text: "I am a man whose life is an open book.", level: 4, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "established", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih018", text: "I am anchored in truth, guided by the principles of my Higher Power.", level: 4, coreBeliefs: [1, 2], category: "integrity-honesty", track: "faith-based", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih019", text: "I am someone who keeps his promises and follows through.", level: 4, coreBeliefs: [1, 2], category: "integrity-honesty", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih020", text: "I am freed by living in truth, no longer bound by secrets.", level: 4, coreBeliefs: [1, 2], category: "integrity-honesty", track: "faith-based", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // ============================================================================
  // CATEGORY: daily-strength (20+ affirmations)
  // Core Beliefs 1, 3, 4
  // Levels: 1-2
  // ============================================================================

  // -- daily-strength: Level 1 (Permission) --
  { affirmationId: "aff_lib_ds001", text: "It is OK for me to take this day one moment at a time.", level: 1, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds002", text: "It is OK for me to start fresh today, no matter what happened yesterday.", level: 1, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds003", text: "It is OK for me to celebrate small wins.", level: 1, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "early", readingLevel: 4, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds004", text: "It is OK for me to move at my own pace in recovery.", level: 1, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds005", text: "It is OK for me to ask my Higher Power for strength today.", level: 1, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "faith-based", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds006", text: "It is OK for me to not have all the answers right now.", level: 1, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds007", text: "It is OK for me to be a work in progress.", level: 1, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds008", text: "It is OK for me to trust that today I have what I need.", level: 1, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "faith-based", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },

  // -- daily-strength: Level 2 (Process) --
  { affirmationId: "aff_lib_ds009", text: "I am choosing recovery today, and that is enough.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds010", text: "I am showing up for my life today, even when it feels hard.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds011", text: "I am putting one foot in front of the other, and that is progress.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds012", text: "I am getting stronger with each day I stay committed to my recovery.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds013", text: "I am making choices today that my future self will be grateful for.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds014", text: "I am relying on my Higher Power's strength when mine runs out.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds015", text: "I am present in this day and grateful for the chance to live it well.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds016", text: "I am doing hard things, and I am proving to myself that I can.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds017", text: "I am walking through today with the confidence that comes from sobriety.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds018", text: "I am trusting that my Higher Power gives me enough grace for today.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds019", text: "I am choosing to see each new morning as a gift.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "faith-based", recoveryStage: "middle", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds020", text: "I am facing today with courage, even if my hands are shaking.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // ============================================================================
  // CATEGORY: healthy-sexuality (15+ affirmations)
  // Core Belief 4: Sex is my most important need
  // Levels: 3-4 only
  // ============================================================================

  // -- healthy-sexuality: Level 3 (Tempered Identity) --
  { affirmationId: "aff_lib_hs001", text: "I have used sexuality in harmful ways, and I am learning what healthy intimacy looks like.", level: 3, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs002", text: "I have confused sex with love, and I am discovering the difference.", level: 3, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs003", text: "I have let compulsion control my sexuality, and I am choosing a different way.", level: 3, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs004", text: "I have misused my body, and I am treating it with respect now.", level: 3, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs005", text: "I have distorted what intimacy means, and my Higher Power is restoring my understanding.", level: 3, coreBeliefs: [4], category: "healthy-sexuality", track: "faith-based", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs006", text: "I have sought validation through sex, and I am finding my worth elsewhere.", level: 3, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs007", text: "I have treated others as objects, and today I choose to honor their dignity.", level: 3, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // -- healthy-sexuality: Level 4 (Full Identity) --
  { affirmationId: "aff_lib_hs008", text: "I am a person who values emotional intimacy alongside physical closeness.", level: 4, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "established", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs009", text: "I am free from compulsive sexual behavior and choose healthy expressions of intimacy.", level: 4, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "established", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs010", text: "I am capable of experiencing intimacy rooted in trust and respect.", level: 4, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "established", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs011", text: "I am someone who honors my body and the bodies of others.", level: 4, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs012", text: "I am created for healthy connection, and my Higher Power is healing my view of intimacy.", level: 4, coreBeliefs: [4], category: "healthy-sexuality", track: "faith-based", recoveryStage: "established", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs013", text: "I am a person whose sexuality is integrated with love, commitment, and respect.", level: 4, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "established", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs014", text: "I am defined by more than my sexual behavior; I am a whole person.", level: 4, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs015", text: "I am learning that true intimacy is built on emotional safety, not performance.", level: 3, coreBeliefs: [4], category: "healthy-sexuality", track: "standard", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs016", text: "I am a temple of my Higher Power, and I treat my body as sacred.", level: 4, coreBeliefs: [4], category: "healthy-sexuality", track: "faith-based", recoveryStage: "established", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // ============================================================================
  // CATEGORY: sos-crisis (25+ affirmations)
  // Core Beliefs 1, 3
  // Levels: 1-2 only (grounding, present-moment)
  // ============================================================================

  // -- sos-crisis: Level 1 (Permission / Grounding) --
  { affirmationId: "aff_lib_sos001", text: "It is OK for me to feel this urge without acting on it.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos002", text: "It is OK for me to ride this wave; it peaks and then it passes.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos003", text: "It is OK for me to stop, breathe, and wait before I do anything.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos004", text: "It is OK for me to call someone right now.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 3, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos005", text: "It is OK for me to leave this situation right now.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 4, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos006", text: "It is OK for me to feel uncomfortable; discomfort is not danger.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos007", text: "It is OK for me to put my phone down and walk away.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 4, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos008", text: "It is OK for me to ask my Higher Power for help right now.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "faith-based", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos009", text: "It is OK for me to close my eyes, breathe, and be still.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 4, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos010", text: "It is OK for me to acknowledge this craving without giving in to it.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos011", text: "It is OK for me to trust that this moment of struggle is temporary.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos012", text: "It is OK for me to surrender this moment to my Higher Power.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // -- sos-crisis: Level 2 (Process / Grounding) --
  { affirmationId: "aff_lib_sos013", text: "I am choosing my recovery over this urge, right here, right now.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos014", text: "I am stronger than this moment, and I have the tools to get through it.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos015", text: "I am breathing through this craving, and it is losing its power.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos016", text: "I am remembering why I started this journey and who I am doing it for.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos017", text: "I am staying present in this moment instead of chasing an escape.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos018", text: "I am leaning into my Higher Power's strength because mine alone is not enough.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos019", text: "I am placing my feet on the ground, feeling the earth beneath me, and I am safe.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos020", text: "I am choosing to text my accountability partner instead of acting out.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos021", text: "I am reminding myself that giving in brings relief for minutes but pain for days.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos022", text: "I am already doing the hard thing by reading this instead of acting out.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos023", text: "I am handing this craving to my Higher Power and trusting the outcome.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos024", text: "I am safe, I am grounded, and this urge does not control me.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos025", text: "I am counting backward from ten and letting each number carry some tension away.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "standard", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos026", text: "I am protected by my Higher Power in this moment of weakness.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // ============================================================================
  // ADDITIONAL FAITH-BASED AFFIRMATIONS
  // Brings faith-based track to ~40% of total
  // ============================================================================

  // -- Additional self-worth (faith-based) --
  { affirmationId: "aff_lib_sw032", text: "It is OK for me to believe that God as I understand God delights in me.", level: 1, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw033", text: "I am learning to see myself through the eyes of a loving Higher Power.", level: 2, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw034", text: "I have done things that brought me shame, yet my Higher Power calls me beloved.", level: 3, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sw035", text: "I am a new creation; my past does not define my future in my Higher Power's eyes.", level: 4, coreBeliefs: [1], category: "self-worth", track: "faith-based", recoveryStage: "established", readingLevel: 8, active: true, createdAt: now, updatedAt: now },

  // -- Additional shame-resilience (faith-based) --
  { affirmationId: "aff_lib_sr026", text: "It is OK for me to lay my shame at the feet of my Higher Power.", level: 1, coreBeliefs: [1], category: "shame-resilience", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr027", text: "I am finding that my Higher Power's mercy is new every morning.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr028", text: "I am walking in the freedom that comes from knowing I am forgiven by my Higher Power.", level: 2, coreBeliefs: [1], category: "shame-resilience", track: "faith-based", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sr029", text: "I have carried guilt too long, and my Higher Power has already lifted it.", level: 3, coreBeliefs: [1], category: "shame-resilience", track: "faith-based", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // -- Additional healthy-relationships (faith-based) --
  { affirmationId: "aff_lib_hr026", text: "I am trusting my Higher Power to show me what healthy love looks like.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr027", text: "I am learning to love others the way my Higher Power loves me: without conditions.", level: 2, coreBeliefs: [2], category: "healthy-relationships", track: "faith-based", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr028", text: "I have broken trust, and my Higher Power is teaching me faithfulness.", level: 3, coreBeliefs: [2], category: "healthy-relationships", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hr029", text: "I am loved with an everlasting love, and I extend that love to others.", level: 4, coreBeliefs: [2], category: "healthy-relationships", track: "faith-based", recoveryStage: "established", readingLevel: 7, active: true, createdAt: now, updatedAt: now },

  // -- Additional connection (faith-based) --
  { affirmationId: "aff_lib_cn022", text: "It is OK for me to trust that my Higher Power meets me in my loneliness.", level: 1, coreBeliefs: [3], category: "connection", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn023", text: "I am learning that my Higher Power placed me in community for a reason.", level: 2, coreBeliefs: [3], category: "connection", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn024", text: "I have felt forsaken, and my Higher Power promises never to leave me.", level: 3, coreBeliefs: [3], category: "connection", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_cn025", text: "I am growing in faith that my needs are known and cared for by my Higher Power.", level: 2, coreBeliefs: [3], category: "connection", track: "faith-based", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },

  // -- Additional emotional-regulation (faith-based) --
  { affirmationId: "aff_lib_er021", text: "It is OK for me to give my anxiety to my Higher Power.", level: 1, coreBeliefs: [1, 3], category: "emotional-regulation", track: "faith-based", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er022", text: "I am learning to be still and know that my Higher Power is in control.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er023", text: "I am finding peace by releasing my worries to my Higher Power each morning.", level: 2, coreBeliefs: [1, 3], category: "emotional-regulation", track: "faith-based", recoveryStage: "middle", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_er024", text: "I have been overwhelmed by my feelings, and my Higher Power gives me a sound mind.", level: 3, coreBeliefs: [1, 3], category: "emotional-regulation", track: "faith-based", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },

  // -- Additional purpose-meaning (faith-based) --
  { affirmationId: "aff_lib_pm021", text: "I am trusting that my Higher Power has a plan for my life beyond addiction.", level: 2, coreBeliefs: [4], category: "purpose-meaning", track: "faith-based", recoveryStage: "early", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm022", text: "I have lost direction, and my Higher Power is guiding my steps.", level: 3, coreBeliefs: [4], category: "purpose-meaning", track: "faith-based", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm023", text: "I am a living testimony that my Higher Power can restore what was broken.", level: 4, coreBeliefs: [4], category: "purpose-meaning", track: "faith-based", recoveryStage: "established", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_pm024", text: "I am using my recovery story to bring hope to others, as my Higher Power leads.", level: 4, coreBeliefs: [4], category: "purpose-meaning", track: "faith-based", recoveryStage: "established", readingLevel: 8, active: true, createdAt: now, updatedAt: now },

  // -- Additional integrity-honesty (faith-based) --
  { affirmationId: "aff_lib_ih021", text: "I am learning to walk in truth because my Higher Power is truth.", level: 2, coreBeliefs: [1, 2], category: "integrity-honesty", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih022", text: "I have lived in deception, and my Higher Power is setting me free through honesty.", level: 3, coreBeliefs: [1, 2], category: "integrity-honesty", track: "faith-based", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih023", text: "I am a person of integrity, rooted in the principles my Higher Power teaches me.", level: 4, coreBeliefs: [1, 2], category: "integrity-honesty", track: "faith-based", recoveryStage: "established", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ih024", text: "I am building a life of truth, guided by the light of my Higher Power.", level: 2, coreBeliefs: [1, 2], category: "integrity-honesty", track: "faith-based", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // -- Additional daily-strength (faith-based) --
  { affirmationId: "aff_lib_ds021", text: "It is OK for me to surrender today's worries to my Higher Power.", level: 1, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds022", text: "I am drawing strength from my Higher Power, who renews me each morning.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds023", text: "I am walking through this day with the peace my Higher Power provides.", level: 2, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "faith-based", recoveryStage: "middle", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_ds024", text: "It is OK for me to believe that today is a gift from my Higher Power.", level: 1, coreBeliefs: [1, 3, 4], category: "daily-strength", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },

  // -- Additional healthy-sexuality (faith-based) --
  { affirmationId: "aff_lib_hs017", text: "I have misunderstood intimacy, and my Higher Power is showing me a sacred path.", level: 3, coreBeliefs: [4], category: "healthy-sexuality", track: "faith-based", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs018", text: "I am honoring my body as a gift from my Higher Power.", level: 4, coreBeliefs: [4], category: "healthy-sexuality", track: "faith-based", recoveryStage: "established", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_hs019", text: "I am learning that my Higher Power designed intimacy for connection, not compulsion.", level: 3, coreBeliefs: [4], category: "healthy-sexuality", track: "faith-based", recoveryStage: "middle", readingLevel: 8, active: true, createdAt: now, updatedAt: now },

  // -- Additional sos-crisis (faith-based) --
  { affirmationId: "aff_lib_sos027", text: "It is OK for me to cry out to my Higher Power for help right now.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "faith-based", recoveryStage: "early", readingLevel: 6, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos028", text: "I am trusting my Higher Power to deliver me through this temptation.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos029", text: "It is OK for me to pray through this moment instead of giving in.", level: 1, coreBeliefs: [1, 3], category: "sos-crisis", track: "faith-based", recoveryStage: "early", readingLevel: 5, active: true, createdAt: now, updatedAt: now },
  { affirmationId: "aff_lib_sos030", text: "I am covered by my Higher Power's grace, even in this moment of struggle.", level: 2, coreBeliefs: [1, 3], category: "sos-crisis", track: "faith-based", recoveryStage: "early", readingLevel: 7, active: true, createdAt: now, updatedAt: now }

]);

// Print summary statistics
print("\\n=== Affirmations Library Seed Complete ===");
print("Total: " + db.affirmationsLibrary.countDocuments({}) + " affirmations");
print("");
print("By track:");
print("  Standard:    " + db.affirmationsLibrary.countDocuments({track: "standard"}));
print("  Faith-based: " + db.affirmationsLibrary.countDocuments({track: "faith-based"}));
print("");
print("By level:");
print("  Level 1 (Permission):         " + db.affirmationsLibrary.countDocuments({level: 1}));
print("  Level 2 (Process):            " + db.affirmationsLibrary.countDocuments({level: 2}));
print("  Level 3 (Tempered Identity):  " + db.affirmationsLibrary.countDocuments({level: 3}));
print("  Level 4 (Full Identity):      " + db.affirmationsLibrary.countDocuments({level: 4}));
print("");
print("By category:");
print("  self-worth:            " + db.affirmationsLibrary.countDocuments({category: "self-worth"}));
print("  shame-resilience:      " + db.affirmationsLibrary.countDocuments({category: "shame-resilience"}));
print("  healthy-relationships: " + db.affirmationsLibrary.countDocuments({category: "healthy-relationships"}));
print("  connection:            " + db.affirmationsLibrary.countDocuments({category: "connection"}));
print("  emotional-regulation:  " + db.affirmationsLibrary.countDocuments({category: "emotional-regulation"}));
print("  purpose-meaning:       " + db.affirmationsLibrary.countDocuments({category: "purpose-meaning"}));
print("  integrity-honesty:     " + db.affirmationsLibrary.countDocuments({category: "integrity-honesty"}));
print("  daily-strength:        " + db.affirmationsLibrary.countDocuments({category: "daily-strength"}));
print("  healthy-sexuality:     " + db.affirmationsLibrary.countDocuments({category: "healthy-sexuality"}));
print("  sos-crisis:            " + db.affirmationsLibrary.countDocuments({category: "sos-crisis"}));
MONGOSCRIPT
