// internal/repository/dynamo.go
package repository

import (
	"context"
	"fmt"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// DynamoClient wraps the AWS DynamoDB client with table name baked in.
type DynamoClient struct {
	client    *dynamodb.Client
	tableName string
}

// NewDynamoClient creates a new DynamoDB client wrapper.
// If endpoint is provided (non-empty), it will be used for the DynamoDB service (e.g., LocalStack).
func NewDynamoClient(cfg aws.Config, tableName string, endpoint string) *DynamoClient {
	var client *dynamodb.Client
	if endpoint != "" {
		client = dynamodb.NewFromConfig(cfg, func(o *dynamodb.Options) {
			o.BaseEndpoint = aws.String(endpoint)
		})
	} else {
		client = dynamodb.NewFromConfig(cfg)
	}

	return &DynamoClient{
		client:    client,
		tableName: tableName,
	}
}

// PutItem writes an item to the table.
func (d *DynamoClient) PutItem(ctx context.Context, item interface{}) error {
	av, err := attributevalue.MarshalMap(item)
	if err != nil {
		return fmt.Errorf("failed to marshal item: %w", err)
	}

	_, err = d.client.PutItem(ctx, &dynamodb.PutItemInput{
		TableName: aws.String(d.tableName),
		Item:      av,
	})
	if err != nil {
		return fmt.Errorf("failed to put item: %w", err)
	}

	return nil
}

// GetItem retrieves an item by primary key.
func (d *DynamoClient) GetItem(ctx context.Context, pk, sk string, out interface{}) error {
	result, err := d.client.GetItem(ctx, &dynamodb.GetItemInput{
		TableName: aws.String(d.tableName),
		Key: map[string]types.AttributeValue{
			"PK": &types.AttributeValueMemberS{Value: pk},
			"SK": &types.AttributeValueMemberS{Value: sk},
		},
		ConsistentRead: aws.Bool(true),
	})
	if err != nil {
		return fmt.Errorf("failed to get item: %w", err)
	}

	if result.Item == nil {
		return fmt.Errorf("item not found: PK=%s, SK=%s", pk, sk)
	}

	if err := attributevalue.UnmarshalMap(result.Item, out); err != nil {
		return fmt.Errorf("failed to unmarshal item: %w", err)
	}

	return nil
}

// Query performs a Query operation on the table.
func (d *DynamoClient) Query(ctx context.Context, input *dynamodb.QueryInput) (*dynamodb.QueryOutput, error) {
	if input.TableName == nil {
		input.TableName = aws.String(d.tableName)
	}

	result, err := d.client.Query(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to query: %w", err)
	}

	return result, nil
}

// QueryGSI performs a Query operation on a Global Secondary Index.
func (d *DynamoClient) QueryGSI(ctx context.Context, indexName string, input *dynamodb.QueryInput) (*dynamodb.QueryOutput, error) {
	if input.TableName == nil {
		input.TableName = aws.String(d.tableName)
	}
	input.IndexName = aws.String(indexName)

	result, err := d.client.Query(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to query GSI %s: %w", indexName, err)
	}

	return result, nil
}

// DeleteItem deletes an item by primary key.
func (d *DynamoClient) DeleteItem(ctx context.Context, pk, sk string) error {
	_, err := d.client.DeleteItem(ctx, &dynamodb.DeleteItemInput{
		TableName: aws.String(d.tableName),
		Key: map[string]types.AttributeValue{
			"PK": &types.AttributeValueMemberS{Value: pk},
			"SK": &types.AttributeValueMemberS{Value: sk},
		},
	})
	if err != nil {
		return fmt.Errorf("failed to delete item: %w", err)
	}

	return nil
}

// UpdateItem updates an item using UpdateItemInput.
func (d *DynamoClient) UpdateItem(ctx context.Context, input *dynamodb.UpdateItemInput) (*dynamodb.UpdateItemOutput, error) {
	if input.TableName == nil {
		input.TableName = aws.String(d.tableName)
	}

	result, err := d.client.UpdateItem(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to update item: %w", err)
	}

	return result, nil
}

// Scan performs a Scan operation on the table (use sparingly).
func (d *DynamoClient) Scan(ctx context.Context, input *dynamodb.ScanInput) (*dynamodb.ScanOutput, error) {
	if input.TableName == nil {
		input.TableName = aws.String(d.tableName)
	}

	result, err := d.client.Scan(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("failed to scan: %w", err)
	}

	return result, nil
}

// BatchGetItem retrieves multiple items in a single request.
func (d *DynamoClient) BatchGetItem(ctx context.Context, keys []map[string]types.AttributeValue) ([]map[string]types.AttributeValue, error) {
	result, err := d.client.BatchGetItem(ctx, &dynamodb.BatchGetItemInput{
		RequestItems: map[string]types.KeysAndAttributes{
			d.tableName: {
				Keys: keys,
			},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to batch get items: %w", err)
	}

	items, ok := result.Responses[d.tableName]
	if !ok {
		return nil, fmt.Errorf("no items returned for table %s", d.tableName)
	}

	return items, nil
}

// BatchWriteItem writes multiple items in a single request.
func (d *DynamoClient) BatchWriteItem(ctx context.Context, requests []types.WriteRequest) error {
	_, err := d.client.BatchWriteItem(ctx, &dynamodb.BatchWriteItemInput{
		RequestItems: map[string][]types.WriteRequest{
			d.tableName: requests,
		},
	})
	if err != nil {
		return fmt.Errorf("failed to batch write items: %w", err)
	}

	return nil
}

// TransactWriteItems performs a transactional write operation.
func (d *DynamoClient) TransactWriteItems(ctx context.Context, items []types.TransactWriteItem) error {
	_, err := d.client.TransactWriteItems(ctx, &dynamodb.TransactWriteItemsInput{
		TransactItems: items,
	})
	if err != nil {
		return fmt.Errorf("failed to transact write items: %w", err)
	}

	return nil
}
