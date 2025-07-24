#!/bin/bash

# Handle credentials from environment variables
if [ -n "$CLAUDE_CREDENTIALS" ]; then
    echo "$CLAUDE_CREDENTIALS" > /home/developer/.claude.json
    # Also keep a backup
    mkdir -p /home/developer/.claude
    cp /home/developer/.claude.json /home/developer/.claude/.credentials.json
    
    # Use jq to properly add the onboarding flags
    if [ -f /home/developer/.claude.json ] && command -v jq >/dev/null; then
        # Create a temporary file with the updates
        jq '. + {
            "hasCompletedOnboarding": true,
            "bypassPermissionsModeAccepted": true,
            "projects": {
                "/workspace/repo": {
                    "hasCompletedProjectOnboarding": true,
                    "hasTrustDialogAccepted": true,
                    "allowedTools": []
                }
            }
        }' /home/developer/.claude.json > /home/developer/.claude.json.tmp && mv /home/developer/.claude.json.tmp /home/developer/.claude.json
    fi
    
    # Clear the environment variable
    unset CLAUDE_CREDENTIALS
fi

# Handle GitHub hosts configuration
if [ -n "$GH_HOSTS_CONTENT" ]; then
    mkdir -p /home/developer/.config/gh
    echo "$GH_HOSTS_CONTENT" > /home/developer/.config/gh/hosts.yml
    unset GH_HOSTS_CONTENT
fi

# CLAUDE.md is now pre-generated in the Docker image

# Handle git configuration from environment
if [ -n "$GIT_CONFIG_DATA" ]; then
    GIT_USER_NAME=$(echo "$GIT_CONFIG_DATA" | cut -d'|' -f1)
    GIT_USER_EMAIL=$(echo "$GIT_CONFIG_DATA" | cut -d'|' -f2)
    
    if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
        # Create a proper .gitconfig file
        cat > /home/developer/.gitconfig <<EOF
[user]
	name = $GIT_USER_NAME
	email = $GIT_USER_EMAIL
EOF
        chmod 644 /home/developer/.gitconfig
    fi
fi

# Get repository and branch from command line arguments
REPO="$1"
BRANCH="$2"

if [ -z "$REPO" ] || [ -z "$BRANCH" ]; then
    echo "Error: Missing repository or branch"
    exit 1
fi

echo "Setting up repository $REPO on branch $BRANCH..."

# Configure git to use gh for authentication
gh auth setup-git --with-token >/dev/null 2>&1

# Create the repo directory immediately
mkdir -p /workspace/repo
cd /workspace/repo

# Create a flag file to indicate cloning is in progress
touch .cloning

# Clone the repository in the background
(
    # Clone to a temp directory first
    TEMP_DIR="/tmp/repo-$$"
    gh repo clone "$REPO" "$TEMP_DIR" -- --quiet >/dev/null 2>&1
    
    # If clone succeeded, move contents to current directory
    if [ $? -eq 0 ]; then
        # Move all files including hidden ones
        mv "$TEMP_DIR"/* "$TEMP_DIR"/.* . 2>/dev/null || true
        rmdir "$TEMP_DIR" 2>/dev/null || true
        
        # Create and checkout the new branch
        git checkout -b "$BRANCH" --quiet >/dev/null 2>&1
        
        # Set up push default
        git config push.default current >/dev/null 2>&1
    fi
    
    # Remove the flag file when done
    rm -f .cloning
) >/dev/null 2>&1 &

# Store the background job PID
CLONE_PID=$!

echo ""
echo "Ready! You're in /workspace/repo"
echo "Repository is cloning in the background (PID: $CLONE_PID)"
echo ""

# Start Claude Code
exec claude --dangerously-skip-permissions
