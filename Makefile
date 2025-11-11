# Makefile for FinNaslain Financial Solution

.PHONY: help install dev build test lint format clean docker-build docker-up docker-down terraform-init terraform-plan terraform-apply backup security-audit deploy

# Default target
.DEFAULT_GOAL := help

# Variables
PROJECT_NAME := finnaslaim
DOCKER_IMAGE := finnaslaim/app
TERRAFORM_DIR := infrastructure/terraform

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies
	npm install

dev: ## Run development environment
	docker-compose -f docker/development/docker-compose.yml up

build: ## Build application
	npm run build

test: ## Run tests
	npm test

test-unit: ## Run unit tests
	npm run test:unit

test-integration: ## Run integration tests
	npm run test:integration

test-coverage: ## Run tests with coverage
	npm run test:coverage

lint: ## Run linter
	npm run lint

lint-fix: ## Run linter and fix issues
	npm run lint:fix

format: ## Format code
	npm run format

format-check: ## Check code formatting
	npm run format:check

clean: ## Clean build artifacts
	rm -rf dist/
	rm -rf node_modules/
	rm -rf coverage/
	rm -rf logs/*.log

# Docker commands
docker-build: ## Build Docker image
	docker build -f docker/production/Dockerfile -t $(DOCKER_IMAGE):latest .

docker-build-dev: ## Build Docker development image
	docker build -f docker/development/Dockerfile -t $(DOCKER_IMAGE):dev .

docker-up: ## Start Docker containers (production)
	docker-compose -f docker/production/docker-compose.yml up -d

docker-down: ## Stop Docker containers
	docker-compose -f docker/production/docker-compose.yml down

docker-logs: ## View Docker logs
	docker-compose -f docker/production/docker-compose.yml logs -f

docker-ps: ## List running containers
	docker ps --filter "name=finnaslaim"

docker-clean: ## Remove all containers and images
	docker-compose -f docker/production/docker-compose.yml down -v
	docker system prune -af

# Terraform commands
terraform-init: ## Initialize Terraform
	cd $(TERRAFORM_DIR) && terraform init

terraform-validate: ## Validate Terraform configuration
	cd $(TERRAFORM_DIR) && terraform validate

terraform-format: ## Format Terraform files
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

terraform-plan: ## Run Terraform plan
	cd $(TERRAFORM_DIR) && terraform plan

terraform-apply: ## Apply Terraform configuration
	cd $(TERRAFORM_DIR) && terraform apply

terraform-destroy: ## Destroy Terraform infrastructure
	cd $(TERRAFORM_DIR) && terraform destroy

terraform-output: ## Show Terraform outputs
	cd $(TERRAFORM_DIR) && terraform output

# Infrastructure commands
backup: ## Run backup script
	sudo bash infrastructure/scripts/backup.sh

security-audit: ## Run security audit
	sudo bash /usr/local/bin/security-audit.sh

monitoring: ## Run monitoring check
	sudo bash infrastructure/scripts/monitoring.sh

deploy: ## Deploy application
	sudo bash infrastructure/scripts/deploy.sh

setup-security: ## Setup security configurations
	sudo bash infrastructure/scripts/setup-security.sh

# Database commands
db-migrate: ## Run database migrations
	npm run db:migrate

db-rollback: ## Rollback database migration
	npm run db:rollback

db-seed: ## Seed database
	npm run db:seed

db-reset: ## Reset database
	npm run db:reset

# Git commands
git-status: ## Show git status
	git status

git-pull: ## Pull latest changes
	git pull origin $(shell git branch --show-current)

git-push: ## Push changes
	git push -u origin $(shell git branch --show-current)

# CI/CD
ci: lint test build ## Run CI pipeline locally

pre-commit: lint-fix format test ## Run pre-commit checks

# Information
info: ## Show project information
	@echo "Project: $(PROJECT_NAME)"
	@echo "Docker Image: $(DOCKER_IMAGE)"
	@echo "Node Version: $(shell node --version)"
	@echo "NPM Version: $(shell npm --version)"
	@echo "Docker Version: $(shell docker --version)"
	@echo "Git Branch: $(shell git branch --show-current)"
