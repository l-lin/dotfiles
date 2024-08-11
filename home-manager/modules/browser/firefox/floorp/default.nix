#
# A fork of Firefox, focused on keeping the Open, Private and Sustainable Web alive, built in Japan.
# src:
# - https://floorp.app/
# - https://github.com/yokoffing/Betterfox
#

{ pkgs, ... }:
let
  userJs = pkgs.fetchFromGitHub {
    owner = "yokoffing";
    repo = "Betterfox";
    # NOTE: Do not forget to sync the version with the Firefox version provided by Floorp.
    rev = "115.0";
    sha256 = "sha256-g/8jfjPFTvml4QOGpNBJbxeqiakK+a+B/2MfjeMiF5I";
  } + "/user.js";
in {
  home.packages = with pkgs; [ floorp ];

  # Symlinks to ~/.floorp.
  home.file.".floorp/profiles.ini".source = ./.floorp/profiles.ini;
  home.file.".floorp/default/user.js".text = ''
    ${builtins.readFile userJs}

    // Browser Manager Sidebar.
    user_pref("floorp.browser.sidebar.enable", false);
    user_pref("floorp.browser.sidebar.is.displayed", false);
    user_pref("floorp.browser.sidebar.right", false);
    user_pref("floorp.browser.sidebar.useIconProvider", "duckduckgo");

    // Manage floorp workspaces in Browser Manager Sidebar.
    user_pref("floorp.browser.workspace.manageOnBMS", true);

    // Rounded corners.
    user_pref("floorp.delete.browser.border", true);

    // Sleeping tabs.
    user_pref("floorp.tabsleep.excludeHosts", "app.slack.com,mail.google.com,mail.proton.me");
    user_pref("floorp.tabsleep.tabTimeoutMinutes", 20);

    // I don't use Floorp Notes, so no need to sync.
    user_pref("services.sync.prefs.sync.floorp.browser.note.memos", false);

    // Ctrl+Tab cycles through tabs in recently used order.
    user_pref("browser.ctrlTab.sortByRecentlyUsed", true);

    // Do not show search bar in new tabs.
    user_pref("browser.newtabpage.activity-stream.showSearch", false);
  '';
}
