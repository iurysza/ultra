# Hammerspoon Window Manager - Project Plan

## Overview
Multi-display window manager for macOS using Hammerspoon. Replaces Karabiner-based AppleScript window management with Lua-based solution supporting ultrawide (3440x1440) and MacBook displays.

## Active Tasks

### Setup & Infrastructure
- [ ] [Install dependencies and setup project](./setup-infrastructure.md)
- [ ] [Configure quality tools](./quality-tools.md)

### Core Implementation
- [ ] [Implement logger module](./logger-module.md)
- [ ] [Implement display detection](./display-detection.md)
- [ ] [Implement layout definitions](./layout-definitions.md)
- [ ] [Implement window manager core](./window-manager-core.md)
- [ ] [Implement keybindings](./keybindings.md)
- [ ] [Create init.lua entry point](./init-entry-point.md)

### Integration
- [ ] [Clean up Karabiner config](./karabiner-cleanup.md)

### Documentation & Release
- [ ] [Write comprehensive README](./documentation.md)
- [ ] [Test multi-display scenarios](./testing.md)
- [ ] [Initialize git repository](./git-setup.md)

## Completed Tasks
None yet - project just started

## Project Context
- Location: `~/.config/hammerspoon/`
- Symlink: `~/.hammerspoon` → `~/.config/hammerspoon/`
- Ultrawide layout: 860px + 1720px + 860px (3440x1440)
- MacBook layout: Simplified left/right halves
- Debug logging: `~/.config/hammerspoon/debug.log`

## Success Criteria
- All window positioning shortcuts work on ultrawide
- MacBook display uses simplified left/right layout
- Monitor switching works (Hyper+Left/Right)
- Smart organizer only affects focused display
- Debug logging captures all actions
- Code passes luacheck with no errors
- Code formatted with stylua
- README is comprehensive
- Works seamlessly with existing Karabiner setup
