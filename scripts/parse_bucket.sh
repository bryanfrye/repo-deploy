#!/bin/bash
# Extracts the artifact_bucket value from repo.toml

set -euo pipefail

TOML_FILE="${1:-repo.toml}"

if [[ ! -f "$TOML_FILE" ]]; then
  echo "❌ Error: $TOML_FILE not found" >&2
  exit 1
fi

BUCKET=$(grep -E '^artifact_bucket\s*=' "$TOML_FILE" | cut -d= -f2 | tr -d ' "')

if [[ -z "$BUCKET" ]]; then
  echo "❌ Error: artifact_bucket not found in $TOML_FILE" >&2
  exit 2
fi

echo "$BUCKET"
