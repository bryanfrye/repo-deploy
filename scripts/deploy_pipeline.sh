#!/bin/bash
set -euo pipefail

REPO_TOML="repo.toml"
STAGES=$(sed -n 's/^stages *= *\[\(.*\)\]/\1/p' "$REPO_TOML" | tr -d '"' | tr -d ' ' | tr ',' '\n')

echo "🚀 Deploying infrastructure..."
for stage in $STAGES; do
  provider="${stage%%.*}"
  role="${stage#*.}"
  echo "🔧 Deploying $provider / $role"

  case "$provider" in
    aws|azure|gcp)
      script="./scripts/deploy/deploy_${provider}.sh"
      if [[ -x "$script" ]]; then
        "$script" "$role" || {
          echo "❌ Deployment failed for $provider / $role"
          exit 1
        }
      else
        echo "❌ No deploy script found for $provider"
        exit 1
      fi
      ;;

    ansible)
      playbook="deploy/ansible/${role}.playbook"
      inventory="deploy/ansible/${role}.inventory"
      if [[ -f "$playbook" && -f "$inventory" ]]; then
        echo "🛠️  Running Ansible for $role..."
        ansible-playbook -i "$inventory" "$playbook" || {
          echo "❌ Ansible deployment failed for $role"
          exit 1
        }
      else
        echo "❌ Playbook or inventory not found for $role"
        exit 1
      fi
      ;;

    *)
      echo "❌ Unknown provider: $provider"
      exit 1
      ;;
  esac
done
