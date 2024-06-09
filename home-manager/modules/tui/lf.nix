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

      fzf = ''
        ''${{
          res="$(find . -maxdepth 1 | fzf --reverse --header='Jump to location')"
          if [ -n "$res" ]; then
              if [ -d "$res" ]; then
                  cmd="cd"
              else
                  cmd="select"
              fi
              res="$(printf '%s' "$res" | sed 's/\\/\\\\/g;s/"/\\"/g')"
              lf -remote "send $id $cmd \"$res\""
          fi
        }}
      '';
    };
    extraConfig = ''
      cmd open-with-gui &$@ $fx
      cmd open-with-tui \$\$@ $fx
    '';

    keybindings = {
      a = "push %mkdir<space>";
      d = "delete";
      f = "fzf";
      gd = "cd ${config.xdg.userDirs.download}";
      o = "push :open-with-gui<space>";
      O = "push :open-with-tui<space>";
      P = "pager";
      t = "push %touch<space>";
      T = "";
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
