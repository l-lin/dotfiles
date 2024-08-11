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
    # NOTE: Do not forget to sync the version with the Firefox version provided by Floorp.
    rev = "115.0";
    sha256 = "sha256-g/8jfjPFTvml4QOGpNBJbxeqiakK+a+B/2MfjeMiF5I";
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
  home.packages = with pkgs; [ floorp ];

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
  # Symlink to ~/.mozilla/native-messaging-hosts.
  home.file."${nativeMessagingHostsPath}" = {
    source = "${nativeMessagingHostsJoined}/lib/mozilla/native-messaging-hosts";
    recursive = true;
  };
}
