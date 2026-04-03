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

	// MongoURI is the MongoDB connection URI
	// Local: mongodb://localhost:27017, Staging/Prod: DocumentDB Serverless endpoint
	MongoURI string

	// MongoDatabase is the MongoDB database name
	MongoDatabase string

	// ValkeyAddr is the Valkey (Redis-compatible) server address
	ValkeyAddr string

	// SNSTopicARN is the ARN of the SNS topic for event publishing
	SNSTopicARN string

	// CognitoPoolID is the Cognito User Pool ID for authentication
	CognitoPoolID string

	// LogLevel controls the log output level: "debug", "info", "warn", "error"
	LogLevel string

	// LocalStackEndpoint is the LocalStack endpoint for all AWS service clients in local dev
	LocalStackEndpoint string

	// OllamaURL is the local LLM endpoint
	OllamaURL string

	// MailhogSMTP is the SMTP server address for local email
	MailhogSMTP string

	// SQSQueueURL is the SQS queue URL for event processing
	SQSQueueURL string

	// S3Bucket is the S3 bucket for content and backups
	S3Bucket string
}

// Load reads configuration from environment variables.
// It returns a Config struct populated with values from the environment,
// using sensible defaults for local development when variables are not set.
func Load() Config {
	return Config{
		Environment:        getEnv("ENVIRONMENT", "local"),
		AWSRegion:          getEnv("AWS_REGION", "us-east-1"),
		MongoURI:           getEnv("MONGODB_URI", "mongodb://localhost:27017"),
		MongoDatabase:      getEnv("MONGODB_DATABASE", "regal-recovery"),
		ValkeyAddr:         getEnv("VALKEY_ADDR", "localhost:6380"),
		SNSTopicARN:        getEnv("SNS_TOPIC_ARN", ""),
		CognitoPoolID:      getEnv("COGNITO_POOL_ID", ""),
		LogLevel:           getEnv("LOG_LEVEL", "info"),
		LocalStackEndpoint: getEnv("LOCALSTACK_ENDPOINT", "http://localhost:4566"),
		OllamaURL:          getEnv("OLLAMA_URL", "http://localhost:11434"),
		MailhogSMTP:        getEnv("MAILHOG_SMTP", "localhost:1025"),
		SQSQueueURL:        getEnv("SQS_QUEUE_URL", ""),
		S3Bucket:           getEnv("S3_BUCKET", "regal-recovery-local"),
	}
}

// getEnv reads an environment variable, returning a default value if not set.
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
