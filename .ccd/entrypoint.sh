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

# Handle CLAUDE.md content
if [ -n "$CLAUDE_MD_CONTENT" ]; then
    mkdir -p /home/developer/.claude
    echo "$CLAUDE_MD_CONTENT" > /home/developer/.claude/CLAUDE.md
    unset CLAUDE_MD_CONTENT
fi

exec "$@"