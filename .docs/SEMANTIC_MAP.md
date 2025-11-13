# Semantic Map: Hammerspoon Window Manager

**Type**: macOS automation tool for window management
**Core Tech**: Lua + Hammerspoon framework
**Primary Use**: Multi-display window management w/ ultrawide monitor optimization

---

## 1. Domain Concepts

### Window Management (Core Domain)
**Location**: `src/window-manager.lua`

Handles all window positioning, movement, and organization logic:
- **Window Positioning**: Place windows in predefined layouts (left, center, right, full, etc.)
- **Multi-Window Organization**: Smart layout with cycling for 2-4+ windows
- **Cycle State Tracking**: Per-display + per-window-count state for layout cycling
- **Monitor Switching**: Move windows between displays (left/right)
- **Window Utilities**: Minimize all, App Exposé

Key functions:
- `positionWindow(position)`: Position focused window to layout
- `moveToDisplay(direction)`: Move window left/right across displays
- `organizeWindows()`: Smart organize w/ cycling through configs
- `minimizeAll()`: Show desktop
- `showAppWindows()`: App Exposé for current app

### Display Management
**Location**: `src/displays.lua`

Display detection and classification:
- **Ultrawide Detection**: Identifies 3440x1440 displays for pixel-perfect layouts
- **Display Metadata**: Name, resolution, frame, ultrawide flag
- **Display Navigation**: Find displays by position (left/right)
- **Display Queries**: Get current, primary, all displays

Key functions:
- `getAllDisplays()`: Returns all displays w/ metadata
- `isUltrawide(screen)`: Checks if 3440x1440
- `getCurrentDisplay(window)`: Get display containing window
- `findDisplayByPosition(direction, currentScreen)`: Navigate displays

### Layout System
**Location**: `src/layouts.lua`

Defines window geometries for different display types:
- **Ultrawide Layouts**: Fixed pixel layouts (860px + 1720px + 860px system)
- **Proportional Layouts**: Adaptive layouts for non-ultrawide displays (MacBook)
- **Layout Translation**: Maps layout names to screen-specific geometries

Constants:
- **Ultrawide**: 860px (sides) + 1720px (center) = 3440px total
- **9 Layout positions**: left, center, right, full, leftHalf, rightHalf, leftTwoThirds, rightTwoThirds, centerFocus

Key functions:
- `getLayout(position, screen)`: Get layout for position on screen (auto-detects ultrawide)
- `getProportionalLayout(position, frame)`: MacBook-style layouts (50/50 splits)
- `getAvailableLayouts(screen)`: List available layouts for screen

### Notification System
**Location**: `src/notifications.lua`

Enhanced macOS notifications w/ tmux integration:
- **Tmux Auto-Detection**: Captures tmux session:window.pane context
- **One-Click Focus**: "Focus Session" button switches to exact tmux location
- **Terminal Auto-Detection**: Supports Ghostty, iTerm2, kitty, Alacritty, Terminal
- **Claude Code Integration**: Task completion, permission, error notifications
- **Global State Management**: Tracks tmux targets per notification ID

Key functions:
- `send(opts)`: Generic notification w/ optional tmux context
- `taskComplete(message, tmuxTarget)`: Claude task done
- `permissionRequired(message, tmuxTarget)`: Claude permission request
- `error(message, tmuxTarget)`: Error notifications
- `waiting(message, tmuxTarget)`: Waiting for input

CLI integration: `/Users/YOUR_USERNAME/.local/bin/notify-claude`

---

## 2. Technical Layers

### Initialization Layer
**Location**: `init.lua`

Entry point & system bootstrap:
- **Module Loading**: logger → displays → layouts → window-manager → keybindings → notifications
- **Configuration**: Debug, log file, max log lines
- **System Detection**: OS version, display count, display metadata
- **Watchers**: Display changes, config file changes (auto-reload)
- **IPC Setup**: Enable CLI access (`hs.ipc.cliInstall()`)
- **Global Exposure**: `_G.notifications` for IPC access

### Input Handling Layer
**Location**: `src/keybindings.lua`

Keyboard shortcut mappings using Hyper key (Shift+Cmd+Ctrl+Opt):
- **Window Positioning**: h/j/k/l/y/u/i/o/p (vim-style)
- **Monitor Switching**: Left/Right arrows
- **Utilities**: \ (organize), = (minimize), ] (App Exposé)
- **System**: r (reload config)

