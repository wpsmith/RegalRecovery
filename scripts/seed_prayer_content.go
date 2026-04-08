// scripts/seed_prayer_content.go
//
// Seeds prayer content into MongoDB for local development.
// Run via: go run scripts/seed_prayer_content.go
//
// This seeds:
// - Freemium prayer content (step prayers, core prayers)
// - Sample premium prayer packs (temptation, shame, marriage)
// - Persona prayer history fixtures (Alex, Diego)

package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

func main() {
	mongoURI := os.Getenv("MONGODB_URI")
	if mongoURI == "" {
		mongoURI = "mongodb://localhost:27017"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client, err := mongo.Connect(options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatalf("Failed to connect to MongoDB: %v", err)
	}
	defer client.Disconnect(ctx)

	db := client.Database("regalrecovery")
	collection := db.Collection("main")

	// Clear existing prayer content.
	_, _ = collection.DeleteMany(ctx, bson.M{"entityType": bson.M{"$in": bson.A{"PRAYER_CONTENT", "PRAYER_SESSION", "PERSONAL_PRAYER", "PRAYER_FAVORITE"}}})

	// Seed freemium prayers.
	seedFreemiumPrayers(ctx, collection)

	// Seed premium sample prayers.
	seedPremiumPrayers(ctx, collection)

	fmt.Println("Prayer content seeded successfully.")
}

func seedFreemiumPrayers(ctx context.Context, coll *mongo.Collection) {
	now := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)

	corePrayers := []bson.M{
		prayerDoc("pack_core", "pryr_serenity", "Serenity Prayer (Full)", serenityPrayerBody, "Reinhold Niebuhr", strPtr("Philippians 4:6-7"), nil, "free", "en", now),
		prayerDoc("pack_core", "pryr_lords", "Lord's Prayer", lordsPrayerBody, "Matthew 6:9-13", strPtr("Matthew 6:9-13"), nil, "free", "en", now),
		prayerDoc("pack_core", "pryr_morning", "Morning Prayer for Recovery", morningPrayerBody, "App Original", strPtr("Lamentations 3:22-23"), nil, "free", "en", now),
		prayerDoc("pack_core", "pryr_evening", "Evening Prayer for Recovery", eveningPrayerBody, "App Original", strPtr("Psalm 4:8"), nil, "free", "en", now),
		prayerDoc("pack_core", "pryr_courage", "Prayer for Courage", couragePrayerBody, "App Original", strPtr("Joshua 1:9"), nil, "free", "en", now),
		prayerDoc("pack_core", "pryr_gratitude", "Prayer of Gratitude in Recovery", gratitudePrayerBody, "App Original", strPtr("1 Thessalonians 5:18"), nil, "free", "en", now),
		prayerDoc("pack_core", "pryr_forgiveness", "Prayer for Forgiveness", forgivenessPrayerBody, "App Original", strPtr("Psalm 51:10"), nil, "free", "en", now),
		prayerDoc("pack_core", "pryr_strength", "Prayer for Strength", strengthPrayerBody, "App Original", strPtr("Isaiah 40:29-31"), nil, "free", "en", now),
		prayerDoc("pack_core", "pryr_surrender", "Prayer of Surrender", surrenderPrayerBody, "App Original", strPtr("Matthew 11:28-30"), nil, "free", "en", now),
	}

	for _, doc := range corePrayers {
		_, err := coll.InsertOne(ctx, doc)
		if err != nil {
			log.Printf("Warning: failed to seed prayer %v: %v", doc["prayerId"], err)
		}
	}

	// Step prayers (1-12).
	stepScriptures := map[int]string{
		1: "2 Corinthians 12:9-10", 2: "Jeremiah 29:11", 3: "Proverbs 3:5-6",
		4: "Psalm 139:23-24", 5: "James 5:16", 6: "Ezekiel 36:26",
		7: "1 Peter 5:6", 8: "Matthew 5:23-24", 9: "Romans 12:18",
		10: "1 John 1:8-9", 11: "Psalm 46:10", 12: "Galatians 6:1-2",
	}
	stepTitles := map[int]string{
		1: "Admitting Powerlessness", 2: "Believing in Restoration", 3: "Turning Over My Will",
		4: "Courage for Moral Inventory", 5: "Honesty Before God and Others", 6: "Readiness for Change",
		7: "Humility Before God", 8: "Willingness to Make Amends", 9: "Making Direct Amends",
		10: "Daily Inventory", 11: "Conscious Contact with God", 12: "Carrying the Message",
	}

	for step := 1; step <= 12; step++ {
		title := fmt.Sprintf("Step %d Prayer: %s", step, stepTitles[step])
		id := fmt.Sprintf("pryr_step%02d", step)
		scripture := stepScriptures[step]
		stepNum := step
		doc := prayerDoc("pack_step_prayers", id, title, fmt.Sprintf("God, help me with Step %d...", step), "App Original", &scripture, &stepNum, "free", "en", now)
		_, err := coll.InsertOne(ctx, doc)
		if err != nil {
			log.Printf("Warning: failed to seed step prayer %d: %v", step, err)
		}
	}

	fmt.Printf("Seeded %d freemium prayers\n", len(corePrayers)+12)
}

