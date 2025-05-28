#!/bin/bash
command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not installed. Skipping."; exit 0; }
find . -type f -name "*.sh" -exec shellcheck {} +
