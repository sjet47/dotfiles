local wezterm = require("wezterm")
local act = wezterm.action

local key_tables = {
  new_pane = {
    { key = 'h', action = act.SplitHorizontal { args = { 'zsh' } } },
    { key = 'l', action = act.SplitHorizontal { args = { 'zsh' } } },
    { key = 'k', action = act.SplitVertical { args = { 'zsh' } } },
    { key = 'j', action = act.SplitVertical { args = { 'zsh' } } },
    -- Cancel the mode by pressing escape
    { key = 'Escape', action = 'PopKeyTable' },
  },

  resize_pane = {
    { key = 'h', action = act.AdjustPaneSize { 'Left', 1 } },
    { key = 'l', action = act.AdjustPaneSize { 'Right', 1 } },
    { key = 'k', action = act.AdjustPaneSize { 'Up', 1 } },
    { key = 'j', action = act.AdjustPaneSize { 'Down', 1 } },
    -- Cancel the mode by pressing escape
    { key = 'Escape', action = 'PopKeyTable' },
  },
}

local keys = {
  {
    key = 'n', mods = 'LEADER', action = act.ActivateKeyTable {
      name = 'new_pane',
      one_shot = false,
    },
  },
  {
    key = 'r', mods = 'LEADER', action = act.ActivateKeyTable {
      name = 'resize_pane',
      one_shot = false,
    },
  },

  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },

  {
    key = 'c',
    mods = 'LEADER',
    action = act.ClearScrollback 'ScrollbackOnly',
  },

  {
    key = 's',
    mods = 'LEADER',
    action = act.PaneSelect {},
  },

  {
    key = 'Space',
    mods = 'LEADER',
    action = act.QuickSelectArgs {},
  },
}

-- Reassign tab to ALT <tab_num>
for i = 1, 8 do
  -- ALT + number to activate that tab
  table.insert(keys, {
    key = tostring(i),
    mods = 'ALT',
    action = act.ActivateTab(i - 1),
  })
end

wezterm.on('update-right-status', function(window, pane)
  -- "Wed Mar 3 08:14"
  local date = wezterm.strftime '%a %b %-d %H:%M '
  local leader = ''
  local bat = ''

  -- Display battery status on right-status
  for _, b in ipairs(wezterm.battery_info()) do
    bat = '🔋 ' .. string.format('%.0f%%', b.state_of_charge * 100)
  end

  -- Display "LEADER" on right-status when pressed leader key
  if window:leader_is_active() then
    leader = 'LEADER'
  end

  window:set_right_status(wezterm.format {
    { Text = leader .. ' ' .. bat .. ' ' .. wezterm.nerdfonts.mdi_clock .. ' ' .. date },
  })
end)

-- System notification when reload config(FIXME won't auto dispear)
-- wezterm.on('window-config-reloaded', function(window, pane)
--   window:toast_notification('wezterm', 'configuration reloaded', nil, 1000)
-- end)

-- Disable because too many noise
-- wezterm.on('bell', function(window, pane)
--   window:toast_notification('wezterm', 'Bell at Pane@' .. pane:pane_id(), nil, 1000)
-- end)

return {
  leader = { key = 'k', mods = 'CTRL' },
  keys = keys,
  key_tables = key_tables,

  -- After pressed leader key, the cursor will become orange
  colors = {
    compose_cursor = 'orange',
  },

  font_size = 11.5,
  font = wezterm.font_with_fallback {
    'JetBrains Mono',
    'Apple Color Emoji',
    'Noto Sans CJK SC',
  },

  quick_select_patterns = {
    -- match things that look like sha1 hashes
    -- (this is actually one of the default patterns)
    '[0-9a-f]{7,40}',
  },

  audible_bell = "SystemBeep",

  window_background_opacity = 0.85,
  text_background_opacity = 1.0,

  enable_scroll_bar = true,
  scrollback_lines = 10000,

  hyperlink_rules = {
    -- Linkify things that look like URLs and the host has a TLD name.
    -- Compiled-in default. Used if you don't specify any hyperlink_rules.
    {
      regex = '\\b\\w+://[\\w.-]+\\.[a-z]{2,15}\\S*\\b',
      format = '$0',
    },

    -- linkify email addresses
    -- Compiled-in default. Used if you don't specify any hyperlink_rules.
    {
      regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
      format = 'mailto:$0',
    },

    -- file:// URI
    -- Compiled-in default. Used if you don't specify any hyperlink_rules.
    {
      regex = [[\bfile://\S*\b]],
      format = '$0',
    },

    -- Linkify things that look like URLs with numeric addresses as hosts.
    -- E.g. http://127.0.0.1:8000 for a local development server,
    -- or http://192.168.1.1 for the web interface of many routers.
    {
      regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]],
      format = '$0',
    },

    -- Make task numbers clickable
    -- The first matched regex group is captured in $1.
    {
      regex = [[\b[tT](\d+)\b]],
      format = 'https://example.com/tasks/?t=$1',
    },

    -- Make username/project paths clickable. This implies paths like the following are for GitHub.
    -- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
    -- As long as a full URL hyperlink regex exists above this it should not match a full URL to
    -- GitHub or GitLab / BitBucket (i.e. https://gitlab.com/user/project.git is still a whole clickable URL)
    {
      regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
      format = 'https://www.github.com/$1/$3',
    },
  },
}