func seedPremiumPrayers(ctx context.Context, coll *mongo.Collection) {
	now := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)

	premiumPrayers := []bson.M{
		prayerDoc("pack_temptation", "pryr_tempt01", "Prayer for Strength Against Temptation", "Heavenly Father, I come to You in my weakness...", "App Original", strPtr("1 Corinthians 10:13"), nil, "premium", "en", now),
		prayerDoc("pack_temptation", "pryr_tempt02", "Prayer When Urges Are Strong", "God, the urge is here and it feels overwhelming...", "App Original", strPtr("James 4:7-8"), nil, "premium", "en", now),
		prayerDoc("pack_temptation", "pryr_tempt03", "Prayer for Purity of Thought", "Lord, cleanse my mind...", "App Original", strPtr("Philippians 4:8"), nil, "premium", "en", now),
		prayerDoc("pack_shame", "pryr_shame01", "Prayer for Release from Shame", "Father, the voice of shame is loud today...", "App Original", strPtr("Romans 8:1"), nil, "premium", "en", now),
		prayerDoc("pack_shame", "pryr_shame02", "Prayer for Identity in Christ", "God, remind me who I am in You...", "App Original", strPtr("2 Corinthians 5:17"), nil, "premium", "en", now),
		prayerDoc("pack_shame", "pryr_shame03", "Prayer Against Condemnation", "Lord, You are the one who blots out my transgressions...", "App Original", strPtr("Isaiah 43:25"), nil, "premium", "en", now),
		prayerDoc("pack_marriage", "pryr_marriage01", "Prayer for My Spouse's Healing", "God, my addiction has wounded the person I love most...", "App Original", strPtr("Psalm 147:3"), nil, "premium", "en", now),
		prayerDoc("pack_marriage", "pryr_marriage02", "Prayer for Trust Restoration", "Father, I have broken trust...", "App Original", strPtr("Proverbs 3:3-4"), nil, "premium", "en", now),
		prayerDoc("pack_marriage", "pryr_marriage03", "Prayer for Honest Communication", "Lord, teach me to speak the truth in love...", "App Original", strPtr("Ephesians 4:25"), nil, "premium", "en", now),
	}

	for _, doc := range premiumPrayers {
		_, err := coll.InsertOne(ctx, doc)
		if err != nil {
			log.Printf("Warning: failed to seed premium prayer %v: %v", doc["prayerId"], err)
		}
	}

	fmt.Printf("Seeded %d premium prayers\n", len(premiumPrayers))
}

func prayerDoc(packID, prayerID, title, body, attribution string, scripture *string, stepNumber *int, tier, language string, createdAt time.Time) bson.M {
	doc := bson.M{
		"PK":                "PACK#" + packID,
		"SK":                "PRAYER_CONTENT#" + prayerID,
		"entityType":        "PRAYER_CONTENT",
		"tenantId":          "SYSTEM",
		"createdAt":         createdAt,
		"modifiedAt":        createdAt,
		"prayerId":          prayerID,
		"title":             title,
		"body":              body,
		"sourceAttribution": attribution,
		"tier":              tier,
		"language":          language,
		"topicTags":         []string{},
	}
	if scripture != nil {
		doc["scriptureConnection"] = *scripture
	}
	if stepNumber != nil {
		doc["stepNumber"] = *stepNumber
	}
	return doc
}

func strPtr(s string) *string { return &s }

// Prayer body text constants (abbreviated for seed data).
const serenityPrayerBody = `God, grant me the serenity to accept the things I cannot change, the courage to change the things I can, and the wisdom to know the difference. Living one day at a time, enjoying one moment at a time; accepting hardship as a pathway to peace; taking, as Jesus did, this sinful world as it is, not as I would have it; trusting that You will make all things right if I surrender to Your will; so that I may be reasonably happy in this life and supremely happy with You forever in the next. Amen.`

const lordsPrayerBody = `Our Father, who art in heaven, hallowed be Thy name. Thy kingdom come, Thy will be done, on earth as it is in heaven. Give us this day our daily bread, and forgive us our trespasses, as we forgive those who trespass against us. And lead us not into temptation, but deliver us from evil. For Thine is the kingdom, and the power, and the glory, forever and ever. Amen.`

const morningPrayerBody = `Lord, as I begin this new day, I thank You that Your mercies are new every morning. I surrender this day to You. Guard my eyes, my heart, and my mind. Where temptation meets me, give me the strength to turn away. Let me walk in honesty today. If I stumble, catch me. Amen.`

const eveningPrayerBody = `Father, as this day comes to a close, I come before You with an honest heart. Thank You for the strength You gave me today. Where I honored my commitments, I give You the glory. Where I fell short, I ask for Your forgiveness. Guard my sleep. In peace I will lie down and sleep. Amen.`

const couragePrayerBody = `Lord, I need Your courage today. The path of recovery is hard. Remind me that You have not given me a spirit of fear, but of power, love, and a sound mind. I choose to walk forward, one step at a time. Amen.`

const gratitudePrayerBody = `Father, thank You for this day of sobriety. Thank You for the people who walk beside me. Thank You for the strength that is not my own. Every sober day is a miracle, and I do not take it for granted. Amen.`

const forgivenessPrayerBody = `God, create in me a clean heart. The weight of guilt is heavy, but Your grace is heavier. I receive Your forgiveness today. Help me to forgive myself as You have forgiven me. Amen.`

const strengthPrayerBody = `Lord, I am weary. Recovery demands more than I have to give. But You promise to give strength to the weary. I wait on You today. Renew my strength. Amen.`

const surrenderPrayerBody = `Jesus, I am tired of carrying this alone. I come to You with my burdens. Your yoke is easy and Your burden is light. I stop fighting and start resting in You. Amen.`
