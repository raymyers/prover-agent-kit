FROM debian:trixie-slim

RUN mkdir /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
	curl \
	git \
	build-essential \
	ca-certificates \
	tree \
	jq \
	ripgrep \
	python3 \
	python3-pip \
	python3-venv \
	&& rm -rf /var/lib/apt/lists/*

# Install Node.js (required for Claude Code)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
	&& apt-get install -y nodejs \
	&& rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user with passwordless sudo for apt
RUN apt-get update && apt-get install -y sudo && rm -rf /var/lib/apt/lists/* && \
	useradd -m -s /bin/bash dev && \
	chown -R dev:dev /workspace && \
	echo "dev ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/apt" > /etc/sudoers.d/dev

RUN mkdir -p /home/dev/.claude /home/dev/.claude-credentials && \
	chown -R dev:dev /home/dev/.claude /home/dev/.claude-credentials

# Shared credentials setup script (called by profile entrypoints)
COPY configs/claude-base/setup-credentials.sh /usr/local/bin/setup-credentials.sh
RUN chmod +x /usr/local/bin/setup-credentials.sh

WORKDIR /workspace
USER dev

# Install uv as dev user so it lands in ~/.local/bin
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/home/dev/.local/bin:$PATH"
