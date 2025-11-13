# Window Manager Core Logic

## Objective
Implement core window positioning and manipulation functions.

## Subtasks
- [ ] Create `src/window-manager.lua`
- [ ] Implement `positionWindow(position)` - move window to layout
- [ ] Implement `moveToDisplay(direction)` - move window between monitors
- [ ] Implement `organizeWindows()` - smart multi-window layout
  - [ ] 1 window: center position
  - [ ] 2 windows: focused left 2/3, other right 1/3
  - [ ] 3 windows: focused center with sidebars
  - [ ] 4+ windows: focused left 2/3, others stacked right
- [ ] Implement `minimizeAll()` - show desktop
- [ ] Implement `showAppWindows()` - App Exposé
- [ ] Add error handling for edge cases
- [ ] Log all window operations
- [ ] Document all functions
- [ ] Test each function thoroughly

## Status
Not Started

## Dependencies
- Logger Module
- Display Detection Module
- Layout Definitions Module

## Related Files
- `src/window-manager.lua`

## Core Logic Flow
1. Get focused window
2. Detect current display
3. Get appropriate layout
4. Apply position
5. Log action
