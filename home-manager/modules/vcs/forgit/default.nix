#
# 💤 A utility tool powered by fzf for using git interactively.
# src: https://github.com/wfxr/forgit
#

{
  home.sessionVariables = {
    FORGIT_COPY_CMD = "xsel -b";
    FORGIT_FZF_DEFAULT_OPTS = "--no-reverse --header '?: toogle preview | C-y: yank commit hash | (S-)Tab: mark | C-r: toggle selection | A-(k/j): move preview up/down | A-e: edit file'";
  };

  # Symlink ~/.config/zsh/plugins/forgit
  xdg.configFile."zsh/plugins/forgit" = {
    source = ./.config/zsh/plugins/forgit;
    recursive = true;
  };
}
