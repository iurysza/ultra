--- App-Specific Keybindings
--- Custom keybindings that only work in specific applications
--- @module app-specific-keys

local logger = require("src.logger")
local config = require("src.config")
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

-- Chrome AX controls belong to one window, so never reuse a button across windows.
local chromeSidebarSearch = nil

-- Chrome's active UI language is English (en-US).
local chromeRemoveFromGroupTitle = "remove from group"
local chromePartOfGroupPattern = "%- Part of (.-) %-"

-- Default shortcut for deleting Chrome tab groups (overridable via config).
local defaultDeleteGroupBinding = { mods = { "ctrl", "shift" }, key = "G" }

--- Depth-first AX search for the first matching element, synchronous.
--- Skips heavy subtrees that never hold the controls we look for (web
--- content, the menu bar). Context menus hang under AXWindow, so windows
--- are traversed.
--- @param root hs.axuielement
--- @param predicate fun(el: hs.axuielement): boolean
--- @param depth number|nil
--- @return hs.axuielement|nil
local function findAXElement(root, predicate, depth)
  depth = depth or 0
  if depth > 25 then
    return nil
  end
  if predicate(root) then
    return root
  end
  local role = root:attributeValue("AXRole")
  if role == "AXWebArea" or role == "AXMenuBar" then
    return nil
  end
  for _, child in ipairs(root:attributeValue("AXChildren") or {}) do
    local hit = findAXElement(child, predicate, depth + 1)
    if hit then
      return hit
    end
  end
  return nil
end

