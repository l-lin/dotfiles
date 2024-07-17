set quiet

NIXOS_HARDWARE_CONFIGURATION_FILE := './nixos/hardware-configuration.nix'
NIX_PROFILE := 'l-lin'
NIX_HOST := 'nixos'
THEMES_FOLDER := './home-manager/modules/style/themes'

PRE_COMMIT_FILE := './home-manager/modules/vcs/git/scripts/pre-commit.sh'

# display help
help:
  just --list

# NIXOS --------------------------------------------------------------------------

# generate hardware-configuration
nixos-hardware-config:
  rm "{{NIXOS_HARDWARE_CONFIGURATION_FILE}}"
  nixos-generate-config --show-hardware-config > "{{NIXOS_HARDWARE_CONFIGURATION_FILE}}"

# apply NixOS configuration
update-nixos: nixos-hardware-config
  just info "Applying NixOS configuration..."
  if type nh >/dev/null 2>&1; then \
    nh os switch --hostname "{{NIX_HOST}}" --ask .; \
  else \
    sudo nixos-rebuild switch --flake '.#{{NIX_HOST}}'; \
  fi
  just check-nixos-health

# clean up nixos garbage
clean-nixos:
  just warn "Cleaning up NixOS garbage..."
  sudo nix-collect-garbage -d
  sudo nixos-rebuild boot --flake '.#{{NIX_HOST}}'

# check NixOS configuration
check-nixos-health:
  nix-shell -p nix-health --run nix-health

# find a Nix package
find-nix-package package:
  nix search nixpkgs {{package}}

# find Nix option documentation
find-nix-option option:
  nix-shell -p manix --run "manix '{{option}}'"

#  update Nix flake lock file
update-flake input="all":
  if [[ "{{input}}" == "all" ]]; then \
    just info "Updating Nix flake lock file..." \
    && nix flake update \
    && just update-nixos update-home; \
  else \
    just info "Updating Nix flake {{input}}..." \
    && nix flake lock --update-input {{input}}; \
  fi

# HOME-MANAGER --------------------------------------------------------------------------

# apply home-manager configuration
update-home: add-pre-commit-hook
  just info "Applying home-manager configuration..."
  if type nh >/dev/null 2>&1; then \
    nh home switch --backup-extension bak --configuration "{{NIX_PROFILE}}" .; \
  else \
    home-manager switch -b bak --flake '.#{{NIX_PROFILE}}'; \
  fi
  just create-symlinks

# show home-manager news entries
show-home-news:
  home-manager news --flake '.#{{NIX_PROFILE}}'

#  clean up home-manager garbage
clean-home:
  just warn "Cleaning up home-manager garbage..."
  nix-collect-garbage -d

# STOW --------------------------------------------------------------------------

# add symlinks for files that need to be writeable
create-symlinks:
  cd stow \
  && for folder in $(find . -type d -maxdepth 1 2>/dev/null); do \
    if [[ "${folder}" != '.' ]] && [[ "${folder}" != './.git' ]]; then \
      app=$(echo "${folder}" | sed 's~./~~') \
      && just info "Add symlinks for ${app}" \
      && stow -t "${HOME}" "${app}"; \
    fi; \
  done

# remove-symlinks
remove-symlinks folder:
  cd stow && stow --delete -t "${HOME}" "{{folder}}"

# --------------------------------------------------------------------------

# import SSH keys, SOPS age key and create git allowed signers
import-keys:
  nix-shell --command zsh -p bitwarden-cli jq ssh-to-age --run "./scripts/import-keys.sh {{NIX_PROFILE}}"

# reload pyprland configuration
reload-pyprland:
  just info "Reloading pyprland configuration..."
  pypr reload

# install navi cheatsheets if not present
install-cheatsheets:
  cheats=('github.com/l-lin/cheats') \
    && for c in ${cheats[@]}; do \
      host=$(echo ${c} | cut --delimiter '/' --fields 1) \
      && owner=$(echo ${c} | cut --delimiter '/' --fields 2) \
      && repo=$(echo ${c} | cut --delimiter '/' --fields 3) \
      && just install-cheatsheet ${host} ${owner} ${repo}; \
    done

# install navi cheatsheet
install-cheatsheet host owner repo:
  cheatsheet_name="{{owner}}__{{repo}}" \
    && folder_name="$(echo $(navi info cheats-path)/${cheatsheet_name})" \
    && if [ -d ${folder_name} ]; then \
      just info "Cheatsheet '${cheatsheet_name}' already exists, skipping..."; \
    else \
      just info "Installing cheatsheet '${cheatsheet_name}'."; \
      git clone "git@{{host}}:{{owner}}/{{repo}}" "${folder_name}/${cheatsheet_name}"; \
    fi

[private]
add-pre-commit-hook:
  cp "{{PRE_COMMIT_FILE}}" .git/hooks/pre-commit

# change theme
change-theme to:
  if [[ ! -d "{{THEMES_FOLDER}}/{{to}}" ]]; then \
    supported_themes=$(find {{THEMES_FOLDER}} -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '\n' ' ') \
    && just error "Unsupported theme '{{to}}', expecting one of '${supported_themes% }'!" >/dev/stderr && exit 1; \
  fi
  just info "Changing theme to '{{to}}'..."
  sed -i 's~theme = "\(.*\)"~theme = "{{to}}"~' flake.nix
  just update-home
  tmux source "${XDG_CONFIG_HOME}/tmux/tmux.conf"
  pkill wpaperd && wpaperd -d

# LOGGING ------------------------------------------------------------------------

BLUE := '\033[1;30;44m'
YELLOW := '\033[1;30;43m'
RED := '\033[1;30;41m'
NC := '\033[0m'

[private]
info msg:
  echo -e "{{BLUE}} I {{NC}} {{msg}}"

[private]
warn msg:
  echo -e "{{YELLOW}} W {{NC}} {{msg}}"

[private]
error msg:
  echo -e "{{RED}} E {{NC}} {{msg}}"