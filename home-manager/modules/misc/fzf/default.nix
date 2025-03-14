#
# Command-line fuzzy finder.
# src: https://github.com/junegunn/fzf
#

{
  programs.fzf = {
    enable = true;

    defaultOptions = [
      "--bind='?:toggle-preview'"
      "--bind='alt-p:toggle-preview-wrap'"
      "--bind='ctrl-d:half-page-down'"
      "--bind='ctrl-u:half-page-up'"
      "--bind='ctrl-f:preview-half-page-down'"
      "--bind='ctrl-j:preview-down'"
      "--bind='ctrl-k:preview-up'"
      "--bind='ctrl-b:preview-half-page-up'"
      "--preview-window='up:65%:border-bottom'"
      "--layout=reverse"
      "--tiebreak=chunk"
      "--cycle"
      "--no-scrollbar"
      "--prompt='󰍉 '"
      "--header='?: toggle preview | A-p: toggle preview wrap'"
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
}
