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
        idiomatic_version_file_enable_tools = ["java"  "node"];
      };
    };
  };

  # Symlink ~/.config/zsh/
  xdg.configFile."zsh/completions/_mise".source = ./.config/zsh/completions/_mise;
  xdg.configFile."zsh/plugins/mise" = {
    source = ./.config/zsh/plugins/mise;
    recursive = true;
  };
}
