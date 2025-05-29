#!/bin/bash
set -euo pipefail

stage="${1:-}"
REPO_TOML="./repo.toml"
TEMPLATE_DIR="./deploy/cloudformation"
TMP_DIR="./tmp"

if [[ -z "$stage" ]]; then
  echo "❌ Usage: $0 <stage-name>"
  exit 1
fi

if [[ ! -f "$REPO_TOML" ]]; then
  echo "❌ repo.toml not found in root directory."
  exit 1
fi

REGION=$(grep '^region' "$REPO_TOML" | cut -d'=' -f2 | tr -d ' "')
TAG_KEY=$(grep '^tag_key' "$REPO_TOML" | cut -d'=' -f2 | tr -d ' "')
TAG_VALUE=$(grep '^tag_value' "$REPO_TOML" | cut -d'=' -f2 | tr -d ' "')
ARTIFACT_BUCKET=$(grep '^artifact_bucket' "$REPO_TOML" | cut -d'=' -f2 | tr -d ' "')

template="$TEMPLATE_DIR/$stage.yaml"
stack_name="${stage}-stack"
packaged_template="$TMP_DIR/${stage}_packaged.yaml"

echo "::group::🔧 Deploying AWS stack for stage: $stage"
echo "   Region          : $REGION"
echo "   Template        : $template"
echo "   Stack Name      : $stack_name"
echo "   Tags            : $TAG_KEY=$TAG_VALUE"
echo "   Artifact Bucket : $ARTIFACT_BUCKET"

if [[ ! -f "$template" ]]; then
  echo "❌ Template not found: $template"
  exit 1
fi

# Package with CloudFormation to inject S3 paths
mkdir -p "$TMP_DIR"
echo "📦 Packaging CloudFormation template to $packaged_template"
aws cloudformation package \
  --template-file "$template" \
  --s3-bucket "$ARTIFACT_BUCKET" \
  --output-template-file "$packaged_template"

# Check if stack exists
exists=$(aws cloudformation describe-stacks \
  --stack-name "$stack_name" \
  --region "$REGION" \
  --query "Stacks[0].StackName" \
  --output text 2>/dev/null || echo "")

if [[ -z "$exists" ]]; then
  echo "-> Creating new stack with termination protection..."
  aws cloudformation create-stack \
    --stack-name "$stack_name" \
    --template-body "file://$packaged_template" \
    --region "$REGION" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --tags Key="${TAG_KEY}",Value="${TAG_VALUE}" \
    --enable-termination-protection || {
    echo "❌ Stack creation skipped or failed (likely intentional) - continuing...."
    exit 0
  }
else
  echo "-> Updating existing stack..."
  aws cloudformation deploy \
    --template-file "$packaged_template" \
    --stack-name "$stack_name" \
    --region "$REGION" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --tags Key="${TAG_KEY}",Value="${TAG_VALUE}"
fi

# Check for stack event errors
errors=$(aws cloudformation describe-stack-events \
  --stack-name "$stack_name" \
  --region "$REGION" \
  --query "StackEvents[?ResourceStatus=='CREATE_FAILED' || ResourceStatus=='ROLLBACK_IN_PROGRESS' || ResourceStatus=='ROLLBACK_COMPLETE'].[LogicalResourceId, ResourceStatusReason]" \
  --output text)

if [[ -n "$errors" ]]; then
  echo "!! Stack errors found:"
  echo "$errors"
  exit 1
fi

echo "✅ Stack $stack_name deployed successfully."
rm -rf "$TMP_DIR"
echo "::endgroup::"
