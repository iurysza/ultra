# Display Detection Module

## Objective
Detect and classify displays (ultrawide vs MacBook) for adaptive layout system.

## Subtasks
- [ ] Create `src/displays.lua`
- [ ] Implement `getAllDisplays()` - get all screens with metadata
- [ ] Implement `isUltrawide(screen)` - check if 3440x1440
- [ ] Implement `getCurrentDisplay(window)` - get window's screen
- [ ] Implement `getDisplayFrame(screen)` - get bounds {x,y,w,h}
- [ ] Implement `findDisplayByPosition(direction)` - get left/right display
- [ ] Add fallback for detection failures
- [ ] Document all functions
- [ ] Test with single and dual displays

## Status
Not Started

## Dependencies
- Logger Module (for debug output)

## Related Files
- `src/displays.lua`

## API Design
```lua
local displays = require("src.displays")
local allScreens = displays.getAllDisplays()
local isWide = displays.isUltrawide(screen)
local currentScreen = displays.getCurrentDisplay(window)
local frame = displays.getDisplayFrame(screen)
local leftScreen = displays.findDisplayByPosition("left")
```
