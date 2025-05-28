#!/bin/bash - 
#===============================================================================
#
#          FILE: lint_cfn_nag.sh
# 
#         USAGE: ./lint_cfn_nag.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 05/27/2025 17:36
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
command -v cfn_nag_scan >/dev/null 2>&1 || {
  echo "cfn_nag not installed. Skipping."
  exit 0
}

TEMPLATE_DIR="./deploy/cloudformation"
if [[ -d "$TEMPLATE_DIR" ]]; then
  echo "🔍 Running cfn_nag on $TEMPLATE_DIR"
  find "$TEMPLATE_DIR" -name '*.yaml' -exec cfn_nag_scan --input-path {} +
else
  echo "No CloudFormation directory found. Skipping cfn_nag."
fi

