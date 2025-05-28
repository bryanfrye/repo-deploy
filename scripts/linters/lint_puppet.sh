#!/bin/bash
command -v puppet-lint >/dev/null 2>&1 || { echo "puppet-lint not installed. Skipping."; exit 0; }
find . -name "*.pp" -exec puppet-lint {} +
