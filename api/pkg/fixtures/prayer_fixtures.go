// pkg/fixtures/prayer_fixtures.go
package fixtures

import (
	"time"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

func intPtr(v int) *int       { return &v }
func strPtr(v string) *string { return &v }

func daysAgo(n int) time.Time {
	return time.Now().UTC().AddDate(0, 0, -n).Truncate(24 * time.Hour).Add(6 * time.Hour)
}

// AlexPrayerHistory represents Alex's prayer history -- 14 consecutive days.
var AlexPrayerHistory = []prayer.PrayerSession{
	{PrayerID: "ps_alex01", UserID: "u_alex", PrayerType: "personal", DurationMinutes: intPtr(15), Timestamp: daysAgo(0), MoodBefore: intPtr(3), MoodAfter: intPtr(4)},
	{PrayerID: "ps_alex02", UserID: "u_alex", PrayerType: "guided", DurationMinutes: intPtr(10), Timestamp: daysAgo(1), LinkedPrayerID: strPtr("pryr_step04"), LinkedPrayerTitle: strPtr("Step 4 Prayer: Courage for Moral Inventory")},
	{PrayerID: "ps_alex03", UserID: "u_alex", PrayerType: "personal", DurationMinutes: nil, Timestamp: daysAgo(2)},
	{PrayerID: "ps_alex04", UserID: "u_alex", PrayerType: "scriptureBased", DurationMinutes: intPtr(20), Timestamp: daysAgo(3), MoodBefore: intPtr(2), MoodAfter: intPtr(4)},
	{PrayerID: "ps_alex05", UserID: "u_alex", PrayerType: "personal", DurationMinutes: intPtr(12), Timestamp: daysAgo(4)},
	{PrayerID: "ps_alex06", UserID: "u_alex", PrayerType: "listening", DurationMinutes: intPtr(8), Timestamp: daysAgo(5)},
	{PrayerID: "ps_alex07", UserID: "u_alex", PrayerType: "personal", DurationMinutes: intPtr(15), Timestamp: daysAgo(6)},
	{PrayerID: "ps_alex08", UserID: "u_alex", PrayerType: "guided", DurationMinutes: intPtr(10), Timestamp: daysAgo(7)},
	{PrayerID: "ps_alex09", UserID: "u_alex", PrayerType: "intercessory", DurationMinutes: intPtr(20), Timestamp: daysAgo(8)},
	{PrayerID: "ps_alex10", UserID: "u_alex", PrayerType: "personal", DurationMinutes: intPtr(5), Timestamp: daysAgo(9)},
	{PrayerID: "ps_alex11", UserID: "u_alex", PrayerType: "group", DurationMinutes: intPtr(30), Timestamp: daysAgo(10)},
	{PrayerID: "ps_alex12", UserID: "u_alex", PrayerType: "personal", DurationMinutes: intPtr(10), Timestamp: daysAgo(11)},
	{PrayerID: "ps_alex13", UserID: "u_alex", PrayerType: "scriptureBased", DurationMinutes: intPtr(15), Timestamp: daysAgo(12)},
	{PrayerID: "ps_alex14", UserID: "u_alex", PrayerType: "personal", DurationMinutes: intPtr(8), Timestamp: daysAgo(13)},
}

// MarcusPrayerHistory represents Marcus's prayer history -- no engagement yet.
var MarcusPrayerHistory = []prayer.PrayerSession{}

// DiegoPrayerHistory represents Diego's prayer history -- prays twice daily, 30-day streak.
func DiegoPrayerHistory() []prayer.PrayerSession {
	var sessions []prayer.PrayerSession
	for i := 0; i < 30; i++ {
		baseTime := daysAgo(i)
		// Morning prayer.
		sessions = append(sessions, prayer.PrayerSession{
			PrayerID:        "ps_diego_m" + time.Now().Format("0102") + "_" + string(rune('A'+i)),
			UserID:          "u_diego",
			PrayerType:      "personal",
			DurationMinutes: intPtr(20),
			Timestamp:       baseTime,
			MoodBefore:      intPtr(3),
			MoodAfter:       intPtr(4),
		})
		// Evening prayer.
		sessions = append(sessions, prayer.PrayerSession{
			PrayerID:        "ps_diego_e" + time.Now().Format("0102") + "_" + string(rune('A'+i)),
			UserID:          "u_diego",
			PrayerType:      "intercessory",
			DurationMinutes: intPtr(10),
			Timestamp:       baseTime.Add(14 * time.Hour),
			MoodBefore:      intPtr(3),
			MoodAfter:       intPtr(5),
		})
	}
	return sessions
}

// FreemiumPrayers are the free prayer content that all users can access.
var FreemiumPrayers = []prayer.LibraryPrayer{
	{ID: "pryr_serenity", Title: "Serenity Prayer (Full)", PackID: "pack_core", Tier: "free", Language: "en", SourceAttribution: "Reinhold Niebuhr"},
	{ID: "pryr_lords", Title: "Lord's Prayer", PackID: "pack_core", Tier: "free", Language: "en", SourceAttribution: "Matthew 6:9-13"},
	{ID: "pryr_morning", Title: "Morning Prayer for Recovery", PackID: "pack_core", Tier: "free", Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_evening", Title: "Evening Prayer for Recovery", PackID: "pack_core", Tier: "free", Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step01", Title: "Step 1 Prayer: Admitting Powerlessness", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(1), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step02", Title: "Step 2 Prayer: Believing in Restoration", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(2), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step03", Title: "Step 3 Prayer: Turning Over My Will", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(3), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step04", Title: "Step 4 Prayer: Courage for Moral Inventory", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(4), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step05", Title: "Step 5 Prayer: Honesty Before God and Others", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(5), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step06", Title: "Step 6 Prayer: Readiness for Change", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(6), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step07", Title: "Step 7 Prayer: Humility Before God", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(7), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step08", Title: "Step 8 Prayer: Willingness to Make Amends", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(8), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step09", Title: "Step 9 Prayer: Making Direct Amends", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(9), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step10", Title: "Step 10 Prayer: Daily Inventory", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(10), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step11", Title: "Step 11 Prayer: Conscious Contact with God", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(11), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_step12", Title: "Step 12 Prayer: Carrying the Message", PackID: "pack_step_prayers", Tier: "free", StepNumber: intPtr(12), Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_courage", Title: "Prayer for Courage", PackID: "pack_core", Tier: "free", Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_gratitude", Title: "Prayer of Gratitude in Recovery", PackID: "pack_core", Tier: "free", Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_forgiveness", Title: "Prayer for Forgiveness", PackID: "pack_core", Tier: "free", Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_strength", Title: "Prayer for Strength", PackID: "pack_core", Tier: "free", Language: "en", SourceAttribution: "App Original"},
	{ID: "pryr_surrender", Title: "Prayer of Surrender", PackID: "pack_core", Tier: "free", Language: "en", SourceAttribution: "App Original"},
}

// PremiumPrayers are sample premium prayer content.
var PremiumPrayers = []prayer.LibraryPrayer{
	{ID: "pryr_tempt01", Title: "Prayer for Strength Against Temptation", PackID: "pack_temptation", Tier: "premium", Language: "en", SourceAttribution: "App Original", TopicTags: []string{"temptation", "strength"}},
	{ID: "pryr_tempt02", Title: "Prayer When Urges Are Strong", PackID: "pack_temptation", Tier: "premium", Language: "en", SourceAttribution: "App Original", TopicTags: []string{"temptation", "urges"}},
	{ID: "pryr_tempt03", Title: "Prayer for Purity of Thought", PackID: "pack_temptation", Tier: "premium", Language: "en", SourceAttribution: "App Original", TopicTags: []string{"temptation", "purity"}},
	{ID: "pryr_shame01", Title: "Prayer for Release from Shame", PackID: "pack_shame", Tier: "premium", Language: "en", SourceAttribution: "App Original", TopicTags: []string{"shame", "identity"}},
	{ID: "pryr_shame02", Title: "Prayer for Identity in Christ", PackID: "pack_shame", Tier: "premium", Language: "en", SourceAttribution: "App Original", TopicTags: []string{"shame", "identity"}},
	{ID: "pryr_shame03", Title: "Prayer Against Condemnation", PackID: "pack_shame", Tier: "premium", Language: "en", SourceAttribution: "App Original", TopicTags: []string{"shame", "freedom"}},
	{ID: "pryr_marriage01", Title: "Prayer for My Spouse's Healing", PackID: "pack_marriage", Tier: "premium", Language: "en", SourceAttribution: "App Original", TopicTags: []string{"marriage", "healing"}},
	{ID: "pryr_marriage02", Title: "Prayer for Trust Restoration", PackID: "pack_marriage", Tier: "premium", Language: "en", SourceAttribution: "App Original", TopicTags: []string{"marriage", "trust"}},
	{ID: "pryr_marriage03", Title: "Prayer for Honest Communication", PackID: "pack_marriage", Tier: "premium", Language: "en", SourceAttribution: "App Original", TopicTags: []string{"marriage", "honesty"}},
}
