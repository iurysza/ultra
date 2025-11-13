#!/usr/bin/env bash
# Setup script for Hammerspoon Window Manager

set -e

echo "Hammerspoon Window Manager Setup"
echo "=================================="
echo ""

# Check Homebrew
if ! command -v brew &> /dev/null; then
  echo "❌ Homebrew not found. Please install Homebrew first."
  exit 1
fi
echo "✓ Homebrew found"

# Check/install Hammerspoon
if ! brew list hammerspoon &> /dev/null; then
  echo "Installing Hammerspoon..."
  brew install hammerspoon
else
  echo "✓ Hammerspoon installed"
fi

# Check/install luacheck
if ! command -v luacheck &> /dev/null; then
  echo "Installing luacheck..."
  brew install luacheck
else
  echo "✓ luacheck installed"
fi

# Check/install stylua
if ! command -v stylua &> /dev/null; then
  echo "Installing stylua..."
  brew install stylua
else
  echo "✓ stylua installed"
fi

# Create symlink if not exists
if [ ! -L "$HOME/.hammerspoon" ]; then
  echo "Creating symlink ~/.hammerspoon -> ~/.config/hammerspoon"
  ln -s "$HOME/.config/hammerspoon" "$HOME/.hammerspoon"
  echo "✓ Symlink created"
else
  echo "✓ Symlink already exists"
fi

# Make scripts executable
chmod +x "$HOME/.config/hammerspoon/scripts/"*.sh
chmod +x "$HOME/.config/hammerspoon/scripts/notify-claude"
echo "✓ Scripts made executable"

# Setup notify-claude CLI
mkdir -p "$HOME/.local/bin"
if [ ! -L "$HOME/.local/bin/notify-claude" ]; then
  echo "Creating symlink ~/.local/bin/notify-claude"
  ln -sf "$HOME/.config/hammerspoon/scripts/notify-claude" "$HOME/.local/bin/notify-claude"
  echo "✓ notify-claude CLI installed"
else
  echo "✓ notify-claude CLI already installed"
fi

echo ""
echo "=================================="
echo "Setup complete! 🎉"
echo ""
echo "Next steps:"
echo "1. Open Hammerspoon.app from Applications"
echo "2. Grant accessibility permissions when prompted"
echo "3. Test shortcuts (Hyper+h/j/k/l)"
echo "4. View logs: tail -f ~/.config/hammerspoon/debug.log"
echo ""
echo "Useful commands:"
echo "  ./scripts/lint.sh    - Run linter"
echo "  ./scripts/format.sh  - Format code"
echo "  Hyper+R              - Reload config"
