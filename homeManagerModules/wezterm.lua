local os = require'os'

function GetOS()
	-- ask LuaJIT first
	if jit then
		return jit.os
	end

	-- Unix, Linux variants
	local fh,err = assert(io.popen("uname -o 2>/dev/null","r"))
	if fh then
		osname = fh:read()
	end

	return osname or "Windows"
end

local is_windows = (GetOS() == 'windows')

-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

config.stderr = '~/.config/wezterm/log.txt'

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- color scheme:
-- config.color_scheme ='Default (light) (terminal.sexy)'
-- config.color_scheme ='terafox'
local file = io.open(wezterm.config_dir .. "/colorscheme", "r")
if file then
	config.color_scheme = file:read("*a")
	file:close()
else
	config.color_scheme = "Tokyo Night Day"
end

-- set the font
-- config.font = wezterm.font "Source Code Pro"
config.font = wezterm.font 'Iosevka'

-- disable bell
config.audible_bell = "Disabled"

-- no window border
-- config.window_decorations = "RESIZE"

-- window opacity
config.window_background_opacity = 0.96


-- Tab bar
-- I don't like the look of "fancy" tab bar
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = true
config.tab_max_width = 50
config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false


wezterm.on("format-tab-title", function(tab)
    local pane = tab.active_pane
    return wezterm.format({
        { Text = " " },
        { Attribute = { Intensity = "Half" } },
        { Text = string.format("%s", tab.tab_index + 1)},
        "ResetAttributes",
        { Text = " "},
        { Text = pane.foreground_process_name }
    })
end)

