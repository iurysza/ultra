--- App Launcher Module
--- Smart toggle: launch → focus → minimize
--- @module app-launcher

local logger = require("src.logger")
local M = {}

--- Check if an app is running
--- @param bundleID string The bundle identifier
--- @return boolean True if app is running
local function isAppRunning(bundleID)
  local app = hs.application.get(bundleID)
  return app ~= nil
end

--- Check if an app is frontmost
--- @param bundleID string The bundle identifier
--- @return boolean True if app is frontmost
local function isAppFrontmost(bundleID)
  local app = hs.application.frontmostApplication()
  return app and app:bundleID() == bundleID
end

--- Check if an app has any visible windows
--- @param bundleID string The bundle identifier
--- @return boolean True if app has visible windows
local function hasVisibleWindows(bundleID)
  local app = hs.application.get(bundleID)
  if not app then
    return false
  end

  local windows = app:visibleWindows()
  return windows and #windows > 0
end

--- Toggle an application (smart launch/focus/minimize)
--- Behavior:
--- 1. Not running → Launch app
--- 2. Running but minimized → Bring to foreground
--- 3. Running and frontmost → Minimize/hide
--- @param bundleID string The bundle identifier
function M.toggleApp(bundleID)
  logger.debug(string.format("Toggle app: %s", bundleID))

  if not isAppRunning(bundleID) then
    -- App not running → launch it
    logger.info(string.format("Launching app: %s", bundleID))
    hs.application.launchOrFocusByBundleID(bundleID)
    return
  end

  if isAppFrontmost(bundleID) then
    local app = hs.application.get(bundleID)
    local visibleWindows = app and app:visibleWindows() or {}

    -- If app is frontmost but has no visible windows, un-minimize instead
    if #visibleWindows == 0 then
      logger.info("App is frontmost but no visible windows, un-minimizing")
      for _, window in ipairs(app:allWindows()) do
        if window:isMinimized() then
          window:unminimize()
        end
      end
      app:activate()
      return
    end

    -- App is frontmost with visible windows → minimize focused window
    local focusedWindow = hs.window.focusedWindow()
    if focusedWindow then
      logger.info(string.format("Minimizing window: %s", focusedWindow:title()))
      focusedWindow:minimize()
    end
    return
  end

  -- App is running but not frontmost → un-minimize and focus it
  logger.info(string.format("Focusing app: %s", bundleID))
  local app = hs.application.get(bundleID)
  if app then
    -- Un-minimize all windows before activating
    for _, window in ipairs(app:allWindows()) do
      if window:isMinimized() then
        logger.debug("Un-minimizing window for: " .. app:name())
        window:unminimize()
      end
    end
    app:activate()
  else
    hs.application.launchOrFocusByBundleID(bundleID)
  end
end

--- Launch or focus app by name (fallback for apps without bundle ID)
--- @param appName string The application name
function M.toggleAppByName(appName)
  logger.debug(string.format("Toggle app by name: %s", appName))

  local app = hs.application.find(appName)

  if not app then
    -- App not running → launch it
    logger.info(string.format("Launching app: %s", appName))
    hs.application.launchOrFocus(appName)
    return
  end

  if app:isFrontmost() then
    local visibleWindows = app:visibleWindows()

    -- If app is frontmost but has no visible windows, un-minimize instead
    if #visibleWindows == 0 then
      logger.info("App is frontmost but no visible windows, un-minimizing")
      for _, window in ipairs(app:allWindows()) do
        if window:isMinimized() then
          window:unminimize()
        end
      end
      app:activate()
      return
    end

    -- App is frontmost with visible windows → minimize focused window
    local focusedWindow = hs.window.focusedWindow()
    if focusedWindow then
      logger.info(string.format("Minimizing window: %s", focusedWindow:title()))
      focusedWindow:minimize()
    end
    return
  end

  -- App is running but not frontmost → un-minimize and focus it
  logger.info(string.format("Focusing app: %s", appName))
  -- Un-minimize all windows before activating
  for _, window in ipairs(app:allWindows()) do
    if window:isMinimized() then
      logger.debug("Un-minimizing window for: " .. app:name())
      window:unminimize()
    end
  end
  app:activate()
end

--- Execute AppleScript command
--- @param script string The AppleScript to execute
function M.executeAppleScript(script)
  logger.debug("Executing AppleScript")
  local ok, result, rawTable = hs.osascript.applescript(script)
  if not ok then
    logger.error(string.format("AppleScript failed: %s", result))
  end
  return ok
end

--- Toggle media playback (Play/Pause)
function M.togglePlayPause()
  logger.debug("Toggling Play/Pause")
  hs.eventtap.event.newSystemKeyEvent("PLAY", true):post()
  hs.eventtap.event.newSystemKeyEvent("PLAY", false):post()
end

return M
