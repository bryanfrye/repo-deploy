.PHONY: lint deploy-preview deploy list-stages check-version update clean help
.DEFAULT_GOAL := help

STAGES := $(shell sed -nE 's/^[[:space:]]*stages[[:space:]]*=[[:space:]]*\[(.*)\]/\1/p' repo.toml | tr -d '"' | tr -d ' ' | tr ',' '\n' | paste -sd, -)

# Help target to display available commands
help:
	@echo "Available commands:"
	@echo "  lint          - Run all configured linters"
	@echo "  deploy-preview - Show what deploy scripts would run based on stages"
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

deploy-preview:
	@echo "🔎 Previewing deployment plan..."
	@selected_stages="$${STAGES:-$(STAGES)}"; \
	for stage in $${selected_stages//,/ }; do \
		if [[ "$$stage" == *.* ]]; then \
			provider=$${stage%%.*}; \
			role=$${stage#*.}; \
		else \
			provider="aws"; \
			role=$$stage; \
		fi; \
		script="scripts/deploy/deploy_$$provider.sh"; \
		if [ "$$provider" = "aws" ]; then \
			template="deploy/cloudformation/$$role.yaml"; \
			if [ -f "$$template" ]; then \
				echo "✔️  Would run: $$script $$role"; \
				echo "📦  CloudFormation resources in $$template:"; \
				yq e '.Resources | to_entries[] | " - " + .key + ": " + .value.Type' "$$template" || echo "⚠️  yq failed to parse"; \
			else \
				echo "❌ Template not found: $$template"; \
			fi; \
		elif [ "$$provider" = "ansible" ]; then \
			playbook="deploy/ansible/$$role.playbook"; \
			if [ -f "$$playbook" ]; then \
				echo "✔️  Would run: $$script $$role"; \
				echo "📜  Tasks/Roles in $$playbook:"; \
				yq e '.[] | select(has("tasks")) | .tasks[].name // "  - unnamed task"' "$$playbook" 2>/dev/null || \
				grep -E '^- name:|^- import_playbook:|^- include:|^- role:' "$$playbook" | sed 's/^/ - /'; \
			else \
				echo "❌ Playbook not found: $$playbook"; \
			fi; \
		elif [ -f "$$script" ]; then \
			echo "✔️  Would run: $$script $$role"; \
		else \
			echo "❌ Missing script: $$script"; \
		fi; \
	done

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
	@sed -nE 's/^[[:space:]]*stages[[:space:]]*=[[:space:]]*\[(.*)\]/\1/p' repo.toml | tr -d '"' | tr ',' '\n' | sed 's/^/ - /'

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
