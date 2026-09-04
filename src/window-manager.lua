--- Window Manager Core Logic
--- Implements core window positioning and manipulation functions
--- @module window-manager

local displays = require("src.displays")
local layouts = require("src.layouts")
local logger = require("src.logger")
local M = {}

-- Cycle state tracking (per display + window count)
local cycleState = {}

-- Keep one filter alive from startup so it learns windows as their Spaces are visited.
-- Hammerspoon cannot discover windows in unvisited Spaces immediately after reload.
local windowFilter = hs.window.filter
-- luacheck: ignore 122
windowFilter.forceRefreshOnSpaceChange = true
local allWindowsFilter = windowFilter.new(true)

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

--- Check whether a window is standard and can be repositioned
--- @param win hs.window Window object
--- @return boolean
local function isEligibleWindow(win)
  return win:isStandard() and not win:isMinimized()
end

--- Check whether a window is assigned to a Space
--- @param win hs.window Window object
--- @param targetSpace number Space ID
--- @return boolean
local function isWindowInSpace(win, targetSpace)
  local spaces, err = hs.spaces.windowSpaces(win)
  if not spaces then
    logger.warn(
      string.format(
        "splitAppWindows: could not get Spaces for '%s': %s",
        win:title(),
        err or "unknown error"
      )
    )
    return false
  end

  for _, space in ipairs(spaces) do
    if space == targetSpace then
      return true
    end
  end

  return false
end

--- Move the focused window to the first item in a list
--- @param windows hs.window[]
--- @param focusedWin hs.window
local function putFocusedWindowFirst(windows, focusedWin)
  for index, win in ipairs(windows) do
    if win == focusedWin then
      table.remove(windows, index)
      table.insert(windows, 1, win)
      return
    end
  end
end

--- Get standard, non-minimized windows of an app on one display and Space
--- @param appName string
--- @param screen hs.screen
--- @param targetSpace number
--- @return hs.window[]
local function getScopedAppWindows(appName, screen, targetSpace)
  local matchingWindows = {}

  for _, win in ipairs(hs.window.visibleWindows()) do
    local app = win:application()
    if
      isEligibleWindow(win)
      and app
      and app:name() == appName
      and win:screen() == screen
      and isWindowInSpace(win, targetSpace)
    then
      table.insert(matchingWindows, win)
    end
  end

  return matchingWindows
end

--- Get known standard, non-minimized windows of an app across displays and Spaces
--- @param appName string
--- @return hs.window[]
local function getAllAppWindows(appName)
  local matchingWindows = {}
  for _, win in ipairs(allWindowsFilter:getWindows()) do
    local app = win:application()
    if isEligibleWindow(win) and app and app:name() == appName then
      table.insert(matchingWindows, win)
    end
  end

  return matchingWindows
end

--- Gather windows on the target display and Space
--- @param windows hs.window[]
--- @param targetScreen hs.screen
--- @param targetSpace number
--- @return hs.window[] Windows confirmed on the target display and Space
--- @return number Number of windows that could not be gathered
local function gatherAppWindows(windows, targetScreen, targetSpace)
  local gatheredWindows = {}
  local failedGatherings = 0

  for _, win in ipairs(windows) do
    if win:screen() ~= targetScreen then
      win:moveToScreen(targetScreen)
    end

    local moveFailed = false
    if not isWindowInSpace(win, targetSpace) then
      local moved, err = hs.spaces.moveWindowToSpace(win, targetSpace)
      if not moved then
        moveFailed = true
        logger.error(
          string.format(
            "splitAppWindows: failed to move '%s' to Space %d: %s",
            win:title(),
            targetSpace,
            err or "unknown error"
          )
        )
      end
    end

    if win:screen() == targetScreen and isWindowInSpace(win, targetSpace) then
      table.insert(gatheredWindows, win)
    else
      failedGatherings = failedGatherings + 1
      if not moveFailed then
        logger.error(
          string.format(
            "splitAppWindows: '%s' did not arrive on the target display and Space",
            win:title()
          )
        )
      end
    end
  end

  return gatheredWindows, failedGatherings
end

