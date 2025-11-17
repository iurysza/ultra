--- Window Manager Core Logic
--- Implements core window positioning and manipulation functions
--- @module window-manager

local displays = require("src.displays")
local layouts = require("src.layouts")
local logger = require("src.logger")
local M = {}

-- Cycle state tracking (per display + window count)
local cycleState = {}

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
