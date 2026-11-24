#
# The front-end to your dev env
# src: https://mise.jdx.dev/
#

{ config, symlinkRoot, ...}: {

  xdg.configFile."mise/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${symlinkRoot}/home-manager/modules/share/code/mise/.config/mise/config.toml";

  home.sessionVariables = {
    # print only stdout/stderr from tasks and nothing from mise
    # src: https://mise.jdx.dev/configuration/settings.html#task_output
    MISE_TASK_OUTPUT = "interleave";
  };
  xdg.configFile = {
    "zsh/completions/_mise".source = ./.config/zsh/completions/_mise;
    "zsh/plugins/mise" = {
      source = ./.config/zsh/plugins/mise;
      recursive = true;
    };
  };
}
