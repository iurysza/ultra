--- Keybindings Configuration
--- Maps all keyboard shortcuts using Hammerspoon hotkey API
--- @module keybindings

local wm = require("src.window-manager")
local logger = require("src.logger")
local appLauncher = require("src.app-launcher")
local workspaces = require("src.workspaces")
local environment = require("src.environment")
local M = {}

-- Hyper key: Shift+Cmd+Ctrl+Opt (mapped via Karabiner from Caps Lock)
local hyper = { "shift", "cmd", "ctrl", "alt" }

--- Get config (from global or fallback)
local function getConfig()
  return _G.ultraConfig or {}
end

--- Setup app launcher keybindings from config
local function setupLaunchers()
  local cfg = getConfig()
  local launchers = cfg.launchers or {}

  for _, launcher in ipairs(launchers) do
    local key = launcher.key
    local name = launcher.name or key

    if launcher.action == "playPause" then
      -- Special action: play/pause
      hs.hotkey.bind(hyper, key, function()
        logger.debug("Keybinding: Hyper+" .. key .. " (Play/Pause)")
        appLauncher.togglePlayPause()
      end)
    elseif launcher.appleScript then
      -- AppleScript action
      hs.hotkey.bind(hyper, key, function()
        logger.debug("Keybinding: Hyper+" .. key .. " (" .. name .. ")")
        appLauncher.executeAppleScript(launcher.appleScript)
      end)
    elseif launcher.appRef then
      -- Environment-aware app reference
      hs.hotkey.bind(hyper, key, function()
        local bundleID = environment.resolveApp(launcher.appRef)
        logger.debug("Keybinding: Hyper+" .. key .. " (" .. name .. ": " .. bundleID .. ")")
        appLauncher.toggleApp(bundleID)
      end)
    elseif launcher.app then
      -- Direct bundle ID
      hs.hotkey.bind(hyper, key, function()
        logger.debug("Keybinding: Hyper+" .. key .. " (" .. name .. ")")
        appLauncher.toggleApp(launcher.app)
      end)
    elseif launcher.appName then
      -- App by name (for apps without stable bundle IDs)
      hs.hotkey.bind(hyper, key, function()
        logger.debug("Keybinding: Hyper+" .. key .. " (" .. name .. ")")
        appLauncher.toggleAppByName(launcher.appName)
      end)
    end

    logger.debug("Registered launcher: Hyper+" .. key .. " -> " .. name)
  end
end

--- Setup all keybindings
function M.setup()
  logger.info("Setting up keybindings")

  -- Window positioning shortcuts
  -- LEFT-ALIGNED POSITIONS
  hs.hotkey.bind(hyper, "y", function()
    logger.debug("Keybinding: Hyper+y (left - small left side)")
    wm.positionWindow("left")
  end)

  hs.hotkey.bind(hyper, "h", function()
    logger.debug("Keybinding: Hyper+h (leftHalf)")
    wm.positionWindow("leftHalf")
  end)

  hs.hotkey.bind(hyper, "j", function()
    logger.debug("Keybinding: Hyper+j (leftTwoThirds)")
    wm.positionWindow("leftTwoThirds")
  end)

  -- CENTER-ALIGNED POSITIONS
  hs.hotkey.bind(hyper, "u", function()
    logger.debug("Keybinding: Hyper+u (centerFocus - small center)")
    wm.positionWindow("centerFocus")
  end)

  hs.hotkey.bind(hyper, "i", function()
    logger.debug("Keybinding: Hyper+i (center - large center split)")
    wm.positionWindow("center")
  end)

  hs.hotkey.bind(hyper, "o", function()
    logger.debug("Keybinding: Hyper+o (full - whole screen)")
    wm.positionWindow("full")
  end)

  -- RIGHT-ALIGNED POSITIONS
  hs.hotkey.bind(hyper, "p", function()
    logger.debug("Keybinding: Hyper+p (right - small right side)")
    wm.positionWindow("right")
  end)

  hs.hotkey.bind(hyper, "l", function()
    logger.debug("Keybinding: Hyper+l (rightHalf)")
    wm.positionWindow("rightHalf")
  end)

  hs.hotkey.bind(hyper, "k", function()
    logger.debug("Keybinding: Hyper+k (rightTwoThirds)")
    wm.positionWindow("rightTwoThirds")
  end)

  -- Monitor switching
  hs.hotkey.bind(hyper, "[", function()
    logger.debug("Keybinding: Hyper+[ (move to left display)")
    wm.moveToDisplay("left")
  end)

  hs.hotkey.bind(hyper, "]", function()
    logger.debug("Keybinding: Hyper+] (move to right display)")
    wm.moveToDisplay("right")
  end)

  -- Utility shortcuts
  hs.hotkey.bind(hyper, "\\", function()
    logger.debug("Keybinding: Hyper+\\ (organize windows)")
    wm.organizeWindows()
  end)

  hs.hotkey.bind(hyper, "1", function()
    logger.debug("Keybinding: Hyper+1 (mission control)")
    hs.spaces.toggleMissionControl()
  end)

  hs.hotkey.bind(hyper, "2", function()
    logger.debug("Keybinding: Hyper+2 (app expose)")
    wm.showAppWindows()
  end)

  hs.hotkey.bind(hyper, "3", function()
    logger.debug("Keybinding: Hyper+3 (minimize all)")
    wm.minimizeAll()
  end)

  hs.hotkey.bind(hyper, "f", function()
    logger.debug("Keybinding: Hyper+F (focus mode)")
    wm.focusMode()
  end)

  -- Reload configuration
  hs.hotkey.bind(hyper, "r", function()
    logger.info("Reloading Hammerspoon configuration")
    hs.reload()
  end)

  -- App Launchers (config-driven)
  logger.info("Setting up app launcher keybindings")
  setupLaunchers()

  -- Workspace shortcuts (cycling)
  logger.info("Setting up workspace keybindings")

  -- Hyper+N: Cycle between Communication and Web workspaces
  hs.hotkey.bind(hyper, "n", function()
    logger.debug("Keybinding: Hyper+N (Cycle: Communication <-> Web)")
    workspaces.cycleWorkspace("n_group")
  end)

  -- Hyper+M: Cycle between Coding and Android workspaces
  hs.hotkey.bind(hyper, "m", function()
    logger.debug("Keybinding: Hyper+M (Cycle: Coding <-> Android)")
    workspaces.cycleWorkspace("m_group")
  end)

  -- Input source cycling (Hyper+4)
  hs.hotkey.bind(hyper, "4", function()
    local layouts = hs.keycodes.layouts()
    local current = hs.keycodes.currentLayout()
    local currentIdx = 1
    for i, layout in ipairs(layouts) do
      if layout == current then
        currentIdx = i
        break
      end
    end
    local nextIdx = (currentIdx % #layouts) + 1
    local nextLayout = layouts[nextIdx]
    hs.keycodes.setLayout(nextLayout)
    logger.debug("Input source: " .. current .. " -> " .. nextLayout)
    hs.alert.show(nextLayout, 0.8)
  end)

  logger.info("Keybindings setup complete")
end

return M
