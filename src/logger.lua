--- Logger Module
--- Provides debug logging functionality with log levels and rotation
--- @module logger

local M = {}

-- Config
local config = {
  enabled = true,
  maxLines = 100,
  logFile = os.getenv("HOME") .. "/.config/hammerspoon/debug.log",
}

-- Log levels
M.DEBUG = "DEBUG"
M.INFO = "INFO"
M.WARN = "WARN"
M.ERROR = "ERROR"

--- Initialize logger with custom configuration
--- @param opts table Configuration options {enabled, maxLines, logFile}
function M.init(opts)
  opts = opts or {}
  for k, v in pairs(opts) do
    config[k] = v
  end
end

--- Get current timestamp
--- @return string Formatted timestamp
local function getTimestamp()
  return os.date("%Y-%m-%d %H:%M:%S")
end

--- Write log entry to file
--- @param level string Log level
--- @param message string Log message
local function writeLog(level, message)
  if not config.enabled then
    return
  end

  local timestamp = getTimestamp()
  local logEntry = string.format("[%s] [%s] %s\n", timestamp, level, message)

  local file = io.open(config.logFile, "a")
  if file then
    file:write(logEntry)
    file:close()

    -- Rotate log if needed
    M.rotate()
  end
end

--- Rotate log file to keep only last N lines
function M.rotate()
  local file = io.open(config.logFile, "r")
  if not file then
    return
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  -- Keep only last maxLines
  if #lines > config.maxLines then
    local newLines = {}
    for i = #lines - config.maxLines + 1, #lines do
      table.insert(newLines, lines[i])
    end

    local outFile = io.open(config.logFile, "w")
    if outFile then
      for _, line in ipairs(newLines) do
        outFile:write(line .. "\n")
      end
      outFile:close()
    end
  end
end

--- Log debug message
--- @param message string Message to log
function M.debug(message)
  writeLog(M.DEBUG, message)
end

--- Log info message
--- @param message string Message to log
function M.info(message)
  writeLog(M.INFO, message)
end

--- Log warning message
--- @param message string Message to log
function M.warn(message)
  writeLog(M.WARN, message)
end

--- Log error message
--- @param message string Message to log
function M.error(message)
  writeLog(M.ERROR, message)
end

--- Clear log file
function M.clear()
  local file = io.open(config.logFile, "w")
  if file then
    file:close()
  end
end

--- Check if logging is enabled
--- @return boolean
function M.isEnabled()
  return config.enabled
end

return M
