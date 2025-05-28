#!/bin/bash
#===============================================================================
#
#          FILE: deploy_stacks.sh
#
#         USAGE: ./deploy_stacks.sh
#
#   DESCRIPTION: Deploys CloudFormation stacks in a specific order using
#                definitions from repo.toml
#
#===============================================================================

set -euo pipefail

REPO_TOML="./repo.toml"
TEMPLATE_DIR="./deploy/cloudformation"

if [[ ! -f "$REPO_TOML" ]]; then
  echo "❌ repo.toml not found in root directory."
  exit 1
fi

# Extract config from TOML
STAGES=$(grep '^stages' "$REPO_TOML" | cut -d'=' -f2 | tr -d '[]",' | tr '\n' ' ')
REGION=$(grep '^region' "$REPO_TOML" | cut -d'=' -f2 | tr -d ' "')
TAG_KEY=$(grep '^tag_key' "$REPO_TOML" | cut -d'=' -f2 | tr -d ' "')
TAG_VALUE=$(grep '^tag_value' "$REPO_TOML" | cut -d'=' -f2 | tr -d ' "')

echo "=== Deploying CloudFormation stacks from: $TEMPLATE_DIR ==="
echo "🌐 Region: $REGION"
echo "🔖 Tag: $TAG_KEY=$TAG_VALUE"
echo "📦 Ordered Stages: $STAGES"

for stage in $STAGES; do
  template="$TEMPLATE_DIR/$stage.yaml"
  param_file="${template%.*}.params.json"
  stack_name="${stage}-stack"

  echo ""
  echo "-> Deploying stage: $stage"
  echo "   Stack name: $stack_name"
  echo "   Template: $template"

  if [[ ! -f "$template" ]]; then
    echo "❌ Template not found: $template"
    exit 1
  fi

  if [[ -f "$param_file" ]]; then
    echo "   Params: $param_file"
  fi

  # Check if stack exists
  exists=$(aws cloudformation describe-stacks \
    --stack-name "$stack_name" \
    --region "$REGION" \
    --query "Stacks[0].StackName" \
    --output text 2>/dev/null || echo "")

  if [[ -z "$exists" ]]; then
    echo "-> New stack detected. Creating with termination protection..."

    create_cmd=(
      aws cloudformation create-stack
      --stack-name "$stack_name"
      --template-body "file://$template"
      --region "$REGION"
      --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
      --tags "${TAG_KEY}=${TAG_VALUE}"
      --enable-termination-protection
    )

    if [[ -f "$param_file" ]]; then
      create_cmd+=(--parameters file://"$param_file")
    fi

    "${create_cmd[@]}"
    continue
  fi

  echo "-> Stack exists. Updating if necessary..."

  deploy_cmd=(
    aws cloudformation deploy
    --template-file "$template"
    --stack-name "$stack_name"
    --region "$REGION"
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
    --tags "${TAG_KEY}=${TAG_VALUE}"
  )

  if [[ -f "$param_file" ]]; then
    param_string=$(jq -r '.[] | "\(.ParameterKey)=\(.ParameterValue)"' "$param_file" | xargs)
    deploy_cmd+=(--parameter-overrides $param_string)
  fi

  "${deploy_cmd[@]}" || {
    echo "!! Deployment failed for stack: $stack_name"
    exit 1
  }

  echo "-> Checking for stack errors in: $stack_name"
  errors=$(aws cloudformation describe-stack-events \
    --stack-name "$stack_name" \
    --region "$REGION" \
    --query "StackEvents[?ResourceStatus=='CREATE_FAILED' || ResourceStatus=='ROLLBACK_IN_PROGRESS' || ResourceStatus=='ROLLBACK_COMPLETE'].[LogicalResourceId, ResourceStatusReason]" \
    --output text)

  if [[ -n "$errors" ]]; then
    echo "!! Stack errors found in $stack_name:"
    echo "$errors"
    exit 1
  fi

  echo "✅ Stack $stack_name deployed successfully."
done

echo ""
echo "=== All stacks processed ==="

