--- App-Specific Keybindings
--- Custom keybindings that only work in specific applications
--- @module app-specific-keys

local logger = require("src.logger")
local M = {}

-- Store hotkeys for cleanup
local obsidianHotkeys = {}
local chromeHotkeys = {}
-- Store watcher to prevent garbage collection
local appWatcher = nil

-- Chrome's active UI language is English (en-US).
local chromeSidebarLabels = {
  ["expand tabs"] = true,
  ["collapse tabs"] = true,
}

local chromeSidebarButton = nil
local chromeSidebarSearch = nil

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

--- @param element hs.axuielement
--- @return boolean
local function isChromeSidebarButton(element)
  if element:attributeValue("AXRole") ~= "AXButton" then
    return false
  end

  local title = string.lower(tostring(element:attributeValue("AXTitle") or ""))
  local description = string.lower(tostring(element:attributeValue("AXDescription") or ""))
  return chromeSidebarLabels[title] or chromeSidebarLabels[description]
end

--- @param button hs.axuielement
local function pressChromeSidebarButton(button)
  local ok, err = button:performAction("AXPress")
  if ok then
    logger.debug("Chrome vertical-tab sidebar toggled")
  else
    logger.warn("Could not toggle Chrome vertical-tab sidebar: " .. tostring(err))
  end
end

--- Toggle Chrome's native vertical-tab sidebar through the macOS Accessibility API.
local function toggleChromeSidebar()
  local chrome = hs.application.frontmostApplication()
  if not chrome or chrome:bundleID() ~= "com.google.Chrome" then
    return
  end

  if chromeSidebarButton then
    local ok, valid = pcall(function()
      return chromeSidebarButton:isValid()
    end)
    if ok and valid then
      pressChromeSidebarButton(chromeSidebarButton)
      return
    end
    chromeSidebarButton = nil
  end

  if chromeSidebarSearch and chromeSidebarSearch:isRunning() then
    return
  end

  local root = hs.axuielement.applicationElement(chrome):attributeValue("AXFocusedWindow")
  if not root then
    logger.warn("Chrome's focused window is unavailable")
    return
  end

  -- Chromium's sidebar button is normally 8–10 AX levels below the window.
  chromeSidebarSearch = root:elementSearch(function(_, elements)
    chromeSidebarSearch = nil
    chromeSidebarButton = elements[1]

    if chromeSidebarButton then
      pressChromeSidebarButton(chromeSidebarButton)
    else
      logger.warn("Chrome vertical-tab sidebar button not found")
    end
  end, isChromeSidebarButton, { count = 1, depth = 15 })
end

--- Setup Chrome-specific keybindings
local function setupChromeKeys()
  logger.info("Setting up Chrome-specific keybindings")

  chromeHotkeys[#chromeHotkeys + 1] = hs.hotkey.bind({ "cmd" }, "1", toggleChromeSidebar)

  for _, hotkey in ipairs(chromeHotkeys) do
    hotkey:disable()
  end
end

--- Set the active application-scoped keybindings.
--- @param bundleID string|nil
local function updateActiveHotkeys(bundleID)
  local isObsidian = bundleID == "md.obsidian"
  local isChrome = bundleID == "com.google.Chrome"

  for _, hotkey in ipairs(obsidianHotkeys) do
    if isObsidian then
      hotkey:enable()
    else
      hotkey:disable()
    end
  end

  for _, hotkey in ipairs(chromeHotkeys) do
    if isChrome then
      hotkey:enable()
    else
      hotkey:disable()
    end
  end
end

--- Setup application watcher to enable/disable app-specific keys
function M.setup()
  logger.info("Setting up app-specific keybindings module")

  setupObsidianKeys()
  setupChromeKeys()

  appWatcher = hs.application.watcher.new(function(_, eventType, app)
    if eventType == hs.application.watcher.activated then
      updateActiveHotkeys(app:bundleID())
    end
  end)

  appWatcher:start()

  local frontmost = hs.application.frontmostApplication()
  updateActiveHotkeys(frontmost and frontmost:bundleID())

  logger.info("App-specific keybindings setup complete")
end

return M
