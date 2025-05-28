.PHONY: lint deploy check-version update
.DEFAULT_GOAL := help

STAGES := $(shell grep -oP 'stages\s*=\s*\[\K[^\]]+' repo.toml | tr -d '"' | tr -d ' ' | tr ',' '\n' | paste -sd, -)

# Help target to display available commands
help:
	@echo "Available commands:"
	@echo "  lint          - Run all configured linters"
	@echo "  deploy        - Run deployments found in repo.toml"
	@echo "                  Optional override: make deploy STAGES=aws.lambda"
	@echo "  list-stages   - List all stages defined in repo.toml"
	@echo "  check-version - Check repo-deploy version"
	@echo "  update        - Update dependencies"
	@echo "  clean         - Clean up temporary files and directories"

# Run all configured linters
lint:
	@echo "🔍 Running linters..."
	@./scripts/run_linters.sh

# Run the deployment logic
deploy:
	@echo "🚀 Running deploy logic..."
	@STAGES=$${STAGES:-aws.webserver}; \
	for stage in $${STAGES//,/ }; do \
		provider=$${stage%%.*}; \
		role=$${stage#*.}; \
		script=./scripts/deploy/deploy_$${provider}.sh; \
		if [[ -x "$$script" ]]; then \
			echo "🔧 Deploying $$provider / $$role..."; \
			$$script "$$role"; \
		else \
			echo "❌ No deploy script found for provider '$$provider'"; \
			exit 1; \
		fi; \
	done

list-stages:
	@echo "📜 Available stages in repo.toml:"
	@grep -oP 'stages\s*=\s*\[\K[^\]]+' repo.toml \
		| tr -d '"' | tr ',' '\n' | sed 's/^/ - /'

# Run version check (matches GitHub Action logic)
check-version:
	@echo "🔁 Checking repo-deploy version..."
	@./scripts/check_repo_version.sh

update:
	echo "🔄 Updating dependencies..."
	@./scripts/update_repo_deploy.sh

clean:
	@echo "🧹 Cleaning up temporary files..."
	@rm -rf .cache .tmp
	@find . -name '*.pyc' -delete
	@find . -name '__pycache__' -delete
	@echo "Cleanup complete."
