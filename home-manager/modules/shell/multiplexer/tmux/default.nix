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

    # Easily extract content with `prefix + tab`.
    # There's some weird behavior when using extrakto with home-manager, especially if we want
    # to use a shell script instead of native `fzf` in order to source my `FZF_DEFAULT_OPTS`,
    # as suggested at https://github.com/laktak/extrakto/issues/78.
    # So we want to have it support in home-manager, no choice but to configure it the "nix-way":
    # https://github.com/laktak/extrakto/wiki/Nixos-Home%E2%80%90manager#passing-fzf-options
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.extrakto;
        extraConfig = let
          fzfExtrakto = pkgs.writeShellScriptBin "fzf.zsh" ''
            #!/usr/bin/env zsh
            source ~/.zshenv
            ${pkgs.fzf}/bin/fzf "$@"
          '';
        in ''
          set -g @extrakto_fzf_unset_default_opts true
          set -g @extrakto_editor '${userSettings.editor}'
          set -g @extrakto_split_direction 'p'
          set -g @extrakto_popup_size '60%'
          set -g @extrakto_copy_key 'tab'
          set -g @extrakto_insert_key 'enter'
          set -g @extrakto_clip_tool 'wl-copy'
          set -g @extrakto_fzf_tool "${fzfExtrakto}/bin/fzf.zsh"
        '';
      }
    ];

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
