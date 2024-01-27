function configure_fzf

    # --------------------------------------------------------
    # FZF options
    # --------------------------------------------------------
    set --global FZF_THEME_BG '#1f1f28'
    set --global FZF_THEME_FG '#dcd7ba'
    set --global FZF_THEME_BLACK '#090618'
    set --global FZF_THEME_RED '#c34043'
    set --global FZF_THEME_GREEN '#76946a'
    set --global FZF_THEME_YELLOW '#c0a36e'
    set --global FZF_THEME_BLUE '#7e9cd8'
    set --global FZF_THEME_MAGENTA '#957fb8'
    set --global FZF_THEME_CYAN '#6a9589'
    set --global FZF_THEME_WHITE '#c8c093'
    set --global FZF_THEME_GRAY '#727169'
    set --global FZF_THEME_ACCENT '#7e9cd8'

    set --global FZF_THEME "\
        --color=bg:$FZF_THEME_BG \
        --color=hl:$FZF_THEME_ACCENT \
        --color=fg:$FZF_THEME_FG \
        --color=fg+:bold:$FZF_THEME_FG \
        --color=bg+:$FZF_THEME_BG \
        --color=hl+:$FZF_THEME_ACCENT \
        --color=gutter:$FZF_THEME_BG \
        --color=info:$FZF_THEME_GRAY \
        --color=separator:$FZF_THEME_ACCENT \
        --color=border:$FZF_THEME_GRAY \
        --color=label:$FZF_THEME_RED \
        --color=prompt:$FZF_THEME_RED \
        --color=spinner:$FZF_THEME_GRAY \
        --color=pointer:bold:$FZF_THEME_RED \
        --color=marker:$FZF_THEME_RED \
        --color=header:$FZF_THEME_RED \
        --color=preview-fg:$FZF_THEME_FG \
        --color=preview-bg:$FZF_THEME_BG \
        --no-scrollbar \
        --prompt='󰍉 ' \
        "
    set --global FZF_DEFAULT_OPTS "\
        --bind='?:toggle-preview' \
        --bind='alt-p:toggle-preview-wrap' \
        --preview-window='right:40%:border-none' \
        --tiebreak=chunk \
        --cycle \
        $FZF_THEME \
        "
    set --global FZF_TMUX_OPTS "-p 90%,90%"
    # preview content of the file under the cursor when searching for a file
    set --global FZF_CTRL_G_OPTS "--no-reverse --preview 'bat --style changes --color=always {} | head -50'"
    # preview full command
    set --global FZF_CTRL_R_OPTS "--preview 'echo {}' --preview-window down:5:wrap"
    # show the entries of the directory
    set --global FZF_ALT_C_OPTS "--no-reverse --sort --preview 'tree -C  | head -200'"
    # display hidden files with CTRL-T command
    set --global FZF_CTRL_G_COMMAND "fd --type f --hidden --exclude .git"
    # display hidden folders with ATL-C command
    set --global FZF_ALT_C_COMMAND "fd --type d --hidden --exclude .git"

    fzf_key_bindings
end

