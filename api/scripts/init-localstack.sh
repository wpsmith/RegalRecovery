#!/usr/bin/env bash
# Initialize LocalStack resources for local development

set -euo pipefail

LOCALSTACK_ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost:4566}"
AWS_OPTS="--endpoint-url=${LOCALSTACK_ENDPOINT} --region us-east-1 --no-cli-pager"

echo "Initializing LocalStack resources at ${LOCALSTACK_ENDPOINT}..."

# Create SQS queue for event processing
echo "Creating SQS queue: regal-recovery-events..."
aws sqs create-queue $AWS_OPTS --queue-name regal-recovery-events 2>/dev/null || true
echo "  ✓ SQS queue created"

# Create SNS topic for notifications
echo "Creating SNS topic: regal-recovery-notifications..."
aws sns create-topic $AWS_OPTS --name regal-recovery-notifications 2>/dev/null || true
echo "  ✓ SNS topic created"

# Create S3 bucket for content/backups
echo "Creating S3 bucket: regal-recovery-local..."
aws s3 mb $AWS_OPTS s3://regal-recovery-local 2>/dev/null || true
echo "  ✓ S3 bucket created"

echo ""
echo "LocalStack initialization complete."
