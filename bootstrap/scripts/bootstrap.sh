#!/bin/bash
#===============================================================================
#
#          FILE:  bootstrap.sh
#
#         USAGE:  Called by run-bootstrap.sh or manually to scaffold a new repo
#
#  DESCRIPTION:  Bootstraps a new cloud infrastructure repo using template stubs.
#                Currently supports AWS; Azure and GCP stubs can be added later.
#
#===============================================================================

set -euo pipefail

PROVIDER=""
REPO_NAME=""
LINTERS=""
DESCRIPTION=""
DEST_DIR=""

# -----------------------------
# Parse input arguments
# -----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)     PROVIDER="$2"; shift 2;;
    --repo-name)    REPO_NAME="$2"; shift 2;;
    --linters)      LINTERS="$2"; shift 2;;
    --description)  DESCRIPTION="$2"; shift 2;;
    --dest-dir)     DEST_DIR="$2"; shift 2;;
    *) echo "Unknown argument: $1"; exit 1;;
  esac
done

# -----------------------------
# Validate required inputs
# -----------------------------
if [[ -z "$REPO_NAME" || -z "$PROVIDER" ]]; then
  echo "❌ Error: --repo-name and --provider are required"
  exit 1
fi

if [[ -z "$DEST_DIR" ]]; then
  DEST_DIR="./$REPO_NAME"
fi

# -----------------------------
# Resolve absolute template path
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_SOURCE="$SCRIPT_DIR/../templates/$PROVIDER"

if [[ ! -d "$TEMPLATE_SOURCE" ]]; then
  echo "❌ ERROR: Template directory not found: $TEMPLATE_SOURCE"
  exit 1
fi

# -----------------------------
# Start scaffolding
# -----------------------------
echo "=== Bootstrapping repo: $REPO_NAME for $PROVIDER ==="
echo "📁 Destination: $DEST_DIR"

mkdir -p "$DEST_DIR"
cd "$DEST_DIR"
git init

case "$PROVIDER" in
  azure|gcp)
    echo "🌐 Using cloud provider: $PROVIDER"
    ;;
  aws)
    echo "🌐 Using cloud provider: $PROVIDER"
    # Create initial AWS-specific files
    mkdir -p deploy/cloudformation
    cp "$TEMPLATE_SOURCE/ec2.yaml.example" "./deploy/cloudformation/ec2.yaml.example"
    mkdir -p deploy/parameters
    cp "$TEMPLATE_SOURCE/ec2.params.json.example" "./deploy/parameters/ec2.params.json.example"
    ;;
  *)
    echo "❌ Unsupported provider: $PROVIDER"
    exit 1
    ;;
esac

# Create README.md
if [[ ! -f README.md ]]; then
  cat <<EOF > README.md
# $REPO_NAME

$DESCRIPTION

**Cloud Provider:** $PROVIDER
**Selected Linters:** ${LINTERS:-none}
EOF
fi

# Store linter config
if [[ -n "$LINTERS" ]]; then
  echo "$LINTERS" | tr ',' '\n' > .linters
fi

# Write .linters file
IFS=',' read -ra LINTER_ARRAY <<< "$LINTERS"

# Auto-include cfn_nag if provider is AWS
if [[ "$PROVIDER" == "aws" && ! " ${LINTER_ARRAY[@]} " =~ " cfn_nag " ]]; then
  LINTERS="$LINTERS,cfn_nag"
  echo "📎 Automatically adding cfn_nag for AWS projects"
fi

# Final .linters output
echo "$LINTERS" | tr ',' '\n' > .linters

# Create GitHub workflow (will be enhanced later)
mkdir -p .github/workflows
cat <<'EOF' > .github/workflows/deploy.yaml
---
# Managed by repo-deploy

name: Deploy Infrastructure

'on':
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  lint:
    name: Run Linters
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Read requested linters
        id: read-linters
        run: |
          if [[ -f .linters ]]; then
            LINTERS=\$(cat .linters | tr '\n' ',')
          else
            LINTERS="none"
          fi
          echo "LINTERS=\$LINTERS" >> \$GITHUB_ENV

      - name: Install requested linters
        run: |
          for linter in $LINTERS; do
            case "$linter" in
              yaml)
                pip install yamllint
                ;;
              cloudformation)
                pip install cfn-lint
                ;;
              shell)
                sudo apt-get update && sudo apt-get install -y shellcheck
                ;;
              ansible)
                pip install ansible-lint
                ;;
              terraform)
                sudo apt-get install -y terraform
                ;;
              puppet)
                gem install puppet-lint
                ;;
              ruby)
                gem install rubocop
                ;;
              python)
                pip install pylint
                ;;
              markdown)
                npm install -g markdownlint-cli
                ;;
            esac
          done

      - name: Run selected linters
        run: |
          echo "Running linters: $LINTERS"
          ./scripts/run_linters.sh

  deploy:
    name: Deploy to $PROVIDER
    runs-on: ubuntu-latest
    environment: production
    needs: lint
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure Credentials
        run: echo "Configure credentials for $PROVIDER (stub)"

      - name: Deploy
        run: |
          git clone https://github.com/bryanfrye/repo-deploy.git
          ./repo-deploy/scripts/deploy_stacks.sh
EOF

# Copy scripts folder into the new repo
SCRIPTS_SOURCE="$SCRIPT_DIR/../../scripts"
SCRIPTS_DEST="$DEST_DIR/scripts"

if [[ -d "$SCRIPTS_SOURCE" ]]; then
  echo "📁 Copying scripts/ to new repo"
  mkdir -p "$SCRIPTS_DEST"
  cp -R "$SCRIPTS_SOURCE/"* "$SCRIPTS_DEST/"
else
  echo "⚠️  scripts/ folder not found in repo-deploy"
fi

cp "$SCRIPT_DIR/../hooks/pre-commit" "$DEST_DIR/.git/hooks/pre-commit"
chmod +x "$DEST_DIR/.git/hooks/pre-commit"
echo "✅ Pre-commit hook installed at $DEST_DIR/.git/hooks/pre-commit"

# Initial commit
git config user.name "github-actions"
git config user.email "github-actions@github.com"
git add .
git commit -m "Initial scaffold for $PROVIDER"

echo "✅ Repo $REPO_NAME bootstrapped in $DEST_DIR"

