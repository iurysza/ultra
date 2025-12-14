---@meta

---@class hs
---@field alert hs.alert
---@field screen hs.screen
---@field window hs.window
---@field application hs.application
---@field hotkey hs.hotkey
---@field pathwatcher hs.pathwatcher
---@field json hs.json
---@field ipc hs.ipc
---@field host hs.host
---@field keycodes hs.keycodes
---@field eventtap hs.eventtap
---@field fnutils hs.fnutils
---@field timer hs.timer
---@field configdir string
hs = {}

---@param msg string
function hs.reload() end

---@param msg string
---@param duration? number
function hs.alert.show(msg, duration) end

---@class hs.alert
hs.alert = {}

---@class hs.screen
---@field watcher fun(): hs.screen.watcher
hs.screen = {}

---@return hs.screen[]
function hs.screen.allScreens() end

---@return hs.screen
function hs.screen.mainScreen() end

---@return hs.screen
function hs.screen.primaryScreen() end

---@class hs.screen.watcher
---@field start fun(self: hs.screen.watcher): hs.screen.watcher
---@field stop fun(self: hs.screen.watcher): hs.screen.watcher

---@param fn function
---@return hs.screen.watcher
function hs.screen.watcher.new(fn) end

---@return string
function hs.screen:name() end

---@return table
function hs.screen:frame() end

---@return table
function hs.screen:currentMode() end

---@return string
function hs.screen:id() end

---@class hs.window
hs.window = {}

---@return hs.window|nil
function hs.window.focusedWindow() end

---@return hs.window[]
function hs.window.allWindows() end

---@return hs.window[]
function hs.window.orderedWindows() end

---@param hints? table
---@return hs.window[]
function hs.window.filter.default:getWindows(hints) end

---@return string
function hs.window:title() end

---@return hs.application
function hs.window:application() end

---@return hs.screen
function hs.window:screen() end

---@return table
function hs.window:frame() end

---@param frame table
function hs.window:setFrame(frame) end

---@param frame table
---@param duration number
function hs.window:setFrame(frame, duration) end

function hs.window:focus() end
function hs.window:minimize() end
function hs.window:unminimize() end
function hs.window:raise() end

---@return boolean
function hs.window:isMinimized() end

---@return boolean
function hs.window:isStandard() end

---@param screen hs.screen
function hs.window:moveToScreen(screen) end

---@class hs.application
hs.application = {}

---@param name string
---@return hs.application|nil
function hs.application.get(name) end

---@param bundleID string
---@return hs.application|nil
function hs.application.get(bundleID) end

---@param name string
---@return hs.application|nil
function hs.application.find(name) end

---@param hint string
---@param exact? boolean
---@return hs.application|nil
function hs.application.find(hint, exact) end

---@param app string
---@return boolean
function hs.application.launchOrFocus(app) end

---@param bundleID string
---@return boolean
function hs.application.launchOrFocusByBundleID(bundleID) end

---@return hs.application|nil
function hs.application.frontmostApplication() end

---@return string
function hs.application:name() end

---@return string
function hs.application:bundleID() end

---@return hs.window[]
function hs.application:allWindows() end

---@return hs.window[]
function hs.application:visibleWindows() end

---@return hs.window|nil
function hs.application:mainWindow() end

---@return hs.window|nil
function hs.application:focusedWindow() end

function hs.application:activate() end
function hs.application:hide() end
function hs.application:unhide() end

---@return boolean
function hs.application:isHidden() end

---@return boolean
function hs.application:isFrontmost() end

---@class hs.hotkey
hs.hotkey = {}

---@param mods table
---@param key string
---@param fn function
---@return hs.hotkey
function hs.hotkey.bind(mods, key, fn) end

---@param mods table
---@param key string
---@param pressedfn? function
---@param releasedfn? function
---@param repeatfn? function
---@return hs.hotkey
function hs.hotkey.bind(mods, key, pressedfn, releasedfn, repeatfn) end

---@class hs.pathwatcher
hs.pathwatcher = {}

---@param path string
---@param fn function
---@return hs.pathwatcher
function hs.pathwatcher.new(path, fn) end

function hs.pathwatcher:start() end
function hs.pathwatcher:stop() end

---@class hs.json
hs.json = {}

---@param str string
---@return table
function hs.json.decode(str) end

---@param tbl table
---@param prettyprint? boolean
---@return string
function hs.json.encode(tbl, prettyprint) end

---@class hs.ipc
hs.ipc = {}

function hs.ipc.cliInstall() end

---@class hs.host
hs.host = {}

---@return table
function hs.host.operatingSystemVersion() end

---@class hs.keycodes
hs.keycodes = {}

---@return table<string, string>
function hs.keycodes.currentSourceID() end

---@return string[]
function hs.keycodes.layouts() end

---@return string[]
function hs.keycodes.methods() end

---@param layout string
---@return boolean
function hs.keycodes.setLayout(layout) end

---@param method string
---@return boolean
function hs.keycodes.setMethod(method) end

---@return string
function hs.keycodes.currentLayout() end

---@return string
function hs.keycodes.currentMethod() end

---@class hs.eventtap
hs.eventtap = {}

---@class hs.eventtap.event
hs.eventtap.event = {}

---@param keycode number
---@param modifiers? table
---@param isdown? boolean
---@return hs.eventtap.event
function hs.eventtap.event.newKeyEvent(keycode, modifiers, isdown) end

---@param events hs.eventtap.event[]
function hs.eventtap.event.newKeyEvent(events) end

---@param key string
---@param modifiers? table
function hs.eventtap.keyStroke(modifiers, key) end

---@class hs.fnutils
hs.fnutils = {}

---@generic T
---@param tbl T[]
---@param fn fun(item: T): boolean
---@return T|nil
function hs.fnutils.find(tbl, fn) end

---@generic T
---@param tbl T[]
---@param fn fun(item: T): boolean
---@return T[]
function hs.fnutils.filter(tbl, fn) end

---@generic T, U
---@param tbl T[]
---@param fn fun(item: T): U
---@return U[]
function hs.fnutils.map(tbl, fn) end

---@generic T
---@param tbl T[]
---@param fn fun(item: T)
function hs.fnutils.each(tbl, fn) end

---@class hs.timer
hs.timer = {}

---@param interval number
---@param fn function
---@return hs.timer
function hs.timer.doAfter(interval, fn) end

---@param interval number
---@param fn function
---@return hs.timer
function hs.timer.doEvery(interval, fn) end

---@class hs.processInfo
---@field version string
hs.processInfo = {}

---@class hs.window.filter
hs.window.filter = {}

---@field default hs.window.filter
hs.window.filter.default = {}
