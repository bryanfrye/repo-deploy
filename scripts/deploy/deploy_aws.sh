#!/bin/bash
set -euo pipefail

stage="${1:-}"
REPO_TOML="./repo.toml"
TEMPLATE_DIR="./deploy/cloudformation"

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

template="$TEMPLATE_DIR/$stage.yaml"
stack_name="${stage}-stack"

echo "::group::🔧 Deploying AWS stack for stage: $stage"
echo "   Region     : $REGION"
echo "   Template   : $template"
echo "   Stack Name : $stack_name"
echo "   Tags       : $TAG_KEY=$TAG_VALUE"

if [[ ! -f "$template" ]]; then
  echo "❌ Template not found: $template"
  exit 1
fi

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
    --template-body "file://$template" \
    --region "$REGION" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --tags "${TAG_KEY}=${TAG_VALUE}" \
    --enable-termination-protection
else
  echo "-> Updating existing stack..."
  aws cloudformation deploy \
    --template-file "$template" \
    --stack-name "$stack_name" \
    --region "$REGION" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
    --tags "${TAG_KEY}=${TAG_VALUE}"
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
echo "::endgroup::"
