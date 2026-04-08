// internal/domain/postmortem/sharing_test.go
package postmortem

import (
	"context"
	"errors"
	"testing"
)

// TestPostMortem_PM_AC7_1_OptInSharing verifies sharing requires complete status.
// Acceptance Criterion (PM-AC7.1): Only completed post-mortems can be shared.
func TestPostMortem_PM_AC7_1_OptInSharing(t *testing.T) {
	complete := &PostMortemAnalysis{Status: StatusComplete}
	err := CanShare(complete)
	if err != nil {
		t.Errorf("expected completed post-mortem to be shareable, got: %v", err)
	}
}

// TestPostMortem_PM_AC7_1_DraftNotShareable verifies drafts cannot be shared.
func TestPostMortem_PM_AC7_1_DraftNotShareable(t *testing.T) {
	draft := &PostMortemAnalysis{Status: StatusDraft}
	err := CanShare(draft)
	if !errors.Is(err, ErrCannotShareDraft) {
		t.Errorf("expected ErrCannotShareDraft, got: %v", err)
	}
}

// TestPostMortem_CanExport_Complete verifies export requires complete status.
func TestPostMortem_CanExport_Complete(t *testing.T) {
	complete := &PostMortemAnalysis{Status: StatusComplete}
	err := CanExport(complete)
	if err != nil {
		t.Errorf("expected completed post-mortem to be exportable, got: %v", err)
	}
}

// TestPostMortem_CanExport_Draft verifies drafts cannot be exported.
func TestPostMortem_CanExport_Draft(t *testing.T) {
	draft := &PostMortemAnalysis{Status: StatusDraft}
	err := CanExport(draft)
	if !errors.Is(err, ErrCannotExportDraft) {
		t.Errorf("expected ErrCannotExportDraft, got: %v", err)
	}
}

// TestPostMortem_CheckSharedAccess_Granted verifies shared access with permission.
func TestPostMortem_CheckSharedAccess_Granted(t *testing.T) {
	analysis := &PostMortemAnalysis{
		UserID: "u_12345",
		Status: StatusComplete,
		Sharing: SharingStatus{
			IsShared: true,
			SharedWith: []SharedWithEntry{
				{ContactID: "c_99999", ShareType: ShareTypeFull},
			},
		},
	}

	checker := &mockPermissions{allowed: true}
	result, err := CheckSharedAccess(context.Background(), analysis, "c_99999", checker)
	if err != nil {
		t.Fatalf("expected access granted, got error: %v", err)
	}
	if result.UserID != analysis.UserID {
		t.Error("expected the analysis to be returned")
	}
}

// TestPostMortem_CheckSharedAccess_Denied verifies access denied returns 404.
func TestPostMortem_CheckSharedAccess_Denied(t *testing.T) {
	analysis := &PostMortemAnalysis{
		UserID: "u_12345",
		Status: StatusComplete,
		Sharing: SharingStatus{
			IsShared: true,
			SharedWith: []SharedWithEntry{
				{ContactID: "c_99999", ShareType: ShareTypeFull},
			},
		},
	}

	checker := &mockPermissions{allowed: false}
	_, err := CheckSharedAccess(context.Background(), analysis, "c_99999", checker)
	if !errors.Is(err, ErrNotFound) {
		t.Errorf("expected ErrNotFound for denied access, got: %v", err)
	}
}

// TestPostMortem_CheckSharedAccess_NotShared verifies unshared contact gets 404.
func TestPostMortem_CheckSharedAccess_NotShared(t *testing.T) {
	analysis := &PostMortemAnalysis{
		UserID: "u_12345",
		Status: StatusComplete,
		Sharing: SharingStatus{
			IsShared:   false,
			SharedWith: nil,
		},
	}

	checker := &mockPermissions{allowed: true}
	_, err := CheckSharedAccess(context.Background(), analysis, "c_99999", checker)
	if !errors.Is(err, ErrNotFound) {
		t.Errorf("expected ErrNotFound for unshared contact, got: %v", err)
	}
}
