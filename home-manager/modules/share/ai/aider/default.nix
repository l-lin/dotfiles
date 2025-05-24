#
# AI pair programming in your terminal.
# src: https://github.com/paul-gauthier/aider
#

{ config, pkgs, userSettings, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
in {
  home.packages = with pkgs; [ aider-chat ];

  # Symlink ~/.config/zsh/functions/aider-convention-scraper.
  xdg.configFile."zsh/functions/aider-convention-scraper".source = ./.config/zsh/functions/aider-convention-scraper;

  # src: https://aider.chat/docs/config/aider_conf.html
  home.file.".aider.conf.yml".text = with palette; ''
#############
# Main model:

model: copilot/claude-sonnet-4

#################
# Model settings:

## Only work with models that have meta-data available (default: True)
show-model-warnings: false

##################
# Output settings:

## Set the color for user input (default: #00cc00)
user-input-color: "${base05-hex}"

## Set the color for tool error messages (default: #FF2222)
tool-error-color: "${base08-hex}"

## Set the color for tool warning messages (default: #FFA500)
tool-warning-color: "${base0A-hex}"

## Set the color for assistant output (default: #0088ff)
assistant-output-color: "${base0D-hex}"

############
# Analytics:

## Permanently disable analytics
analytics-disable: true

#################
# Other settings:

## Use VI editing mode in the terminal (default: False)
vim: true

## Enable/disable multi-line input mode with Meta-Enter to submit (default: False)
multiline: true

## Specify which editor to use for the /editor command
editor: ${userSettings.editor}
  '';

  home.file.".aider.model.settings.yml".text = ''
- name: copilot/claude-sonnet-4
  extra_params:
    model: openai/claude-sonnet-4
    api_base: https://api.githubcopilot.com
    extra_headers:
      Editor-Version: Aider/0.83.1
      Copilot-Integration-Id: vscode-chat
    max_tokens: 64000
    max_input_tokens: 1048576
    max_output_tokens: 65536
  '';
}