Requires Karabiner-Elements to map Caps Lock → Hyper.

### Core Logic Layer
**Location**: `src/window-manager.lua`, `src/displays.lua`, `src/layouts.lua`

Business logic for window management:
- **Window Manager**: Core positioning, movement, organization algorithms
- **Displays**: Hardware detection, screen classification
- **Layouts**: Geometry calculations, layout definitions

### Utilities Layer
**Location**: `src/logger.lua`

Supporting infrastructure:
- **Logger**: File-based logging w/ rotation (max 100 lines)
- **Log Levels**: DEBUG, INFO, WARN, ERROR
- **Log Rotation**: Auto-truncates to last N lines

---

## 3. Cross-Cutting Concerns

### Logging
**Files**: All modules (`require("src.logger")`)

Every module logs:
- Initialization steps
- Window/display operations
- Errors and warnings
- User actions (keybindings)

Log file: `~/.config/hammerspoon/debug.log`

### Configuration
**Files**: `init.lua`, `src/logger.lua`, `src/layouts.lua`

Config points:
- Debug enabled/disabled
- Log file path & max lines
- Ultrawide constants (3440x1440)
- Layout pixel definitions
- Hyper key definition

### Error Handling
**Files**: All modules

Patterns:
- Nil checks for windows, screens
- Layout validation
- Display detection failures
- Alert notifications on errors

---

## 4. Data Flow Paths

### Keybinding → Window Positioning
```
User presses Hyper+h
  ↓
keybindings.lua: hotkey callback
  ↓
window-manager.lua: positionWindow("left")
  ↓
displays.lua: getCurrentDisplay(win)
  ↓
layouts.lua: getLayout("left", screen)
  ↓
window-manager.lua: win:setFrame(layout)
```

### Smart Organization (Cycling)
```
User presses Hyper+\
  ↓
window-manager.lua: organizeWindows()
  ↓
Get focused window + screen
  ↓
Get all visible windows on screen
  ↓
Count windows
  ↓
Increment cycle state for display+count key
  ↓
Apply layout config (2-window: 3 configs, 3-window: 4 configs)
  ↓
Position windows with layouts.getLayout()
```

### Monitor Switching
```
User presses Hyper+Left/Right
  ↓
window-manager.lua: moveToDisplay("left" or "right")
  ↓
displays.lua: getCurrentDisplay(win)
  ↓
displays.lua: findDisplayByPosition(direction, currentScreen)
  ↓
window-manager.lua: win:moveToScreen(targetScreen)
  ↓
Maximize on new screen
```

### Notification with Tmux Focus
```
CLI: notify-claude task-complete
  ↓
notifications.lua: taskComplete(message, tmuxTarget)
  ↓
notifications.lua: send(opts) with tmux context
  ↓
Store tmux target globally (notificationTargets[notifId])
  ↓
macOS notification shown w/ "Focus Session" button
  ↓
User clicks button
  ↓
Callback retrieves tmux target from global storage
  ↓
focusTmuxTarget(tmuxTarget)
  ↓
Focus terminal app + run tmux select-window/select-pane
```

### Display Change Detection
```
macOS display configuration changes
  ↓
init.lua: displayWatcher callback
  ↓
displays.lua: getAllDisplays()
  ↓
Log new display count
  ↓
Alert user
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         init.lua                             │
│  (Bootstrap, IPC, Watchers, Module Loading, Global Exposure) │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────┐          ┌──────────────┐
│ keybindings  │          │ notifications│
│  (Input)     │          │ (IPC/CLI)    │
└──────┬───────┘          └──────────────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│          window-manager.lua                   │
│  (Core Logic: Position, Move, Organize)       │
└────────┬─────────────────────┬────────────────┘
         │                     │
         ▼                     ▼
    ┌─────────┐           ┌─────────┐
    │displays │           │ layouts │
    │(Hardware)           │(Geometry)│
    └─────────┘           └─────────┘
         │                     │
         └──────────┬──────────┘
                    ▼
            ┌───────────────┐
            │    logger     │
            │  (Utilities)  │
            └───────────────┘
```

---

## Module Dependency Graph

