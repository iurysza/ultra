# Semantic Map: Hammerspoon Window Manager

**Type**: macOS automation tool for window management + app launching
**Core Tech**: Lua + Hammerspoon framework
**Primary Use**: Multi-display window management w/ ultrawide monitor optimization + smart app toggling

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

### App Launcher (Smart Toggle)
**Location**: `src/app-launcher.lua`

Smart application launcher with 3-state toggle behavior:
- **Launch**: Start app if not running
- **Focus**: Bring to foreground if running but hidden
- **Hide**: Minimize/hide if already frontmost

Toggle strategies:
- **Bundle ID**: Primary method for most apps (`toggleApp(bundleID)`)
- **App Name**: Fallback for apps w/o bundle ID (`toggleAppByName(name)`)
- **AppleScript**: Special cases (e.g., scrcpy window focus)

Key functions:
- `toggleApp(bundleID)`: Smart 3-state toggle by bundle ID
- `toggleAppByName(appName)`: Toggle by app name (fallback)
- `executeAppleScript(script)`: Execute AppleScript commands
- `togglePlayPause()`: Media control (Play/Pause system key)

### App-Specific Keybindings
**Location**: `src/app-specific-keys.lua`

Context-aware keybindings that activate only in specific apps:
- **Dynamic Enable/Disable**: Hotkeys enabled only when target app is frontmost
- **Application Watcher**: Monitors app activation events
- **Obsidian Integration**: Vim-style navigation + custom shortcuts

Current implementations:
- **Obsidian**:
  - Ctrl+h/j/k/l → Arrow keys (vim navigation)
  - Cmd+` → Forward delete
  - Cmd+w → Cmd+= (zoom in)
  - Cmd+s → Cmd+- (zoom out)

Key functions:
- `setup()`: Initialize app-specific keybindings + watcher

### Workspaces (App Groups)
**Location**: `src/workspaces.lua`

Predefined app layouts w/ cycling:
- **Workspace Definitions**: Named groups of apps w/ layouts (comms, web, webdev, androiddev)
- **Workspace Groups**: Cycling sets for shortcuts (n_group, m_group)
- **Smart Launch**: Launch/focus all apps + minimize non-workspace windows
- **Multi-Window Support**: Handle multiple windows of same app (e.g., 2 Chrome windows)
- **Auto-Positioning**: Apply layouts after 0.5s delay
- **Cycle State**: Track current workspace per group

Predefined workspaces:
- **comms**: Slack + Meet + Chrome (3-way split)
- **web**: 2 Chrome windows (50/50)
- **webdev**: Cursor + Ghostty + Chrome (3-way split)
- **androiddev**: Android Studio + Ghostty (50/50)

Key functions:
- `activateWorkspace(workspaceId)`: Launch + position workspace apps
- `cycleWorkspace(groupId)`: Cycle through workspace group
- `getWorkspaces()`: List all workspaces

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
- **Auto-Dismiss**: Notifications auto-withdraw after 5 seconds

Key functions:
- `send(opts)`: Generic notification w/ optional tmux context
- `taskComplete(message, tmuxTarget)`: Claude task done
- `permissionRequired(message, tmuxTarget)`: Claude permission request
- `error(message, tmuxTarget)`: Error notifications
- `waiting(message, tmuxTarget)`: Waiting for input

CLI integration: `~/.local/bin/notify-claude` (via scripts/)

---

## 2. Technical Layers

### Initialization Layer
**Location**: `init.lua`

Entry point & system bootstrap:
- **Module Loading**: logger → displays → layouts → window-manager → keybindings → app-specific-keys → notifications
- **Configuration**: Debug, log file, max log lines
- **System Detection**: OS version, display count, display metadata
- **Watchers**: Display changes, config file changes (auto-reload)
- **IPC Setup**: Enable CLI access (`hs.ipc.cliInstall()`)
- **Global Exposure**: `_G.notifications` for IPC access

### Input Handling Layer
**Location**: `src/keybindings.lua`, `src/app-specific-keys.lua`

**Global Keybindings** (`keybindings.lua`):
Hyper key (Shift+Cmd+Ctrl+Opt) shortcuts:
- **Window Positioning**: h/j/k/l/y/u/i/o/p (vim-style)
- **Monitor Switching**: Left/Right arrows
- **Utilities**: \ (organize), = (minimize), ] (App Exposé), r (reload)
- **App Launchers**: F1-F12, ;, g, 5 (smart toggle)
- **Workspace Cycling**: n (comms ↔ web), m (webdev ↔ androiddev)

**App-Specific Keybindings** (`app-specific-keys.lua`):
Context-aware shortcuts that only work in specific apps:
- Dynamic enable/disable based on frontmost app
- Currently: Obsidian vim navigation + custom shortcuts

Requires Karabiner-Elements to map Caps Lock → Hyper.

### Core Logic Layer
**Location**: `src/window-manager.lua`, `src/app-launcher.lua`, `src/workspaces.lua`, `src/displays.lua`, `src/layouts.lua`

Business logic:
- **Window Manager**: Core positioning, movement, organization algorithms
- **App Launcher**: Smart toggle logic (launch → focus → hide)
- **Workspaces**: Multi-app layout orchestration w/ cycling
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
- App launches/toggles
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
- Notification auto-dismiss timeout (5s)

### Error Handling
**Files**: All modules

Patterns:
- Nil checks for windows, screens, apps
- Layout validation
- Display detection failures
- Bundle ID validation
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

### App Launcher Toggle (3-State)
```
User presses Hyper+F10 (Obsidian)
  ↓
