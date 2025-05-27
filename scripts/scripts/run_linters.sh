#!/bin/bash - 
#===============================================================================
#
#          FILE: run_linters.sh
# 
#         USAGE: ./run_linters.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 05/27/2025 17:08
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -e

if [[ ! -f .linters ]]; then
  echo "No .linters file found. Skipping linting."
  exit 0
fi

echo "🔍 Detected linters:"
cat .linters

while read -r linter; do
  script="./scripts/linters/lint_${linter}.sh"
  if [[ -x "$script" ]]; then
    echo "➡️  Running $linter linter..."
    "$script"
  else
    echo "⚠️  Skipping $linter — no script found at $script"
  fi
done < .linters

