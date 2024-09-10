#
# A fork of Firefox, focused on keeping the Open, Private and Sustainable Web alive, built in Japan.
# src:
# - https://floorp.app/
# - https://github.com/yokoffing/Betterfox
#

{ pkgs, userSettings, ... }:
let
  userJs = pkgs.fetchFromGitHub {
    owner = "yokoffing";
    repo = "Betterfox";
    # WARN: Do not forget to sync the version with the Firefox version provided by Floorp
    # at https://github.com/Floorp-Projects/Floorp/blob/ESR128/browser/config/version.txt.
    rev = "128.0";
    sha256 = "sha256-Xbe9gHO8Kf9C+QnWhZr21kl42rXUQzqSDIn99thO1kE=";
  } + "/user.js";
  profileName = userSettings.username;

  # Native messaging hosts installation.
  # I think floorp still does not override native messaging hosts, so add-on like tridactyl is still
  # trying to read from `~/.mozilla/native-messaging-hosts`.
  vendorPath = if isDarwin then
    "Library/Application Support/Mozilla"
  else
    ".mozilla";
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  nativeMessagingHostsPath = if isDarwin then
    "${vendorPath}/NativeMessagingHosts"
  else
    "${vendorPath}/native-messaging-hosts";
  nativeMessagingHostsJoined = pkgs.symlinkJoin {
    name = "floorp_native-messaging-hosts";
    paths = [
      # Link a .keep file to keep the directory around.
      (pkgs.writeTextDir "lib/mozilla/native-messaging-hosts/.keep" "")
      # Link package configured native messaging hosts (entire browser actually).
      pkgs.floorp
    ]
      # Link user configured native messaging hosts.
      ++ [ pkgs.tridactyl-native ];
  };
in {
  # BUG: floorp from home-manager has some issue with WebGL!
  home.packages = with pkgs; [ floorp ];
  #home.packages = [ outputs.packages.${systemSettings.system}.floorp ];

  # Symlinks to ~/.floorp.
  home.file.".floorp/profiles.ini".text = ''
[Profile0]
Name=${profileName}
IsRelative=1
Path=${profileName}
Default=1

[General]
StartWithLastProfile=1
Version=2
  '';
  home.file.".floorp/${profileName}/user.js".text = ''
    ${builtins.readFile userJs}

    /******************************************************************************
      * SECTION: BROWSER                                                         *
    ******************************************************************************/

    // Ctrl+Tab cycles through tabs in recently used order.
    user_pref("browser.ctrlTab.sortByRecentlyUsed", true);

    // Do not show search bar in new tabs.
    user_pref("browser.newtabpage.activity-stream.showSearch", false);

    // Do not show warning when going to about:config.
    user_pref("browser.aboutConfig.showWarning", false);

    /******************************************************************************
     * SECTION: HTTPS-ONLY MODE                                                  *
    ******************************************************************************/

    // PREF: enable HTTPS-only Mode
    // Private Browsing only
    user_pref("dom.security.https_only_mode", true);

    // PREF: HTTP background requests in HTTPS-only Mode
    // When attempting to upgrade, if the server doesn't respond within 3 seconds[=default time],
    // Firefox sends HTTP requests in order to check if the server supports HTTPS or not.
    // This is done to avoid waiting for a timeout which takes 90 seconds.
    // Firefox only sends top level domain when falling back to http.
    // [WARNING] Disabling causes long timeouts when no path to HTTPS is present.
    // [NOTE] Use "Manage Exceptions" for sites known for no HTTPS.
    // [1] https://bugzilla.mozilla.org/buglist.cgi?bug_id=1642387,1660945
    // [2] https://blog.mozilla.org/attack-and-defense/2021/03/10/insights-into-https-only-mode/
    user_pref("dom.security.https_only_mode_send_http_background_request", false);

    /******************************************************************************
      * SECTION: FLOORP                                                          *
    ******************************************************************************/

    // Browser Manager Sidebar.
    user_pref("floorp.browser.sidebar.enable", false);
    user_pref("floorp.browser.sidebar.is.displayed", false);
    user_pref("floorp.browser.sidebar.right", false);
    user_pref("floorp.browser.sidebar.useIconProvider", "duckduckgo");

    // Manage floorp workspaces in Browser Manager Sidebar.
    user_pref("floorp.browser.workspace.manageOnBMS", true);

    // Rounded corners.
    user_pref("floorp.delete.browser.border", false);

    // Sleeping tabs.
    user_pref("floorp.tabsleep.excludeHosts", "app.slack.com,mail.google.com,mail.proton.me");
    user_pref("floorp.tabsleep.enabled", true);
    user_pref("floorp.tabsleep.tabTimeoutMinutes", 60);

    // I don't use Floorp Notes, so no need to sync.
    user_pref("services.sync.prefs.sync.floorp.browser.note.memos", false);

    // Homepage: display unsplash.
    user_pref("browser.newtabpage.activity-stream.floorp.background.type", 1);
    user_pref("browser.newtabpage.activity-stream.floorp.newtab.imagecredit.hide", true);
    user_pref("browser.newtabpage.activity-stream.floorp.newtab.releasenote.hide", true);

    // Open new tabs next to the current tab.
    user_pref("floorp.browser.tabs.openNewTabPosition", 1);

  '';
  # Symlink to ~/.mozilla/native-messaging-hosts.
  home.file."${nativeMessagingHostsPath}" = {
    source = "${nativeMessagingHostsJoined}/lib/mozilla/native-messaging-hosts";
    recursive = true;
  };
}
