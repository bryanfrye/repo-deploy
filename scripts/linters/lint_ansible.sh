#!/bin/bash
command -v ansible-lint >/dev/null 2>&1 || { echo "ansible-lint not installed. Skipping."; exit 0; }
find . -name "*.yml" -o -name "*.yaml" | grep -i "ansible" | xargs ansible-lint
