--- Layout Definitions Module
--- Defines window layouts for ultrawide and MacBook displays
--- @module layouts

local displays = require("src.displays")
local logger = require("src.logger")
local M = {}

-- Ultrawide layout constants (3440x1440)
-- System: 860px + 1720px + 860px = 3440px
local ULTRAWIDE_LAYOUTS = {
  left = { x = 0, y = 0, w = 860, h = 1440 },
  center = { x = 860, y = 0, w = 1720, h = 1440 },
  right = { x = 2580, y = 0, w = 860, h = 1440 },
  full = { x = 0, y = 0, w = 3440, h = 1440 },
  leftTwoThirds = { x = 0, y = 0, w = 2580, h = 1440 },
  rightTwoThirds = { x = 860, y = 0, w = 2580, h = 1440 },
  leftHalf = { x = 0, y = 0, w = 1720, h = 1440 },
  rightHalf = { x = 1720, y = 0, w = 1720, h = 1440 },
  centerFocus = { x = 1120, y = 0, w = 1200, h = 1440 },
}

--- Get layout for position on given screen
--- @param position string Layout position name
--- @param screen hs.screen Screen object
--- @return table|nil Layout {x, y, w, h} or nil
function M.getLayout(position, screen)
  if not screen then
    logger.error("getLayout: screen is nil")
    return nil
  end

  local frame = screen:frame()
  local isUltrawide = displays.isUltrawide(screen)

  logger.debug(
    string.format(
      "Getting layout '%s' for %s (ultrawide=%s)",
      position,
      screen:name(),
      tostring(isUltrawide)
    )
  )

  if isUltrawide then
    -- Use fixed pixel layouts for ultrawide
    local layout = ULTRAWIDE_LAYOUTS[position]
    if not layout then
      logger.warn(string.format("Unknown ultrawide layout: %s", position))
      return nil
    end
    return {
      x = frame.x + layout.x,
      y = frame.y + layout.y,
      w = layout.w,
      h = layout.h,
    }
  else
    -- Use proportional layouts for MacBook/other displays
    return M.getProportionalLayout(position, frame)
  end
end

--- Get proportional layout for non-ultrawide displays
--- @param position string Layout position name
--- @param frame table Display frame {x, y, w, h}
--- @return table|nil Layout {x, y, w, h} or nil
function M.getProportionalLayout(position, frame)
  -- Mapping for MacBook: simplified to left/right halves
  -- h, y, u -> left half
  -- l, p, o -> right half
  -- j -> center (same as full for MacBook)
  -- k -> full

  local halfW = frame.w / 2

  local layouts = {
    -- Left half group
    left = { x = frame.x, y = frame.y, w = halfW, h = frame.h },
    leftHalf = { x = frame.x, y = frame.y, w = halfW, h = frame.h },
    leftTwoThirds = { x = frame.x, y = frame.y, w = halfW, h = frame.h },

    -- Right half group
    right = { x = frame.x + halfW, y = frame.y, w = halfW, h = frame.h },
    rightHalf = { x = frame.x + halfW, y = frame.y, w = halfW, h = frame.h },
    rightTwoThirds = { x = frame.x + halfW, y = frame.y, w = halfW, h = frame.h },

    -- Center and full
    center = { x = frame.x, y = frame.y, w = frame.w, h = frame.h },
    centerFocus = { x = frame.x, y = frame.y, w = frame.w, h = frame.h },
    full = { x = frame.x, y = frame.y, w = frame.w, h = frame.h },
  }

  local layout = layouts[position]
  if not layout then
    logger.warn(string.format("Unknown proportional layout: %s, defaulting to full", position))
    return { x = frame.x, y = frame.y, w = frame.w, h = frame.h }
  end

  return layout
end

--- Get all available layout names for a screen
--- @param screen hs.screen Screen object
--- @return table Array of layout names
function M.getAvailableLayouts(screen)
  if displays.isUltrawide(screen) then
    local layouts = {}
    for name, _ in pairs(ULTRAWIDE_LAYOUTS) do
      table.insert(layouts, name)
    end
    return layouts
  else
    return {
      "left",
      "right",
      "center",
      "full",
      "leftHalf",
      "rightHalf",
      "leftTwoThirds",
      "rightTwoThirds",
      "centerFocus",
    }
  end
end

return M
