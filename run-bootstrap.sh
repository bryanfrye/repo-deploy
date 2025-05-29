#!/bin/bash - 
#===============================================================================
#
#          FILE: run-bootstrap.sh
# 
#         USAGE: ./run-bootstrap.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 05/27/2025 16:35
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -euo pipefail

# Input arguments
REPO_NAME=${1:-"example-repo"}
PROVIDER=${2:-"aws"}
LINTERS=${3:-"yaml,cloudformation"}
DESCRIPTION=${4:-"Example repo generated via repo-deploy"}
DEST_DIR=${5:-"$PWD/../$REPO_NAME"}  # Defaults to one level up
ARTIFACT_BUCKET="cf-artifacts-$(echo "$REPO_NAME" | tr '[:upper:]' '[:lower:]')"

echo "🔧 Starting bootstrap with:"
echo "  Repo Name   : $REPO_NAME"
echo "  Provider    : $PROVIDER"
echo "  Linters     : $LINTERS"
echo "  Description : $DESCRIPTION"
echo "  Destination : $DEST_DIR"
echo "  Artifact Bucket: $ARTIFACT_BUCKET"
echo ""

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Call bootstrap.sh with directory override
./bootstrap/scripts/bootstrap.sh \
  --repo-name "$REPO_NAME" \
  --provider "$PROVIDER" \
  --linters "$LINTERS" \
  --description "$DESCRIPTION" \
  --dest-dir "$DEST_DIR"

# Create the S3 bucket for artifacts
aws s3api create-bucket --bucket "$ARTIFACT_BUCKET" --region us-east-1 --create-bucket-configuration LocationConstraint=us-east-1

# Enable versioning on the S3 bucket
aws s3api put-bucket-versioning --bucket "$ARTIFACT_BUCKET" --versioning-configuration Status=Enabled

# Inject bucket name into repo.toml
sed -i "s|^artifact_bucket =.*|artifact_bucket = \"$ARTIFACT_BUCKET\"|" "$DEST_DIR/repo.toml"

echo "✅ Created artifact bucket: $ARTIFACT_BUCKET"
echo "✅ Bootstrap completed successfully!"
