#!/bin/bash

# Bootstrap script for CCD containers
REPO="$1"
BRANCH="$2"

if [[ -z "$REPO" || -z "$BRANCH" ]]; then
    echo "Error: Missing required arguments"
    echo "Usage: bootstrap.sh <repo> <branch>"
    exit 1
fi

echo "Setting up repository $REPO on branch $BRANCH..."

# Clone the repository
gh repo clone "https://github.com/$REPO" /workspace/repo -- --quiet
cd /workspace/repo

# Create and checkout the new branch
git checkout -b "$BRANCH" --quiet

echo ""
echo "Ready! You're in /workspace/repo on branch $BRANCH"
echo "Starting Claude Code..."
echo ""

# Start Claude Code with skip permissions flag
exec claude --dangerously-skip-permissions