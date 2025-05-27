#!/bin/bash - 
#===============================================================================
#
#          FILE: deploy_stacks.sh
# 
#         USAGE: ./deploy_stacks.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 05/27/2025 15:24
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -euo pipefail

TEMPLATE_DIR="./deploy/cloudformation"
REGION="${AWS_REGION:-us-east-1}"
TAG_KEY="Project"
TAG_VALUE="$(basename "$(pwd)")"

echo "=== Deploying CloudFormation stacks from: $TEMPLATE_DIR ==="

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "No CloudFormation directory found at $TEMPLATE_DIR"
  exit 0
fi

template_files=$(find "$TEMPLATE_DIR" -type f \( -iname "*.yaml" -o -iname "*.yml" \))

if [ -z "$template_files" ]; then
  echo "No CloudFormation templates found."
  exit 0
fi

for template in $template_files; do
  filename=$(basename "$template")
  stack_name="$(basename "$template" .yaml | sed 's/[^a-zA-Z0-9-]//g')-stack"
  param_file="${template%.*}.params.json"

  echo "-> Deploying stack: $stack_name"
  echo "   Template: $template"
  [ -f "$param_file" ] && echo "   Params: $param_file"

  # Check for existing stack
  exists=$(aws cloudformation describe-stacks \
    --stack-name "$stack_name" \
    --region "$REGION" \
    --query "Stacks[0].StackName" \
    --output text 2>/dev/null || echo "")

  deploy_cmd=(
    aws cloudformation deploy
    --template-file "$template"
    --stack-name "$stack_name"
    --region "$REGION"
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
    --tags "${TAG_KEY}=${TAG_VALUE}"
  )

  # Add params if file exists
  if [ -f "$param_file" ]; then
    deploy_cmd+=(--parameter-overrides "$(jq -r '.[] | "\(.ParameterKey)=\(.ParameterValue)"' "$param_file")")
  fi

  # Enable termination protection if new stack
  if [ -z "$exists" ]; then
    echo "-> New stack detected. Enabling termination protection..."
    aws cloudformation create-stack \
      --stack-name "$stack_name" \
      --template-body "file://$template" \
      --region "$REGION" \
      --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
      --tags "${TAG_KEY}=${TAG_VALUE}" \
      ${param_file:+--parameters file://$param_file} \
      --enable-termination-protection
    continue
  fi

  # Execute deploy
  echo "-> Running CloudFormation deploy..."
  "${deploy_cmd[@]}" || {
    echo "!! Deployment command failed for $stack_name"
    exit 1
  }

  # Check for stack event errors
  echo "-> Checking for stack errors in: $stack_name"
  errors=$(aws cloudformation describe-stack-events \
    --stack-name "$stack_name" \
    --region "$REGION" \
    --query "StackEvents[?ResourceStatus=='CREATE_FAILED' || ResourceStatus=='ROLLBACK_IN_PROGRESS' || ResourceStatus=='ROLLBACK_COMPLETE'].[LogicalResourceId, ResourceStatusReason]" \
    --output text)

  if [ -n "$errors" ]; then
    echo "!! Stack errors found in $stack_name:"
    echo "$errors"
    exit 1
  fi

  echo "-> Stack $stack_name deployed successfully."
done

echo "=== All stacks processed ==="

