FROM ubuntu:24.04

# Install essential tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    nodejs \
    npm \
    jq \
    sudo \
    neovim \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Create a non-root user
RUN useradd -m -s /bin/bash developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create necessary directories with proper ownership
RUN mkdir -p /home/developer/.claude /home/developer/.config/gh /workspace && \
    chown -R developer:developer /home/developer /workspace

# Copy scripts and CLAUDE.md
COPY entrypoint.sh /entrypoint.sh
COPY CLAUDE.md /home/developer/.claude/CLAUDE.md
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER developer
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
