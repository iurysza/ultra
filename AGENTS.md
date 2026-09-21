# Agent map

ULTRA is a keyboard-driven macOS tiling window manager for ultrawide monitors. Hammerspoon runs the Lua in this repository. Caps Lock becomes Hyper through Karabiner-Elements: Shift, Cmd, Ctrl, and Opt.

## How it works

How-it-works docs belong in `ai-artifacts/` and must stay current when behavior or architecture changes.

Start here:

- product overview and keybindings: [README.md](README.md)
- Hammerspoon runtime: [src/](src/)
- agent knowledge index: [ai-artifacts/_index.md](ai-artifacts/_index.md)

Grow CONTEXT.md, architecture decision records, and architecture notes under `ai-artifacts/` when they are worth recording.

## Commands

Install Hammerspoon, luacheck, and stylua through Homebrew. Write `~/.hammerspoon/init.lua` so it loads `~/.config/ultra`:

```bash
./scripts/install.sh
```

Format Lua with StyLua. `stylua.toml` sets 2-space indent and a 100-column line:

```bash
./scripts/format.sh
```

Lint Lua with luacheck. `.luacheckrc` uses Lua 5.4 and treats `hs` as a global:

```bash
./scripts/lint.sh
```

Remove the Hammerspoon bootstrap and the `notify-claude` symlink:

```bash
./scripts/uninstall.sh
```

`scripts/notify-claude` is a tmux-aware notification CLI. `install.sh` links it to `~/.local/bin/notify-claude`.

LuaLS uses `.luarc.json` and `types/hs.lua`. `.editorconfig` matches the StyLua indent.

This repository has no GitHub Actions workflow. `./scripts/format.sh` and `./scripts/lint.sh` are the quality gate.

Reload the running config with Hyper+R. Follow logs with `tail -f ~/.config/ultra/debug.log`.

## Layout

`init.lua` is the Hammerspoon entry point after the bootstrap file loads this repo from `~/.config/ultra`.

`src/` holds these modules:

- `config.lua` loads `config.json` over `config.default.json`
- `keybindings.lua` binds Hyper hotkeys
- `layouts.lua` defines ultrawide pixel zones and proportional standard layouts
- `displays.lua` treats aspect ratio 2.3 or higher as ultrawide
- `window-manager.lua` positions, organizes, and splits windows
- `workspaces.lua` applies multi-app presets
- `app-launcher.lua` launches, focuses, or hides apps
- `environment.lua` picks work or personal apps from the hostname
- `app-specific-keys.lua` remaps keys inside some apps
- `notifications.lua` sends macOS alerts
- `logger.lua` writes `debug.log`

## Git commits

Never include Cursor (or any Cursor agent/bot) as git author, committer, or in a Co-authored-by / similar trailer.
