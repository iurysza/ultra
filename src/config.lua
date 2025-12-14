--- Configuration Loader Module
--- Loads JSON config with defaults and hot-reload support
--- @module config

local M = {}

-- Use actual config location (not hs.configdir which points to bootstrap)
local configDir = os.getenv("HOME") .. "/.config/ultra"
local configPath = configDir .. "/config.json"
local defaultConfigPath = configDir .. "/config.default.json"

local currentConfig = nil
local watcher = nil

--- @param target table Target table (modified in place)
--- @param source table Source table to merge from
local function deepMerge(target, source)
  for k, v in pairs(source) do
    if type(v) == "table" and type(target[k]) == "table" then
      deepMerge(target[k], v)
    else
      if target[k] == nil then
        target[k] = v
      end
    end
  end
  return target
end

local function deepCopy(orig)
  if type(orig) ~= "table" then
    return orig
  end
  local copy = {}
  for k, v in pairs(orig) do
    copy[k] = deepCopy(v)
  end
  return copy
end

--- @return table|nil, string|nil Parsed JSON or nil, error message
local function readJson(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local content = file:read("*a")
  file:close()

  if not content or content == "" then
    return nil
  end

  local ok, result = pcall(hs.json.decode, content)
  if not ok then
    return nil, result
  end

  return result
end

function M.load()
  -- Load defaults first
  local defaults = readJson(defaultConfigPath)
  if not defaults then
    hs.alert.show("Warning: config.default.json not found")
    defaults = {}
  end

  -- Load user config
  local userConfig, err = readJson(configPath)
  if err then
    hs.alert.show("Config parse error: " .. tostring(err))
    userConfig = {}
  elseif not userConfig then
    -- No user config, use defaults only
    userConfig = {}
  end

  -- Merge: user config takes precedence, defaults fill gaps
  local config = deepCopy(userConfig)
  deepMerge(config, defaults)

  currentConfig = config
  return config
end

function M.get()
  if not currentConfig then
    return M.load()
  end
  return currentConfig
end

--- @param path string Dot-separated path (e.g., "environment.personalHostnamePattern")
function M.getValue(path)
  local config = M.get()
  local current = config

  for segment in path:gmatch("[^%.]+") do
    if type(current) ~= "table" then
      return nil
    end
    current = current[segment]
  end

  return current
end

function M.watch(callback)
  if watcher then
    watcher:stop()
  end

  watcher = hs.pathwatcher.new(configDir, function(files)
    for _, file in pairs(files) do
      if file:match("config%.json$") then
        local newConfig = M.load()
        if callback then
          callback(newConfig)
        end
        break
      end
    end
  end)
  watcher:start()
end

function M.stopWatch()
  if watcher then
    watcher:stop()
    watcher = nil
  end
end

function M.userConfigExists()
  local file = io.open(configPath, "r")
  if file then
    file:close()
    return true
  end
  return false
end

function M.getConfigPath()
  return configPath
end

function M.getDefaultConfigPath()
  return defaultConfigPath
end

return M
