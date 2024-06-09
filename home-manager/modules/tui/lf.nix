#
# Terminal file manager.
# src: https://godoc.org/github.com/gokcehan/lf
#

{ config, inputs, pkgs, userSettings, ...}: {
  programs.lf = {
    enable = true;
    settings = {
      icons = true;
      shell = userSettings.shell;
    };

    # options: https://github.com/gokcehan/lf/blob/master/doc.md
    commands = {
      pager = ''
        ''${{
          bat --paging=always "$f"
        }}
      '';
    };

    keybindings = {
      a = "push %mkdir<space>";
      d = "delete";
      gd = "cd ${config.xdg.userDirs.download}";
      o = "open";
      O = "pager";
      t = "push %touch<space>";
      # Open terminal at current directory
      T = "push %${userSettings.term}<enter>";
      x = "cut";
      "<enter>" = "open";
    };

    previewer.source = pkgs.writeShellScript "lf-previewer.sh" ''
      file=$1
      case "$file" in
          *.tar*) tar tf "$file";;
          *.zip) unzip -l "$file";;
          *) bat --color=always --plain "$file";;
      esac
    '';
  };

  # Add icons.
  xdg.configFile."lf/icons".source = "${inputs.lf-icons}/etc/icons.example";
}
