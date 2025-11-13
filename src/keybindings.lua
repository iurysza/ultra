--- Keybindings Configuration
--- Maps all keyboard shortcuts using Hammerspoon hotkey API
--- @module keybindings

local wm = require("src.window-manager")
local logger = require("src.logger")
local appLauncher = require("src.app-launcher")
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

  -- App Launchers (smart toggle: launch → focus → minimize)
  logger.info("Setting up app launcher keybindings")

  -- Media control
  hs.hotkey.bind(hyper, "f1", function()
    logger.debug("Keybinding: Hyper+F1 (Play/Pause)")
    appLauncher.togglePlayPause()
  end)

  -- Ghostty
  hs.hotkey.bind(hyper, "f2", function()
    logger.debug("Keybinding: Hyper+F2 (Ghostty)")
    appLauncher.toggleApp("com.mitchellh.ghostty")
  end)

  -- Cursor
  hs.hotkey.bind(hyper, "f3", function()
    logger.debug("Keybinding: Hyper+F3 (Cursor)")
    appLauncher.toggleApp("com.todesktop.230313mzl4w4u92")
  end)

  -- Spotify
  hs.hotkey.bind(hyper, "f4", function()
    logger.debug("Keybinding: Hyper+F4 (Spotify)")
    appLauncher.toggleApp("com.spotify.client")
  end)

  -- Slack
  hs.hotkey.bind(hyper, "f8", function()
    logger.debug("Keybinding: Hyper+F8 (Slack)")
    appLauncher.toggleApp("com.tinyspeck.slackmacgap")
  end)

  -- Android Studio
  hs.hotkey.bind(hyper, "f9", function()
    logger.debug("Keybinding: Hyper+F9 (Android Studio)")
    appLauncher.toggleAppByName("Android Studio")
  end)

  -- Obsidian
  hs.hotkey.bind(hyper, "f10", function()
    logger.debug("Keybinding: Hyper+F10 (Obsidian)")
    appLauncher.toggleApp("md.obsidian")
  end)

  -- Chrome
  hs.hotkey.bind(hyper, "f11", function()
    logger.debug("Keybinding: Hyper+F11 (Chrome)")
    appLauncher.toggleApp("com.google.Chrome")
  end)

  -- WhatsApp
  hs.hotkey.bind(hyper, "f12", function()
    logger.debug("Keybinding: Hyper+F12 (WhatsApp)")
    appLauncher.toggleApp("net.whatsapp.WhatsApp")
  end)

  -- Msty
  hs.hotkey.bind(hyper, ";", function()
    logger.debug("Keybinding: Hyper+; (Msty)")
    appLauncher.toggleApp("MstyStudio")
  end)

  -- Google Meet (Chrome app)
  hs.hotkey.bind(hyper, "m", function()
    logger.debug("Keybinding: Hyper+M (Google Meet)")
    appLauncher.toggleApp("com.google.Chrome.app.kjgfgldnnfoeklkmfkjfagphfepbbdan")
  end)

  -- scrcpy (AppleScript focus)
  hs.hotkey.bind(hyper, "5", function()
    logger.debug("Keybinding: Hyper+5 (scrcpy)")
    appLauncher.executeAppleScript(
      'tell application "System Events" to tell process "scrcpy" to set frontmost to true'
    )
  end)

  logger.info("Keybindings setup complete")
end

return M
