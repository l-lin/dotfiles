#
# Kubernetes CLI To Manage Your Clusters In Style.
# src: https://github.com/derailed/k9s
#

{
  programs.k9s = {
    enable = true;
    # Need to set this manually, otherwise, k9s will not keep up Stylix theming.
    # src: https://github.com/danth/stylix/pull/232#issuecomment-2013546184
    settings.skin = "skin";
  };
}
