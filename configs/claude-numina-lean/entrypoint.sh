#!/bin/bash
# Entrypoint: configure MCP servers and permissions for Lean proving

set -e -o pipefail

# Link shared credentials into this profile's config volume
source /usr/local/bin/setup-credentials.sh

MCP_JSON="/workspace/.mcp.json"
USER_SETTINGS="/home/dev/.claude/settings.json"

# Write user-level settings so MCP tools and Lean commands are auto-approved.
if [ ! -f "$USER_SETTINGS" ]; then
    echo "Creating user-level Claude settings..."
    cat > "$USER_SETTINGS" <<'EOF'
{
  "enabledMcpjsonServers": ["lean-lsp"],
  "enableAllProjectMcpServers": true,
  "permissions": {
    "allow": [
      "mcp__lean-lsp__*",
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "MultiEdit(*)",
      "Bash(lake *)",
      "Bash(lean *)",
      "Bash(elan *)",
      "Bash(rg *)",
      "Bash(python *)",
      "Bash(uv *)"
    ]
  }
}
EOF
    echo "✓ MCP tool permissions pre-approved (user-level)"
else
    echo "✓ User-level Claude settings already exist"
fi

# Create .mcp.json in the workspace if it doesn't exist
if [ ! -f "$MCP_JSON" ]; then
    echo "Creating .mcp.json with lean-lsp MCP server..."
    cat > "$MCP_JSON" <<'EOF'
{
  "mcpServers": {
    "lean-lsp": {
      "command": "uvx",
      "args": ["lean-lsp-mcp"],
      "env": {
        "LEAN_PROJECT_PATH": "/workspace"
      }
    }
  }
}
EOF
    echo "✓ MCP server configured: lean-lsp"
else
    echo "✓ .mcp.json already exists"
fi

exec "$@"
