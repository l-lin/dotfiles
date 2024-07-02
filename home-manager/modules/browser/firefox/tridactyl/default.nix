#
# Vim-link navigation browser extension.
# src: https://tridactyl.xyz/
#

{ config, pkgs, userSettings, ... }:
let
  theme = if (config.theme.polarity == "dark") then "kanagawa" else "github-light";
in {
  # Symlink to ~/.config/tridactyl/tridactylrc
  xdg.configFile."tridactyl/tridactylrc".text = ''
" open nvim instead of default 'auto', which opens gvim (shortcut: Ctrl+i)
set editorcmd ${userSettings.term} -e nvim %f '+normal!%lGzv%c|'

" theme
colors ${theme}

" binds
bind H tabprev
bind L tabnext
bind J back
bind K forward
  '';

  # Symlink to ~/.config/tridactyl/themes
  xdg.configFile."tridactyl/themes" = {
    source = ./.config/tridactyl/themes;
  };

  programs.firefox = {
    # Need to install tridactyl-native in order to use ~/.config/tridactyl/.tridactylrc
    nativeMessagingHosts = with pkgs; [
      tridactyl-native
    ];
  };
}
