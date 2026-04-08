// internal/domain/phonecalls/validator.go
package phonecalls

import (
	"errors"
	"fmt"
	"regexp"
	"strings"
)

var (
	// ErrInvalidDirection indicates the direction value is not valid.
	ErrInvalidDirection = errors.New("direction must be 'made' or 'received'")

	// ErrInvalidContactType indicates the contact type value is not valid.
	ErrInvalidContactType = errors.New("invalid contact type")

	// ErrCustomLabelRequired indicates customContactLabel is required when contactType is custom.
	ErrCustomLabelRequired = errors.New("customContactLabel is required when contactType is custom")

	// ErrContactNameTooLong indicates contact name exceeds 50 characters.
	ErrContactNameTooLong = errors.New("contactName must not exceed 50 characters")

	// ErrNotesTooLong indicates notes exceed 500 characters.
	ErrNotesTooLong = errors.New("notes must not exceed 500 characters")

	// ErrNegativeDuration indicates duration is negative.
	ErrNegativeDuration = errors.New("durationMinutes must not be negative")

	// ErrTimestampImmutable indicates an attempt to change an immutable timestamp.
	ErrTimestampImmutable = errors.New("timestamp is immutable")

	// ErrInvalidPhoneNumber indicates the phone number is not in E.164 format.
	ErrInvalidPhoneNumber = errors.New("phoneNumber must be in E.164 format")

	// ErrSavedContactNameRequired indicates the contact name is required.
	ErrSavedContactNameRequired = errors.New("contactName is required")

	// ErrMaxSavedContacts indicates the maximum number of saved contacts has been reached.
	ErrMaxSavedContacts = errors.New("maximum 10 saved contacts allowed")

	// ErrPhoneCallNotFound indicates the phone call does not exist.
	ErrPhoneCallNotFound = errors.New("phone call not found")

	// ErrSavedContactNotFound indicates the saved contact does not exist.
	ErrSavedContactNotFound = errors.New("saved contact not found")
)

// MaxContactNameLength is the maximum length for contact names.
const MaxContactNameLength = 50

// MaxNotesLength is the maximum length for notes.
const MaxNotesLength = 500

// MaxSavedContacts is the maximum number of saved contacts per user.
const MaxSavedContacts = 10

// validDirections contains all valid direction values.
var validDirections = map[Direction]bool{
	DirectionMade:     true,
	DirectionReceived: true,
}

// validContactTypes contains all valid contact type values.
var validContactTypes = map[ContactType]bool{
	ContactTypeSponsor:               true,
	ContactTypeAccountabilityPartner: true,
	ContactTypeCounselor:             true,
	ContactTypeCoach:                 true,
	ContactTypeSupportPerson:         true,
	ContactTypeCustom:                true,
}

// e164Pattern matches E.164 phone numbers.
var e164Pattern = regexp.MustCompile(`^\+[1-9]\d{1,14}$`)

// ValidateDirection checks if a direction value is valid.
func ValidateDirection(d Direction) error {
	if !validDirections[d] {
		return ErrInvalidDirection
	}
	return nil
}

// ValidateContactType checks if a contact type value is valid.
func ValidateContactType(ct ContactType) error {
	if !validContactTypes[ct] {
		return ErrInvalidContactType
	}
	return nil
}

// ValidateCreateRequest validates a CreatePhoneCallRequest.
func ValidateCreateRequest(req *CreatePhoneCallRequest) error {
	if err := ValidateDirection(req.Direction); err != nil {
		return err
	}

	if err := ValidateContactType(req.ContactType); err != nil {
		return err
	}

	if req.ContactType == ContactTypeCustom {
		if req.CustomContactLabel == nil || strings.TrimSpace(*req.CustomContactLabel) == "" {
			return ErrCustomLabelRequired
		}
	}

	if req.ContactName != nil && len(*req.ContactName) > MaxContactNameLength {
		return fmt.Errorf("%w: got %d characters", ErrContactNameTooLong, len(*req.ContactName))
	}

	if req.Notes != nil && len(*req.Notes) > MaxNotesLength {
		return fmt.Errorf("%w: got %d characters", ErrNotesTooLong, len(*req.Notes))
	}

	if req.DurationMinutes != nil && *req.DurationMinutes < 0 {
		return ErrNegativeDuration
	}

	return nil
}

// ValidateUpdateRequest validates an UpdatePhoneCallRequest.
// It specifically rejects any attempt to change the timestamp (FR2.7).
func ValidateUpdateRequest(req *UpdatePhoneCallRequest) error {
	if req.Timestamp != nil {
		return ErrTimestampImmutable
	}

	if req.Direction != nil {
		if err := ValidateDirection(*req.Direction); err != nil {
			return err
		}
	}

	if req.ContactType != nil {
		if err := ValidateContactType(*req.ContactType); err != nil {
			return err
		}
	}

	if req.ContactName != nil && len(*req.ContactName) > MaxContactNameLength {
		return fmt.Errorf("%w: got %d characters", ErrContactNameTooLong, len(*req.ContactName))
	}

	if req.Notes != nil && len(*req.Notes) > MaxNotesLength {
		return fmt.Errorf("%w: got %d characters", ErrNotesTooLong, len(*req.Notes))
	}

	if req.DurationMinutes != nil && *req.DurationMinutes < 0 {
		return ErrNegativeDuration
	}

	return nil
}

// ValidatePhoneNumber checks if a phone number is in E.164 format.
func ValidatePhoneNumber(phone string) error {
	if !e164Pattern.MatchString(phone) {
		return fmt.Errorf("%w: got %q", ErrInvalidPhoneNumber, phone)
	}
	return nil
}

// ValidateCreateSavedContactRequest validates a CreateSavedContactRequest.
func ValidateCreateSavedContactRequest(req *CreateSavedContactRequest) error {
	if strings.TrimSpace(req.ContactName) == "" {
		return ErrSavedContactNameRequired
	}

	if len(req.ContactName) > MaxContactNameLength {
		return fmt.Errorf("%w: got %d characters", ErrContactNameTooLong, len(req.ContactName))
	}

	if err := ValidateContactType(req.ContactType); err != nil {
		return err
	}

	if req.PhoneNumber != nil {
		if err := ValidatePhoneNumber(*req.PhoneNumber); err != nil {
			return err
		}
	}

	return nil
}

// ValidateCanAddSavedContact checks if a user can add another saved contact.
func ValidateCanAddSavedContact(currentCount int) error {
	if currentCount >= MaxSavedContacts {
		return ErrMaxSavedContacts
	}
	return nil
}
