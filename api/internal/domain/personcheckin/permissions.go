// internal/domain/personcheckin/permissions.go
package personcheckin

// FilterCheckInsByViewerRole filters check-ins based on the viewer's role.
// Per community permissions:
// - Spouse: sees only spouse sub-type check-ins
// - Sponsor/Counselor: sees all sub-types (except journal & financial, which doesn't apply here)
// - AP (Accountability Partner): sees all sub-types
// - No permission: returns empty (caller should return 404)
func FilterCheckInsByViewerRole(checkIns []PersonCheckIn, viewerRole string) []PersonCheckIn {
	if !hasViewPermission(viewerRole) {
		return nil
	}

	if viewerRole == "spouse" {
		// FR-PCI-10.1: Spouse sees only spouse sub-type.
		var filtered []PersonCheckIn
		for _, ci := range checkIns {
			if ci.CheckInType == CheckInTypeSpouse {
				filtered = append(filtered, ci)
			}
		}
		return filtered
	}

	// FR-PCI-10.2: Sponsor, counselor, AP see all sub-types.
	return checkIns
}

// hasViewPermission checks if a role has permission to view person check-in data.
func hasViewPermission(role string) bool {
	switch role {
	case "spouse", "sponsor", "counselor", "accountability-partner":
		return true
	default:
		// FR-PCI-10.3: No permission granted → return empty (caller returns 404).
		return false
	}
}

// CanViewPersonCheckIns determines whether a viewer has access based on their role
// and whether explicit permission has been granted.
func CanViewPersonCheckIns(hasPermission bool, viewerRole string) bool {
	if !hasPermission {
		return false
	}
	return hasViewPermission(viewerRole)
}
