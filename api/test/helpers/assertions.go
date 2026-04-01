// test/helpers/assertions.go
package helpers

import (
	"encoding/json"
	"testing"
)

// AssertSiemensEnvelope verifies that the response body conforms to Siemens API envelope format.
// Expected structure:
//
//	{
//	  "data": { ... },
//	  "links": { "self": "..." },
//	  "meta": { ... }
//	}
func AssertSiemensEnvelope(t *testing.T, body []byte) {
	t.Helper()

	var envelope map[string]interface{}
	if err := json.Unmarshal(body, &envelope); err != nil {
		t.Fatalf("failed to parse JSON envelope: %v", err)
	}

	if _, ok := envelope["data"]; !ok {
		t.Errorf("response missing 'data' key in Siemens envelope")
	}
}

// AssertSiemensError verifies that the error response conforms to Siemens error format.
// Expected structure:
//
//	{
//	  "errors": [{
//	    "id": "unique-id",
//	    "code": "0x00000001",
//	    "status": 415,
//	    "title": "Human-readable summary",
//	    "detail": "Occurrence-specific description",
//	    "correlationId": "UUID"
//	  }]
//	}
func AssertSiemensError(t *testing.T, body []byte, expectedStatus int) {
	t.Helper()

	var errorEnvelope map[string]interface{}
	if err := json.Unmarshal(body, &errorEnvelope); err != nil {
		t.Fatalf("failed to parse JSON error envelope: %v", err)
	}

	errors, ok := errorEnvelope["errors"]
	if !ok {
		t.Errorf("error response missing 'errors' key")
		return
	}

	errorList, ok := errors.([]interface{})
	if !ok || len(errorList) == 0 {
		t.Errorf("errors must be a non-empty array")
		return
	}

	firstError, ok := errorList[0].(map[string]interface{})
	if !ok {
		t.Errorf("error object must be a map")
		return
	}

	status, ok := firstError["status"].(float64)
	if !ok {
		t.Errorf("error missing 'status' field")
		return
	}

	if int(status) != expectedStatus {
		t.Errorf("expected status %d, got %d", expectedStatus, int(status))
	}

	// Verify required fields
	requiredFields := []string{"title", "detail"}
	for _, field := range requiredFields {
		if _, ok := firstError[field]; !ok {
			t.Errorf("error missing required field '%s'", field)
		}
	}
}

// AssertJSON extracts a value from JSON body and compares it to expected.
// The key parameter supports dot notation for nested access (e.g., "data.userId").
func AssertJSON(t *testing.T, body []byte, key string, expected interface{}) {
	t.Helper()

	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		t.Fatalf("failed to parse JSON: %v", err)
	}

	actual, ok := data[key]
	if !ok {
		t.Fatalf("key '%s' not found in JSON response", key)
	}

	if actual != expected {
		t.Errorf("expected %s=%v, got %v", key, expected, actual)
	}
}

// AssertJSONNested extracts a nested value from JSON body using a path and compares it to expected.
// The path is a slice of keys for nested navigation (e.g., []string{"data", "user", "id"}).
func AssertJSONNested(t *testing.T, body []byte, path []string, expected interface{}) {
	t.Helper()

	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		t.Fatalf("failed to parse JSON: %v", err)
	}

	// Navigate nested structure
	current := data
	for i, key := range path {
		if i == len(path)-1 {
			// Last key - compare value
			actual, ok := current[key]
			if !ok {
				t.Fatalf("key '%s' not found at path %v", key, path)
			}
			if actual != expected {
				t.Errorf("expected %v=%v, got %v", path, expected, actual)
			}
			return
		}

		// Intermediate key - descend
		next, ok := current[key]
		if !ok {
			t.Fatalf("key '%s' not found at path %v", key, path[:i+1])
		}
		current, ok = next.(map[string]interface{})
		if !ok {
			t.Fatalf("value at '%s' is not an object", key)
		}
	}
}
