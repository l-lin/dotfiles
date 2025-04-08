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
  xdg.configFile."zsh/functions/refresh-fzf-opts".source = ./.config/zsh/functions/refresh-fzf-opts;

  # Symlink to ~/.config/zsh/zprofile.d/.zprofile.fzf.
  # Using colors defined in stylix: https://github.com/danth/stylix/blob/master/modules/fzf/hm.nix
  # Home-manager env variables are sourced only once. So to have the colors
  # updated, I have to execute `tmux kill-server`, which is not nice.
  # src: https://github.com/nix-community/home-manager/issues/3999
  xdg.configFile."zsh/zprofile.d/.zprofile.fzf".text = with palette; ''
export FZF_DEFAULT_OPTS="\
  --bind='alt-p:toggle-preview' \
  --bind='ctrl-d:half-page-down' \
  --bind='ctrl-u:half-page-up' \
  --bind='ctrl-f:preview-half-page-down' \
  --bind='ctrl-j:preview-down' \
  --bind='ctrl-k:preview-up' \
  --bind='ctrl-b:preview-half-page-up' \
  --preview-window='up:65%:border-bottom' \
  --layout=default \
  --tiebreak=chunk \
  --cycle \
  --no-scrollbar \
  --prompt='󰍉 ' \
  --header='A-p: toggle preview' \
  --color bg:${base00-hex},bg+:${base01-hex},fg:${base04-hex},fg+:${base06-hex},\
header:${base0D-hex},hl:${base0D-hex},hl+:${base0D-hex},info:${base0A-hex},\
marker:${base0C-hex},pointer:${base0A-hex},prompt:${base0A-hex},spinner:${base0C-hex}"
  '';
}
