--- Display Detection Module
--- Detects and classifies displays for adaptive layout system
--- @module displays

local logger = require("src.logger")
local M = {}

-- Ultrawide detection threshold
-- 21:9 aspect ratio ≈ 2.33
-- We use 2.3 to allow some tolerance and catch various ultrawide formats
-- Standard displays: 16:9 (1.78), 16:10 (1.6)
-- Ultrawide displays: 21:9 (2.33), 32:9 (3.56)
local ULTRAWIDE_ASPECT_THRESHOLD = 2.3

--- Get all displays with metadata
--- @return table Array of screens with metadata
function M.getAllDisplays()
  logger.debug("Getting all displays")
  local screens = hs.screen.allScreens()
  local displays = {}

  for i, screen in ipairs(screens) do
    local mode = screen:currentMode()
    local frame = screen:frame()
    local name = screen:name()

    local display = {
      screen = screen,
      name = name,
      width = mode.w,
      height = mode.h,
      frame = frame,
      isUltrawide = M.isUltrawide(screen),
    }

    table.insert(displays, display)
    logger.debug(
      string.format(
        "Display %d: %s (%dx%d) ultrawide=%s",
        i,
        name,
        mode.w,
        mode.h,
        tostring(display.isUltrawide)
      )
    )
  end

  return displays
end

--- Check if screen is ultrawide (aspect ratio >= 2.3)
--- @param screen hs.screen Screen object
--- @return boolean True if ultrawide
function M.isUltrawide(screen)
  if not screen then
    return false
  end

  local mode = screen:currentMode()
  local aspectRatio = mode.w / mode.h

  logger.debug(
    string.format(
      "Display aspect ratio check: %s (%dx%d) = %.2f",
      screen:name(),
      mode.w,
      mode.h,
      aspectRatio
    )
  )

  return aspectRatio >= ULTRAWIDE_ASPECT_THRESHOLD
end

--- Get display containing the given window
--- @param window hs.window Window object
--- @return hs.screen|nil Screen object or nil
function M.getCurrentDisplay(window)
  if not window then
    logger.warn("getCurrentDisplay: window is nil")
    return nil
  end

  local screen = window:screen()
  if screen then
    local mode = screen:currentMode()
    logger.debug(string.format("Current display: %s (%dx%d)", screen:name(), mode.w, mode.h))
  else
    logger.warn("getCurrentDisplay: no screen found for window")
  end

  return screen
end

--- Get display frame (bounds)
--- @param screen hs.screen Screen object
--- @return table|nil Frame {x, y, w, h} or nil
function M.getDisplayFrame(screen)
  if not screen then
    logger.warn("getDisplayFrame: screen is nil")
    return nil
  end

  local frame = screen:frame()
  logger.debug(
    string.format("Display frame: x=%d y=%d w=%d h=%d", frame.x, frame.y, frame.w, frame.h)
  )

  return frame
end

--- Find display by position (left/right relative to current)
--- @param direction string "left" or "right"
--- @param currentScreen hs.screen Current screen (optional, uses focused window's screen)
--- @return hs.screen|nil Screen in the specified direction or nil
function M.findDisplayByPosition(direction, currentScreen)
  currentScreen = currentScreen or hs.window.focusedWindow():screen()

  if not currentScreen then
    logger.warn("findDisplayByPosition: no current screen")
    return nil
  end

  local targetScreen
  if direction == "left" then
    -- Try west, then north, then previous (cycle fallback)
    targetScreen = currentScreen:toWest() or currentScreen:toNorth() or currentScreen:previous()
  elseif direction == "right" then
    -- Try east, then south, then next (cycle fallback)
    targetScreen = currentScreen:toEast() or currentScreen:toSouth() or currentScreen:next()
  else
    logger.error(string.format("findDisplayByPosition: invalid direction '%s'", direction))
    return nil
  end

  if targetScreen then
    logger.info(
      string.format(
        "Found display %s of %s: %s",
        direction,
        currentScreen:name(),
        targetScreen:name()
      )
    )
  else
    logger.warn(string.format("No display found %s of %s", direction, currentScreen:name()))
  end

  return targetScreen
end

--- Get primary display
--- @return hs.screen Primary screen
function M.getPrimaryDisplay()
  return hs.screen.primaryScreen()
end

return M
