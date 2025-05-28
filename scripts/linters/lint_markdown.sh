#!/bin/bash
command -v markdownlint >/dev/null 2>&1 || { echo "markdownlint not installed. Skipping."; exit 0; }
find . -name "*.md" -exec markdownlint {} +
