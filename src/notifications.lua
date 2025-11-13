--- Notifications Module
--- Provides enhanced macOS notifications with tmux integration
--- @module notifications

local logger = require("src.logger")
local M = {}

--- Get terminal application name (auto-detect)
--- @return string Terminal app name
local function getTerminalApp()
  -- Check which terminal is running
  local terminals = { "Ghostty", "iTerm2", "kitty", "Alacritty", "Terminal" }
  for _, term in ipairs(terminals) do
    local app = hs.application.get(term)
    if app then
      return term
    end
  end
  return "Terminal" -- Fallback to default
end

--- Focus tmux session/window/pane
--- @param tmuxTarget string Target in format "session:window.pane"
local function focusTmuxTarget(tmuxTarget)
  if not tmuxTarget or tmuxTarget == "" then
    logger.warn("No tmux target provided")
    return
  end

  logger.info(string.format("Focusing tmux target: %s", tmuxTarget))

  -- Parse tmux target (format: session:window.pane)
  local session, windowPane = tmuxTarget:match("([^:]+):(.+)")
  if not session then
    logger.error(string.format("Invalid tmux target format: %s", tmuxTarget))
    return
  end

  local window, pane = windowPane:match("([^%.]+)%.?(.*)")

  -- Build tmux command
  local cmd = string.format("tmux select-window -t %s:%s", session, window or "1")

  if pane and pane ~= "" then
    cmd = cmd .. string.format(" && tmux select-pane -t %s", pane)
  end

  -- Focus terminal app first
  local termApp = getTerminalApp()
  logger.debug(string.format("Focusing terminal app: %s", termApp))
  hs.application.launchOrFocus(termApp)

  -- Wait a bit for terminal to focus, then run tmux command
  hs.timer.doAfter(0.2, function()
    local output, status = hs.execute(cmd)
    if status then
      logger.info(string.format("Successfully focused tmux: %s", tmuxTarget))
    else
      logger.error(string.format("Failed to focus tmux: %s (output: %s)", tmuxTarget, output))
    end
  end)
end

--- Send notification with optional tmux context
--- @param opts table Notification options
---   - title: string (required)
---   - message: string (required)
---   - sound: string (optional, default: "Glass")
---   - tmuxTarget: string (optional, format: "session:window.pane")
---   - hasButton: boolean (optional, default: true if tmuxTarget provided)
---   - buttonTitle: string (optional, default: "Focus Session")
---   - autoWithdraw: number (optional, seconds before auto-dismiss, 0 = never)
function M.send(opts)
  if not opts or not opts.title or not opts.message then
    logger.error("send: title and message are required")
    return
  end

  logger.info(string.format("Sending notification: %s - %s", opts.title, opts.message))

  local hasTmux = opts.tmuxTarget and opts.tmuxTarget ~= ""
  local hasButton = opts.hasButton
  if hasButton == nil then
    hasButton = hasTmux -- Default: show button if tmux context provided
  end

  local withdrawAfter = opts.autoWithdraw or (hasTmux and 0 or 5)

  -- Create notification
  local notification = hs.notify.new(function(notif)
    -- Callback when notification is clicked
    logger.info(string.format("Notification activated! Type: %s", tostring(notif:activationType())))

    local target = notif:userInfo()["tmuxTarget"]
    logger.debug(string.format("Tmux target from userInfo: %s", target or "none"))

    -- Handle both button click and notification body click
    local actType = notif:activationType()
    if
      actType == hs.notify.activationTypes.actionButtonClicked
      or actType == hs.notify.activationTypes.contentsClicked
    then
      if target and target ~= "" then
        focusTmuxTarget(target)
      else
        logger.warn("No tmux target available, just focusing terminal")
        local termApp = getTerminalApp()
        hs.application.launchOrFocus(termApp)
      end
    end
  end, {
    title = opts.title,
    informativeText = opts.message,
    soundName = opts.sound or "Glass",
    hasActionButton = hasButton,
    actionButtonTitle = opts.buttonTitle or "Focus Session",
    withdrawAfter = withdrawAfter,
    userInfo = {
      tmuxTarget = opts.tmuxTarget or "",
    },
  })

  notification:send()
  logger.debug("Notification sent successfully")
end

--- Send notification for Claude task completion
--- @param message string Custom message (optional)
--- @param tmuxTarget string Tmux target (optional)
function M.taskComplete(message, tmuxTarget)
  M.send({
    title = "🎯 Claude Code - Task Complete",
    message = message or "Claude has finished your request",
    sound = "Hero",
    tmuxTarget = tmuxTarget,
  })
end

--- Send notification for Claude permission request
--- @param message string Custom message (optional)
--- @param tmuxTarget string Tmux target (optional)
function M.permissionRequired(message, tmuxTarget)
  M.send({
    title = "⚠️ Claude Code - Permission Required",
    message = message or "Claude is requesting tool access",
    sound = "Glass",
    tmuxTarget = tmuxTarget,
  })
end

--- Send notification for Claude error
--- @param message string Custom message (optional)
--- @param tmuxTarget string Tmux target (optional)
function M.error(message, tmuxTarget)
  M.send({
    title = "❌ Claude Code - Error",
    message = message or "Claude encountered an issue",
    sound = "Basso",
    tmuxTarget = tmuxTarget,
  })
end

--- Send notification for Claude waiting
--- @param message string Custom message (optional)
--- @param tmuxTarget string Tmux target (optional)
function M.waiting(message, tmuxTarget)
  M.send({
    title = "⏳ Claude Code - Waiting",
    message = message or "Claude is awaiting your input",
    sound = "Ping",
    tmuxTarget = tmuxTarget,
  })
end

return M
