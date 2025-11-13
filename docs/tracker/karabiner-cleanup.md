# Karabiner Configuration Cleanup

## Objective
Remove window management shortcuts from Karabiner, keep only essential remaps.

## Subtasks
- [ ] Backup current `karabiner.json`
- [ ] Remove window positioning shortcuts (h/j/k/l/u/i/o/y/p)
- [ ] Remove smart organizer shortcut (=)
- [ ] Remove minimize all shortcut (\)
- [ ] Remove App Exposé shortcut (])
- [ ] Remove monitor switching shortcuts (arrows)
- [ ] Keep Hyper key mapping (Caps Lock)
- [ ] Keep app launchers (F2-F12)
- [ ] Keep media controls (F1)
- [ ] Keep Obsidian remaps
- [ ] Keep Fn ↔ Ctrl swap
- [ ] Delete `scripts/organize-windows.scpt`
- [ ] Delete `scripts/pip-window.scpt`
- [ ] Test remaining shortcuts work
- [ ] Commit cleanup changes

## Status
Not Started

## Dependencies
- Keybindings (need Hammerspoon working first)

## Related Files
- `~/.config/karabiner/karabiner.json`
- `~/.config/karabiner/scripts/organize-windows.scpt` (DELETE)
- `~/.config/karabiner/scripts/pip-window.scpt` (DELETE)

## What to Keep
- Hyper key (Caps Lock → Shift+Cmd+Ctrl+Opt)
- App launchers
- Media controls
- Obsidian-specific remaps
- System key swaps
