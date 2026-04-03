# ============================================================================
# Regal Recovery API - Makefile
# ============================================================================

.DEFAULT_GOAL := help

# ============================================================================
# Spec & Generation
# ============================================================================

spec-validate:            ## Validate all OpenAPI specs against OpenAPI 3.1 schema
	@echo "Validating OpenAPI specs..."
	npx @redocly/cli lint specs/openapi/openapi.yaml

contract-test:            ## Run contract tests validating implementations against OpenAPI specs
	@echo "Running contract tests..."
	go test ./test/contract/... -v -race -count=1

spec-docs:                ## Generate interactive API documentation (Redoc)
	npx @redocly/cli build-docs specs/openapi/openapi.yaml \
	  -o docs/api/index.html

# ============================================================================
# Testing
# ============================================================================

test-unit:                ## Run unit tests
	go test ./test/unit/... -v -race -count=1

test-integration:         ## Run integration tests (requires MongoDB + Valkey)
	go test ./test/integration/... -v -race -count=1 -tags=integration

test-e2e:                ## Run end-to-end tests against staging
	go test ./test/e2e/... -v -count=1 -tags=e2e

test-all:                ## Run unit + integration tests
	$(MAKE) test-unit
	$(MAKE) test-integration

coverage:                ## Generate coverage report (HTML + console)
	go test ./internal/... ./test/unit/... -coverprofile=coverage.out \
	  -covermode=atomic -race
	go tool cover -html=coverage.out -o coverage.html
	go tool cover -func=coverage.out | tail -1

coverage-check:          ## Verify coverage meets 80% threshold
	@COVERAGE=$$(go test ./internal/... -coverprofile=/dev/null 2>&1 \
	  | grep total | awk '{print $$3}' | sed 's/%//'); \
	if [ -z "$$COVERAGE" ]; then \
	  echo "WARN: Could not determine coverage (no packages to test yet)"; \
	elif [ $$(echo "$$COVERAGE < 80.0" | bc -l 2>/dev/null || echo 0) -eq 1 ]; then \
	  echo "FAIL: Coverage $$COVERAGE% is below 80% threshold"; exit 1; \
	else echo "PASS: Coverage $$COVERAGE%"; fi

# ============================================================================
# Code Quality
# ============================================================================

lint:                    ## Run linters (golangci-lint)
	golangci-lint run ./...

fmt:                     ## Format Go code
	gofmt -w -s .
	goimports -w .

vet:                     ## Run go vet
	go vet ./...

# ============================================================================
# Build
# ============================================================================

build:                   ## Build all Lambda binaries (ARM64 for Graviton)
	@for dir in cmd/lambda/*/; do \
	  name=$$(basename $$dir); \
	  echo "Building $$name..."; \
	  GOOS=linux GOARCH=arm64 CGO_ENABLED=0 \
	    go build -ldflags="-s -w" -o bin/$$name/bootstrap ./cmd/lambda/$$name/; \
	done

build-single:            ## Build a single Lambda: make build-single NAME=tracking
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 \
	  go build -ldflags="-s -w" -o bin/$(NAME)/bootstrap ./cmd/lambda/$(NAME)/

# ============================================================================
# Local Development
# ============================================================================

local-up:                ## Start all local services (MongoDB, LocalStack, Valkey, Ollama, Mailhog)
	docker compose up -d
	@echo "Waiting for MongoDB..."
	@until docker compose exec mongodb mongosh --quiet --eval "db.runCommand({ping:1})" > /dev/null 2>&1; do sleep 1; done
	@echo "Waiting for LocalStack..."
	@until curl -sf http://localhost:4566/_localstack/health > /dev/null 2>&1; do sleep 1; done
	@echo "Waiting for Valkey..."
	@until docker compose exec valkey valkey-cli ping > /dev/null 2>&1; do sleep 1; done
	@echo "Creating MongoDB indexes..."
	@./scripts/init-indexes.sh
	@echo "Initializing LocalStack resources..."
	@./scripts/init-localstack.sh
	@echo "Initializing Ollama (CA certs + model pull)..."
	@./scripts/init-ollama.sh
	@echo ""
	@echo "Local environment ready:"
	@echo "  MongoDB:    mongodb://localhost:27017"
	@echo "  Valkey:     localhost:6380"
	@echo "  LocalStack: http://localhost:4566"
	@echo "  Ollama:     http://localhost:11434"
	@echo "  Mailhog UI: http://localhost:8025"

dev-api:                 ## Start local API server with hot reload
	go run ./cmd/local/

local-down:              ## Stop all local services
	docker compose down

local-reset:             ## Stop, remove volumes, and restart with fresh data
	docker compose down -v
	$(MAKE) local-up
	$(MAKE) local-seed

local-seed:              ## Seed local MongoDB with test data (Alex persona)
	@./scripts/seed-local-data.sh
	@./scripts/init-indexes.sh

local-logs:              ## Tail logs from all local services
	docker compose logs -f

# ============================================================================
# Deployment
# ============================================================================

deploy-dev:              ## Deploy to dev environment
	cd cdk && npx cdk deploy --all --context env=dev --require-approval never

deploy-staging:          ## Deploy to staging environment
	cd cdk && npx cdk deploy --all --context env=staging

deploy-prod:             ## Deploy to production (requires approval)
	cd cdk && npx cdk deploy --all --context env=prod

cdk-diff:                ## Show infrastructure diff
	cd cdk && npx cdk diff --all --context env=$(ENV)

cdk-synth:               ## Synthesize CloudFormation templates
	cd cdk && npx cdk synth --all --context env=$(ENV)

# ============================================================================
# Utilities
# ============================================================================

clean:                   ## Remove build artifacts
	rm -rf bin/ coverage.out coverage.html

deps:                    ## Download and verify Go dependencies
	go mod download
	go mod verify

tools:                   ## Install required development tools
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install golang.org/x/tools/cmd/goimports@latest
	npm install -g @redocly/cli

help:                    ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

.PHONY: spec-validate contract-test spec-docs test-unit test-integration test-e2e \
        test-all coverage coverage-check lint fmt vet build build-single \
        local-up local-down local-reset local-seed local-logs deploy-dev deploy-staging \
        deploy-prod cdk-diff cdk-synth clean deps tools help
