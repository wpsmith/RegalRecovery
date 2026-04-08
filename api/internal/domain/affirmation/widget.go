// internal/domain/affirmation/widget.go
package affirmation

// GetWidgetData assembles the dashboard widget data for the affirmation activity.
func GetWidgetData(
	todayAffirmation *Affirmation,
	progress *AffirmationProgress,
	hasReadToday bool,
) *AffirmationWidgetData {
	statement := ""
	affID := ""
	category := ""

	if todayAffirmation != nil {
		statement = todayAffirmation.Statement
		if len(statement) > 100 {
			statement = statement[:97] + "..."
		}
		affID = todayAffirmation.AffirmationID
		category = string(todayAffirmation.Category)
	}

	totalRead := 0
	totalFavorites := 0
	if progress != nil {
		totalRead = progress.TotalRead
		totalFavorites = progress.TotalFavorites
	}

	return &AffirmationWidgetData{
		TodayStatement:     statement,
		TodayAffirmationID: affID,
		TodayCategory:      category,
		TotalRead:          totalRead,
		TotalFavorites:     totalFavorites,
		HasReadToday:       hasReadToday,
	}
}
