-- WezTerm config - symlinked from $DOTFILES/wezterm/wezterm.lua
-- Docs: https://wezfurlong.org/wezterm/config/files.html

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Appearance
config.color_scheme = 'Tokyo Night'
-- Cascadia Code matches the Windows Terminal default - installed by install.sh
-- from assets/fonts/cascadia-code/ so it's reproducible on every machine.
-- Symbols Nerd Font Mono fills in the Nerd Font glyphs (eza --icons, etc)
-- that Cascadia doesn't cover; shipped from assets/fonts/symbols-nerd-font/.
config.font = wezterm.font_with_fallback {
  'Cascadia Code',
  'Symbols Nerd Font Mono',
  'JetBrains Mono', -- common fallback
  'Menlo',          -- macOS-native fallback
}
config.font_size = 13.0
config.line_height = 1.1
config.window_background_opacity = 0.98
config.macos_window_background_blur = 20

-- Tab bar - kept visible so the integrated window buttons (and a draggable
-- area) are always there to grab. The fancy bar is needed for INTEGRATED_BUTTONS.
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false

-- Keybinds, because I like to paste
config.keys = {
  -- Paste from system clipboard using CTRL + V
  { key = 'v', mods = 'CTRL', action = wezterm.action.PasteFrom 'Clipboard' }
}

-- Window - no traditional title bar, but the tab strip hosts the
-- minimize/maximize/close buttons and gives us a drag target. Resize edges
-- still active.
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_padding = { left = 8, right = 8, top = 4, bottom = 4 }
config.initial_cols = 140
config.initial_rows = 40

-- Scrollback
config.scrollback_lines = 50000

-- Cross-platform default shell
-- WSL on Windows, zsh elsewhere
if wezterm.target_triple:find('windows') then
  config.default_domain = 'WSL:Ubuntu'
  -- New tabs otherwise inherit the Windows cwd (C:\Users\...). Force WSL $HOME.
  local wsl_domains = wezterm.default_wsl_domains()
  for _, dom in ipairs(wsl_domains) do
    dom.default_cwd = '/home/jgreen'
  end
  config.wsl_domains = wsl_domains
else
  config.default_prog = { '/bin/zsh', '-l' }
end

-- Sensible defaults: disable bell, ligatures on
config.audible_bell = 'Disabled'
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

return config
