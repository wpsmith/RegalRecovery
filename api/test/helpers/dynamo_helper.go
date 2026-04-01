// test/helpers/dynamo_helper.go
package helpers

import (
	"context"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// SetupLocalDynamo creates a DynamoDB client pointing to LocalStack at localhost:4566.
// It configures the client with test credentials and the local endpoint resolver.
func SetupLocalDynamo(t *testing.T) *dynamodb.Client {
	t.Helper()

	ctx := context.Background()

	customResolver := aws.EndpointResolverWithOptionsFunc(
		func(service, region string, options ...interface{}) (aws.Endpoint, error) {
			if service == dynamodb.ServiceID {
				return aws.Endpoint{
					URL:               "http://localhost:4566",
					SigningRegion:     "us-east-1",
					HostnameImmutable: true,
				}, nil
			}
			return aws.Endpoint{}, &aws.EndpointNotFoundError{}
		},
	)

	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithRegion("us-east-1"),
		config.WithEndpointResolverWithOptions(customResolver),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
			"test",
			"test",
			"",
		)),
	)
	if err != nil {
		t.Fatalf("failed to load AWS config: %v", err)
	}

	client := dynamodb.NewFromConfig(cfg)

	return client
}

// CreateTestTable creates the regal-recovery DynamoDB table with the standard schema:
// - PK (partition key, string)
// - SK (sort key, string)
// - GSI1PK + GSI1SK (global secondary index 1)
// - GSI2PK + GSI2SK (global secondary index 2)
//
// This mirrors the production single-table design.
func CreateTestTable(t *testing.T, client *dynamodb.Client) {
	t.Helper()

	ctx := context.Background()
	tableName := "regal-recovery"

	input := &dynamodb.CreateTableInput{
		TableName: aws.String(tableName),
		AttributeDefinitions: []types.AttributeDefinition{
			{
				AttributeName: aws.String("PK"),
				AttributeType: types.ScalarAttributeTypeS,
			},
			{
				AttributeName: aws.String("SK"),
				AttributeType: types.ScalarAttributeTypeS,
			},
			{
				AttributeName: aws.String("GSI1PK"),
				AttributeType: types.ScalarAttributeTypeS,
			},
			{
				AttributeName: aws.String("GSI1SK"),
				AttributeType: types.ScalarAttributeTypeS,
			},
			{
				AttributeName: aws.String("GSI2PK"),
				AttributeType: types.ScalarAttributeTypeS,
			},
			{
				AttributeName: aws.String("GSI2SK"),
				AttributeType: types.ScalarAttributeTypeS,
			},
		},
		KeySchema: []types.KeySchemaElement{
			{
				AttributeName: aws.String("PK"),
				KeyType:       types.KeyTypeHash,
			},
			{
				AttributeName: aws.String("SK"),
				KeyType:       types.KeyTypeRange,
			},
		},
		GlobalSecondaryIndexes: []types.GlobalSecondaryIndex{
			{
				IndexName: aws.String("GSI1"),
				KeySchema: []types.KeySchemaElement{
					{
						AttributeName: aws.String("GSI1PK"),
						KeyType:       types.KeyTypeHash,
					},
					{
						AttributeName: aws.String("GSI1SK"),
						KeyType:       types.KeyTypeRange,
					},
				},
				Projection: &types.Projection{
					ProjectionType: types.ProjectionTypeAll,
				},
			},
			{
				IndexName: aws.String("GSI2"),
				KeySchema: []types.KeySchemaElement{
					{
						AttributeName: aws.String("GSI2PK"),
						KeyType:       types.KeyTypeHash,
					},
					{
						AttributeName: aws.String("GSI2SK"),
						KeyType:       types.KeyTypeRange,
					},
				},
				Projection: &types.Projection{
					ProjectionType: types.ProjectionTypeAll,
				},
			},
		},
		BillingMode: types.BillingModePayPerRequest,
	}

	_, err := client.CreateTable(ctx, input)
	if err != nil {
		t.Fatalf("failed to create test table: %v", err)
	}

	// Wait for table to be active
	waiter := dynamodb.NewTableExistsWaiter(client)
	err = waiter.Wait(ctx, &dynamodb.DescribeTableInput{
		TableName: aws.String(tableName),
	}, 0)
	if err != nil {
		t.Fatalf("failed waiting for table to be active: %v", err)
	}
}

// CleanupTable deletes all items from the test table.
// Uses Scan + BatchWriteItem for efficient bulk deletion.
func CleanupTable(t *testing.T, client *dynamodb.Client) {
	t.Helper()

	ctx := context.Background()
	tableName := "regal-recovery"

	// Scan all items
	scanOutput, err := client.Scan(ctx, &dynamodb.ScanInput{
		TableName:      aws.String(tableName),
		AttributesToGet: []string{"PK", "SK"},
	})
	if err != nil {
		t.Fatalf("failed to scan table for cleanup: %v", err)
	}

	if len(scanOutput.Items) == 0 {
		return // Nothing to delete
	}

	// Batch delete in chunks of 25 (DynamoDB limit)
	const batchSize = 25
	for i := 0; i < len(scanOutput.Items); i += batchSize {
		end := i + batchSize
		if end > len(scanOutput.Items) {
			end = len(scanOutput.Items)
		}

		batch := scanOutput.Items[i:end]
		writeRequests := make([]types.WriteRequest, 0, len(batch))

		for _, item := range batch {
			writeRequests = append(writeRequests, types.WriteRequest{
				DeleteRequest: &types.DeleteRequest{
					Key: map[string]types.AttributeValue{
						"PK": item["PK"],
						"SK": item["SK"],
					},
				},
			})
		}

		_, err := client.BatchWriteItem(ctx, &dynamodb.BatchWriteItemInput{
			RequestItems: map[string][]types.WriteRequest{
				tableName: writeRequests,
			},
		})
		if err != nil {
			t.Fatalf("failed to batch delete items: %v", err)
		}
	}
}
