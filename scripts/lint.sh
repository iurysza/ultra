#!/usr/bin/env bash
# Run luacheck on all Lua files

set -e

echo "Running luacheck..."
luacheck . --config .luacheckrc
echo "✓ Lint check passed"
