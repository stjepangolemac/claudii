#!/bin/bash

# Generate CLAUDE.md based on the Dockerfile
echo "Generating CLAUDE.md from Dockerfile..."

# Create the prompt file
cat > /tmp/dockerfile-content.txt << 'EOF'
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

# Switch to non-root user
USER developer
WORKDIR /workspace
EOF

# Generate CLAUDE.md using Claude
claude -p "Based on this Dockerfile, generate a comprehensive CLAUDE.md file that will help Claude Code understand the development environment inside this container. The file should:

1. List all installed tools and their purposes
2. Explain the environment setup (user permissions, working directory)
3. Note any special configurations or limitations
4. Include helpful reminders about available commands
5. Be concise but informative
6. Mention that this is a CCD (Claude Code Docker) environment

Important context:
- The container is used for Claude Code development work
- GitHub CLI and Claude are pre-authenticated using host credentials
- The repository will be cloned to /workspace/repo
- A new branch will be created for the work

Generate ONLY the markdown content for CLAUDE.md, nothing else. No explanations, just the content." < /tmp/dockerfile-content.txt

rm /tmp/dockerfile-content.txt