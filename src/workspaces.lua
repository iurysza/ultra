local logger = require("src.logger")
local appLauncher = require("src.app-launcher")
local displays = require("src.displays")
local layouts = require("src.layouts")
local environment = require("src.environment")

local M = {}

-- Cycle state for workspace groups
local cycleState = {}

-- Workspace definitions (environment-aware)
local workspaces = {
	comms = {
		name = "Communication",
		apps = {
			{ bundleID = environment.resolveApp("communication") }, -- Slack (work) / WhatsApp (personal)
			{ bundleID = "com.google.Chrome.app.kjgfgldnnfoeklkmfkjfagphfepbbdan" }, -- Google Meet
			{ bundleID = environment.resolveApp("browser") }, -- Chrome (work) / Vivaldi (personal)
		},
		layouts = { "left", "center", "right" }, -- Equal 3-way split
	},
	web = {
		name = "Web",
		apps = {
			{ bundleID = environment.resolveApp("browser") }, -- Chrome (work) / Vivaldi (personal)
			{ bundleID = environment.resolveApp("browser") }, -- Same browser, window 2
		},
		layouts = { "leftHalf", "rightHalf" }, -- 50/50 split
		multiWindow = true, -- Special flag for handling multiple windows of same app
	},
	webdev = {
		name = "Coding",
		apps = {
			{ bundleID = "com.todesktop.230313mzl4w4u92" }, -- Cursor
			{ bundleID = "com.mitchellh.ghostty" }, -- Ghostty
			{ bundleID = environment.resolveApp("browser") }, -- Chrome (work) / Vivaldi (personal)
		},
		layouts = { "left", "center", "right" }, -- Equal 3-way split
	},
	androiddev = {
		name = "Android",
		apps = {
			{ appName = "Android Studio" }, -- Use name (no bundle ID)
			{ bundleID = "com.mitchellh.ghostty" }, -- Ghostty
		},
		layouts = { "leftHalf", "rightHalf" }, -- 50/50 split
	},
}

-- Workspace groups for cycling
local workspaceGroups = {
	n_group = { "comms", "web" }, -- Hyper+N cycles: Communication -> Web
	m_group = { "webdev", "androiddev" }, -- Hyper+M cycles: Coding -> Android
}

-- Launch or focus a single app
local function launchApp(appConfig)
	if appConfig.bundleID then
		logger.info("Launching/focusing app with bundle ID: " .. appConfig.bundleID)
		local app = hs.application.get(appConfig.bundleID)
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
			hs.application.launchOrFocusByBundleID(appConfig.bundleID)
		end
	elseif appConfig.appName then
		logger.info("Launching/focusing app by name: " .. appConfig.appName)
		local app = hs.application.get(appConfig.appName)
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
			hs.application.launchOrFocus(appConfig.appName)
		end
	end
end

-- Get main window for an app
local function getAppWindow(appConfig)
	local app = nil
	if appConfig.bundleID then
		app = hs.application.get(appConfig.bundleID)
	elseif appConfig.appName then
		app = hs.application.get(appConfig.appName)
	end

	if not app then
		return nil
	end

	-- Get main window or first standard window
	local window = app:mainWindow()
	if not window then
		local windows = app:allWindows()
		if windows and #windows > 0 then
			window = windows[1]
		end
	end

	return window
end

-- Minimize all windows not in workspace
local function minimizeNonWorkspaceWindows(workspaceApps)
	logger.info("Minimizing windows not in workspace")

	-- Build set of workspace bundle IDs and app names
	local workspaceBundleIDs = {}
	local workspaceAppNames = {}

	for _, appConfig in ipairs(workspaceApps) do
		if appConfig.bundleID then
			workspaceBundleIDs[appConfig.bundleID] = true
		end
		if appConfig.appName then
			workspaceAppNames[appConfig.appName] = true
		end
	end

	-- Get all visible windows
	local allWindows = hs.window.visibleWindows()
	local minimizedCount = 0

	for _, window in ipairs(allWindows) do
		local app = window:application()
		if app then
			local bundleID = app:bundleID()
			local appName = app:name()

			-- Check if this window belongs to workspace
			local isWorkspaceWindow = false
			if bundleID and workspaceBundleIDs[bundleID] then
				isWorkspaceWindow = true
			elseif appName and workspaceAppNames[appName] then
				isWorkspaceWindow = true
			end

			-- Minimize if not in workspace
			if not isWorkspaceWindow then
				logger.debug("Minimizing: " .. (appName or "unknown"))
				window:minimize()
				minimizedCount = minimizedCount + 1
			end
		end
	end

	logger.info("Minimized " .. minimizedCount .. " non-workspace windows")
end

