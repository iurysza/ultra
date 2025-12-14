--- Environment Detection Module
--- Detects work vs personal environment based on hostname
--- @module environment

local logger = require("src.logger")
local M = {}

-- Environment types
M.WORK = "work"
M.PERSONAL = "personal"

-- Current environment (cached)
local currentEnvironment = nil

--- Get config (from global or fallback)
local function getConfig()
  return _G.ultraConfig or {}
end

--- Get macOS hostname
--- @return string The computer hostname
local function getHostname()
  local handle = io.popen("hostname")
  if not handle then
    logger.error("Failed to get hostname")
    return ""
  end
  local hostname = handle:read("*a")
  handle:close()
  return hostname:gsub("%s+", "") -- trim whitespace
end

--- Detect current environment based on hostname
--- @return string Either M.WORK or M.PERSONAL
function M.detect()
  if currentEnvironment then
    return currentEnvironment
  end

  local hostname = getHostname()
  logger.info("Detected hostname: " .. hostname)

  -- Get patterns from config
  local cfg = getConfig()
  local envConfig = cfg.environment or {}
  local personalPattern = envConfig.personalHostnamePattern or "iury"
  local workPattern = envConfig.workHostnamePattern

  -- Detect environment
  local isPersonal = hostname:lower():match(personalPattern) ~= nil
  local isWork = workPattern and hostname:lower():match(workPattern) ~= nil

  if isWork then
    currentEnvironment = M.WORK
  elseif isPersonal then
    currentEnvironment = M.PERSONAL
  else
    -- Default to work if no pattern matches
    currentEnvironment = M.WORK
  end

  logger.info("Environment detected: " .. currentEnvironment)
  return currentEnvironment
end

--- Get app mappings from config or defaults
local function getAppMappings()
  local cfg = getConfig()
  local apps = cfg.apps or {}

  -- Build mappings from config
  local mappings = {}
  for appType, envApps in pairs(apps) do
    mappings[appType] = {
      [M.WORK] = envApps.work,
      [M.PERSONAL] = envApps.personal,
    }
  end

  return mappings
end

--- Resolve app bundle ID based on app type and environment
--- @param appType string App type key (e.g., "browser", "communication")
--- @return string The bundle ID for current environment
function M.resolveApp(appType)
  local env = M.detect()
  local mappings = getAppMappings()
  local mapping = mappings[appType]

  if not mapping then
    logger.error("Unknown app type: " .. appType)
    return nil
  end

  local bundleID = mapping[env]

  if not bundleID then
    logger.error("No bundle ID found for app type: " .. appType .. " in environment: " .. env)
    return nil
  end

  logger.debug("Resolved " .. appType .. " to " .. bundleID .. " (env: " .. env .. ")")
  return bundleID
end

--- Get current environment (without re-detection)
--- @return string Current environment
function M.get()
	return currentEnvironment or M.detect()
end

logger.info("Environment module loaded")

return M
