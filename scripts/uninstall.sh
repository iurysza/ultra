#!/usr/bin/env bash
# Uninstall script for Ultra Window Manager

set -e

echo "Ultra Window Manager Uninstall"
echo "=============================="
echo ""

ULTRA_DIR="$HOME/.config/ultra"
BOOTSTRAP_DIR="$HOME/.hammerspoon"
NOTIFY_CLI="$HOME/.local/bin/notify-claude"

# Remove bootstrap directory
if [ -d "$BOOTSTRAP_DIR" ]; then
  echo "Removing bootstrap directory: $BOOTSTRAP_DIR"
  rm -rf "$BOOTSTRAP_DIR"
  echo "✓ Bootstrap directory removed"
elif [ -L "$BOOTSTRAP_DIR" ]; then
  echo "Removing old symlink: $BOOTSTRAP_DIR"
  rm "$BOOTSTRAP_DIR"
  echo "✓ Symlink removed"
else
  echo "- Bootstrap directory not found (already removed)"
fi

# Remove notify-claude CLI
if [ -L "$NOTIFY_CLI" ]; then
  echo "Removing CLI symlink: $NOTIFY_CLI"
  rm "$NOTIFY_CLI"
  echo "✓ CLI symlink removed"
else
  echo "- CLI symlink not found (already removed)"
fi

# Ask about config directory
if [ -d "$ULTRA_DIR" ]; then
  echo ""
  read -p "Delete config directory $ULTRA_DIR? (y/N) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$ULTRA_DIR"
    echo "✓ Config directory removed"
  else
    echo "- Config directory kept at $ULTRA_DIR"
  fi
fi

echo ""
echo "=============================="
echo "Uninstall complete!"
echo ""
echo "Hammerspoon will no longer load Ultra on restart."
echo "To reinstall: git clone <repo> ~/.config/ultra && ~/.config/ultra/scripts/install.sh"