```
init.lua
├── logger.lua (first)
├── displays.lua (requires: logger)
├── layouts.lua (requires: displays, logger)
├── window-manager.lua (requires: displays, layouts, logger)
├── keybindings.lua (requires: window-manager, logger)
└── notifications.lua (requires: logger)
```

---

## Key Design Patterns

### 1. Display-Adaptive Layouts
Layouts automatically adapt based on display type:
- **Ultrawide (3440x1440)**: Fixed pixel layouts (860/1720/860 system)
- **Other displays**: Proportional layouts (50/50 splits)

### 2. Stateful Cycling
Cycle state tracked per display + window count:
```lua
cycleState["Display Name_3"] = 2  -- Display "X", 3 windows, config 2
```

### 3. Global IPC Exposure
Notifications exposed globally for CLI access:
```lua
_G.notifications = notifications  -- Accessible via hs command-line
```

### 4. Declarative Keybindings
All shortcuts use Hyper key, mapped in single function:
```lua
hs.hotkey.bind(hyper, "h", function() wm.positionWindow("left") end)
```

### 5. Separation of Concerns
- **Displays**: "What hardware do we have?"
- **Layouts**: "What geometries are available?"
- **Window Manager**: "Where should windows go?"
- **Keybindings**: "What keys trigger what?"

---

## External Integrations

### Karabiner-Elements
Maps Caps Lock → Hyper key (Shift+Cmd+Ctrl+Opt)
**Config**: `~/.config/karabiner/karabiner.json`

### Claude Code
Notification hooks for task completion, permission requests
**Config**: `~/.claude/settings.json` (hooks section)
**CLI**: `/Users/YOUR_USERNAME/.local/bin/notify-claude`

### Tmux
Auto-detects tmux context (session:window.pane)
**Integration**: Notification callbacks run tmux select commands

### Terminal Apps
Auto-detects running terminal (Ghostty, iTerm2, kitty, Alacritty, Terminal)
**Usage**: Focuses terminal before tmux commands

---

## File Structure

```
.
├── init.lua                    # Bootstrap & config
├── src/
│   ├── displays.lua            # Display detection (3440x1440 check)
│   ├── keybindings.lua         # Hyper key shortcuts
│   ├── layouts.lua             # Layout definitions (860+1720+860)
│   ├── logger.lua              # File logging w/ rotation
│   ├── notifications.lua       # macOS notifications + tmux focus
│   └── window-manager.lua      # Core positioning & organization
├── scripts/
│   ├── install.sh              # Setup script
│   ├── lint.sh                 # luacheck
│   └── format.sh               # stylua
├── docs/tracker/               # Task tracking
├── .luacheckrc                 # Linter config
├── stylua.toml                 # Formatter config
├── .editorconfig               # Editor config
└── README.md                   # User documentation
```

---

## Quick Reference

### Key Layout Positions
- **left**: 860px left column (ultrawide) / 50% left (MacBook)
- **center**: 1720px center (ultrawide) / 100% (MacBook)
- **right**: 860px right column (ultrawide) / 50% right (MacBook)
- **full**: 3440px full (ultrawide) / 100% (MacBook)
- **leftHalf**: 1720px left half (ultrawide) / 50% left (MacBook)
- **rightHalf**: 1720px right half (ultrawide) / 50% right (MacBook)
- **leftTwoThirds**: 2580px (860+1720) (ultrawide) / 50% left (MacBook)
- **rightTwoThirds**: 2580px (1720+860) (ultrawide) / 50% right (MacBook)
- **centerFocus**: 1200px centered (ultrawide) / 100% (MacBook)

### Keybindings (all use Hyper = Caps Lock)
- **h/j/k/l**: Vim-style window positioning
- **y/u/i/o/p**: Additional window positions
- **Left/Right**: Move to adjacent display
- **\\**: Smart organize (cycles configs)
- **=**: Minimize all (show desktop)
- **]**: App Exposé
- **r**: Reload config

### Smart Organize Cycling
- **1 window**: Full screen (no cycling)
- **2 windows**: 3 configs (focused 2/3 left, 50/50, focused 2/3 right)
- **3 windows**: 4 configs (center focus, left focus + stack, equal thirds, right focus + stack)
- **4+ windows**: Focused left 2/3 + stack right (no cycling)

---

**Generated at commit**: `aea679f8acda618bcba5b0b2e9f430eaf533ba19`
