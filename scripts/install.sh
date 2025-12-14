#!/usr/bin/env bash
# Setup script for Ultra Window Manager

set -e

echo "Ultra Window Manager Setup"
echo "=========================="
echo ""

ULTRA_DIR="$HOME/.config/ultra"
BOOTSTRAP_DIR="$HOME/.hammerspoon"
BOOTSTRAP_FILE="$BOOTSTRAP_DIR/init.lua"

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

# Remove old symlink if exists (must do before mkdir)
if [ -L "$BOOTSTRAP_DIR" ]; then
  echo "Removing old symlink at $BOOTSTRAP_DIR"
  rm "$BOOTSTRAP_DIR"
fi

# Create bootstrap directory
mkdir -p "$BOOTSTRAP_DIR"

# Create bootstrap file (loads config from ~/.config/ultra)
echo "Creating bootstrap file at $BOOTSTRAP_FILE"
cat > "$BOOTSTRAP_FILE" << 'EOF'
-- Ultra Window Manager Bootstrap
-- This file loads the actual configuration from ~/.config/ultra
package.path = os.getenv("HOME") .. "/.config/ultra/?.lua;" .. package.path
package.path = os.getenv("HOME") .. "/.config/ultra/src/?.lua;" .. package.path
dofile(os.getenv("HOME") .. "/.config/ultra/init.lua")
EOF
echo "✓ Bootstrap file created"

# Make scripts executable
chmod +x "$ULTRA_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$ULTRA_DIR/scripts/notify-claude" 2>/dev/null || true
echo "✓ Scripts made executable"

# Setup notify-claude CLI
mkdir -p "$HOME/.local/bin"
if [ -f "$ULTRA_DIR/scripts/notify-claude" ]; then
  ln -sf "$ULTRA_DIR/scripts/notify-claude" "$HOME/.local/bin/notify-claude"
  echo "✓ notify-claude CLI installed"
fi

# Copy default config if user config doesn't exist
if [ ! -f "$ULTRA_DIR/config.json" ] && [ -f "$ULTRA_DIR/config.default.json" ]; then
  echo "Creating config.json from defaults..."
  cp "$ULTRA_DIR/config.default.json" "$ULTRA_DIR/config.json"
  echo "✓ config.json created (customize this file)"
fi

echo ""
echo "=========================="
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Open Hammerspoon.app from Applications"
echo "2. Grant accessibility permissions when prompted"
echo "3. Customize ~/.config/ultra/config.json"
echo "4. Test shortcuts (Hyper+h/j/k/l)"
echo "5. View logs: tail -f ~/.config/ultra/debug.log"
echo ""
echo "Useful commands:"
echo "  ./scripts/lint.sh    - Run linter"
echo "  ./scripts/format.sh  - Format code"
echo "  Hyper+R              - Reload config"
echo ""
