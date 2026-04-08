// internal/domain/devotionals/share.go
package devotionals

import (
	"errors"
	"fmt"
)

var (
	// ErrInvalidShareType indicates an invalid share type.
	ErrInvalidShareType = errors.New("invalid share type")

	// ErrContactRequired indicates a contact ID is required for contact sharing.
	ErrContactRequired = errors.New("contact ID required for contact share type")

	// ErrContactNotFound indicates the contact was not found.
	ErrContactNotFound = errors.New("contact not found")
)

// ShareService manages devotional sharing.
type ShareService struct {
	contentRepo DevotionalContentRepository
}

// NewShareService creates a new ShareService.
func NewShareService(contentRepo DevotionalContentRepository) *ShareService {
	return &ShareService{contentRepo: contentRepo}
}

// ShareDevotional generates a shareable representation of a devotional.
// The shared content never includes the user's personal reflection (AC-DEV-SHARE-01).
func (s *ShareService) ShareDevotional(devotionalID string, req *ShareRequest, contactExists func(string) bool) (*ShareResponse, error) {
	if req.ShareType != ShareContact && req.ShareType != ShareLink && req.ShareType != ShareImage {
		return nil, ErrInvalidShareType
	}

	if req.ShareType == ShareContact {
		if req.ContactID == nil || *req.ContactID == "" {
			return nil, ErrContactRequired
		}
		if !contactExists(*req.ContactID) {
			return nil, ErrContactNotFound
		}
	}

	resp := &ShareResponse{}
	switch req.ShareType {
	case ShareLink, ShareImage:
		url := fmt.Sprintf("https://app.regalrecovery.com/devotionals/%s", devotionalID)
		resp.Data.ShareURL = &url
		resp.Data.Message = "Devotional shared via link"
	case ShareContact:
		resp.Data.SharedToContactID = req.ContactID
		resp.Data.Message = "Devotional shared with contact"
	}

	return resp, nil
}

// BuildShareableContent creates a sanitized content payload suitable for sharing.
// It excludes the user's reflection and personal data.
func BuildShareableContent(d *DevotionalContent, language Language, translation BibleTranslation) map[string]string {
	content := map[string]string{
		"title":              d.Title,
		"scriptureReference": d.ScriptureReference,
	}

	if text, ok := d.ScriptureText[translation]; ok {
		content["scriptureText"] = text
	}
	if reading, ok := d.Reading[language]; ok {
		content["reading"] = reading
	}
	if prayer, ok := d.Prayer[language]; ok {
		content["prayer"] = prayer
	}
	if d.AuthorName != nil {
		content["authorName"] = *d.AuthorName
	}

	return content
}
