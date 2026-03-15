#!/bin/bash
# Entrypoint script to ensure MCP servers are properly configured

set -e -o pipefail

# Link shared credentials into this profile's config volume
source /usr/local/bin/setup-credentials.sh

MCP_JSON="/workspace/.mcp.json"
USER_SETTINGS="/home/dev/.claude/settings.json"
KB_SERVER_PATH="/home/dev/mcp-servers/kb/dist/server.js"
KB_DATA_DIR="/home/dev/mcp-servers/kb/data"

# KB indices are pre-built in the Docker image
echo "✓ KB indices pre-built in Docker image"

# Write user-level settings so MCP tools are auto-approved without a trust prompt.
# Project-level settings (.claude/settings.json in the workspace) require the user
# to approve "trust this project" before permissions.allow takes effect. User-level
# settings are always trusted, so MCP calls never prompt for approval.
if [ ! -f "$USER_SETTINGS" ]; then
    echo "Creating user-level Claude settings with MCP tool permissions..."
    cat > "$USER_SETTINGS" <<EOF
{
  "enabledMcpjsonServers": ["quint-lsp", "quint-kb"],
  "enableAllProjectMcpServers": true,
  "permissions": {
    "allow": [
      "mcp__quint-kb__*",
      "mcp__quint-lsp__*",
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "MultiEdit(*)",
      "Bash(quint*)",
      "Bash(cargo check*)",
      "Bash(cargo test*)",
      "Bash(cargo build*)",
      "Bash(cargo clippy*)",
      "Bash(cargo run*)",
      "Bash(go test*)",
      "Bash(go build*)",
      "Bash(go vet*)",
      "Bash(tsc*)",
      "Bash(npx tsc*)",
      "Bash(npm test*)",
      "Bash(npm run *)",
      "Bash(yarn test*)",
      "Bash(yarn run *)",
      "Bash(bun test*)",
      "Bash(bun run *)",
      "Bash(pytest*)",
      "Bash(python -m pytest*)",
      "Bash(make test*)",
      "Bash(make check*)",
      "Bash(make build*)"
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
    echo "Creating .mcp.json with MCP server configuration..."
    cat > "$MCP_JSON" <<EOF
{
  "mcpServers": {
    "quint-lsp": {
      "command": "mcp-language-server",
      "args": [
        "--workspace",
        "/workspace",
        "--lsp",
        "quint-language-server",
        "--",
        "--stdio"
      ]
    },
    "quint-kb": {
      "command": "node",
      "args": [
        "$KB_SERVER_PATH"
      ]
    }
  }
}
EOF
    echo "✓ MCP servers configured: quint-lsp, quint-kb"
    echo "✓ Configuration saved to: $MCP_JSON"
else
    echo "✓ .mcp.json already exists at: $MCP_JSON"
fi

# Execute the command passed to docker run
exec "$@"
