#!/bin/bash
command -v cfn-lint >/dev/null 2>&1 || { echo "cfn-lint not installed. Skipping."; exit 0; }
find ./deploy/cloudformation -name '*.yaml' -exec cfn-lint {} +
