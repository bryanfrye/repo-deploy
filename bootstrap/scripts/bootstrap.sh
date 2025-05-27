#!/bin/bash - 
#===============================================================================
#
#          FILE: bootstrap.sh
# 
#         USAGE: ./bootstrap.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 05/27/2025 16:37
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -euo pipefail

PROVIDER=""
REPO_NAME=""
LINTERS=""
DESCRIPTION=""
DEST_DIR=""

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

if [[ -z "$REPO_NAME" || -z "$PROVIDER" ]]; then
  echo "Error: --repo-name and --provider are required"
  exit 1
fi

if [[ -z "$DEST_DIR" ]]; then
  DEST_DIR="./$REPO_NAME"
fi

echo "=== Bootstrapping repo: $REPO_NAME for $PROVIDER ==="
echo "📁 Destination: $DEST_DIR"

# Uncomment to create real GitHub repo
# gh repo create "$REPO_NAME" --private --confirm --description "$DESCRIPTION"

mkdir -p "$DEST_DIR"
cd "$DEST_DIR"
git init

# Copy skeleton templates
cp -r ../../bootstrap/templates/$PROVIDER/* .
mkdir -p deploy/parameters

# Create README.md
if [[ ! -f README.md ]]; then
  cat <<EOF > README.md
# $REPO_NAME

$DESCRIPTION

**Cloud Provider:** $PROVIDER  
**Selected Linters:** ${LINTERS:-none}
EOF
fi

# Save selected linters
if [[ -n "$LINTERS" ]]; then
  echo "$LINTERS" | tr ',' '\n' > .linters
fi

# Generate deploy.yaml
mkdir -p .github/workflows
cat <<EOF > .github/workflows/deploy.yaml
# Managed by repo-deploy v1.0

name: Deploy Infrastructure

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  lint:
    name: Run Linters
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

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

      - name: Configure AWS Credentials
        if: $PROVIDER == "aws"
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-region: us-east-1
          role-to-assume: arn:aws:iam::123456789012:role/GitHubDeployRole

      - name: Deploy with repo-deploy
        run: |
          git clone https://github.com/bryanfrye/repo-deploy.git
          ./repo-deploy/scripts/deploy_stacks.sh
EOF

# Optionally commit locally
git config user.name "github-actions"
git config user.email "github-actions@github.com"
git add .
git commit -m "Initial scaffold for $PROVIDER"

echo "✅ Repo $REPO_NAME bootstrapped in $DEST_DIR"

