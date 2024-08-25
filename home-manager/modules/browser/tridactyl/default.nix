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
  xdg.configFile."tridactyl/tridactylrc".text = ''
" open nvim instead of default 'auto', which opens gvim (shortcut: Ctrl+i)
set editorcmd ${userSettings.term} -e nvim %f '+normal!%lGzv%c|'

" theme
colors ${theme}

" binds
" With vertical tabs, it's more intuitive to use J/K to navigate tabs instead.
"bind H tabprev
"bind L tabnext
"bind J back
"bind K forward

set profiledir ${config.home.homeDirectory}/${vendorPath}/${profileName}
  '';

  # Symlink to ~/.config/tridactyl/themes
  xdg.configFile."tridactyl/themes" = {
    source = ./.config/tridactyl/themes;
  };
}
