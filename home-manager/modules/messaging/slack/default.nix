#
# Desktop client for Slack.
# src: https://slack.com/
#

{ pkgs, ... }: {
  home.packages = with pkgs; [ slack ];
}
