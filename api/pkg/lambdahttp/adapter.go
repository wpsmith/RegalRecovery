// Package lambdahttp provides HTTP-to-Lambda adapters for API Gateway proxy integration.
package lambdahttp

import (
	"bytes"
	"context"
	"encoding/base64"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"

	"github.com/aws/aws-lambda-go/events"
)

// Adapter converts API Gateway proxy requests to http.Request and back.
type Adapter struct {
	handler http.Handler
}

// NewAdapter creates a new Lambda HTTP adapter wrapping an http.Handler.
func NewAdapter(handler http.Handler) *Adapter {
	return &Adapter{handler: handler}
}

// Handle processes an API Gateway proxy request and returns a proxy response.
func (a *Adapter) Handle(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// Convert API Gateway request to http.Request
	httpReq, err := toHTTPRequest(ctx, request)
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusBadRequest,
			Headers:    map[string]string{"Content-Type": "application/json"},
			Body:       `{"errors":[{"status":400,"title":"Invalid request","detail":"Failed to parse API Gateway request"}]}`,
		}, nil
	}

	// Use httptest.ResponseRecorder to capture the response
	recorder := httptest.NewRecorder()
	a.handler.ServeHTTP(recorder, httpReq)

	// Convert http.Response to API Gateway response
	return toAPIGatewayResponse(recorder), nil
}

// toHTTPRequest converts an API Gateway proxy request to an http.Request.
func toHTTPRequest(ctx context.Context, request events.APIGatewayProxyRequest) (*http.Request, error) {
	// Decode body if base64 encoded
	var body io.Reader
	if request.IsBase64Encoded {
		decoded, err := base64.StdEncoding.DecodeString(request.Body)
		if err != nil {
			return nil, err
		}
		body = bytes.NewReader(decoded)
	} else {
		body = strings.NewReader(request.Body)
	}

	// Build URL path with query string
	path := request.Path
	if len(request.QueryStringParameters) > 0 {
		query := make([]string, 0, len(request.QueryStringParameters))
		for k, v := range request.QueryStringParameters {
			query = append(query, k+"="+v)
		}
		path += "?" + strings.Join(query, "&")
	}

	// Create http.Request
	httpReq, err := http.NewRequestWithContext(ctx, request.HTTPMethod, path, body)
	if err != nil {
		return nil, err
	}

	// Copy headers
	for k, v := range request.Headers {
		httpReq.Header.Set(k, v)
	}

	// Copy multi-value headers (override single values if present)
	for k, values := range request.MultiValueHeaders {
		httpReq.Header.Del(k)
		for _, v := range values {
			httpReq.Header.Add(k, v)
		}
	}

	return httpReq, nil
}

// toAPIGatewayResponse converts an httptest.ResponseRecorder to an API Gateway proxy response.
func toAPIGatewayResponse(recorder *httptest.ResponseRecorder) events.APIGatewayProxyResponse {
	headers := make(map[string]string)
	for k, v := range recorder.Header() {
		if len(v) > 0 {
			headers[k] = v[0]
		}
	}

	return events.APIGatewayProxyResponse{
		StatusCode:      recorder.Code,
		Headers:         headers,
		Body:            recorder.Body.String(),
		IsBase64Encoded: false,
	}
}
