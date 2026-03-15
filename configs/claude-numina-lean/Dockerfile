FROM prover-agent-base

# Install elan (Lean version manager)
RUN curl https://elan.lean-lang.org/elan-init.sh -sSf | sh -s -- -y
ENV PATH="/home/dev/.elan/bin:$PATH"

# Pre-install lean-lsp-mcp so first run is fast
RUN uvx lean-lsp-mcp --help > /dev/null 2>&1 || true

# Clone numina-lean-agent for its prompts and runner
RUN git clone --depth 1 https://github.com/project-numina/numina-lean-agent.git /home/dev/numina-lean-agent

# Install numina-lean-agent Python deps
WORKDIR /home/dev/numina-lean-agent
RUN uv python install 3.13 && uv sync
WORKDIR /workspace

# Copy entrypoint (need root for /usr/local/bin)
USER root
COPY configs/claude-numina-lean/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
USER dev

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
