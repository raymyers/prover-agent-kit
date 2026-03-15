FROM prover-agent-base

# Quint-specific system deps (need root for apt)
USER root

RUN apt-get update && apt-get install -y \
	openjdk-21-jdk \
	openssl \
	protobuf-compiler \
	&& rm -rf /var/lib/apt/lists/*

# Java: use arch-agnostic path for JAVA_HOME
RUN ln -sf /usr/lib/jvm/java-21-openjdk-$(dpkg --print-architecture) /usr/lib/jvm/java-21-openjdk
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Quint CLI and Language Server (separate installs to avoid dep resolution issues)
RUN npm install -g @informalsystems/quint && \
	npm install -g @informalsystems/quint-language-server

# Install Go (needed for mcp-language-server)
ARG GO_VERSION=1.24.1
RUN set -eux; \
  arch="$(dpkg --print-architecture)"; \
  case "$arch" in \
    amd64) goarch="amd64" ;; \
    arm64) goarch="arm64" ;; \
    *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
  esac; \
  curl -fsSLO "https://go.dev/dl/go${GO_VERSION}.linux-${goarch}.tar.gz"; \
  tar -C /usr/local -xzf "go${GO_VERSION}.linux-${goarch}.tar.gz"; \
  rm "go${GO_VERSION}.linux-${goarch}.tar.gz"
ENV PATH=/usr/local/go/bin:$PATH
ENV GOPATH=/tmp/go

# Install mcp-language-server (MCP bridge for LSP servers)
RUN mkdir -p /tmp/mcp-build && \
	cd /tmp/mcp-build && \
	git clone https://github.com/isaacphi/mcp-language-server.git && \
	cd mcp-language-server && \
	go build -o /usr/local/bin/mcp-language-server . && \
	cd / && rm -rf /tmp/mcp-build /tmp/go

ARG INSTALL_FOUNDRY=false

# Create MCP server directories
RUN mkdir -p /home/dev/mcp-servers/kb/data && \
	chown -R dev:dev /home/dev/mcp-servers

# Copy agentic directory (agents, commands, guidelines, schemas, scripts)
COPY --chown=dev:dev quint-llm-kit/agentic/ /home/dev/.claude/

# Copy MCP servers
COPY --chown=dev:dev quint-llm-kit/mcp-servers/lsp-setup/ /home/dev/mcp-servers/lsp-setup/
COPY --chown=dev:dev quint-llm-kit/mcp-servers/README.md /home/dev/mcp-servers/README.md
COPY --chown=dev:dev quint-llm-kit/mcp-servers/kb/package.json mcp-servers/kb/package-lock.json /home/dev/mcp-servers/kb/
COPY --chown=dev:dev quint-llm-kit/mcp-servers/kb/tsconfig.json mcp-servers/kb/jest.config.js /home/dev/mcp-servers/kb/
COPY --chown=dev:dev quint-llm-kit/mcp-servers/kb/src/ /home/dev/mcp-servers/kb/src/
COPY --chown=dev:dev quint-llm-kit/mcp-servers/kb/scripts/ /home/dev/mcp-servers/kb/scripts/
COPY --chown=dev:dev quint-llm-kit/mcp-servers/kb/tests/ /home/dev/mcp-servers/kb/tests/

# Copy config-specific files
COPY --chown=dev:dev configs/claude-quint/setup-mcp.sh /home/dev/setup-mcp.sh
RUN chmod +x /home/dev/setup-mcp.sh

COPY configs/claude-quint/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
USER dev

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Foundry (optional)
RUN if [ "$INSTALL_FOUNDRY" = "true" ]; then \
    curl -L https://foundry.paradigm.xyz | bash && \
    /home/dev/.foundry/bin/foundryup; \
  fi

ENV GOPATH=/home/dev/go
ENV PATH=/usr/local/go/bin:$GOPATH/bin:/home/dev/.cargo/bin:/home/dev/.foundry/bin:$PATH

# Build KB server
WORKDIR /home/dev/mcp-servers/kb
RUN npm install && npm run build

# KB content (changes frequently)
COPY --chown=dev:dev quint-llm-kit/mcp-servers/kb/kb/ /home/dev/mcp-servers/kb/kb/

# Build indices
RUN npm run setup && \
	chown -R dev:dev /home/dev/mcp-servers/kb/data

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
