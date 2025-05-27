#!/bin/bash - 
#===============================================================================
#
#          FILE: setup_linters_linux.sh
# 
#         USAGE: ./setup_linters_linux.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 05/27/2025 15:20
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
i#!/bin/bash
set -euo pipefail

echo "=== Setting up linter dependencies ==="

# Python
echo "-> Installing Python requirements"
python3 -m pip install --upgrade pip
pip install -r repo-deploy/requirements.txt

# Ruby
if ! command -v bundler &> /dev/null; then
  echo "-> Installing bundler (Ruby)"
  gem install bundler
fi

echo "-> Installing Ruby gems"
bundle install --gemfile=repo-deploy/Gemfile --path vendor/bundle

# Node.js
if command -v npm &> /dev/null && [ -f "repo-deploy/package.json" ]; then
  echo "-> Installing Node.js packages"
  (cd repo-deploy && npm install)
else
  echo "-> Skipping Node setup (npm not found or package.json missing)"
fi

# Optional: Terraform lint tools
if command -v tflint &> /dev/null; then
  echo "-> tflint found"
else
  echo "!! WARNING: tflint not found in PATH. Please install it manually."
fi

if command -v terraform &> /dev/null; then
  echo "-> terraform found"
else
  echo "!! WARNING: terraform not found in PATH. Please install it manually."
fi

# Optional: ShellCheck
if command -v shellcheck &> /dev/null; then
  echo "-> shellcheck found"
else
  echo "!! WARNING: shellcheck not found. Please install via package manager."
fi

echo "=== Linter setup complete ==="

