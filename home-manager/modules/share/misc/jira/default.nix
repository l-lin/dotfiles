#
# Feature-rich interactive Jira command line.
# src: https://github.com/ankitpokhrel/jira-cli
#

{ pkgs, ... }: {
  home = {
    packages = with pkgs; [ jira-cli-go ];

    file.".claude/skills/jira/SKILL.md".source = ./.config/ai/skills/jira/SKILL.md;
  };

  xdg.configFile = {
    "zsh/completions/_jira".source = ./.config/zsh/completions/_jira;
    "zsh/functions/open-jira-ticket".source = ./.config/zsh/functions/open-jira-ticket;
  };
}
