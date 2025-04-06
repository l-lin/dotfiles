#
# Terminal multiplexer
#
# src: https://github.com/tmux/tmux/wiki
#

{ config, pkgs, userSettings, ...}:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
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
          set -g @extrakto_clip_tool '$COPY_TO_CLIPBOARD'
          set -g @extrakto_fzf_tool "${fzfExtrakto}/bin/fzf.zsh"
        '';
      }
    ];

    extraConfig = ''
      ${builtins.readFile ./.config/tmux/tmux.conf}
    '';
  };

  # Symlinks to ~/.config/tmux/
  xdg.configFile."tmux/plugins.conf".source = ./.config/tmux/plugins.conf;
  xdg.configFile."tmux/colorscheme.conf".text = ''
# Colorscheme (must be set before other plugins)
set -g @plugin 'l-lin/tmux-colorscheme'
set -g @tmux-colorscheme 'home-manager'
set -g @tmux-colorscheme-show-pomodoro true
set -g @tmux-colorscheme-show-upload-speed false
set -g @tmux-colorscheme-show-download-speed false
set -g @tmux-colorscheme-show-prefix-highlight true
set -g @tmux-colorscheme-show-battery false
set -g @tmux-colorscheme-show-cpu false
set -g @tmux-colorscheme-show-cpu-temp false
set -g @tmux-colorscheme-show-ram false
set -g @tmux-colorscheme-show-date false
  '';
  xdg.configFile."zsh/functions/switch-tmux-window".source = ./.config/zsh/functions/switch-tmux-window;
  xdg.configFile."tmux/tpm.conf".source = ./.config/tmux/tpm.conf;
  xdg.dataFile."tmux/tmux-colorscheme/home-manager.tmuxtheme".text = with palette; ''
theme_bg='${base00-hex}'
theme_fg='${base05-hex}'
theme_black='${base04-hex}'
theme_red='${base08-hex}'
theme_green='${base0B-hex}'
theme_yellow='${base0A-hex}'
theme_blue='${base0D-hex}'
theme_magenta='${base0E-hex}'
theme_cyan='${base0C-hex}'
theme_white='${base05-hex}'
theme_gray='${base04-hex}'
theme_accent='${base0D-hex}'
theme_accent_bg='${base0D-hex}'
theme_accent_fg='${base01-hex}'
theme_alt_bg='${base01-hex}'
theme_search_match_bg='${base0D-hex}'
theme_search_match_fg='${base00-hex}'
  '';

  home.packages = with pkgs; [
    # Tmux end-of-line is behaving like VIM, i.e. taking the trailing newline.
    # I don't want that, no need to suffer each time I want to copy a line without this newline.
    (writeShellScriptBin "tmux-end-of-line" ''
      tmux send -X end-of-line
      tmux send -X cursor-left
    '')
  ];
}
