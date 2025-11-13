# Keybindings Configuration

## Objective
Map all keyboard shortcuts using Hammerspoon hotkey API.

## Subtasks
- [ ] Create `src/keybindings.lua`
- [ ] Define Hyper key (Shift+Cmd+Ctrl+Opt)
- [ ] Map window positioning shortcuts
  - [ ] Hyper+h → left
  - [ ] Hyper+j → center
  - [ ] Hyper+k → full
  - [ ] Hyper+l → right
  - [ ] Hyper+u → leftTwoThirds
  - [ ] Hyper+i → centerFocus
  - [ ] Hyper+o → rightTwoThirds
  - [ ] Hyper+y → leftHalf
  - [ ] Hyper+p → rightHalf
- [ ] Map monitor switching
  - [ ] Hyper+Left → move to left display
  - [ ] Hyper+Right → move to right display
- [ ] Map utilities
  - [ ] Hyper+= → organizeWindows
  - [ ] Hyper+\ → minimizeAll
  - [ ] Hyper+] → showAppWindows
- [ ] Document all shortcuts
- [ ] Test each shortcut works

## Status
Not Started

## Dependencies
- Window Manager Core Logic

## Related Files
- `src/keybindings.lua`

## Keybinding Pattern
All shortcuts use Hyper modifier (Caps Lock via Karabiner)
