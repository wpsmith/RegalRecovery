// internal/domain/personcheckin/permissions_test.go
package personcheckin

import "testing"

func TestPersonCheckInPermission_FR_PCI_10_1_SpouseSeesOnlySpouseCheckIns(t *testing.T) {
	checkIns := []PersonCheckIn{
		{CheckInID: "pci_1", CheckInType: CheckInTypeSpouse},
		{CheckInID: "pci_2", CheckInType: CheckInTypeSponsor},
		{CheckInID: "pci_3", CheckInType: CheckInTypeCounselorCoach},
	}

	filtered := FilterCheckInsByViewerRole(checkIns, "spouse")

	if len(filtered) != 1 {
		t.Fatalf("expected 1 check-in visible to spouse, got %d", len(filtered))
	}
	if filtered[0].CheckInType != CheckInTypeSpouse {
		t.Fatalf("expected spouse check-in, got %s", filtered[0].CheckInType)
	}
}

func TestPersonCheckInPermission_FR_PCI_10_2_SponsorSeesAllSubTypes(t *testing.T) {
	checkIns := []PersonCheckIn{
		{CheckInID: "pci_1", CheckInType: CheckInTypeSpouse},
		{CheckInID: "pci_2", CheckInType: CheckInTypeSponsor},
		{CheckInID: "pci_3", CheckInType: CheckInTypeCounselorCoach},
	}

	filtered := FilterCheckInsByViewerRole(checkIns, "sponsor")

	if len(filtered) != 3 {
		t.Fatalf("expected 3 check-ins visible to sponsor, got %d", len(filtered))
	}
}

func TestPersonCheckInPermission_FR_PCI_10_3_NoPermission_Returns404(t *testing.T) {
	checkIns := []PersonCheckIn{
		{CheckInID: "pci_1", CheckInType: CheckInTypeSpouse},
	}

	filtered := FilterCheckInsByViewerRole(checkIns, "")

	if filtered != nil {
		t.Fatal("expected nil for no permission")
	}
}

func TestPersonCheckInPermission_CounselorSeesAllSubTypes(t *testing.T) {
	checkIns := []PersonCheckIn{
		{CheckInID: "pci_1", CheckInType: CheckInTypeSpouse},
		{CheckInID: "pci_2", CheckInType: CheckInTypeSponsor},
		{CheckInID: "pci_3", CheckInType: CheckInTypeCounselorCoach},
	}

	filtered := FilterCheckInsByViewerRole(checkIns, "counselor")

	if len(filtered) != 3 {
		t.Fatalf("expected 3 check-ins visible to counselor, got %d", len(filtered))
	}
}

func TestPersonCheckInPermission_DefaultDeny_NoAccessWithoutGrant(t *testing.T) {
	result := CanViewPersonCheckIns(false, "sponsor")
	if result {
		t.Fatal("expected false when no permission granted")
	}

	result = CanViewPersonCheckIns(true, "unknown-role")
	if result {
		t.Fatal("expected false for unknown role")
	}

	result = CanViewPersonCheckIns(true, "sponsor")
	if !result {
		t.Fatal("expected true for sponsor with permission granted")
	}
}