keybindings.lua: hotkey callback
  ↓
app-launcher.lua: toggleApp("md.obsidian")
  ↓
Check app state:
  - Not running? → hs.application.launchOrFocusByBundleID()
  - Running but not frontmost? → Focus app
  - Already frontmost? → app:hide()
  ↓
Log action to debug.log
```

### App-Specific Keybinding Activation
```
User switches to Obsidian
  ↓
app-specific-keys.lua: appWatcher callback (activated event)
  ↓
Check if app:bundleID() == "md.obsidian"
  ↓
Enable all Obsidian hotkeys (Ctrl+hjkl, Cmd+`, etc.)
  ↓
User presses Ctrl+h
  ↓
app-specific-keys.lua: hotkey callback
  ↓
hs.eventtap.keyStroke({}, "left")  -- Send arrow key
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

### Workspace Cycling
```
User presses Hyper+N (comms ↔ web)
  ↓
keybindings.lua: hotkey callback
  ↓
workspaces.lua: cycleWorkspace("n_group")
  ↓
Get cycle state → increment → wrap around
  ↓
workspaces.lua: activateWorkspace(workspaceId)
  ↓
minimizeNonWorkspaceWindows(apps) → minimize all other windows
  ↓
Launch/focus all workspace apps (deduplicated)
  ↓
Wait 0.5s for apps to launch
  ↓
positionApps() → apply layouts to windows
  ↓
Focus first app window
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
Auto-dismiss after 5 seconds (unless user interacts)
  ↓
User clicks button (optional)
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
Alert user (auto-dismiss after 5s)
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         init.lua                             │
│  (Bootstrap, IPC, Watchers, Module Loading, Global Exposure) │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┬──────────────────┬─────────┐
        │                         │                   │         │
        ▼                         ▼                   ▼         ▼
┌──────────────┐          ┌──────────────┐    ┌──────────────┐ │
│ keybindings  │          │app-specific  │    │ notifications│ │
│  (Global)    │          │  -keys       │    │ (IPC/CLI)    │ │
└──────┬───────┘          │(Context-     │    └──────────────┘ │
       │                  │ aware)       │                      │
       │                  └──────────────┘                      │
       │                                                         │
       ├──────────────┬──────────────────────────────────────────┘
       ▼              ▼
┌──────────────┐  ┌──────────────────────────────────┐
│window-manager│  │       workspaces.lua              │
│(Position,    │  │ (Multi-app orchestration, cycling)│
│Move, Organize)  └────────────┬──────────────────────┘
└──────┬───────┘               │
       │                       │
       ▼                       ▼
┌──────────────────┐      ┌─────────┐           ┌─────────┐
│  app-launcher    │      │displays │           │ layouts │
│(Launch/Focus/Hide)      │(Hardware)           │(Geometry)│
└──────────────────┘      └─────────┘           └─────────┘
         │                     │                     │
         └──────────┬──────────┴─────────────────────┘
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
├── workspaces.lua (requires: app-launcher, displays, layouts, logger)
├── keybindings.lua (requires: window-manager, app-launcher, workspaces, logger)
├── app-specific-keys.lua (requires: logger)
└── notifications.lua (requires: logger)

app-launcher.lua (standalone, requires: logger)
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

### 3. Smart Toggle State Machine
App launcher uses 3-state logic:
```lua
Not Running → Launch
Running + Hidden → Focus
Running + Frontmost → Hide
```

### 4. Context-Aware Keybindings
App-specific hotkeys dynamically enabled/disabled:
```lua
appWatcher → Check bundleID → Enable/Disable hotkeys
```

### 5. Global IPC Exposure
Notifications exposed globally for CLI access:
```lua
_G.notifications = notifications  -- Accessible via hs command-line
```

### 6. Declarative Keybindings
All shortcuts use Hyper key, mapped in single function:
```lua
hs.hotkey.bind(hyper, "h", function() wm.positionWindow("left") end)
hs.hotkey.bind(hyper, "f10", function() appLauncher.toggleApp("md.obsidian") end)
```

### 7. Workspace Orchestration
Multi-app coordination w/ group cycling:
```lua
workspaceGroups["n_group"] = { "comms", "web" }  -- Hyper+N cycles
cycleState["n_group"] = 1  -- Track current workspace
```

### 8. Separation of Concerns
- **Displays**: "What hardware do we have?"
- **Layouts**: "What geometries are available?"
- **Window Manager**: "Where should windows go?"
- **App Launcher**: "How do we launch/focus/hide apps?"
- **Workspaces**: "How do we orchestrate multiple apps?"
- **Keybindings**: "What keys trigger what?"
- **App-Specific Keys**: "What keys work in which apps?"

---

## External Integrations

### Karabiner-Elements
Maps Caps Lock → Hyper key (Shift+Cmd+Ctrl+Opt), Esc when tapped alone
**Config**: `~/.config/karabiner/karabiner.json`
**Note**: Only handles key mapping; app launchers and Obsidian bindings now in Hammerspoon

### Claude Code
Notification hooks for task completion, permission requests
**Config**: `~/.claude/settings.json` (hooks section)
**CLI**: `~/.local/bin/notify-claude`

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
│   ├── app-launcher.lua        # Smart app toggle (launch/focus/hide)
│   ├── app-specific-keys.lua   # Context-aware keybindings (Obsidian, etc.)
│   ├── displays.lua            # Display detection (3440x1440 check)
│   ├── keybindings.lua         # Hyper key shortcuts (window + app + workspace)
│   ├── layouts.lua             # Layout definitions (860+1720+860)
│   ├── logger.lua              # File logging w/ rotation
│   ├── notifications.lua       # macOS notifications + tmux focus (5s auto-dismiss)
│   ├── window-manager.lua      # Core positioning & organization
│   └── workspaces.lua          # Multi-app orchestration w/ cycling
├── scripts/
│   ├── install.sh              # Setup script
│   ├── lint.sh                 # luacheck
│   ├── format.sh               # stylua
│   └── notify-claude           # CLI notification tool
├── docs/tracker/               # Task tracking
├── .docs/                      # Hidden docs (SEMANTIC_MAP.md)
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

**Window Management:**
- **h/j/k/l**: Vim-style window positioning
- **y/u/i/o/p**: Additional window positions
- **Left/Right**: Move to adjacent display
- **\\**: Smart organize (cycles configs)
- **=**: Minimize all (show desktop)
- **]**: App Exposé
- **r**: Reload config

