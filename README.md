# Hammerspoon Window Manager

Multi-display window manager for macOS with dedicated support for ultrawide monitors (3440x1440). Built with Hammerspoon and Lua.

## Features

- **Ultrawide-Optimized Layouts**: Center-focused 860px + 1720px + 860px layout system
- **Multi-Display Support**: Adaptive layouts for ultrawide and MacBook displays
- **Vim-Style Navigation**: h/j/k/l keyboard shortcuts for window positioning
- **Smart Window Organizer**: Automatically arranges multiple windows based on count
- **Monitor Switching**: Move windows between displays with arrow keys
- **Debug Logging**: Comprehensive logging for troubleshooting
- **Auto-Reload**: Configuration reloads automatically on file changes
- **Code Quality**: Linted with luacheck and formatted with stylua

## Installation

### Prerequisites

- macOS 10.12 or later
- [Homebrew](https://brew.sh/)
- [Karabiner-Elements](https://karabiner-elements.pqrs.org/) (for Hyper key mapping)

### Quick Install

```bash
# Clone or navigate to the project
cd ~/.config/hammerspoon

# Run installation script
./scripts/install.sh

# Launch Hammerspoon
open -a Hammerspoon

# Grant accessibility permissions when prompted
```

### Manual Installation

```bash
# Install dependencies
brew install hammerspoon luacheck stylua

# Create symlink
ln -s ~/.config/hammerspoon ~/.hammerspoon

# Launch Hammerspoon
open -a Hammerspoon
```

## Configuration

### Hyper Key Setup (Required)

This window manager uses the **Hyper key** (Shift+Cmd+Ctrl+Opt) for all shortcuts. You need Karabiner-Elements to map Caps Lock to Hyper.

Add this to your Karabiner configuration:

```json
{
  "description": "Caps Lock → Hyper Key",
  "manipulators": [{
    "from": {
      "key_code": "caps_lock",
      "modifiers": { "optional": ["any"] }
    },
    "to": [{
      "key_code": "left_shift",
      "modifiers": ["left_command", "left_control", "left_option"]
    }],
    "type": "basic"
  }]
}
```

### Debug Logging

Enable/disable debug logging in `init.lua`:

```lua
local config = {
  debug = true,  -- Set to false to disable
  logFile = "~/.config/hammerspoon/debug.log",
  maxLogLines = 100,
}
```

View logs:

```bash
tail -f ~/.config/hammerspoon/debug.log
```

## Keyboard Shortcuts

All shortcuts use **Hyper** (Caps Lock via Karabiner) + key.

### Window Positioning

| Shortcut | Action | Ultrawide Layout | MacBook Layout |
|----------|--------|------------------|----------------|
| **Hyper+H** | Left | 860px left column | Left half |
| **Hyper+J** | Center | 1720px center | Full screen |
| **Hyper+K** | Full | Full screen | Full screen |
| **Hyper+L** | Right | 860px right column | Right half |
| **Hyper+Y** | Left half | 1720px left half | Left half |
| **Hyper+U** | Left 2/3 | 2580px left | Left half |
| **Hyper+I** | Center focus | 1200px centered | Full screen |
| **Hyper+O** | Right 2/3 | 2580px right | Right half |
| **Hyper+P** | Right half | 1720px right half | Right half |

### Monitor Switching

| Shortcut | Action |
|----------|--------|
| **Hyper+←** | Move window to left display |
| **Hyper+→** | Move window to right display |

### Utilities

| Shortcut | Action |
|----------|--------|
| **Hyper+=** | Smart organize all windows |
| **Hyper+\\** | Minimize all windows (show desktop) |
| **Hyper+]** | Show all windows of current app (App Exposé) |
| **Hyper+R** | Reload Hammerspoon configuration |

## Layout System

### Ultrawide (3440x1440)

The ultrawide layout uses a **center-focused** approach:

```
┌──────────┬──────────────────────┬──────────┐
│   Left   │       Center         │  Right   │
│  860px   │       1720px         │  860px   │
└──────────┴──────────────────────┴──────────┘
```

- **Left/Right columns**: Perfect for terminals, file browsers, or reference windows
- **Center**: Main work area for editors, browsers
- **Center Focus** (Hyper+I): 1200px centered window for focused work

### MacBook Display

On non-ultrawide displays, layouts are simplified to **proportional halves**:

- h/y/u → Left 50%
- l/p/o → Right 50%
- j/k/i → Full 100%

### Smart Window Organizer (Hyper+=)

Automatically arranges windows based on count:

- **1 window**: Center position
- **2 windows**: Focused gets left 2/3, other gets right 1/3
- **3 windows**: Focused in center, others on sides
- **4+ windows**: Focused gets left 2/3, others stacked on right

Only affects windows on the currently focused display.

## Project Structure

```
~/.config/hammerspoon/
├── init.lua                 # Entry point
├── src/
│   ├── logger.lua           # Debug logging
│   ├── displays.lua         # Display detection
│   ├── layouts.lua          # Layout definitions
│   ├── window-manager.lua   # Core window logic
│   └── keybindings.lua      # Keyboard shortcuts
├── scripts/
│   ├── install.sh           # Setup script
│   ├── lint.sh              # Run linter
│   └── format.sh            # Format code
├── docs/
│   └── tracker/             # Project task tracking
├── .luacheckrc              # Linter config
├── stylua.toml              # Formatter config
├── .editorconfig            # Editor config
└── .gitignore               # Git ignore
```

## Development

### Code Quality

```bash
# Run linter
./scripts/lint.sh

# Format code
./scripts/format.sh
```

### Adding New Shortcuts

1. Add function to `src/window-manager.lua`
2. Add keybinding in `src/keybindings.lua`
3. Test and reload with **Hyper+R**

### Adding New Layouts

1. Add layout to `ULTRAWIDE_LAYOUTS` in `src/layouts.lua`
2. Add proportional mapping in `getProportionalLayout()`
3. Test on both display types

## Troubleshooting

### Shortcuts not working

1. Check Hammerspoon accessibility permissions:
   - System Settings → Privacy & Security → Accessibility
   - Ensure Hammerspoon is enabled
2. Verify Karabiner Hyper key mapping is active
3. Check logs: `tail -f ~/.config/hammerspoon/debug.log`
4. Reload config: **Hyper+R**

### Window positioning incorrect

1. Check detected displays: Look for "Detected N display(s)" in logs
2. Verify display resolution in logs
3. Ultrawide must be exactly 3440x1440 for fixed layouts
4. Other displays use proportional layouts automatically

### Configuration not loading

1. Check symlink exists: `ls -la ~/.hammerspoon`
2. Verify Hammerspoon is running: Check menu bar icon
3. Check for Lua syntax errors in logs
4. Restart Hammerspoon app

### Display changes not detected

The system watches for display changes automatically. If not working:

1. Check logs for "Display configuration changed"
2. Manually reload: **Hyper+R**
3. Restart Hammerspoon app

## Contributing

Contributions welcome! Please:

1. Run `./scripts/lint.sh` before committing
2. Run `./scripts/format.sh` to format code
3. Test on both single and dual display setups
4. Update README for new features

## License

MIT License - see LICENSE file for details

## Acknowledgments

- [Hammerspoon](https://www.hammerspoon.org/) - macOS automation framework
- [Karabiner-Elements](https://karabiner-elements.pqrs.org/) - Keyboard customization
- Inspired by various tiling window managers

## System Requirements

- **macOS**: 10.12 (Sierra) or later
- **Hammerspoon**: 1.0.0 or later
- **Display**: Works with any resolution, optimized for 3440x1440 ultrawide
- **Keyboard**: Requires Hyper key setup via Karabiner-Elements

---

Made with ❤️ for ultrawide productivity
