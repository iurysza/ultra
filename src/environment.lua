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

	-- TODO: Update work hostname pattern when you remember it
	-- Examples: "work%-laptop", "corp%-", "company%-"
	-- For now, we'll detect personal by "iury" pattern
	local isPersonal = hostname:lower():match("iury") ~= nil

	currentEnvironment = isPersonal and M.PERSONAL or M.WORK
	logger.info("Environment detected: " .. currentEnvironment)

	return currentEnvironment
end

--- App bundle ID mappings per environment
local APP_MAPPINGS = {
	browser = {
		[M.WORK] = "com.google.Chrome",
		[M.PERSONAL] = "app.zen-browser.zen",
	},
	communication = {
		[M.WORK] = "com.tinyspeck.slackmacgap", -- Slack
		[M.PERSONAL] = "net.whatsapp.WhatsApp", -- WhatsApp
	},
}

--- Resolve app bundle ID based on app type and environment
--- @param appType string App type key (e.g., "browser", "communication")
--- @return string The bundle ID for current environment
function M.resolveApp(appType)
	local env = M.detect()
	local mapping = APP_MAPPINGS[appType]

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
