#
# AI pair programming in your terminal.
# src: https://github.com/paul-gauthier/aider
#

{ config, pkgs, userSettings, ... }:
let
  palette = config.lib.stylix.colors.withHashtag;
  aiderVersion = "0.83.1";
  codeTheme = if (config.theme.polarity == "dark") then "github-dark" else "solarized-light";
in {
  home.packages = with pkgs; [ aider-chat ];

  # Symlink ~/.config/zsh/functions/aider-convention-scraper.
  xdg.configFile."zsh/functions/aider-convention-scraper".source = ./.config/zsh/functions/aider-convention-scraper;

  # src: https://aider.chat/docs/config/aider_conf.html
  home.file.".aider.conf.yml".text = with palette; ''
#############
# Main model:

## Specify the model to use for the main chat
model: copilot/claude-3.7-sonnet

#################
# Model settings:

## Specify the model to use for commit messages and chat history summarization (default depends on --model)
weak-model: copilot/gpt-4o

## Add a model alias (can be used multiple times)
alias:
  - "fast:copilot/gpt-4o"
  - "code:copilot/claude-3.7-sonnet"
  - "think:copilot/claude-3.7-sonnet-thought"
  - "edge:copilot/claude-sonnet-4"

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

## Set the markdown code theme (default: default, other options include monokai, solarized-dark, solarized-light, or a Pygments builtin style, see https://pygments.org/styles for available themes)
code-theme: ${codeTheme}

############
# Analytics:

## Enable/disable analytics for current session (default: random)
analytics: true

#################
# Other settings:

## Use VI editing mode in the terminal (default: False)
vim: true

## Specify which editor to use for the /editor command
editor: ${userSettings.editor}
  '';

  home.file.".aider.model.settings.yml".text = ''
- name: copilot/claude-sonnet-4
  extra_params:
    model: openai/claude-sonnet-4
    api_base: https://api.githubcopilot.com
    extra_headers:
      Editor-Version: Aider/${aiderVersion}
      Copilot-Integration-Id: vscode-chat
    max_tokens: 64000
    max_input_tokens: 1048576
    max_output_tokens: 65536
- name: copilot/gpt-4o
  extra_params:
    model: openai/gpt-4o
    api_base: https://api.githubcopilot.com
    extra_headers:
      Editor-Version: Aider/${aiderVersion}
      Copilot-Integration-Id: vscode-chat
- name: copilot/claude-3.7-sonnet
  extra_params:
    model: openai/claude-3.7-sonnet
    api_base: https://api.githubcopilot.com
    extra_headers:
      Editor-Version: Aider/${aiderVersion}
      Copilot-Integration-Id: vscode-chat
- name: copilot/claude-3.7-sonnet-thought
  extra_params:
    model: openai/claude-3.7-sonnet-thought
    api_base: https://api.githubcopilot.com
    extra_headers:
      Editor-Version: Aider/${aiderVersion}
      Copilot-Integration-Id: vscode-chat
  '';
}