# ------------
# - $FZF_TMUX_OPTS
# - $FZF_CTRL_G_COMMAND
# - $FZF_CTRL_G_OPTS
# - $FZF_CTRL_R_OPTS
# - $FZF_ALT_C_COMMAND
# - $FZF_ALT_C_OPTS
# From https://github.com/junegunn/fzf/blob/76cf6559ccaa6262d47a95fe3b1dfae053047cbd/shell/key-bindings.fish
# ------------
function fzf_key_bindings

  # Store current token in $dir as root for the 'find' command
  function fzf-file-widget -d "List files and folders"
    set -l commandline (__fzf_parse_commandline)
    set -l dir $commandline[1]
    set -l fzf_query $commandline[2]
    set -l prefix $commandline[3]

    # "-path \$dir'*/.*'" matches hidden files/folders inside $dir but not
    # $dir itself, even if hidden.
    test -n "$FZF_CTRL_G_COMMAND"; or set -l FZF_CTRL_G_COMMAND "
    command find -L \$dir -mindepth 1 \\( -path \$dir'*/.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | sed 's@^\./@@'"

    test -n "$FZF_TMUX_HEIGHT"; or set FZF_TMUX_HEIGHT 40%
    begin
      set -lx FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT --reverse --scheme=path --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_CTRL_G_OPTS"
      eval "$FZF_CTRL_G_COMMAND | "(__fzfcmd)' -m --query "'$fzf_query'"' | while read -l r; set result $result $r; end
    end
    if [ -z "$result" ]
      commandline -f repaint
      return
    else
      # Remove last token from commandline.
      commandline -t ""
    end
    for i in $result
      commandline -it -- $prefix
      commandline -it -- (string escape $i)
      commandline -it -- ' '
    end
    commandline -f repaint
  end

  function fzf-history-widget -d "Show command history"
    test -n "$FZF_TMUX_HEIGHT"; or set FZF_TMUX_HEIGHT 40%
    begin
      set -lx FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT $FZF_DEFAULT_OPTS --scheme=history --bind=ctrl-r:toggle-sort,ctrl-z:ignore $FZF_CTRL_R_OPTS +m"

      set -l FISH_MAJOR (echo $version | cut -f1 -d.)
      set -l FISH_MINOR (echo $version | cut -f2 -d.)

      # history's -z flag is needed for multi-line support.
      # history's -z flag was added in fish 2.4.0, so don't use it for versions
      # before 2.4.0.
      if [ "$FISH_MAJOR" -gt 2 -o \( "$FISH_MAJOR" -eq 2 -a "$FISH_MINOR" -ge 4 \) ];
        history -z | eval (__fzfcmd) --read0 --print0 -q '(commandline)' | read -lz result
        and commandline -- $result
      else
        history | eval (__fzfcmd) -q '(commandline)' | read -l result
        and commandline -- $result
      end
    end
    commandline -f repaint
  end

  function fzf-cd-widget -d "Change directory"
    set -l commandline (__fzf_parse_commandline)
    set -l dir $commandline[1]
    set -l fzf_query $commandline[2]
    set -l prefix $commandline[3]

    test -n "$FZF_ALT_C_COMMAND"; or set -l FZF_ALT_C_COMMAND "
    command find -L \$dir -mindepth 1 \\( -path \$dir'*/.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' \\) -prune \
    -o -type d -print 2> /dev/null | sed 's@^\./@@'"
    test -n "$FZF_TMUX_HEIGHT"; or set FZF_TMUX_HEIGHT 40%
    begin
      set -lx FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT --reverse --scheme=path --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS"
      eval "$FZF_ALT_C_COMMAND | "(__fzfcmd)' +m --query "'$fzf_query'"' | read -l result

      if [ -n "$result" ]
        cd -- $result

        # Remove last token from commandline.
        commandline -t ""
        commandline -it -- $prefix
      end
    end

    commandline -f repaint
  end

  function __fzfcmd
    test -n "$FZF_TMUX"; or set FZF_TMUX 0
    test -n "$FZF_TMUX_HEIGHT"; or set FZF_TMUX_HEIGHT 40%
    if [ -n "$FZF_TMUX_OPTS" ]
      echo "fzf-tmux $FZF_TMUX_OPTS -- "
    else if [ $FZF_TMUX -eq 1 ]
      echo "fzf-tmux -d$FZF_TMUX_HEIGHT -- "
    else
      echo "fzf"
    end
  end

  bind \cg fzf-file-widget
  bind \cr fzf-history-widget
  bind \ec fzf-cd-widget

  if bind -M insert > /dev/null 2>&1
    bind -M insert \cg fzf-file-widget
    bind -M insert \cr fzf-history-widget
    bind -M insert \ec fzf-cd-widget
  end

  function __fzf_parse_commandline -d 'Parse the current command line token and return split of existing filepath, fzf query, and optional -option= prefix'
    set -l commandline (commandline -t)

    # strip -option= from token if present
    set -l prefix (string match -r -- '^-[^\s=]+=' $commandline)
    set commandline (string replace -- "$prefix" '' $commandline)

    # eval is used to do shell expansion on paths
    eval set commandline $commandline

    if [ -z $commandline ]
      # Default to current directory with no --query
      set dir '.'
      set fzf_query ''
    else
      set dir (__fzf_get_dir $commandline)

      if [ "$dir" = "." -a (string sub -l 1 -- $commandline) != '.' ]
        # if $dir is "." but commandline is not a relative path, this means no file path found
        set fzf_query $commandline
      else
        # Also remove trailing slash after dir, to "split" input properly
        set fzf_query (string replace -r "^$dir/?" -- '' "$commandline")
      end
    end

    echo $dir
    echo $fzf_query
    echo $prefix
  end

  function __fzf_get_dir -d 'Find the longest existing filepath from input string'
    set dir $argv

    # Strip all trailing slashes. Ignore if $dir is root dir (/)
    if [ (string length -- $dir) -gt 1 ]
      set dir (string replace -r '/*$' -- '' $dir)
    end

    # Iteratively check if dir exists and strip tail end of path
    while [ ! -d "$dir" ]
      # If path is absolute, this can keep going until ends up at /
      # If path is relative, this can keep going until entire input is consumed, dirname returns "."
      set dir (dirname -- "$dir")
    end

    echo $dir
  end

end
