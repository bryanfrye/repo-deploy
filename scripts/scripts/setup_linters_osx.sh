#!/bin/bash - 
#===============================================================================
#
#          FILE: setup_linters_osx.sh
# 
#         USAGE: ./setup_linters_osx.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 05/27/2025 15:21
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
i#!/bin/bash
set -euo pipefail

echo "=== macOS Linter Setup ==="

# Check for Homebrew
if ! command -v brew &> /dev/null; then
  echo "Homebrew not found. Please install Homebrew first: https://brew.sh/"
  exit 1
fi

# Install dependencies via Homebrew if missing
brew_install_if_missing() {
  if ! command -v "$1" &> /dev/null; then
    echo "-> Installing $1..."
    brew install "$1"
  else
    echo "-> $1 already installed"
  fi
}

brew_install_if_missing python3
brew_install_if_missing ruby
brew_install_if_missing npm
brew_install_if_missing terraform
brew_install_if_missing tflint
brew_install_if_missing shellcheck

# Python setup
echo "-> Installing Python requirements"
python3 -m pip install --upgrade pip
pip3 install -r repo-deploy/requirements.txt

# Ruby setup
if ! command -v bundler &> /dev/null; then
  echo "-> Installing bundler (Ruby)"
  gem install bundler
fi

echo "-> Installing Ruby gems"
bundle install --gemfile=repo-deploy/Gemfile --path vendor/bundle

# Node.js setup
if [ -f "repo-deploy/package.json" ]; then
  echo "-> Installing Node.js packages"
  (cd repo-deploy && npm install)
else
  echo "-> Skipping Node setup (package.json not found)"
fi

echo "=== macOS linter setup complete ==="

