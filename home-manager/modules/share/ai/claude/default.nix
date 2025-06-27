#
# An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
# src: https://github.com/anthropics/claude-code
#

{
  # Installing via mise, in order to have latest version, as the CLI is
  # releasing every day...
  # home.packages = with pkgs; [ claude-code ];

  home.sessionVariables = {
    # Equivalent of setting DISABLE_AUTOUPDATER, DISABLE_BUG_COMMAND, DISABLE_ERROR_REPORTING, and DISABLE_TELEMETRY
    # src: https://docs.anthropic.com/en/docs/claude-code/settings#environment-variables
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
  };

  xdg.configFile."mise/conf.d/claude-code.toml".source = ./.config/mise/conf.d/claude-code.toml;
}
