#
# Terminal file manager.
# src: https://godoc.org/github.com/gokcehan/lf
#

{ inputs, pkgs, ...}: {
  programs.lf = {
    enable = true;
    settings = {
      icons = true;
    };
    # options: https://github.com/gokcehan/lf/blob/master/doc.md
    commands = {
      open = ''
        ''${{
          case $(file --mime-type -Lb $f) in
              text/*) lf -remote "send $id \$$EDITOR \$fx";;
              *) for f in $fx; do xdg-open "$f" > /dev/null 2> /dev/null & done;;
          esac
        }}
      '';

      pager = ''
        ''${{
        bat --paging=always "$f"
        }}
      '';
    };
    keybindings = {
      a = "push %mkdir<space>";
      d = "delete";
      f = "fzf";
      o = "open";
      O = "pager";
      t = "push %touch<space>";
      x = "cut";
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
