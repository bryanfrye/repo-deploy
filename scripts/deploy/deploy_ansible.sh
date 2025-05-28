#!/bin/bash
#===============================================================================
#
#          FILE: deploy_ansible.sh
#
#         USAGE: ./deploy_ansible.sh lamp.playbook
#
#   DESCRIPTION: Executes Ansible playbook against provisioned infrastructure.
#
#===============================================================================

set -euo pipefail

RESOURCE="$1"
PLAYBOOK_PATH="./deploy/ansible/${RESOURCE}.playbook"

echo "➡️  Running Ansible playbook: $PLAYBOOK_PATH"

# Optional: dynamically build inventory from EC2 tag/filter/etc.
INVENTORY="./deploy/ansible/inventory.ini"

# Validate playbook exists
if [[ ! -f "$PLAYBOOK_PATH" ]]; then
  echo "❌ Playbook not found: $PLAYBOOK_PATH"
  exit 1
fi

# Validate inventory exists
if [[ ! -f "$INVENTORY" ]]; then
  echo "⚠️  Inventory not found: $INVENTORY"
  echo "   You may need to generate dynamic inventory or define a static one."
  exit 1
fi

# Run the playbook
ANSIBLE_HOST_KEY_CHECKING=False \
  ansible-playbook -i "$INVENTORY" "$PLAYBOOK_PATH" \
  --extra-vars "env=production"

echo "✅ Ansible deployment completed: $RESOURCE"
