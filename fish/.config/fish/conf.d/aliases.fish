# -----------------------------------------------------------------
# ALIASES
# https://fishshell.com/docs/current/language.html#defining-aliases
# -----------------------------------------------------------------

# --------------------------------------------------------
# Shortcuts
# --------------------------------------------------------
function l
    lsd -la --group-dirs first $argv
end

# --------------------------------------------------------
# Override default commands with "modern" ones
# --------------------------------------------------------
function top
    procs --watch --sortd cpu
end
function watch
    viddy $argv
end
# Compute space disk
function df
    duf
end
function du
    dust
end
# prettyping
function ping
    prettyping --nolegend $argv
end

# --------------------------------------------------------
# Default options
# --------------------------------------------------------
# Prevent recursive change on root directory
function chmod
    command chmod --preserve-root $argv
end
function chown
    command chown --preserve-root $argv
end
# ssh support with alacritty
# see https://github.com/alacritty/alacritty/issues/3932 for more info
function ssh
    set TERM xterm-256color && command ssh $argv
end

# --------------------------------------------------------
# GIT
# --------------------------------------------------------
function gbdr
    git branch -r \
        | awk "{print \$1}" \
        | grep -E -v -f /dev/fd/0 (git branch -vv | grep origin | psub) \
        | awk "{print \$1}" \
        | xargs git branch -D $argv
end
function gup
    git fetch --all --prune \
        && git checkout develop \
        && git pull \
        && gbdr
end
function gupm
    git fetch --all --prune \
        && git checkout master \
        && git pull \
        && gbdr
end
function gcb
    git branch \
        | fzf --header Checkout \
        | xargs git checkout
end
function gbd
    git branch \
        | fzf --header "Branch to delete" \
        | xargs git branch -D
end
function gchurn
    git log --format=format: --name-only --since=12.month \
        | grep -E -v "^\$" \
        | sort \
        | uniq -c \
        | sort -nr \
        | head -50
end
# git checkout shortcut to add the task type, the jira id and the branch name
function gcob
  set branch_type $(echo "feature\nbugfix\ntask\nrefactor" | gum filter --placeholder "branch type")
  set jira_task_id $(gum input --placeholder "jira task ID")

  set branch_name $(gum input --value "$branch_type/CLOUD-$jira_task_id/" --placeholder "branch name")

  git checkout -b "$branch_name"
end
function batdiff
    git diff --name-only --diff-filter=d | xargs bat --diff
end
# git commit shortcut
function gci
  set type $(echo "feat\nfix\nchore\ntask\nrefactor\nci\ncd\nbuild" | gum filter --placeholder "type")
  set scope $(gum input --value "$(git rev-parse --abbrev-ref HEAD | awk -F'/' '{ print $2 }')" --placeholder "scope")

  test -n "$scope" && set scope "($scope)"

  set summary=$(gum input --value "$type$scope: " --placeholder "summary of the change" --width 50)
  set description $(gum write --placeholder "detail of the change" --width 80)

  git add -A && git commit -m "$summary" -m "$description"
end
# git push remote
function gpush
  set branch_name $(git rev-parse --abbrev-ref HEAD)

  git push -u origin $branch_name
end

# --------------------------------------------------------
# AWS
# --------------------------------------------------------
# target localstack
function awslocal
    aws --endpoint-url=http://localhost:4566 $argv
end
# synchronize AWS S3
function aws-sync-perso
    set folder_name $(pwd | awk -F'/' '{ print $NF }')
    aws s3 sync . \
        "s3://$folder_name" \
        --storage-class ONEZONE_IA \
        --delete \
        --profile perso
end

# --------------------------------------------------------
# Custom functions
# --------------------------------------------------------
function diffc
    diff -u $argv[1] $argv[2] \
        | colordiff \
        | less -R
end
# pandoc
function pandoc
    docker run --rm \
        --volume \${PWD}:/data \
        --user $(id -u):$(id -g) \
        pandoc/core:3.0.1-alpine $argv
end
function pandoc-latex
    docker run --rm \
        --volume \${PWD}:/data \
        --user $(id -u):$(id -g) \
        pandoc/latex:3.0.1-alpine $argv
end

# aws

# termgraph
function termgraph
    docker run --rm \
        --volume $PWD:/data \
        --user $(id -u):$(id -g) \
        ghcr.io/l-lin/termgraph:main $argv
end
# copy with a progress bar.
function cpv
    rsync -apoghb \
        --backup-dir=/tmp \
        -e /dev/null \
        --inplace \
        --info=progress2 -- \
        $argv
end
# Record a GIF
function gif
    byzanz-record \
        --duration=5 \
        --x=250 \
        --y=235 \
        --width=1200 \
        --height=800 \
        $argv
end
# find configured local DNS servers
function find-dns-servers
    nmcli dev show | grep 'IP4.DNS'
end
# weather
function weather
    curl https://wttr.in/
end
# check used port
function usedports
    netstat -taupen
end
function who-use-that-port
    lsof -i $argv
end
