--- Window Manager Core Logic
--- Implements core window positioning and manipulation functions
--- @module window-manager

local displays = require("src.displays")
local layouts = require("src.layouts")
local logger = require("src.logger")
local M = {}

--- Position focused window to specified layout
--- @param position string Layout position name
function M.positionWindow(position)
  local win = hs.window.focusedWindow()
  if not win then
    logger.warn("positionWindow: no focused window")
    hs.alert.show("No focused window")
    return
  end

  local screen = displays.getCurrentDisplay(win)
  if not screen then
    logger.error("positionWindow: could not get current display")
    hs.alert.show("Error: could not detect display")
    return
  end

  local layout = layouts.getLayout(position, screen)
  if not layout then
    logger.error(string.format("positionWindow: invalid layout '%s'", position))
    hs.alert.show("Error: invalid layout")
    return
  end

  logger.info(string.format("Positioning '%s' to %s on %s", win:title(), position, screen:name()))

  win:setFrame(layout)
end

--- Move focused window to display in specified direction
--- @param direction string "left" or "right"
function M.moveToDisplay(direction)
  local win = hs.window.focusedWindow()
  if not win then
    logger.warn("moveToDisplay: no focused window")
    hs.alert.show("No focused window")
    return
  end

  local currentScreen = displays.getCurrentDisplay(win)
  if not currentScreen then
    logger.error("moveToDisplay: could not get current display")
    return
  end

  local targetScreen = displays.findDisplayByPosition(direction, currentScreen)
  if not targetScreen then
    logger.warn(string.format("moveToDisplay: no display found %s", direction))
    hs.alert.show(string.format("No display %s", direction))
    return
  end

  logger.info(
    string.format(
      "Moving '%s' from %s to %s",
      win:title(),
      currentScreen:name(),
      targetScreen:name()
    )
  )

  win:moveToScreen(targetScreen)

  -- Maximize on new screen
  local frame = targetScreen:frame()
  win:setFrame(frame)
end

--- Smart organize all windows on focused display
function M.organizeWindows()
  local focusedWin = hs.window.focusedWindow()
  if not focusedWin then
    logger.warn("organizeWindows: no focused window")
    hs.alert.show("No focused window")
    return
  end

  local screen = displays.getCurrentDisplay(focusedWin)
  if not screen then
    logger.error("organizeWindows: could not get focused display")
    return
  end

  -- Get all visible windows on focused display
  local allWindows = hs.window.visibleWindows()
  local windowsOnScreen = {}

  for _, win in ipairs(allWindows) do
    if win:screen() == screen and win:isStandard() then
      table.insert(windowsOnScreen, win)
    end
  end

  local count = #windowsOnScreen
  logger.info(string.format("Organizing %d windows on %s", count, screen:name()))

  if count == 0 then
    hs.alert.show("No windows to organize")
    return
  end

  -- Find focused window in list
  local focusedIndex = 1
  for i, win in ipairs(windowsOnScreen) do
    if win == focusedWin then
      focusedIndex = i
      break
    end
  end

  if count == 1 then
    -- 1 window: center position
    local layout = layouts.getLayout("center", screen)
    if layout then
      windowsOnScreen[1]:setFrame(layout)
    end
  elseif count == 2 then
    -- 2 windows: focused left 2/3, other right 1/3
    local leftLayout = layouts.getLayout("leftTwoThirds", screen)
    local rightLayout = layouts.getLayout("right", screen)

    if leftLayout and rightLayout then
      focusedWin:setFrame(leftLayout)

      for i, win in ipairs(windowsOnScreen) do
        if i ~= focusedIndex then
          win:setFrame(rightLayout)
          break
        end
      end
    end
  elseif count == 3 then
    -- 3 windows: focused center, others on sides
    local leftLayout = layouts.getLayout("left", screen)
    local centerLayout = layouts.getLayout("center", screen)
    local rightLayout = layouts.getLayout("right", screen)

    if leftLayout and centerLayout and rightLayout then
      focusedWin:setFrame(centerLayout)

      local sideIndex = 1
      for i, win in ipairs(windowsOnScreen) do
        if i ~= focusedIndex then
          if sideIndex == 1 then
            win:setFrame(leftLayout)
          else
            win:setFrame(rightLayout)
          end
          sideIndex = sideIndex + 1
        end
      end
    end
  else
    -- 4+ windows: focused left 2/3, others stacked right
    local leftLayout = layouts.getLayout("leftTwoThirds", screen)
    local rightLayout = layouts.getLayout("right", screen)

    if leftLayout and rightLayout then
      focusedWin:setFrame(leftLayout)

      -- Stack others on right
      local frame = screen:frame()
      local rightWidth = 860
      local stackHeight = frame.h / (count - 1)

      local stackIndex = 0
      for i, win in ipairs(windowsOnScreen) do
        if i ~= focusedIndex then
          local y = frame.y + (stackIndex * stackHeight)
          win:setFrame({
            x = frame.x + frame.w - rightWidth,
            y = y,
            w = rightWidth,
            h = stackHeight,
          })
          stackIndex = stackIndex + 1
        end
      end
    end
  end

  hs.alert.show(string.format("Organized %d windows", count))
end

--- Minimize all windows (show desktop)
function M.minimizeAll()
  local windows = hs.window.visibleWindows()
  local count = 0

  for _, win in ipairs(windows) do
    if win:isStandard() then
      win:minimize()
      count = count + 1
    end
  end

  logger.info(string.format("Minimized %d windows", count))
  hs.alert.show(string.format("Minimized %d windows", count))
end

--- Show App Exposé for current app
function M.showAppWindows()
  local focusedWin = hs.window.focusedWindow()
  if not focusedWin then
    logger.warn("showAppWindows: no focused window")
    return
  end

  local app = focusedWin:application()
  if not app then
    logger.warn("showAppWindows: no application found")
    return
  end

  logger.info(string.format("Showing windows for %s", app:name()))

  -- Use Hammerspoon's expose module for app windows
  local expose = hs.expose.new()
  expose:toggleShow({ onlyActiveApplication = true })
end

return M
