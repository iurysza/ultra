# Layout Definitions Module

## Objective
Define window layouts for ultrawide and MacBook displays.

## Subtasks
- [ ] Create `src/layouts.lua`
- [ ] Define ultrawide layouts (860/1720/860 system)
  - [ ] left (860px)
  - [ ] center (1720px)
  - [ ] right (860px)
  - [ ] full (3440px)
  - [ ] leftTwoThirds (2580px)
  - [ ] rightTwoThirds (2580px)
  - [ ] leftHalf (1720px)
  - [ ] rightHalf (1720px)
  - [ ] centerFocus (1200px centered)
- [ ] Define MacBook proportional layouts
  - [ ] left (50%)
  - [ ] right (50%)
  - [ ] full (100%)
- [ ] Implement layout selection logic
- [ ] Document layout coordinate system
- [ ] Test layouts with both display types

## Status
Not Started

## Dependencies
- Display Detection Module

## Related Files
- `src/layouts.lua`

## Layout System
Ultrawide: Fixed pixel positions based on 860+1720+860
MacBook: Proportional (50% left/right, 100% full)
