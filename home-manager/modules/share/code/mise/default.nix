#
# The front-end to your dev env
# src: https://mise.jdx.dev/
#

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    # src: https://mise.jdx.dev/configuration.html#global-config-config-mise-config-toml
    globalConfig = {
      # Dev tools to install globally.
      tools = {
        # Specification for CLI: https://usage.jdx.dev/.
        usage = "2.0.7";
      };
      settings = {
        trusted_config_paths = ["~/work" "~/perso"];
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
