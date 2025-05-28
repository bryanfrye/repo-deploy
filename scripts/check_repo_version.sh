#!/bin/bash - 
#===============================================================================
#
#          FILE: check_repo_version.sh
# 
#         USAGE: ./check_repo_version.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 05/27/2025 19:51
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -e

# Ensure jq is installed
if ! command -v jq &> /dev/null; then
  echo "❌ 'jq' is required but not installed."
  exit 1
fi

echo "🔁 Checking repo-deploy version..."

# Fetch latest short commit hash from repo-deploy
LATEST=$(curl -s https://api.github.com/repos/bryanfrye/repo-deploy/commits/main | jq -r '.sha' | cut -c1-7)

# Read local version
if [[ ! -f .repo-deploy-version ]]; then
  echo "❌ .repo-deploy-version not found in this repo."
  exit 1
fi

CURRENT=$(cat .repo-deploy-version)

echo "🔒 Current version: $CURRENT"
echo "🌐 Latest version : $LATEST"

if [[ "$CURRENT" != "$LATEST" ]]; then
  echo "❌ This repo is using an outdated repo-deploy skeleton."
  echo "💡 Please re-bootstrap or run the sync script to update workflows and scripts."
  exit 1
else
  echo "✅ Repo-deploy version is up to date."
fi

