// internal/domain/actingin/export.go
package actingin

import (
	"bytes"
	"fmt"
	"strings"
	"time"
)

// ExportFormat represents the export file format.
type ExportFormat string

const (
	ExportCSV ExportFormat = "csv"
	ExportPDF ExportFormat = "pdf"
)

// ExportCSVData generates a CSV export of check-in history.
// Headers: Date, Behaviors, Context Notes, Triggers, Relationships.
func ExportCSVData(checkIns []CheckIn, startDate, endDate *time.Time) []byte {
	var buf bytes.Buffer

	// Write header.
	buf.WriteString("Date,Behaviors,Context Notes,Triggers,Relationships\n")

	for _, ci := range checkIns {
		if startDate != nil && ci.Timestamp.Before(*startDate) {
			continue
		}
		if endDate != nil && ci.Timestamp.After(*endDate) {
			continue
		}

		date := ci.Timestamp.Format("2006-01-02")
		behaviors := behaviorNamesCSV(ci.Behaviors)
		notes := contextNotesCSV(ci.Behaviors)
		triggers := triggersCSV(ci.Behaviors)
		relationships := relationshipsCSV(ci.Behaviors)

		line := fmt.Sprintf("%s,%s,%s,%s,%s\n",
			csvEscape(date),
			csvEscape(behaviors),
			csvEscape(notes),
			csvEscape(triggers),
			csvEscape(relationships),
		)
		buf.WriteString(line)
	}

	return buf.Bytes()
}

// ExportPDFData generates a PDF export of check-in history.
// For v1, this generates a simple text-based PDF report.
func ExportPDFData(checkIns []CheckIn, startDate, endDate *time.Time) []byte {
	var buf bytes.Buffer

	// Simple PDF structure.
	buf.WriteString("%PDF-1.4\n")

	// Build the content stream.
	var content bytes.Buffer
	content.WriteString("BT\n")
	content.WriteString("/F1 16 Tf\n")
	content.WriteString("50 750 Td\n")
	content.WriteString("(Acting-In Behaviors Report) Tj\n")
	content.WriteString("/F1 10 Tf\n")

	dateRange := "All Time"
	if startDate != nil && endDate != nil {
		dateRange = fmt.Sprintf("%s to %s", startDate.Format("2006-01-02"), endDate.Format("2006-01-02"))
	}
	content.WriteString(fmt.Sprintf("0 -20 Td\n(Date Range: %s) Tj\n", dateRange))
	content.WriteString(fmt.Sprintf("0 -15 Td\n(Total Check-Ins: %d) Tj\n", len(checkIns)))

	y := 0
	for _, ci := range checkIns {
		if startDate != nil && ci.Timestamp.Before(*startDate) {
			continue
		}
		if endDate != nil && ci.Timestamp.After(*endDate) {
			continue
		}

		y -= 25
		date := ci.Timestamp.Format("2006-01-02")
		behaviorList := behaviorNamesCSV(ci.Behaviors)

		content.WriteString(fmt.Sprintf("0 %d Td\n", y))
		content.WriteString(fmt.Sprintf("(%s - %d behaviors: %s) Tj\n",
			pdfEscape(date), ci.BehaviorCount, pdfEscape(behaviorList)))
		y = 0
	}

	content.WriteString("ET\n")

	contentStr := content.String()
	contentLen := len(contentStr)

	// Objects.
	buf.WriteString("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n")
	buf.WriteString("2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n")
	buf.WriteString("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792]\n")
	buf.WriteString("   /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n")
	buf.WriteString(fmt.Sprintf("4 0 obj\n<< /Length %d >>\nstream\n%sendstream\nendobj\n", contentLen, contentStr))
	buf.WriteString("5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n")

	// Cross-reference and trailer.
	buf.WriteString("xref\n0 6\n")
	buf.WriteString("trailer\n<< /Size 6 /Root 1 0 R >>\n")
	buf.WriteString("startxref\n0\n%%EOF\n")

	return buf.Bytes()
}

func behaviorNamesCSV(behaviors []CheckedBehavior) string {
	names := make([]string, len(behaviors))
	for i, b := range behaviors {
		names[i] = b.BehaviorName
	}
	return strings.Join(names, "; ")
}

func contextNotesCSV(behaviors []CheckedBehavior) string {
	notes := make([]string, 0, len(behaviors))
	for _, b := range behaviors {
		if b.ContextNote != "" {
			notes = append(notes, b.BehaviorName+": "+b.ContextNote)
		}
	}
	return strings.Join(notes, "; ")
}

func triggersCSV(behaviors []CheckedBehavior) string {
	triggers := make([]string, 0, len(behaviors))
	for _, b := range behaviors {
		if b.Trigger != "" {
			triggers = append(triggers, string(b.Trigger))
		}
	}
	return strings.Join(triggers, "; ")
}

func relationshipsCSV(behaviors []CheckedBehavior) string {
	rels := make([]string, 0, len(behaviors))
	for _, b := range behaviors {
		if b.RelationshipTag != "" {
			rels = append(rels, string(b.RelationshipTag))
		}
	}
	return strings.Join(rels, "; ")
}

func csvEscape(s string) string {
	if strings.ContainsAny(s, ",\"\n") {
		return `"` + strings.ReplaceAll(s, `"`, `""`) + `"`
	}
	return s
}

func pdfEscape(s string) string {
	s = strings.ReplaceAll(s, `\`, `\\`)
	s = strings.ReplaceAll(s, `(`, `\(`)
	s = strings.ReplaceAll(s, `)`, `\)`)
	return s
}
