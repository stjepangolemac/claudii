ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

# Verify this is an Ubuntu-based image
RUN if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then \
        echo "Error: Only Ubuntu-based images are supported" >&2 && \
        exit 1; \
    fi

# Install essential system packages
# Update package lists and install essentials, handling potential errors
RUN apt-get update || true && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    gpg \
    sudo \
    lsb-release \
    software-properties-common \
    || (apt-get update --fix-missing && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        gpg \
        sudo \
        lsb-release \
        software-properties-common)

# Install version control tools
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    || echo "Git might already be installed"

# Install text editors
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    vim \
    neovim \
    || echo "Text editors might already be installed"

# Install Node.js and npm
# Check if nodejs/npm are already installed, if not install them
RUN if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then \
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
        nodejs \
        npm \
        || (curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
            DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs); \
    fi

# Install JSON processing tools
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    jq \
    || echo "jq might already be installed"

# Install GitHub CLI
# Check if gh is already installed
RUN if ! command -v gh >/dev/null 2>&1; then \
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y gh; \
    fi

# Clean up apt cache
RUN rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Create a non-root user if it doesn't exist
# Some base images might already have users
RUN if ! id -u developer >/dev/null 2>&1; then \
        useradd -m -s /bin/bash developer && \
        echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    else \
        echo "User 'developer' already exists"; \
    fi

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
