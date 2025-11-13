-- Luacheck configuration for Hammerspoon
-- Defines globals and standards for linting

-- Hammerspoon globals
globals = {
  "hs",
}

-- Read-only globals (can be used but not modified)
read_globals = {
  "hs",
}

-- Lua standard (Hammerspoon uses Lua 5.4)
std = "lua54"

-- Code style
max_line_length = 100
max_code_line_length = 100
max_comment_line_length = 120

-- Ignore some warnings
ignore = {
  "212", -- Unused argument (often intentional in callbacks)
}
