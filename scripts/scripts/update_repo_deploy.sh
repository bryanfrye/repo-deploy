#!/bin/bash - 
#===============================================================================
#
#          FILE: update_repo_deploy.sh
# 
#         USAGE: ./update_repo_deploy.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 05/27/2025 19:22
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -euo pipefail

REPO_DEPLOY_URL="https://raw.githubusercontent.com/bryanfrye/repo-deploy/main"
TMP_DIR=".tmp-repo-deploy"

echo "🚀 Updating from latest repo-deploy..."

# Step 1: Get latest hash
LATEST_HASH=$(curl -s https://api.github.com/repos/bryanfrye/repo-deploy/commits/main | jq -r .sha | cut -c1-7)

# Step 2: Download deploy.yaml
mkdir -p .github/workflows
curl -s "$REPO_DEPLOY_URL/.github/workflows/deploy.yaml" -o .github/workflows/deploy.yaml

# Step 3: Sync scripts/ (quick + dirty version)
rm -rf "$TMP_DIR"
git clone --depth 1 https://github.com/bryanfrye/repo-deploy.git "$TMP_DIR"

rm -rf ./scripts/*
cp -r "$TMP_DIR/scripts/*" .

# Step 4: Update version
echo "$LATEST_HASH" > .repo-deploy-version

# Optional: Auto commit
git add .github/workflows/deploy.yaml scripts/ .repo-deploy-version
git commit -m "🔄 Sync with repo-deploy ($LATEST_HASH)"
git push

# Cleanup
rm -rf "$TMP_DIR"

echo "✅ Updated to repo-deploy $LATEST_HASH"

