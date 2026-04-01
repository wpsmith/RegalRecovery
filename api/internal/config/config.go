// internal/config/config.go
package config

import (
	"os"
)

// Config holds all configuration for the application.
// Configuration is loaded from environment variables with sensible defaults for local development.
type Config struct {
	// Environment is the deployment environment: "local", "staging", or "prod"
	Environment string

	// AWSRegion is the AWS region for all services
	AWSRegion string

	// DynamoDBTable is the name of the single DynamoDB table
	DynamoDBTable string

	// DynamoEndpoint is the DynamoDB endpoint URL (for LocalStack in local dev)
	// Empty in production to use the default AWS endpoint
	DynamoEndpoint string

	// ValkeyAddr is the Valkey (Redis-compatible) server address
	ValkeyAddr string

	// SNSTopicARN is the ARN of the SNS topic for event publishing
	SNSTopicARN string

	// CognitoPoolID is the Cognito User Pool ID for authentication
	CognitoPoolID string

	// LogLevel controls the log output level: "debug", "info", "warn", "error"
	LogLevel string
}

// Load reads configuration from environment variables.
// It returns a Config struct populated with values from the environment,
// using sensible defaults for local development when variables are not set.
func Load() Config {
	return Config{
		Environment:    getEnv("ENVIRONMENT", "local"),
		AWSRegion:      getEnv("AWS_REGION", "us-east-1"),
		DynamoDBTable:  getEnv("DYNAMODB_TABLE", "regal-recovery"),
		DynamoEndpoint: getEnv("DYNAMO_ENDPOINT", "http://localhost:4566"),
		ValkeyAddr:     getEnv("VALKEY_ADDR", "localhost:6380"),
		SNSTopicARN:    getEnv("SNS_TOPIC_ARN", ""),
		CognitoPoolID:  getEnv("COGNITO_POOL_ID", ""),
		LogLevel:       getEnv("LOG_LEVEL", "info"),
	}
}

// getEnv reads an environment variable, returning a default value if not set.
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
