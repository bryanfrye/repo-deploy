REPO_CONFIG="./repo.toml"
STAGES=$(tomlq -r '.stages[]' "$REPO_CONFIG")

for stage in $STAGES; do
  provider="${stage%%.*}"     # everything before the first dot
  resource="${stage#*.}"      # everything after the first dot
  script="scripts/deploy/deploy_${provider}.sh"

  echo "➡️  Stage: $stage"
  echo "🔧 Using: $script"

  if [[ -x "$script" ]]; then
    "$script" "$resource" || {
      echo "❌ Stage $stage failed"
      exit 1
    }
  else
    echo "⚠️  No deploy script for provider: $provider"
    exit 1
  fi
done
