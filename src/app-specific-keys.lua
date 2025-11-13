--- App-Specific Keybindings
--- Custom keybindings that only work in specific applications
--- @module app-specific-keys

local logger = require("src.logger")
local M = {}

-- Store hotkeys for cleanup
local obsidianHotkeys = {}

--- Setup Obsidian-specific keybindings
local function setupObsidianKeys()
  logger.info("Setting up Obsidian-specific keybindings")

  -- Vim-style navigation (Ctrl+hjkl → Arrow keys)
  obsidianHotkeys[#obsidianHotkeys + 1] =
    hs.hotkey.bind({ "ctrl" }, "h", function()
      hs.eventtap.keyStroke({}, "left")
    end, nil, function()
      hs.eventtap.keyStroke({}, "left")
    end)

  obsidianHotkeys[#obsidianHotkeys + 1] =
    hs.hotkey.bind({ "ctrl" }, "j", function()
      hs.eventtap.keyStroke({}, "down")
    end, nil, function()
      hs.eventtap.keyStroke({}, "down")
    end)

  obsidianHotkeys[#obsidianHotkeys + 1] =
    hs.hotkey.bind({ "ctrl" }, "k", function()
      hs.eventtap.keyStroke({}, "up")
    end, nil, function()
      hs.eventtap.keyStroke({}, "up")
    end)

  obsidianHotkeys[#obsidianHotkeys + 1] =
    hs.hotkey.bind({ "ctrl" }, "l", function()
      hs.eventtap.keyStroke({}, "right")
    end, nil, function()
      hs.eventtap.keyStroke({}, "right")
    end)

  -- Delete forward (Cmd+` → forwarddelete)
  obsidianHotkeys[#obsidianHotkeys + 1] =
    hs.hotkey.bind({ "cmd" }, "`", function()
      hs.eventtap.keyStroke({}, "forwarddelete")
    end)

  -- Zoom controls (remap to standard zoom shortcuts)
  -- Cmd+W → Cmd+= (zoom in)
  obsidianHotkeys[#obsidianHotkeys + 1] =
    hs.hotkey.bind({ "cmd" }, "w", function()
      hs.eventtap.keyStroke({ "cmd" }, "=")
    end)

  -- Cmd+S → Cmd+- (zoom out)
  obsidianHotkeys[#obsidianHotkeys + 1] =
    hs.hotkey.bind({ "cmd" }, "s", function()
      hs.eventtap.keyStroke({ "cmd" }, "-")
    end)

  -- Enable all hotkeys
  for _, hotkey in ipairs(obsidianHotkeys) do
    hotkey:disable() -- Start disabled
  end
end

--- Cleanup Obsidian keybindings
local function cleanupObsidianKeys()
  logger.debug("Cleaning up Obsidian keybindings")
  for _, hotkey in ipairs(obsidianHotkeys) do
    hotkey:delete()
  end
  obsidianHotkeys = {}
end

--- Setup application watcher to enable/disable app-specific keys
function M.setup()
  logger.info("Setting up app-specific keybindings module")

  -- Setup Obsidian keys
  setupObsidianKeys()

  -- Watch for app changes
  local appWatcher = hs.application.watcher.new(function(appName, eventType, app)
    if eventType == hs.application.watcher.activated then
      if app:bundleID() == "md.obsidian" then
        logger.debug("Obsidian activated - enabling custom keys")
        for _, hotkey in ipairs(obsidianHotkeys) do
          hotkey:enable()
        end
      else
        logger.debug("Non-Obsidian app activated - disabling Obsidian keys")
        for _, hotkey in ipairs(obsidianHotkeys) do
          hotkey:disable()
        end
      end
    end
  end)

  appWatcher:start()

  -- Check if Obsidian is already frontmost
  local frontmost = hs.application.frontmostApplication()
  if frontmost and frontmost:bundleID() == "md.obsidian" then
    for _, hotkey in ipairs(obsidianHotkeys) do
      hotkey:enable()
    end
  end

  logger.info("App-specific keybindings setup complete")
end

return M
