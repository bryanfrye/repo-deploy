.PHONY: lint deploy check-version

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
