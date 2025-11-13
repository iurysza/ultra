#!/usr/bin/env bash
# Run stylua formatter on all Lua files

set -e

echo "Running stylua..."
stylua --config-path stylua.toml .
echo "✓ Format complete"
