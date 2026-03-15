# Prover Agent Kit — Repository Notes

## Project Overview

A toolkit for AI-assisted formal verification and theorem proving. Each profile bundles an AI agent with a prover, MCP servers, skills, and pre-approved permissions into a Docker environment.

## CLI

`./prover-agent` is the single entry point. It scans `configs/*/profile.yml` to discover profiles.

```
prover-agent list                              # Show available profiles
prover-agent run <profile> [dir] [-- args...]  # Start interactive session
prover-agent build <profile> [docker args...]  # Build image
prover-agent clean <profile>                   # Remove image + volumes
prover-agent status                            # Show running sessions
```

## Profile Architecture

Profiles live in `configs/<name>/`. Each contains:

| File | Purpose |
|---|---|
| `profile.yml` | Name, description, image tag, volume, exec command |
| `Dockerfile` | Builds on `prover-agent-base` (from `configs/claude-base/`) |
| `entrypoint.sh` | Configures MCP servers, permissions, and shared credentials on startup |

### Active profiles

| Profile | Prover | Platform |
|---|---|---|
| `claude-quint` | Quint formal specification | arm64, amd64 |
| `claude-numina-lean` | Lean 4 theorem proving (Numina) | arm64, amd64 |
| `claude-esbmc` | ESBMC model checking (C/C++/Solidity) | amd64 only |

## Key Directories

| Path | Purpose |
|---|---|
| `configs/claude-base/` | Shared base image: Debian trixie + Node + Claude Code + uv + dev user |
| `configs/claude-quint/` | Quint profile: Dockerfile, entrypoint, setup-mcp |
| `configs/claude-numina-lean/` | Numina Lean profile: Dockerfile, entrypoint |
| `configs/claude-esbmc/` | ESBMC profile: Dockerfile, entrypoint |
| `quint-llm-kit/` | Git submodule of [informalsystems/quint-llm-kit](https://github.com/informalsystems/quint-llm-kit) (agents, commands, MCP servers) |

## Docker Volumes

Two types of volumes are mounted by `prover-agent run`:

- **`prover-agent-credentials`** — shared across all profiles at `/home/dev/.claude-credentials/`. Holds `.credentials.json` so you log in once and all profiles pick it up.
- **`prover-agent-config-<profile>`** — per-profile at `/home/dev/.claude/`. Holds settings, MCP config, history. Profile-specific so MCP servers and permissions don't collide.

The `setup-credentials.sh` script (in base image) is called by every entrypoint. It symlinks credentials between the shared and per-profile volumes.

## Docker Build Context

All builds use the repo root as context:
```
docker build -t <image> -f configs/<profile>/Dockerfile .
```
`COPY` paths in Dockerfiles are relative to the root.

## MCP Auto-Approval

Each `entrypoint.sh` writes **user-level** settings to `/home/dev/.claude/settings.json` on first run. User-level settings are always trusted by Claude Code — no prompts for MCP calls, file reads/edits, or listed Bash commands.

- `enableAllProjectMcpServers: true` auto-approves all project MCP servers
- `Read(*)`, `Write(*)`, `Edit(*)`, `MultiEdit(*)` cover file operations
- Profile-specific `Bash(...)` patterns cover prover commands
- The `if [ ! -f ]` guard preserves existing settings across restarts
