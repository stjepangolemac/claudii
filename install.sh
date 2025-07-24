#!/bin/bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
CONFIG_DIR="$HOME/.config/claudii"
BIN_DIR="$HOME/.local/bin"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${GREEN}Claudii Installation Script${NC}"
echo "=============================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}! Warning: Docker is not installed. Please install Docker to use claudii.${NC}"
fi

# Check for existing installation
if [ -d "$CONFIG_DIR" ]; then
    echo -e "${YELLOW}! Existing claudii installation found at $CONFIG_DIR${NC}"
    read -p "Do you want to overwrite it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    rm -rf "$CONFIG_DIR"
fi

# Create directories
echo -e "✓ Creating directories..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$BIN_DIR"

# Copy .claudii directory 
if [ -d "$SCRIPT_DIR/.claudii" ]; then
    echo -e "✓ Copying claudii files..."
    rm -rf "$CONFIG_DIR/.claudii" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/.claudii" "$CONFIG_DIR/"
    # Create empty Dockerfiles directory for user
    mkdir -p "$CONFIG_DIR/Dockerfiles"
else
    echo -e "${RED}✗ Error: .claudii directory not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Copy main claudii script
if [ -f "$SCRIPT_DIR/claudii" ]; then
    echo -e "✓ Copying claudii script..."
    cp "$SCRIPT_DIR/claudii" "$CONFIG_DIR/"
    chmod +x "$CONFIG_DIR/claudii"
else
    echo -e "${RED}✗ Error: claudii script not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Create symlink
echo -e "✓ Creating symlink..."
# Remove existing symlink if it exists
[ -L "$BIN_DIR/claudii" ] && rm "$BIN_DIR/claudii"
ln -s "$CONFIG_DIR/claudii" "$BIN_DIR/claudii"

# Check if ~/.local/bin is in PATH
PATH_UPDATED=false
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo -e "${YELLOW}! $BIN_DIR is not in your PATH${NC}"
    
    # Detect shell and update appropriate config file
    SHELL_NAME=$(basename "$SHELL")
    PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
    
    update_shell_config() {
        local config_file="$1"
        if [ -f "$config_file" ]; then
            if ! grep -q "/.local/bin" "$config_file"; then
                echo "" >> "$config_file"
                echo "# Added by claudii installer" >> "$config_file"
                echo "$PATH_LINE" >> "$config_file"
                echo -e "✓ Added $BIN_DIR to PATH in $config_file"
                PATH_UPDATED=true
            fi
        fi
    }
    
    case "$SHELL_NAME" in
        bash)
            update_shell_config "$HOME/.bashrc"
            # Also update .bash_profile on macOS
            if [[ "$OSTYPE" == "darwin"* ]]; then
                update_shell_config "$HOME/.bash_profile"
            fi
            ;;
        zsh)
            update_shell_config "$HOME/.zshrc"
            ;;
        *)
            echo -e "${YELLOW}! Unknown shell: $SHELL_NAME${NC}"
            echo "Please add the following line to your shell configuration file:"
            echo "  $PATH_LINE"
            ;;
    esac
else
    echo -e "✓ $BIN_DIR is already in PATH"
fi

# Verify installation
echo ""
echo -e "${GREEN}Installation completed!${NC}"
echo ""

if [ -x "$BIN_DIR/claudii" ]; then
    echo -e "✓ claudii is installed at: $BIN_DIR/claudii"
else
    echo -e "${RED}✗ Error: claudii installation verification failed${NC}"
    exit 1
fi

# Final instructions
echo ""
echo "Next steps:"
if [ "$PATH_UPDATED" = true ]; then
    echo "1. Restart your terminal or run: source ~/.${SHELL_NAME}rc"
    echo "2. Run 'claudii build' to build the default image"
    echo "3. Run 'claudii start owner/repo branch' to start coding"
else
    echo "1. Run 'claudii build' to build the default image"
    echo "2. Run 'claudii start owner/repo branch' to start coding"
fi

echo ""
echo "For environment-specific images:"
echo "1. Create a Dockerfile at ~/.config/claudii/Dockerfiles/<name>.Dockerfile"
echo "2. Run 'claudii build <name>' to build it"
echo "3. Run 'claudii start <name> owner/repo branch' to use it"

echo ""
echo "To uninstall claudii later, run: claudii uninstall"