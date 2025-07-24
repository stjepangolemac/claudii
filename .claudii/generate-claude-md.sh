#!/bin/bash

# Generate CLAUDE.md based on the Dockerfile
# This runs on the host before Docker build

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKERFILE="$SCRIPT_DIR/Dockerfile"

if [ ! -f "$DOCKERFILE" ]; then
    echo "Error: Dockerfile not found at $DOCKERFILE" >&2
    exit 1
fi

# Read the Dockerfile content
DOCKERFILE_CONTENT=$(cat "$DOCKERFILE")

# Generate CLAUDE.md using Claude on the host
claude --model sonnet -p "Based on this Dockerfile, generate a comprehensive CLAUDE.md file that will help Claude Code understand the development environment inside this container. The file should:

1. List all installed tools and their purposes
2. Explain the environment setup (user permissions, working directory)
3. Note any special configurations or limitations
4. Include helpful reminders about available commands
5. Be concise but informative
6. Mention that this is a Claudii (Claude Code Docker) environment

Important context:
- The container is used for Claude Code development work
- GitHub CLI is pre-authenticated using host OAuth token
- Git is configured to use gh for authentication (HTTPS)
- The repository will be cloned to /workspace/repo
- A new branch will be created for the work
- Git user.name and user.email are pre-configured from host

Here is the Dockerfile:

$DOCKERFILE_CONTENT

Generate ONLY the markdown content for CLAUDE.md, nothing else. No explanations, just the content."
