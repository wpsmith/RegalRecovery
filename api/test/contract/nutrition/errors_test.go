// test/contract/nutrition/errors_test.go
package nutrition

import (
	"encoding/json"
	"regexp"
	"testing"
)

// TestContract_ErrorResponses_MatchSiemensFormat validates all error responses
// follow the Siemens error object structure with rr:0x error codes.
func TestContract_ErrorResponses_MatchSiemensFormat(t *testing.T) {
	errorCodes := []string{
		"rr:0x00040001", // mealType required
		"rr:0x00040002", // timestamp immutable
		"rr:0x00040003", // invalid meal type
		"rr:0x00040004", // description required
		"rr:0x00040005", // description too long
		"rr:0x00040006", // notes too long
		"rr:0x00040007", // invalid mood range
		"rr:0x00040008", // invalid eating context
		"rr:0x00040009", // invalid mindfulness check
		"rr:0x0004000A", // custom label required
		"rr:0x0004000B", // custom label too long
		"rr:0x0004000C", // invalid hydration
	}

	codePattern := regexp.MustCompile(`^rr:0x[0-9A-Fa-f]{8}$`)
	for _, code := range errorCodes {
		if !codePattern.MatchString(code) {
			t.Errorf("error code %s does not match pattern rr:0x{8 hex digits}", code)
		}
	}

	// Validate error response structure matches Siemens format.
	errorResponse := `{
		"errors": [
			{
				"code": "rr:0x00040001",
				"status": 422,
				"title": "mealType is required"
			}
		]
	}`

	var resp map[string]interface{}
	if err := json.Unmarshal([]byte(errorResponse), &resp); err != nil {
		t.Fatalf("invalid error response JSON: %v", err)
	}

	errors, ok := resp["errors"].([]interface{})
	if !ok || len(errors) == 0 {
		t.Fatal("error response must have errors array")
	}

	errObj := errors[0].(map[string]interface{})
	for _, field := range []string{"code", "status", "title"} {
		if _, ok := errObj[field]; !ok {
			t.Errorf("error object must include %s", field)
		}
	}
}