wezterm.on("update-status", function(window, pane)
    -- Workspace name
    local stat = window:active_workspace()
    local stat_color = "#f7768e"
    -- It's a little silly to have workspace name all the time
    -- Utilize this to display LDR or current key table name
    if window:active_key_table() then
        stat = window:active_key_table()
        stat_color = "#7dcfff"
    end
    if window:leader_is_active() then
        stat = "LDR"
        stat_color = "#bb9af7"
    end

    -- Current working directory
    local basename = function(s)
        -- Nothing a little regex can't fix
        return string.gsub(tostring(s), "(.*[/\\])(.*)", "%2") end
    -- CWD and CMD could be nil (e.g. viewing log using Ctrl-Alt-l). Not a big deal, but check in case
    local cwd = pane:get_current_working_dir()
    cwd = cwd and basename(cwd) or ""
    -- Current command
    local cmd = pane:get_foreground_process_name()
    cmd = cmd and basename(cmd) or ""

    -- Time
    local time = wezterm.strftime("%H:%M")

    -- Left status (left of the tab line)
    window:set_left_status(wezterm.format({
        { Foreground = { Color = stat_color } },
        { Text = "  " },
        { Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
        { Text = " |" },
    }))

    -- Right status
    window:set_right_status(wezterm.format({
        -- Wezterm has a built-in nerd fonts
        -- https://wezfurlong.org/wezterm/config/lua/wezterm/nerdfonts.html
        { Text = wezterm.nerdfonts.md_folder .. "  " .. cwd },
        { Text = " | " },
        { Foreground = { Color = "#e0af68" } },
        { Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
        -- "ResetAttributes",
        { Text = " | " },
        { Text = wezterm.nerdfonts.md_clock .. "  " .. time },
        { Text = "  " },
    }))
end)

-- The art is a bit too bright and colorful to be useful as a backdrop
-- for text, so we're going to dim it down to 10% of its normal brightness
local dimmer = { brightness = 0.1 }

config.enable_scroll_bar = true
config.min_scroll_bar_height = '2cell'
config.colors = {
    scrollbar_thumb = 'white',
}

-- local act = wezterm.action

-- wezterm.on('momdv', function(window, pane)
--     window:perform_action(
--         act.SpawnCommandInNewWindow
--     )
-- end)

local SSH_COMMAND = {}
local NVIM_COMMAND = {}
local SPOTIFY_COMMAND = {}

if is_windows then
    table.insert(SSH_COMMAND, "wsl")
    table.insert(SSH_COMMAND, "--")
    table.insert(NVIM_COMMAND, "wsl")
    table.insert(NVIM_COMMAND, "--")
end

if is_windows then
    table.insert(SSH_COMMAND, "ssh")
    table.insert(SSH_COMMAND, "-tt")
    table.insert(SSH_COMMAND, "v5dev")
else
    table.insert(SSH_COMMAND, "ssh")
    table.insert(SSH_COMMAND, "salhashemi2@picloud.local")
end

table.insert(NVIM_COMMAND, "nvim")

table.insert(SPOTIFY_COMMAND, "spotify_player")


-- keymappings
-- references used:
-- https://wezfurlong.org/wezterm/config/keys.html#configuring-key-assignments
config.leader = { key = "a", mods = "ALT", timeout_milliseconds = 1000 }
config.keys = {
    { key = "phys:Space", mods = "LEADER",       action = wezterm.action.ActivateCommandPalette },
    { key = "-",          mods = "LEADER", action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },
    { key = "\\",          mods = "LEADER", action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { key = "h",          mods = "LEADER",         action = wezterm.action.ActivatePaneDirection("Left") },
    { key = "j",          mods = "LEADER",         action = wezterm.action.ActivatePaneDirection("Down") },
    { key = "k",          mods = "LEADER",         action = wezterm.action.ActivatePaneDirection("Up") },
    { key = "l",          mods = "LEADER",         action = wezterm.action.ActivatePaneDirection("Right") },
    { key = "q",          mods = "LEADER",       action = wezterm.action.CloseCurrentPane { confirm = true } },
    { key = "z",          mods = "LEADER",       action = wezterm.action.TogglePaneZoomState },
    { key = "o",          mods = "LEADER",       action = wezterm.action.RotatePanes "Clockwise" },
    -- Tab keybindings
    { key = "t",          mods = "LEADER",       action = wezterm.action.SpawnTab("CurrentPaneDomain") },
    { key = "[",          mods = "LEADER",       action = wezterm.action.ActivateTabRelative(-1) },
    { key = "]",          mods = "LEADER",       action = wezterm.action.ActivateTabRelative(1) },
    { key = "n",          mods = "LEADER",       action = wezterm.action.ShowTabNavigator },
    { key = "Tab",        mods = "LEADER",       action = wezterm.action.ActivateLastTab },
    { key = "m",          mods = "LEADER",       action = wezterm.action.SpawnCommandInNewTab({ args = SSH_COMMAND }) },
    { key = "v",          mods = "LEADER",       action = wezterm.action.SpawnCommandInNewTab({ args = NVIM_COMMAND }) },
    { key = "s",          mods = "LEADER",       action = wezterm.action.SpawnCommandInNewTab({ args = SPOTIFY_COMMAND }) },
    { key = "w",          mods = "LEADER",       action = wezterm.action.SpawnCommandInNewTab({ args = {"wsl"} }) },
}

--> <leader><num> = move to tab <num>
for i = 1, 8 do
    table.insert(config.keys, {
        key = tostring(i),
        mods = "LEADER",
        action = wezterm.action.ActivateTab(i - 1)
    })
end

-- NOTE This is only useful if you replace tmux with wezterm fully
-- local smart_splits = wezterm.plugin.require('https://github.com/mrjones2014/smart-splits.nvim')
-- you can put the rest of your Wezterm config here
-- smart_splits.apply_to_config(config, {
--   -- the default config is here, if you'd like to use the default keys,
--   -- you can omit this configuration table parameter and just use
--   -- smart_splits.apply_to_config(config)
--
--   -- directional keys to use in order of: left, down, up, right
--   direction_keys = { 'h', 'j', 'k', 'l' },
--   -- modifier keys to combine with direction_keys
--   modifiers = {
--     move = 'CTRL', -- modifier to use for pane movement, e.g. CTRL+h to move left
--     resize = 'META', -- modifier to use for pane resize, e.g. META+h to resize to the left
--   },
-- })

config.enable_wayland = true;
return config
