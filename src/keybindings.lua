--- Keybindings Configuration
--- Maps all keyboard shortcuts using Hammerspoon hotkey API
--- @module keybindings

local wm = require("src.window-manager")
local logger = require("src.logger")
local M = {}

-- Hyper key: Shift+Cmd+Ctrl+Opt (mapped via Karabiner from Caps Lock)
local hyper = { "shift", "cmd", "ctrl", "alt" }

--- Setup all keybindings
function M.setup()
  logger.info("Setting up keybindings")

  -- Window positioning shortcuts
  hs.hotkey.bind(hyper, "h", function()
    logger.debug("Keybinding: Hyper+h (left)")
    wm.positionWindow("left")
  end)

  hs.hotkey.bind(hyper, "j", function()
    logger.debug("Keybinding: Hyper+j (center)")
    wm.positionWindow("center")
  end)

  hs.hotkey.bind(hyper, "k", function()
    logger.debug("Keybinding: Hyper+k (full)")
    wm.positionWindow("full")
  end)

  hs.hotkey.bind(hyper, "l", function()
    logger.debug("Keybinding: Hyper+l (right)")
    wm.positionWindow("right")
  end)

  hs.hotkey.bind(hyper, "u", function()
    logger.debug("Keybinding: Hyper+u (leftTwoThirds)")
    wm.positionWindow("leftTwoThirds")
  end)

  hs.hotkey.bind(hyper, "i", function()
    logger.debug("Keybinding: Hyper+i (centerFocus)")
    wm.positionWindow("centerFocus")
  end)

  hs.hotkey.bind(hyper, "o", function()
    logger.debug("Keybinding: Hyper+o (rightTwoThirds)")
    wm.positionWindow("rightTwoThirds")
  end)

  hs.hotkey.bind(hyper, "y", function()
    logger.debug("Keybinding: Hyper+y (leftHalf)")
    wm.positionWindow("leftHalf")
  end)

  hs.hotkey.bind(hyper, "p", function()
    logger.debug("Keybinding: Hyper+p (rightHalf)")
    wm.positionWindow("rightHalf")
  end)

  -- Monitor switching
  hs.hotkey.bind(hyper, "left", function()
    logger.debug("Keybinding: Hyper+Left (move to left display)")
    wm.moveToDisplay("left")
  end)

  hs.hotkey.bind(hyper, "right", function()
    logger.debug("Keybinding: Hyper+Right (move to right display)")
    wm.moveToDisplay("right")
  end)

  -- Utility shortcuts
  hs.hotkey.bind(hyper, "\\", function()
    logger.debug("Keybinding: Hyper+\\ (organize windows)")
    wm.organizeWindows()
  end)

  hs.hotkey.bind(hyper, "=", function()
    logger.debug("Keybinding: Hyper+= (minimize all)")
    wm.minimizeAll()
  end)

  hs.hotkey.bind(hyper, "]", function()
    logger.debug("Keybinding: Hyper+] (show app windows)")
    wm.showAppWindows()
  end)

  -- Reload configuration
  hs.hotkey.bind(hyper, "r", function()
    logger.info("Reloading Hammerspoon configuration")
    hs.reload()
  end)

  logger.info("Keybindings setup complete")
end

return M
