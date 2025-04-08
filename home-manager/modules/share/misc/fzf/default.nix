#
# Command-line fuzzy finder.
# src: https://github.com/junegunn/fzf
#

{ config, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
  programs.fzf = {
    enable = true;

    defaultOptions = [
      "--bind='alt-p:toggle-preview'"
      "--bind='ctrl-d:half-page-down'"
      "--bind='ctrl-u:half-page-up'"
      "--bind='ctrl-f:preview-half-page-down'"
      "--bind='ctrl-j:preview-down'"
      "--bind='ctrl-k:preview-up'"
      "--bind='ctrl-b:preview-half-page-up'"
      "--preview-window='up:65%:border-bottom'"
      "--layout=default"
      "--tiebreak=chunk"
      "--cycle"
      "--no-scrollbar"
      "--prompt='󰍉 '"
      "--header='A-p: toggle preview'"
      "--color=$(cat ${config.xdg.dataHome}/fzf/colorscheme)"
    ];

    # Find file with CTRL-G (set in fzf.plugins.zsh).
    # FZF_ALT_C_COMMAND
    fileWidgetCommand = "fd --type f --hidden --exclude .git";
    # FZF_CTRL_T_OPTS
    fileWidgetOptions = [ "--no-reverse --preview 'bat --style changes --color \"always\" {} | head -200'" ];

    # Change directory with ALT-C.
    # FZF_ALT_C_COMMAND
    changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
    # FZF_ALT_C_OPTS
    changeDirWidgetOptions = [ "--no-reverse --sort --preview 'tree -C {} | head -200'" ];

    tmux.shellIntegrationOptions = [ "-p 90%,90%" ];
  };

  # Symlink ~/.config/zsh/plugins/fzf/
  xdg.configFile."zsh/plugins/fzf" = {
    source = ./.config/zsh/plugins/fzf;
    recursive = true;
  };

  # Symlink to ~/.local/share/fzf/colorscheme.
  # Putting FZF colors in a file, then have FZF_DEFAULT_OPTS to read this file,
  # so that when I'm switching the theme, fzf will use the new colors automatically.
  # Using stylix colors: https://github.com/danth/stylix/blob/master/modules/fzf/hm.nix
  xdg.dataFile."fzf/colorscheme".text = with palette; ''
bg:${base00-hex},bg+:${base01-hex},fg:${base04-hex},fg+:${base06-hex},header:#${base0D-hex},hl:${base0D-hex},hl+:${base0D-hex},info:${base0A-hex},marker:${base0C-hex},pointer:${base0A-hex},prompt:${base0A-hex},spinner:${base0C-hex}
  '';
}
