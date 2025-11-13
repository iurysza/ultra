# Testing Multi-Display Scenarios

## Objective
Verify all functionality works correctly in single and dual display setups.

## Test Scenarios

### Single Display (Ultrawide Only)
- [ ] Test all positioning shortcuts (h/j/k/l/u/i/o/y/p)
- [ ] Verify 860/1720/860 layout system
- [ ] Test centerFocus (1200px)
- [ ] Test smart organizer with 1 window
- [ ] Test smart organizer with 2 windows
- [ ] Test smart organizer with 3 windows
- [ ] Test smart organizer with 4+ windows
- [ ] Test minimize all
- [ ] Test App Exposé
- [ ] Verify debug logging

### Dual Display (Ultrawide + MacBook)
- [ ] Window on ultrawide → verify fixed pixel layouts
- [ ] Window on MacBook → verify proportional layouts
- [ ] Test monitor switching (Hyper+Left)
- [ ] Test monitor switching (Hyper+Right)
- [ ] Smart organizer only affects focused display
- [ ] Minimize all works across both displays
- [ ] Test switching focused display
- [ ] Verify correct display detection

### Edge Cases
- [ ] No windows open
- [ ] Window partially off-screen
- [ ] More than 2 displays
- [ ] Display arrangement changes
- [ ] Hammerspoon reload with windows open
- [ ] App without windows
- [ ] Minimized windows

## Debug Approach
- [ ] Enable debug logging
- [ ] Tail log: `tail -f ~/.config/hammerspoon/debug.log`
- [ ] Verify each action is logged
- [ ] Check display detection output

## Status
Not Started

## Dependencies
- All modules completed
- Keybindings configured

## Related Files
- `debug.log`
