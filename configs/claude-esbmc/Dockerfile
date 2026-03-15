FROM prover-agent-base

USER root

# ESBMC release binary (Ubuntu 24.04 build, compatible with Debian trixie)
# NOTE: Only x86_64 binaries are available. On arm64 hosts, build with:
#   docker build --platform linux/amd64 ...
ARG ESBMC_VERSION=8.1
RUN set -eux; \
  apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*; \
  curl -fsSL -o /tmp/esbmc.zip \
    "https://github.com/esbmc/esbmc/releases/download/v${ESBMC_VERSION}/release-ubuntu-24.04--b.RelWithDebInfo.-e.OFF.zip"; \
  unzip -j /tmp/esbmc.zip -d /tmp/esbmc; \
  install -m 755 /tmp/esbmc/esbmc /usr/local/bin/esbmc; \
  rm -rf /tmp/esbmc /tmp/esbmc.zip

# Clone ESBMC agent-marketplace for commands and skills
RUN git clone --depth 1 https://github.com/esbmc/agent-marketplace.git /opt/esbmc-plugin

# Copy plugin commands and skills into Claude Code's directory
RUN mkdir -p /home/dev/.claude/commands && \
    cp /opt/esbmc-plugin/esbmc-plugin/commands/*.md /home/dev/.claude/commands/ && \
    mkdir -p /home/dev/.claude/skills && \
    cp -r /opt/esbmc-plugin/esbmc-plugin/skills/* /home/dev/.claude/skills/ && \
    chown -R dev:dev /home/dev/.claude

# Copy entrypoint
COPY configs/claude-esbmc/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER dev
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["claude"]
