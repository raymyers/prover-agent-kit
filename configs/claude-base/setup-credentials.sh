#!/bin/bash
# Shared credentials setup: symlink credential files between per-profile
# config volume and the shared credentials volume.
#
# Shared volume:     /home/dev/.claude-credentials/ (same across all profiles)
# Per-profile volume: /home/dev/.claude/             (profile-specific)
#
# On login, Claude Code writes .credentials.json to .claude/.
# This script symlinks it to the shared volume so all profiles see it.

CREDS_DIR="/home/dev/.claude-credentials"
CLAUDE_DIR="/home/dev/.claude"
CRED_FILE=".credentials.json"

mkdir -p "$CREDS_DIR" "$CLAUDE_DIR"

if [ -f "$CREDS_DIR/$CRED_FILE" ] && [ ! -e "$CLAUDE_DIR/$CRED_FILE" ]; then
    # Shared credentials exist, profile doesn't have them yet — symlink in
    ln -sf "$CREDS_DIR/$CRED_FILE" "$CLAUDE_DIR/$CRED_FILE"
    echo "✓ Credentials loaded from shared volume"
elif [ -f "$CLAUDE_DIR/$CRED_FILE" ] && [ ! -L "$CLAUDE_DIR/$CRED_FILE" ]; then
    # Profile has real credentials file (from a previous login) — move to shared, symlink back
    mv "$CLAUDE_DIR/$CRED_FILE" "$CREDS_DIR/$CRED_FILE"
    ln -sf "$CREDS_DIR/$CRED_FILE" "$CLAUDE_DIR/$CRED_FILE"
    echo "✓ Credentials migrated to shared volume"
elif [ -L "$CLAUDE_DIR/$CRED_FILE" ]; then
    echo "✓ Credentials already linked"
else
    # No credentials anywhere — first run, Claude will prompt for login.
    # On next start, the migration path above will move them to shared.
    echo "⚠ No credentials found — Claude will prompt for login"
fi

# Configure git identity from host (passed as env vars by prover-agent)
if [ -n "${GIT_AUTHOR_NAME:-}" ]; then
    git config --global user.name "$GIT_AUTHOR_NAME"
    git config --global user.email "${GIT_AUTHOR_EMAIL:-}"
    echo "✓ Git identity: $GIT_AUTHOR_NAME <${GIT_AUTHOR_EMAIL:-}>"
fi
