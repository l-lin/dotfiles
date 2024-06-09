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
      fzf_search = ''
        ''${{
            RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
            res="$(
                FZF_DEFAULT_COMMAND="$RG_PREFIX \'\'" \
                    fzf --bind "change:reload:$RG_PREFIX {q} || true" \
                    --ansi --layout=reverse --header 'Search in files' \
                    | cut -d':' -f1 | sed 's/\\/\\\\/g;s/"/\\"/g'
            )"
            [ -n "$res" ] && lf -remote "send $id select \"$res\""
        }}
      '';

      pager = ''
        ''${{
          bat --paging=always "$f"
        }}
      '';

      paste = ''
        &{{
            set -- $(cat ~/.local/share/lf/files)
            mode="$1"
            shift
            case "$mode" in
                copy)
                    rsync -av --ignore-existing --progress -- "$@" . |
                    stdbuf -i0 -o0 -e0 tr '\r' '\n' |
                    while IFS= read -r line; do
                        lf -remote "send $id echo $line"
                    done
                    ;;
                move) mv -n -- "$@" .;;
            esac
            rm ~/.local/share/lf/files
            lf -remote "send clear"
        }}
      '';
    };

    keybindings = {
      a = "push %mkdir<space>";
      d = "delete";
      f = "fzf_search";
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
