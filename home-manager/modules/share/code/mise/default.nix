#
# The front-end to your dev env
# src: https://mise.jdx.dev/
#

{
  programs.mise = {
    enable = true;
    # src: https://mise.jdx.dev/configuration.html#global-config-config-mise-config-toml
    globalConfig = {
      # Dev tools to install globally.
      # To know the version, you can use the command `mise ls-remote <tool>`.
      # NOTE: Each tool must register themselves by creating a
      # $XDG_CONFIG_HOME/mise/conf.d/<tool>.toml file.
      tools = {
      };
      settings = {
        # Enable experimental if you want to use the golang backend to install 3rd party tools.
        experimental = true;
        trusted_config_paths = ["~/work" "~/perso"];
        # Tools can read the versions files used by other version managers
        # for example, .nvmrc in the case of node's nvm.
        idiomatic_version_file_enable_tools = ["java"  "node" "ruby"];
      };
    };
  };

  home.sessionVariables = {
    # print only stdout/stderr from tasks and nothing from mise
    # src: https://mise.jdx.dev/configuration/settings.html#task_output
    MISE_TASK_OUTPUT = "quiet";
  };
  xdg.configFile = {
    "zsh/completions/_mise".source = ./.config/zsh/completions/_mise;
    "zsh/plugins/mise" = {
      source = ./.config/zsh/plugins/mise;
      recursive = true;
    };
    "mise/conf.d/mise.toml".source = ./.config/mise/conf.d/mise.toml;
  };
}
