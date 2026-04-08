// internal/domain/personcheckin/quick_log.go
package personcheckin

import "time"

// DefaultMethodForQuickLog returns the default method for a quick-log entry.
// It uses the last-used method for the sub-type if available, otherwise defaults to in-person.
func DefaultMethodForQuickLog(settings *PersonCheckInSettings, checkInType CheckInType) Method {
	subSettings := GetSubTypeSettings(settings, checkInType)
	if subSettings != nil && subSettings.LastUsedMethod != nil {
		return *subSettings.LastUsedMethod
	}
	return MethodInPerson
}

// BuildQuickLogCheckIn creates a PersonCheckIn from a quick-log request.
func BuildQuickLogCheckIn(req *QuickLogPersonCheckInRequest, settings *PersonCheckInSettings, checkInID, userID, tenantID string) *PersonCheckIn {
	now := time.Now()

	method := DefaultMethodForQuickLog(settings, req.CheckInType)
	if req.Method != nil {
		method = *req.Method
	}

	// Auto-populate contact name from settings.
	var contactName *string
	subSettings := GetSubTypeSettings(settings, req.CheckInType)
	if subSettings != nil && subSettings.ContactName != nil {
		contactName = subSettings.ContactName
	}

	return &PersonCheckIn{
		CheckInID:   checkInID,
		UserID:      userID,
		TenantID:    tenantID,
		CheckInType: req.CheckInType,
		Method:      method,
		Timestamp:   now,
		ContactName: contactName,
		CreatedAt:   now,
		ModifiedAt:  now,
	}
}

// ApplyUpdate applies a partial update to a check-in.
// The createdAt and checkInType fields are immutable.
func ApplyUpdate(checkIn *PersonCheckIn, req *UpdatePersonCheckInRequest) {
	if req.Method != nil {
		checkIn.Method = *req.Method
	}

	if req.ContactName != nil {
		checkIn.ContactName = req.ContactName
	}

	if req.DurationMinutes != nil {
		checkIn.DurationMinutes = req.DurationMinutes
	}

	if req.QualityRating != nil {
		checkIn.QualityRating = req.QualityRating
	}

	if req.TopicsDiscussed != nil {
		checkIn.TopicsDiscussed = req.TopicsDiscussed
	}

	if req.Notes != nil {
		checkIn.Notes = req.Notes
	}

	if req.FollowUpItems != nil {
		checkIn.FollowUpItems = FollowUpItemsFromStrings(req.FollowUpItems)
	}

	if req.CounselorSubCategory != nil {
		checkIn.CounselorSubCategory = req.CounselorSubCategory
	}

	checkIn.ModifiedAt = time.Now()
	// createdAt remains unchanged (immutable - FR2.7 / NFR-PCI-1).
}
