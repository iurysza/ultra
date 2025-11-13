# Logger Module

## Objective
Implement debug logging system for troubleshooting and development.

## Subtasks
- [ ] Create `src/logger.lua`
- [ ] Implement log levels (DEBUG, INFO, WARN, ERROR)
- [ ] Add timestamp formatting
- [ ] Write to `~/.config/hammerspoon/debug.log`
- [ ] Implement log rotation (keep last 100 lines)
- [ ] Add configurable enable/disable flag
- [ ] Document logger API
- [ ] Test all log levels

## Status
Not Started

## Dependencies
- Setup Infrastructure

## Related Files
- `src/logger.lua`
- `debug.log` (generated at runtime)

## API Design
```lua
local logger = require("src.logger")
logger.init({enabled = true, maxLines = 100})
logger.debug("message")
logger.info("message")
logger.warn("message")
logger.error("message")
```
