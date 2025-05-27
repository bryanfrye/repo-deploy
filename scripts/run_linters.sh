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
#       CREATED: 05/27/2025 15:17
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#!/bin/bash
set -euo pipefail

echo "=== Running linters ==="
failures=0

# YAML
if find . -type f \( -iname "*.yml" -o -iname "*.yaml" \) | grep -q .; then
  echo "-> Running yamllint"
  pip install --quiet yamllint
  yamllint . || failures=$((failures+1))
fi

# Python
if find . -type f -iname "*.py" | grep -q .; then
  echo "-> Running flake8 for Python"
  pip install --quiet flake8
  flake8 . || failures=$((failures+1))
fi

# Ruby
if find . -type f -iname "*.rb" | grep -q .; then
  echo "-> Running rubocop"
  gem install --silent rubocop
  rubocop . || failures=$((failures+1))
fi

# Puppet
if find . -type f -iname "*.pp" | grep -q .; then
  echo "-> Running puppet-lint"
  gem install --silent puppet-lint
  puppet-lint . || failures=$((failures+1))
fi

# Ansible
if find . -type f \( -iname "*.yml" -o -iname "*.yaml" \) -exec grep -q "hosts:" {} \;; then
  echo "-> Running ansible-lint"
  pip install --quiet ansible-lint
  ansible-lint || failures=$((failures+1))
fi

# CloudFormation
if grep -q '"AWSTemplateFormatVersion"' $(find . -name '*.yaml' -o -name '*.yml') 2>/dev/null; then
  echo "-> Running cfn-lint"
  pip install --quiet cfn-lint
  cfn-lint $(find . -name '*.yaml' -o -name '*.yml') || failures=$((failures+1))
fi

# Markdown
if find . -type f -iname "*.md" | grep -q .; then
  echo "-> Running markdownlint"
  npm install -g markdownlint-cli
  markdownlint . || failures=$((failures+1))
fi

# Terraform
if find . -type f -iname "*.tf" | grep -q .; then
  echo "-> Running terraform fmt and tflint"
  terraform fmt -check -recursive || failures=$((failures+1))
  tflint || failures=$((failures+1))
fi

# Shell
if find . -type f -iname "*.sh" | grep -q .; then
  echo "-> Running shellcheck"
  sudo apt-get update -qq
  sudo apt-get install -y shellcheck
  find . -name \"*.sh\" -exec shellcheck {} + || failures=$((failures+1))
fi

# Result
if [ "$failures" -ne 0 ]; then
  echo "=== Linting completed with errors ==="
  exit 1
else
  echo "=== All linters passed ==="
fi

