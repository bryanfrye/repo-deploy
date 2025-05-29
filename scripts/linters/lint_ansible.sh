#!/bin/bash
TEMPLATE_DIR="./deploy/ansible"
command -v ansible-lint >/dev/null 2>&1 || { echo "ansible-lint not installed. Skipping."; exit 0; }
find $TEMPLATE_DIR  -name "*.playbook" | grep -i "ansible" | xargs ansible-lint
