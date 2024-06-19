#
# Terminal multiplexer
#
# src: https://github.com/tmux/tmux/wiki
#

{ pkgs, userSettings, ...}: {
  programs.tmux = {
    enable = true;
    # Cannot set the shell directly in the tmux.conf file as the binary is not in /bin folder.
    shell = "${pkgs.zsh}/bin/zsh";
    extraConfig = ''
      ${builtins.readFile ./config/tmux.conf}
    '';
  };

  # Symlinks to ~/.config/tmux/
  xdg.configFile."tmux/plugins.conf".source = ./config/plugins.conf;
  xdg.configFile."tmux/colorscheme.conf".text = ''
# Colorscheme (must be set before other plugins)
set -g @plugin 'l-lin/tmux-colorscheme'
set -g @tmux-colorscheme '${userSettings.theme}'
set -g @tmux-colorscheme-show-pomodoro true
set -g @tmux-colorscheme-show-upload-speed true
set -g @tmux-colorscheme-show-download-speed true
set -g @tmux-colorscheme-show-prefix-highlight true
set -g @tmux-colorscheme-show-battery true
set -g @tmux-colorscheme-show-cpu true
set -g @tmux-colorscheme-show-cpu-temp true
set -g @tmux-colorscheme-show-ram true
  '';
}
