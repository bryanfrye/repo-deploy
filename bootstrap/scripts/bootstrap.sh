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
WORKFLOW_TEMPLATE="$SCRIPT_DIR/../template/workflows/deploy.yaml"
VERSION_HASH=$(git rev-parse --short HEAD)
echo "$VERSION_HASH" > "$DEST_DIR/.repo-deploy-version"

# -----------------------------
# Start scaffolding
# -----------------------------
echo "=== Bootstrapping repo: $REPO_NAME for $PROVIDER ==="
echo "📁 Destination: $DEST_DIR"

mkdir -p "$DEST_DIR"
cd "$DEST_DIR"
git init

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

IFS=',' read -ra LINTER_ARRAY <<< "$LINTERS"

# Auto-include cfn_nag for AWS
if [[ "$PROVIDER" == "aws" && ! " ${LINTER_ARRAY[*]} " =~ " cfn_nag " ]]; then
  LINTERS="$LINTERS,cfn_nag"
  echo "📎 Automatically adding cfn_nag for AWS projects"
fi

# Final .linters output
echo "$LINTERS" | tr ',' '\n' > .linters

# Add GitHub Actions workflow
mkdir -p .github/workflows
if [[ -f "$WORKFLOW_TEMPLATE" ]]; then
  cp "$WORKFLOW_TEMPLATE" ".github/workflows/deploy.yaml"
else
  echo "⚠️  Workflow template not found at $WORKFLOW_TEMPLATE"
fi

# Pre-commit hook
cp "$SCRIPT_DIR/../hooks/pre-commit" "$DEST_DIR/.git/hooks/pre-commit"
chmod +x "$DEST_DIR/.git/hooks/pre-commit"
echo "✅ Pre-commit hook installed at $DEST_DIR/.git/hooks/pre-commit"

# Add Makefile
cp "$SCRIPT_DIR/../../Makefile" "Makefile"

# Initial commit
git config user.name "github-actions"
git config user.email "github-actions@github.com"
#git add .
#git commit -m "Initial scaffold for $PROVIDER"