--- Depth-first AX search for all matching elements, same pruning rules as
--- findAXElement.
--- @return hs.axuielement[]
local function findAXElements(root, predicate)
  local found = {}
  local function walk(el, depth)
    if depth > 25 then
      return
    end
    if predicate(el) then
      found[#found + 1] = el
    end
    local role = el:attributeValue("AXRole")
    if role == "AXWebArea" or role == "AXMenuBar" then
      return
    end
    for _, child in ipairs(el:attributeValue("AXChildren") or {}) do
      walk(child, depth + 1)
    end
  end
  walk(root, 0)
  return found
end

--- Find Chrome's active tab. The active tab only reports AXValue in the
--- window where it is active, so every window is checked — the focused
--- window can be a popup (e.g. the group editor).
--- @param appEl hs.axuielement Chrome's application element
--- @return hs.axuielement|nil activeTab, hs.axuielement|nil tabStrip
local function findChromeActiveTab(appEl)
  for _, win in ipairs(appEl:attributeValue("AXWindows") or {}) do
    local tabStrip = findAXElement(win, function(el)
      return el:attributeValue("AXRole") == "AXTabGroup"
    end)
    if tabStrip then
      local activeTab = findAXElement(tabStrip, function(el)
        if el:attributeValue("AXRole") ~= "AXRadioButton" then
          return false
        end
        local value = el:attributeValue("AXValue")
        return value == true or value == 1
      end)
      if activeTab then
        return activeTab, tabStrip
      end
    end
  end
  return nil, nil
end

--- Extract the group name from a tab's AXDescription, which Chrome reports
--- as "<title> - Part of <group> - ..." for grouped tabs.
--- @return string|nil
local function chromeTabGroupName(tab)
  local desc = tostring(tab:attributeValue("AXDescription") or "")
  return desc:match(chromePartOfGroupPattern)
end

--- Setup Obsidian-specific keybindings
local function setupObsidianKeys()
  logger.info("Setting up Obsidian-specific keybindings")

  -- Vim-style navigation (Ctrl+hjkl → Arrow keys)
  obsidianHotkeys[#obsidianHotkeys + 1] = hs.hotkey.bind(
    { "ctrl" },
    "h",
    function()
      hs.eventtap.keyStroke({}, "left")
    end,
    nil,
    function()
      hs.eventtap.keyStroke({}, "left")
    end
  )

  obsidianHotkeys[#obsidianHotkeys + 1] = hs.hotkey.bind(
    { "ctrl" },
    "j",
    function()
      hs.eventtap.keyStroke({}, "down")
    end,
    nil,
    function()
      hs.eventtap.keyStroke({}, "down")
    end
  )

  obsidianHotkeys[#obsidianHotkeys + 1] = hs.hotkey.bind(
    { "ctrl" },
    "k",
    function()
      hs.eventtap.keyStroke({}, "up")
    end,
    nil,
    function()
      hs.eventtap.keyStroke({}, "up")
    end
  )

  obsidianHotkeys[#obsidianHotkeys + 1] = hs.hotkey.bind(
    { "ctrl" },
    "l",
    function()
      hs.eventtap.keyStroke({}, "right")
    end,
    nil,
    function()
      hs.eventtap.keyStroke({}, "right")
    end
  )

  -- Delete forward (Cmd+` → forwarddelete)
  obsidianHotkeys[#obsidianHotkeys + 1] = hs.hotkey.bind({ "cmd" }, "`", function()
    hs.eventtap.keyStroke({}, "forwarddelete")
  end)

  -- Zoom controls (remap to standard zoom shortcuts)
  -- Cmd+W → Cmd+= (zoom in)
  obsidianHotkeys[#obsidianHotkeys + 1] = hs.hotkey.bind({ "cmd" }, "w", function()
    hs.eventtap.keyStroke({ "cmd" }, "=")
  end)

  -- Cmd+S → Cmd+- (zoom out)
  obsidianHotkeys[#obsidianHotkeys + 1] = hs.hotkey.bind({ "cmd" }, "s", function()
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

  local root = hs.axuielement.applicationElement(chrome):attributeValue("AXFocusedWindow")
  if not root then
    logger.warn("Chrome's focused window is unavailable")
    return
  end

  if chromeSidebarSearch and chromeSidebarSearch:isRunning() then
    chromeSidebarSearch:cancel("superseded by a newer Chrome sidebar request")
  end

  -- Chromium's sidebar button is normally 8–10 AX levels below the window.
  local search
  search = root:elementSearch(function(_, elements)
    if chromeSidebarSearch ~= search then
      return
    end

    chromeSidebarSearch = nil
    local button = elements[1]
    if button then
      pressChromeSidebarButton(button)
    else
      logger.warn("Chrome vertical-tab sidebar button not found")
    end
  end, isChromeSidebarButton, { count = 1, depth = 15 })
  chromeSidebarSearch = search
end

--- Delete the tab group holding Chrome's active tab by dissolving it: every
--- tab of the group is removed from it through the tab context menu, which
--- Chrome fully exposes to AX. Tabs stay open. (The group's own context menu
--- cannot be used: Chrome opens it on AXShowMenu but does not expose it to AX,
--- and synthetic clicks are not portable.)
local function deleteActiveChromeTabGroup()
  local chrome = hs.application.frontmostApplication()
  if not chrome or chrome:bundleID() ~= "com.google.Chrome" then
    return
  end

  local appEl = hs.axuielement.applicationElement(chrome)
  local activeTab, tabStrip = findChromeActiveTab(appEl)
  if not activeTab then
    logger.warn("Chrome's active tab not found")
    return
  end

  local groupName = chromeTabGroupName(activeTab)
  if not groupName then
    logger.warn("Chrome's active tab is not in a group")
    return
  end

  local memberMarker = "Part of " .. groupName
  local members = findAXElements(tabStrip, function(el)
    if el:attributeValue("AXRole") ~= "AXRadioButton" then
      return false
    end
    local desc = tostring(el:attributeValue("AXDescription") or "")
    return desc:find(memberMarker, 1, true) ~= nil
  end)

  if #members == 0 then
    logger.warn("No Chrome tabs found for group: " .. groupName)
    return
  end

  -- Remove each tab from the group. The context menu posts asynchronously,
  -- so poll for the item before pressing it.
  local index = 0
  local attempts = 0
  local poll
  poll = hs.timer.doEvery(0.1, function()
    local member = members[index + 1]
    if not member then
      poll:stop()
      logger.debug("Chrome tab group deleted: " .. groupName)
      return
    end

    if attempts == 0 then
      member:performAction("AXShowMenu")
      attempts = attempts + 1
      return
    end

    attempts = attempts + 1
    local item = findAXElement(appEl, function(el)
      return el:attributeValue("AXRole") == "AXMenuItem"
        and string.lower(tostring(el:attributeValue("AXTitle") or ""))
          == chromeRemoveFromGroupTitle
    end)
    if item then
      local pressed, pressErr = item:performAction("AXPress")
      if pressed then
        index = index + 1
        attempts = 0
      else
        poll:stop()
        logger.warn("Could not remove Chrome tab from group: " .. tostring(pressErr))
      end
    elseif attempts > 20 then
      poll:stop()
      hs.eventtap.keyStroke({}, "escape")
      logger.warn("Chrome 'Remove From Group' menu item not found for: " .. groupName)
    end
  end)
end

--- @return table { mods = string[], key = string }
local function getDeleteGroupBinding()
  local binding = config.getValue("appKeys.chrome.deleteGroup")
  if type(binding) ~= "table" or type(binding.mods) ~= "table" or type(binding.key) ~= "string" then
    return defaultDeleteGroupBinding
  end
  return binding
end

--- Setup Chrome-specific keybindings
local function setupChromeKeys()
  logger.info("Setting up Chrome-specific keybindings")

  chromeHotkeys[#chromeHotkeys + 1] = hs.hotkey.bind({ "cmd" }, "1", toggleChromeSidebar)

  local deleteGroupBinding = getDeleteGroupBinding()
  chromeHotkeys[#chromeHotkeys + 1] =
    hs.hotkey.bind(deleteGroupBinding.mods, deleteGroupBinding.key, deleteActiveChromeTabGroup)

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
