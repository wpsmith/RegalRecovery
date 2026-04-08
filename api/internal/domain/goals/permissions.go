// internal/domain/goals/permissions.go
package goals

// PermissionChecker is an interface for checking support network permissions (AC-IP-3).
type PermissionChecker interface {
	// HasPermission checks if the requesting user has permission to view
	// another user's goal data. Returns true if permission is granted.
	HasPermission(requestingUserID, targetUserID, dataCategory string) (bool, error)
}

// GoalsPermissionCategory is the data category key for goals visibility.
const GoalsPermissionCategory = "goals"

// CheckSponsorViewPermission verifies the requesting user can view the target user's goals.
// Returns false for unauthorized access (AC-IP-3).
// We return 404 (not 403) to hide data existence from unauthorized users.
func CheckSponsorViewPermission(checker PermissionChecker, requestingUserID, targetUserID string) (bool, error) {
	return checker.HasPermission(requestingUserID, targetUserID, GoalsPermissionCategory)
}