-- Position apps in workspace (handles multi-window workspaces)
local function positionApps(apps, layoutNames, screen, multiWindow)
	logger.info("Positioning " .. #apps .. " apps on screen: " .. screen:name())

	if multiWindow then
		-- Special handling for multi-window workspaces (e.g., 2 Chrome windows)
		local appConfig = apps[1]
		local app = nil
		if appConfig.bundleID then
			app = hs.application.get(appConfig.bundleID)
		elseif appConfig.appName then
			app = hs.application.get(appConfig.appName)
		end

		if app then
			local windows = app:visibleWindows()
			logger.info("Found " .. #windows .. " windows for multi-window workspace")

			-- Position up to the number of layouts we have
			for i = 1, math.min(#windows, #layoutNames) do
				local window = windows[i]
				local layoutName = layoutNames[i]
				if layoutName then
					local layout = layouts.getLayout(layoutName, screen)
					if layout then
						logger.info("Positioning window " .. i .. " to layout: " .. layoutName)
						window:setFrame(layout)
					end
				end
			end

			-- Minimize extra windows beyond layout count
			if #windows > #layoutNames then
				logger.info("Minimizing " .. (#windows - #layoutNames) .. " extra windows")
				for i = #layoutNames + 1, #windows do
					windows[i]:minimize()
				end
			end
		end
	else
		-- Normal handling: one app per config
		-- Track which apps/windows we've positioned
		local positionedApps = {}

		for i, appConfig in ipairs(apps) do
			local appId = appConfig.bundleID or appConfig.appName
			local app = nil

			if appConfig.bundleID then
				app = hs.application.get(appConfig.bundleID)
			elseif appConfig.appName then
				app = hs.application.get(appConfig.appName)
			end

			if app then
				local allWindows = app:visibleWindows()
				local layoutName = layoutNames[i]

				if layoutName and #allWindows > 0 then
					local layout = layouts.getLayout(layoutName, screen)
					if layout then
						-- Position first window for this app
						logger.info(
							"Positioning app "
								.. (appConfig.bundleID or appConfig.appName)
								.. " (window 1/"
								.. #allWindows
								.. ") to layout: "
								.. layoutName
						)
						allWindows[1]:setFrame(layout)

						-- Track how many times we've seen this app
						positionedApps[appId] = (positionedApps[appId] or 0) + 1

						-- Minimize additional windows from this app
						if #allWindows > 1 then
							logger.info("Minimizing " .. (#allWindows - 1) .. " extra windows from " .. app:name())
							for j = 2, #allWindows do
								allWindows[j]:minimize()
							end
						end
					else
						logger.warn("No layout found for: " .. layoutName)
					end
				end
			else
				logger.warn("No app found for: " .. (appConfig.bundleID or appConfig.appName))
			end
		end
	end
end

-- Activate a workspace
function M.activateWorkspace(workspaceId)
	local workspace = workspaces[workspaceId]
	if not workspace then
		logger.error("Unknown workspace: " .. workspaceId)
		hs.alert.show("Unknown workspace: " .. workspaceId)
		return
	end

	logger.info("Activating workspace: " .. workspace.name)
	hs.alert.show("Activating: " .. workspace.name, 1)

	-- Get current screen
	local focusedWindow = hs.window.focusedWindow()
	local screen = focusedWindow and focusedWindow:screen() or hs.screen.mainScreen()

	-- Minimize all non-workspace windows
	minimizeNonWorkspaceWindows(workspace.apps)

	-- Launch/focus all apps (deduplicate for multi-window workspaces)
	local launchedApps = {}
	for _, appConfig in ipairs(workspace.apps) do
		local appId = appConfig.bundleID or appConfig.appName
		if appId and not launchedApps[appId] then
			launchApp(appConfig)
			launchedApps[appId] = true
		elseif not appId then
			-- No ID, launch anyway (shouldn't happen)
			launchApp(appConfig)
		end
	end

	-- Wait for apps to launch and become ready
	hs.timer.doAfter(0.5, function()
		positionApps(workspace.apps, workspace.layouts, screen, workspace.multiWindow)

		-- Focus first app
		local firstApp = workspace.apps[1]
		if firstApp then
			local window = getAppWindow(firstApp)
			if window then
				window:focus()
			end
		end

		logger.info("Workspace activation complete: " .. workspace.name)
	end)
end

-- Cycle through workspace group
function M.cycleWorkspace(groupId)
	local group = workspaceGroups[groupId]
	if not group then
		logger.error("Unknown workspace group: " .. groupId)
		return
	end

	-- Get current cycle state (default to 0)
	local currentIndex = cycleState[groupId] or 0

	-- Increment and wrap around
	currentIndex = (currentIndex % #group) + 1
	cycleState[groupId] = currentIndex

	-- Get workspace ID from group
	local workspaceId = group[currentIndex]
	logger.info(
		string.format(
			"Cycling workspace group '%s': index %d/%d -> %s",
			groupId,
			currentIndex,
			#group,
			workspaceId
		)
	)

	-- Activate the workspace
	M.activateWorkspace(workspaceId)
end

-- Get list of available workspaces
function M.getWorkspaces()
	local list = {}
	for id, workspace in pairs(workspaces) do
		table.insert(list, { id = id, name = workspace.name })
	end
	return list
end

logger.info("Workspaces module loaded")

return M