**App Launchers (Smart Toggle):**
- **F1**: Play/Pause
- **F2**: Ghostty
- **F3**: Cursor
- **F4**: Spotify
- **F8**: Slack
- **F9**: Android Studio
- **F10**: Obsidian
- **F11**: Chrome
- **F12**: WhatsApp
- **;**: Msty
- **g**: Google Meet (moved from 'm')
- **5**: scrcpy

**Workspace Cycling:**
- **n**: Cycle Communication ↔ Web
- **m**: Cycle Coding ↔ Android (moved from Google Meet)

**Obsidian-Specific (only when Obsidian is frontmost):**
- **Ctrl+h/j/k/l**: Arrow navigation (vim-style)
- **Cmd+`**: Forward delete
- **Cmd+w**: Zoom in (remapped to Cmd+=)
- **Cmd+s**: Zoom out (remapped to Cmd+-)

### Smart Organize Cycling
- **1 window**: Full screen (no cycling)
- **2 windows**: 3 configs (focused 2/3 left, 50/50, focused 2/3 right)
- **3 windows**: 4 configs (center focus, left focus + stack, equal thirds, right focus + stack)
- **4+ windows**: Focused left 2/3 + stack right (no cycling)

---

## Recent Changes

### Workspaces System (Current)
- **New Module**: `src/workspaces.lua` for multi-app orchestration
- **4 Workspaces**: comms, web, webdev, androiddev
- **Cycling Groups**: Hyper+N (comms ↔ web), Hyper+M (webdev ↔ androiddev)
- **Smart Launch**: Auto-minimize non-workspace windows
- **Multi-Window Support**: Handle 2+ windows of same app (e.g., Chrome)
- **Auto-Positioning**: 0.5s delay for app launch
- **Keybinding Changes**: Google Meet moved from 'm' to 'g' (m = workspace cycling)

### App Launcher System (Previous Session)
- **New Module**: `app-launcher.lua` with 3-state toggle logic
- **Smart Behavior**: Launch → Focus → Hide based on app state
- **12 App Shortcuts**: F1-F12, semicolon, g, 5 keys
- **Integration**: Migrated from Karabiner to Hammerspoon

### App-Specific Keybindings (Previous Session)
- **New Module**: `app-specific-keys.lua` with dynamic hotkey management
- **Obsidian Integration**: Vim navigation + custom shortcuts
- **Application Watcher**: Auto-enable/disable based on frontmost app
- **Extensible Design**: Easy to add bindings for other apps

### Notification Auto-Dismiss (Previous Session)
- **5-Second Timeout**: All notifications now auto-dismiss
- **Consistent UX**: Applies to all notification types (task complete, errors, etc.)

---

**Generated at commit**: `a0065918c3870c67423d86606bd4c908da8fd7be`
