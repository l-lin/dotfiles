#
# Vim-link navigation browser extension.
# src: https://tridactyl.xyz/
#

{ config, userSettings, ... }:
let
  theme = if (config.theme.polarity == "dark") then "kanagawa" else "github-light";
  vendorPath = if userSettings.browser == "floorp" then
    ".floorp"
  else
    ".mozilla/firefox";
  profileName = userSettings.username;
in {
  # Symlink to ~/.config/tridactyl/tridactylrc
  # Default keymaps: https://github.com/tridactyl/tridactyl/blob/8e4525a758dbf23c59af64f9ae3a5dacb633cb23/src/lib/config.ts#L132
  # To find what keymap is bind to, press :bindshow <your_keymap>
  xdg.configFile."tridactyl/tridactylrc".text = ''
" open nvim instead of default 'auto', which opens gvim (shortcut: Ctrl+i)
set editorcmd ${userSettings.term} -e nvim %f '+normal!%lGzv%c|'

" THEME
" The custom theme is in conflict with Dark Reader extension, i.e. display a huge ugly white rectangular behind tridactyl.
"colors ${theme}

" BINDS
" With vertical tabs, it's more intuitive to use J/K to navigate tabs instead.
bind K tabprev
bind J tabnext
bind H back
bind L forward

" UNBINDS
" With zen browser, this keymap is used to open web panel, and I don't often pin tabs.
unbind <A-p>

set profiledir ${config.home.homeDirectory}/${vendorPath}/${profileName}
  '';

  # Symlink to ~/.config/tridactyl/themes
  xdg.configFile."tridactyl/themes" = {
    source = ./.config/tridactyl/themes;
  };
}
