// internal/domain/postmortem/sharing.go
package postmortem

import "context"

// CanShare checks if a post-mortem can be shared (must be complete).
func CanShare(analysis *PostMortemAnalysis) error {
	if analysis.Status != StatusComplete {
		return ErrCannotShareDraft
	}
	return nil
}

// CanExport checks if a post-mortem can be exported (must be complete).
func CanExport(analysis *PostMortemAnalysis) error {
	if analysis.Status != StatusComplete {
		return ErrCannotExportDraft
	}
	return nil
}

// CheckSharedAccess verifies a contact has permission to view a shared post-mortem.
// Returns the analysis if access is granted, ErrNotFound if denied (per PM-AC7.5).
func CheckSharedAccess(ctx context.Context, analysis *PostMortemAnalysis, contactID string, checker PermissionChecker) (*PostMortemAnalysis, error) {
	// Check if the contact is in the shared list.
	for _, share := range analysis.Sharing.SharedWith {
		if share.ContactID == contactID {
			// Verify permission.
			hasPermission, err := checker.HasPermission(ctx, analysis.UserID, contactID, "post-mortem:read")
			if err != nil {
				return nil, err
			}
			if hasPermission {
				return analysis, nil
			}
		}
	}
	// Return 404, not 403, to hide existence.
	return nil, ErrNotFound
}
