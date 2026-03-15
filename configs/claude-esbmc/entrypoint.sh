#!/bin/bash
# Entrypoint: configure permissions for ESBMC verification

set -e -o pipefail

# Link shared credentials into this profile's config volume
source /usr/local/bin/setup-credentials.sh

USER_SETTINGS="/home/dev/.claude/settings.json"

# Write user-level settings so ESBMC commands are auto-approved.
if [ ! -f "$USER_SETTINGS" ]; then
    echo "Creating user-level Claude settings..."
    cat > "$USER_SETTINGS" <<'EOF'
{
  "permissions": {
    "allow": [
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "MultiEdit(*)",
      "Bash(esbmc *)",
      "Bash(gcc *)",
      "Bash(g++ *)",
      "Bash(clang *)",
      "Bash(clang++ *)",
      "Bash(make *)",
      "Bash(cmake *)",
      "Bash(solc *)"
    ]
  }
}
EOF
    echo "✓ ESBMC permissions pre-approved (user-level)"
else
    echo "✓ User-level Claude settings already exist"
fi

exec "$@"
