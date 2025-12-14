--- Ultra Window Manager
--- Multi-display window manager with adaptive ultrawide support (aspect ratio detection)
--- @author iury.souza
--- @module init

-- Enable IPC for CLI access
hs.ipc.cliInstall()

-- Actual config directory (hs.configdir points to bootstrap location)
local ultraDir = os.getenv("HOME") .. "/.config/ultra"

-- Load configuration first
local config = require("src.config")
local cfg = config.load()

-- Load logger early
local logger = require("src.logger")

-- Initialize logger with config
local loggingConfig = cfg.logging or {}
logger.init({
  enabled = loggingConfig.enabled ~= false,
  logFile = ultraDir .. "/debug.log",
  maxLogLines = loggingConfig.maxLines or 100,
})

-- Make config globally available for modules
_G.ultraConfig = cfg

-- Load modules
local environment = require("src.environment")
local displays = require("src.displays")
require("src.layouts") -- Loaded for use in other modules
require("src.window-manager") -- Loaded for use in keybindings
require("src.workspaces") -- Loaded for workspace management
local keybindings = require("src.keybindings")
local appSpecificKeys = require("src.app-specific-keys")
local notifications = require("src.notifications")

logger.info("========================================")
logger.info("Ultra Window Manager Starting")
logger.info("========================================")

-- Log system info
local osVersion = hs.host.operatingSystemVersion()
logger.info(
  string.format("macOS Version: %d.%d.%d", osVersion.major, osVersion.minor, osVersion.patch)
)
logger.info("Hammerspoon Version: " .. hs.processInfo.version)
logger.info("Environment: " .. environment.get())

-- Detect displays
local allDisplays = displays.getAllDisplays()
logger.info(string.format("Detected %d display(s)", #allDisplays))

for i, display in ipairs(allDisplays) do
  logger.info(
    string.format(
      "  Display %d: %s (%dx%d) ultrawide=%s",
      i,
      display.name,
      display.width,
      display.height,
      tostring(display.isUltrawide)
    )
  )
end

-- Setup keybindings
keybindings.setup()

-- Setup app-specific keybindings
appSpecificKeys.setup()

-- Expose notifications globally for IPC access
_G.notifications = notifications

-- Show success notification
hs.alert.show("Ultra Window Manager Loaded", 5)
logger.info("Window Manager loaded successfully")

-- Watch for display changes
local displayWatcher = hs.screen.watcher.new(function()
  logger.info("Display configuration changed, updating...")
  local newDisplays = displays.getAllDisplays()
  logger.info(string.format("Now have %d display(s)", #newDisplays))
  hs.alert.show("Display configuration updated", 5)
end)
displayWatcher:start()

-- Watch for config file changes (auto-reload)
hs.pathwatcher
  .new(ultraDir, function(files)
    local doReload = false
    for _, file in pairs(files) do
      if file:match("%.lua$") or file:match("config%.json$") then
        doReload = true
        break
      end
    end
    if doReload then
      logger.info("Configuration files changed, reloading...")
      hs.reload()
    end
  end)
  :start()

logger.info("Watchers started (display config, file changes)")
logger.info("Initialization complete")
logger.info("========================================")
