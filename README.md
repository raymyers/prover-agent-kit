# Prover Agent Kit
[![MIT][mit-badge]][mit-url]

[mit-badge]: https://img.shields.io/badge/license-MIT-blue
[mit-url]: https://github.com/raymyers/prover-agent-kit/blob/main/LICENSE

A containerized toolkit for AI-assisted formal verification and theorem proving. Each profile bundles an AI agent with a prover, MCP servers, skills, and pre-approved permissions into a ready-to-use Docker environment.

## Profiles

| Profile | Agent | Prover | Platform |
|---|---|---|---|
| `claude-quint` | Claude Code | [Quint](https://quint-lang.org/) formal specification | linux/arm64, linux/amd64 |
| `claude-numina-lean` | Claude Code | [Lean 4](https://lean-lang.org/) theorem proving ([Numina](https://github.com/project-numina/numina-lean-agent)) | linux/arm64, linux/amd64 |
| `claude-esbmc` | Claude Code | [ESBMC](https://esbmc.org/) model checking (C/C++/Solidity) | linux/amd64 only |

> **Note:** `claude-esbmc` requires x86_64. On Apple Silicon or other ARM hosts, Docker will use Rosetta/QEMU emulation, which works but is slower. The ESBMC project does not currently publish ARM binaries.

## Prerequisites

- Docker
- A project directory (new or existing)

## Quick Start

```bash
# List available profiles
./prover-agent list

# Start an interactive session (auto-builds on first run)
./prover-agent run claude-quint ~/my-project

# Forward args to the agent after --
./prover-agent run claude-quint ~/my-project -- --resume
```

## Commands

```
prover-agent list                              Show available profiles
prover-agent run <profile> [dir] [-- args...]  Start interactive session
prover-agent build <profile> [docker args...]  Build a profile's image
prover-agent clean <profile>                   Remove image and volumes
prover-agent status                            Show running sessions
```

Build args are forwarded to `docker build`:

```bash
# Quint with Foundry toolchain
./prover-agent build claude-quint --build-arg INSTALL_FOUNDRY=true

# ESBMC on ARM host (emulated)
./prover-agent build claude-esbmc --platform linux/amd64
```

## How It Works

Each profile is a directory under `configs/` containing:

- **`profile.yml`** — name, description, image tag, exec command, volumes
- **`Dockerfile`** — builds on the shared `claude-base` image
- **`entrypoint.sh`** — configures MCP servers and auto-approves permissions on first run

The session runs as `docker run --rm -it` — when you exit, the container is removed. A persistent Docker volume preserves Claude Code auth between sessions.

## Profile Details

### claude-quint

Quint formal specification with MCP servers for LSP diagnostics and a knowledge base of docs/examples/patterns. Includes slash commands for the full workflow: `/spec:start`, `/verify:generate-witness`, `/code:start`, `/refactor:start`.

### claude-numina-lean

Lean 4 theorem proving using [Numina's lean-lsp-mcp](https://github.com/project-numina/lean-lsp-mcp) (16 tools: goal inspection, diagnostics, leansearch, loogle, multi-attempt screening). The [numina-lean-agent](https://github.com/project-numina/numina-lean-agent) runner and prompts are available at `/home/dev/numina-lean-agent`.

### claude-esbmc

[ESBMC](https://github.com/esbmc/esbmc) bounded model checker for C, C++, and Solidity. Includes `/verify` and `/audit` commands from the [ESBMC agent marketplace](https://github.com/esbmc/agent-marketplace). Supports memory safety, integer overflow, undefined behavior, and concurrency checks.

## Security Notes

- Containers run as a non-root user (`dev`)
- API keys are stored by Claude Code inside the persistent volume (not in the image)
- Permissions for MCP tools, file operations, and prover commands are pre-approved via user-level Claude settings

## Adding a New Profile

```bash
mkdir configs/my-profile
# Add: Dockerfile, entrypoint.sh, profile.yml
# It appears in `prover-agent list` automatically
```

## License

MIT