--- Tile windows as equal-width columns on a display
--- @param windows hs.window[]
--- @param screen hs.screen
local function tileWindowsInColumns(windows, screen)
  for index, win in ipairs(windows) do
    local frame = layouts.getColumnFrame(screen, index, #windows)
    if frame then
      win:setFrame(frame)
    end
  end
end

--- Minimize visible standard windows that are not being split
--- @param splitWindows hs.window[]
--- @return number Number of windows minimized
local function minimizeOtherWindows(splitWindows)
  local splitWindowIds = {}
  for _, win in ipairs(splitWindows) do
    splitWindowIds[win:id()] = true
  end

  local minimizedCount = 0
  for _, win in ipairs(hs.window.visibleWindows()) do
    if isEligibleWindow(win) and not splitWindowIds[win:id()] then
      win:minimize()
      minimizedCount = minimizedCount + 1
    end
  end

  return minimizedCount
end

--- Split standard, non-minimized windows of the focused app and minimize all others
--- @param gatherAll boolean Whether to gather windows from every display and Space
function M.splitAppWindows(gatherAll)
  local focusedWin = hs.window.focusedWindow()
  if not focusedWin or not focusedWin:isStandard() then
    logger.warn("splitAppWindows: no focused standard window")
    hs.alert.show("No focused standard window")
    return
  end

  local app = focusedWin:application()
  local screen = displays.getCurrentDisplay(focusedWin)
  local targetSpace = hs.spaces.focusedSpace()
  local appName = app and app:name()
  if not appName or not screen or not targetSpace then
    logger.error("splitAppWindows: could not resolve app, display, or Space")
    hs.alert.show("Could not detect display or Space")
    return
  end

  local windows = gatherAll and getAllAppWindows(appName)
    or getScopedAppWindows(appName, screen, targetSpace)
  if #windows < 2 then
    logger.info("splitAppWindows: fewer than two eligible app windows")
    hs.alert.show("Need 2 app windows")
    return
  end

  putFocusedWindowFirst(windows, focusedWin)

  local failedGatherings = 0
  if gatherAll then
    local candidateCount = #windows
    windows, failedGatherings = gatherAppWindows(windows, screen, targetSpace)
    if #windows < 2 then
      logger.warn(
        string.format(
          "splitAppWindows: gathered %d of %d app windows; %d failed",
          #windows,
          candidateCount,
          failedGatherings
        )
      )
      hs.alert.show(
        string.format(
          "Only %d of %d app windows gathered; %d failed",
          #windows,
          candidateCount,
          failedGatherings
        )
      )
      return
    end
  end

  putFocusedWindowFirst(windows, focusedWin)
  tileWindowsInColumns(windows, screen)
  local minimizedCount = minimizeOtherWindows(windows)

  local mode = gatherAll and "gathered" or "scoped"
  logger.info(
    string.format(
      "Split %d %s app windows; minimized %d other windows",
      #windows,
      mode,
      minimizedCount
    )
  )
  if failedGatherings > 0 then
    hs.alert.show(
      string.format(
        "Split %d gathered windows; minimized %d others; %d failed",
        #windows,
        minimizedCount,
        failedGatherings
      )
    )
  else
    hs.alert.show(
      string.format("Split %d app windows; minimized %d others", #windows, minimizedCount)
    )
  end
end

--- Get cycle state key for current display + window count
--- @param screen hs.screen Screen object
--- @param count number Window count
--- @return string State key
local function getCycleKey(screen, count)
  return string.format("%s_%d", screen:name(), count)
end

--- Apply 2-window layout configuration
--- @param config number Config index (1-3)
--- @param focusedWin hs.window Focused window
--- @param otherWin hs.window Other window
--- @param screen hs.screen Screen object
local function apply2WindowLayout(config, focusedWin, otherWin, screen)
  local layoutNames = {
    { focused = "leftTwoThirds", other = "right" }, -- Focused left 2/3 + right 1/3
    { focused = "leftHalf", other = "rightHalf" }, -- Equal 50/50 split
    { focused = "rightTwoThirds", other = "left" }, -- Focused right 2/3 + left 1/3
  }

  local chosen = layoutNames[config]
  local focusedLayout = layouts.getLayout(chosen.focused, screen)
  local otherLayout = layouts.getLayout(chosen.other, screen)

  if focusedLayout and otherLayout then
    focusedWin:setFrame(focusedLayout)
    otherWin:setFrame(otherLayout)
  end
end

--- Apply 3-window layout configuration
--- @param config number Config index (1-4)
--- @param focusedWin hs.window Focused window
--- @param otherWins table Other windows
--- @param screen hs.screen Screen object
local function apply3WindowLayout(config, focusedWin, otherWins, screen)
  local frame = screen:frame()

  if config == 1 then
    -- Focused center + sides
    local leftLayout = layouts.getLayout("left", screen)
    local centerLayout = layouts.getLayout("center", screen)
    local rightLayout = layouts.getLayout("right", screen)

    if leftLayout and centerLayout and rightLayout then
      focusedWin:setFrame(centerLayout)
      otherWins[1]:setFrame(leftLayout)
      otherWins[2]:setFrame(rightLayout)
    end
  elseif config == 2 then
    -- Focused left 2/3 + 2 stacked right
    local leftLayout = layouts.getLayout("leftTwoThirds", screen)
    if leftLayout then
      focusedWin:setFrame(leftLayout)

      local rightWidth = 860
      local stackHeight = frame.h / 2

      otherWins[1]:setFrame({
        x = frame.x + frame.w - rightWidth,
        y = frame.y,
        w = rightWidth,
        h = stackHeight,
      })
      otherWins[2]:setFrame({
        x = frame.x + frame.w - rightWidth,
        y = frame.y + stackHeight,
        w = rightWidth,
        h = stackHeight,
      })
    end
  elseif config == 3 then
    -- All equal thirds
    local leftLayout = layouts.getLayout("left", screen)
    local centerLayout = layouts.getLayout("center", screen)
    local rightLayout = layouts.getLayout("right", screen)

    if leftLayout and centerLayout and rightLayout then
      focusedWin:setFrame(centerLayout)
      otherWins[1]:setFrame(leftLayout)
      otherWins[2]:setFrame(rightLayout)
    end
  elseif config == 4 then
    -- Focused right 2/3 + 2 stacked left
    local rightLayout = layouts.getLayout("rightTwoThirds", screen)
    if rightLayout then
      focusedWin:setFrame(rightLayout)

      local leftWidth = 860
      local stackHeight = frame.h / 2

      otherWins[1]:setFrame({
        x = frame.x,
        y = frame.y,
        w = leftWidth,
        h = stackHeight,
      })
      otherWins[2]:setFrame({
        x = frame.x,
        y = frame.y + stackHeight,
        w = leftWidth,
        h = stackHeight,
      })
    end
  end
end

--- Apply 4+ window layout configuration
--- @param config number Config index (1-4)
--- @param focusedWin hs.window Focused window
--- @param otherWins table Other windows (first is second window, rest are stacked)
--- @param screen hs.screen Screen object
local function apply4PlusWindowLayout(config, focusedWin, otherWins, screen)
  local frame = screen:frame()
  local secondWin = otherWins[1]
  local restWins = {}

  -- Collect remaining windows (3rd, 4th, 5th...)
  for i = 2, #otherWins do
    table.insert(restWins, otherWins[i])
  end

  if config == 1 then
    -- Focused left 2/3 | second right top | rest right bottom (stacked)
    local leftLayout = layouts.getLayout("leftTwoThirds", screen)
    if leftLayout then
      focusedWin:setFrame(leftLayout)

      local rightWidth = 860
      local rightTopHeight = frame.h / 2
      local stackHeight = frame.h / 2 / #restWins

      -- Second window on right top
      secondWin:setFrame({
        x = frame.x + frame.w - rightWidth,
        y = frame.y,
        w = rightWidth,
        h = rightTopHeight,
      })

      -- Rest stacked on right bottom
      for i, win in ipairs(restWins) do
        local y = frame.y + rightTopHeight + ((i - 1) * stackHeight)
        win:setFrame({
          x = frame.x + frame.w - rightWidth,
          y = y,
          w = rightWidth,
          h = stackHeight,
        })
      end
    end
  elseif config == 2 then
    -- Focused center | second left | rest right (stacked)
    local centerLayout = layouts.getLayout("center", screen)
    local leftLayout = layouts.getLayout("left", screen)
    if centerLayout and leftLayout then
      focusedWin:setFrame(centerLayout)
      secondWin:setFrame(leftLayout)

      -- Rest stacked on right
      local rightWidth = 860
      local stackHeight = frame.h / #restWins

      for i, win in ipairs(restWins) do
        local y = frame.y + ((i - 1) * stackHeight)
        win:setFrame({
          x = frame.x + frame.w - rightWidth,
          y = y,
          w = rightWidth,
          h = stackHeight,
        })
      end
    end
  elseif config == 3 then
    -- Focused center | second right | rest left (stacked)
    local centerLayout = layouts.getLayout("center", screen)
    local rightLayout = layouts.getLayout("right", screen)
    if centerLayout and rightLayout then
      focusedWin:setFrame(centerLayout)
      secondWin:setFrame(rightLayout)

      -- Rest stacked on left
      local leftWidth = 860
      local stackHeight = frame.h / #restWins

      for i, win in ipairs(restWins) do
        local y = frame.y + ((i - 1) * stackHeight)
        win:setFrame({
          x = frame.x,
          y = y,
          w = leftWidth,
          h = stackHeight,
        })
      end
    end
  elseif config == 4 then
    -- Focused right 2/3 | second left top | rest left bottom (stacked)
    local rightLayout = layouts.getLayout("rightTwoThirds", screen)
    if rightLayout then
      focusedWin:setFrame(rightLayout)

      local leftWidth = 860
      local leftTopHeight = frame.h / 2
      local stackHeight = frame.h / 2 / #restWins

      -- Second window on left top
      secondWin:setFrame({
        x = frame.x,
        y = frame.y,
        w = leftWidth,
        h = leftTopHeight,
      })

      -- Rest stacked on left bottom
      for i, win in ipairs(restWins) do
        local y = frame.y + leftTopHeight + ((i - 1) * stackHeight)
        win:setFrame({
          x = frame.x,
          y = y,
          w = leftWidth,
          h = stackHeight,
        })
      end
    end
  end
end

--- Smart organize all windows on focused display (with cycling)
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

  -- Get cycle state key
  local stateKey = getCycleKey(screen, count)

  -- Get other windows (non-focused)
  local otherWins = {}
  for _, win in ipairs(windowsOnScreen) do
    if win ~= focusedWin then
      table.insert(otherWins, win)
    end
  end

  if count == 1 then
    -- 1 window: full screen (no cycling)
    local layout = layouts.getLayout("full", screen)
    if layout then
      focusedWin:setFrame(layout)
      logger.info("1 window: Applied full screen")
      hs.alert.show("Full screen")
    end
  elseif count == 2 then
    -- 2 windows: cycle through 3 configs
    cycleState[stateKey] = (cycleState[stateKey] or 0) + 1
    if cycleState[stateKey] > 3 then
      cycleState[stateKey] = 1
    end

    apply2WindowLayout(cycleState[stateKey], focusedWin, otherWins[1], screen)

    local configNames = {
      "Focused 2/3 left",
      "Equal 50/50",
      "Focused 2/3 right",
    }
    logger.info(
      string.format(
        "2 windows: Applied config %d/%d: %s",
        cycleState[stateKey],
        3,
        configNames[cycleState[stateKey]]
      )
    )
    hs.alert.show(configNames[cycleState[stateKey]])
  elseif count == 3 then
    -- 3 windows: cycle through 4 configs
    cycleState[stateKey] = (cycleState[stateKey] or 0) + 1
    if cycleState[stateKey] > 4 then
      cycleState[stateKey] = 1
    end

    apply3WindowLayout(cycleState[stateKey], focusedWin, otherWins, screen)

    local configNames = {
      "Focused center + sides",
      "Focused 2/3 left + stack",
      "All equal thirds",
      "Focused 2/3 right + stack",
    }
    logger.info(
      string.format(
        "3 windows: Applied config %d/%d: %s",
        cycleState[stateKey],
        4,
        configNames[cycleState[stateKey]]
      )
    )
    hs.alert.show(configNames[cycleState[stateKey]])
  else
    -- 4+ windows: cycle through 4 configs
    cycleState[stateKey] = (cycleState[stateKey] or 0) + 1
    if cycleState[stateKey] > 4 then
      cycleState[stateKey] = 1
    end

    apply4PlusWindowLayout(cycleState[stateKey], focusedWin, otherWins, screen)

    local configNames = {
      "Focused 2/3 left + stack right",
      "Focused center + stack right",
      "Focused center + stack left",
      "Focused 2/3 right + stack left",
    }
    logger.info(
      string.format(
        "%d windows: Applied config %d/%d: %s",
        count,
        cycleState[stateKey],
        4,
        configNames[cycleState[stateKey]]
      )
    )
    hs.alert.show(configNames[cycleState[stateKey]])
  end
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

--- Focus mode: minimize all except focused, center it at 80% height
function M.focusMode()
  local focusedWin = hs.window.focusedWindow()
  if not focusedWin then
    hs.alert.show("No focused window")
    return
  end

  -- Minimize all other windows
  local windows = hs.window.visibleWindows()
  local minimizedCount = 0
  for _, win in ipairs(windows) do
    if win:isStandard() and win:id() ~= focusedWin:id() then
      win:minimize()
      minimizedCount = minimizedCount + 1
    end
  end

  -- Position focused window: 80% height, 1.25 width ratio, centered
  local screen = focusedWin:screen()
  local frame = screen:frame()

  local h = frame.h * 0.80
  local w = h * 1.25
  if w > frame.w then w = frame.w end

  local x = frame.x + (frame.w - w) / 2
  local y = frame.y + (frame.h - h) / 2

  focusedWin:setFrame({ x = x, y = y, w = w, h = h })

  logger.info(string.format("Focus mode: minimized %d windows", minimizedCount))
  hs.alert.show("Focus")
end

--- Show App Exposé for current app (native macOS)
function M.showAppWindows()
  logger.info("Triggering native App Exposé")
  hs.spaces.toggleAppExpose()
end

return M
