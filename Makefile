.PHONY: lint deploy check-version update
.DEFAULT_GOAL := help

# Help target to display available commands
help:
	@echo "Available commands:"
	@echo "  lint          - Run all configured linters"
	@echo "  deploy        - Run the deployment logic"
	@echo "  check-version - Check repo-deploy version"
	@echo "  update        - Update dependencies"

# Run all configured linters
lint:
	@echo "🔍 Running linters..."
	@./scripts/run_linters.sh

# Run the deployment logic
deploy:
	@echo "🚀 Running deploy script..."
	@./scripts/deploy.sh

# Run version check (matches GitHub Action logic)
check-version:
	@echo "🔁 Checking repo-deploy version..."
	@./scripts/check_repo_version.sh

update:
	echo "🔄 Updating dependencies..."
	@./scripts/update_repo_deploy.sh
