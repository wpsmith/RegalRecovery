// internal/domain/actingin/export_test.go
package actingin

import (
	"strings"
	"testing"
	"time"
)

// TestExport_AC_AIB_043_CsvFormat verifies that CSV export contains correct
// headers and all check-in data.
//
// AC-AIB-043: CSV file generated with all check-in data.
func TestExport_AC_AIB_043_CsvFormat(t *testing.T) {
	checkIns := []CheckIn{
		{
			Timestamp:     time.Date(2026, 3, 28, 21, 0, 0, 0, time.UTC),
			BehaviorCount: 2,
			Behaviors: []CheckedBehavior{
				{BehaviorID: "beh_default_stonewall", BehaviorName: "Stonewall", ContextNote: "Shut down", Trigger: TriggerConflict, RelationshipTag: RelationshipSpouse},
				{BehaviorID: "beh_default_avoid", BehaviorName: "Avoid", ContextNote: "Avoided call", Trigger: TriggerShame, RelationshipTag: RelationshipSponsor},
			},
		},
		{
			Timestamp:     time.Date(2026, 3, 29, 21, 0, 0, 0, time.UTC),
			BehaviorCount: 0,
			Behaviors:     []CheckedBehavior{},
		},
	}

	data := ExportCSVData(checkIns, nil, nil)
	csv := string(data)

	// Verify header.
	if !strings.HasPrefix(csv, "Date,Behaviors,Context Notes,Triggers,Relationships\n") {
		t.Error("CSV missing expected header row")
	}

	// Verify data rows.
	lines := strings.Split(strings.TrimSpace(csv), "\n")
	if len(lines) != 3 { // header + 2 data rows.
		t.Errorf("expected 3 lines (header + 2 rows), got %d", len(lines))
	}

	// First row should contain behavior names.
	if !strings.Contains(lines[1], "Stonewall") {
		t.Error("first data row should contain 'Stonewall'")
	}
	if !strings.Contains(lines[1], "Avoid") {
		t.Error("first data row should contain 'Avoid'")
	}
}

// TestExport_AC_AIB_044_PdfFormat verifies that PDF export is generated as
// valid PDF binary.
//
// AC-AIB-044: PDF export is generated as valid PDF binary.
func TestExport_AC_AIB_044_PdfFormat(t *testing.T) {
	checkIns := []CheckIn{
		{
			Timestamp:     time.Date(2026, 3, 28, 21, 0, 0, 0, time.UTC),
			BehaviorCount: 1,
			Behaviors: []CheckedBehavior{
				{BehaviorID: "beh_default_blame", BehaviorName: "Blame"},
			},
		},
	}

	data := ExportPDFData(checkIns, nil, nil)

	if len(data) == 0 {
		t.Fatal("expected non-empty PDF data")
	}

	// Verify PDF header.
	if !strings.HasPrefix(string(data), "%PDF-") {
		t.Error("PDF data should start with %PDF- header")
	}

	// Verify PDF trailer.
	if !strings.Contains(string(data), "%%EOF") {
		t.Error("PDF data should contain EOF trailer marker")
	}
}

// TestExport_DateRangeFilter verifies that export respects startDate and endDate.
func TestExport_DateRangeFilter(t *testing.T) {
	checkIns := []CheckIn{
		{
			Timestamp:     time.Date(2026, 3, 28, 21, 0, 0, 0, time.UTC),
			BehaviorCount: 1,
			Behaviors:     []CheckedBehavior{{BehaviorID: "a", BehaviorName: "A"}},
		},
		{
			Timestamp:     time.Date(2026, 4, 5, 21, 0, 0, 0, time.UTC),
			BehaviorCount: 1,
			Behaviors:     []CheckedBehavior{{BehaviorID: "b", BehaviorName: "B"}},
		},
	}

	start := time.Date(2026, 4, 1, 0, 0, 0, 0, time.UTC)
	end := time.Date(2026, 4, 30, 23, 59, 59, 0, time.UTC)

	data := ExportCSVData(checkIns, &start, &end)
	csv := string(data)
	lines := strings.Split(strings.TrimSpace(csv), "\n")

	// Only the April check-in should be included.
	if len(lines) != 2 { // header + 1 data row.
		t.Errorf("expected 2 lines (header + 1 filtered row), got %d", len(lines))
	}
}

// TestExport_EmptyRange_ReturnsEmptyFile verifies that an export with no data
// in range returns a file with just the header.
func TestExport_EmptyRange_ReturnsEmptyFile(t *testing.T) {
	start := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	end := time.Date(2026, 1, 31, 23, 59, 59, 0, time.UTC)

	data := ExportCSVData([]CheckIn{}, &start, &end)
	csv := string(data)
	lines := strings.Split(strings.TrimSpace(csv), "\n")

	if len(lines) != 1 { // header only.
		t.Errorf("expected 1 line (header only), got %d", len(lines))
	}
}
