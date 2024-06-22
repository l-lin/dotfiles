default: help

PROJECTNAME=$(shell basename "$(PWD)")
NIXOS_HARDWARE_CONFIGURATION_FILE=./nixos/hardware-configuration.nix
NIX_PROFILE=l-lin
NIX_HOST=nixos
THEMES_FOLDER=./home-manager/modules/style/themes

PRE_COMMIT_FILE=./home-manager/modules/vcs/git/script/pre-commit.sh

BLUE=\033[1;30;44m
YELLOW=\033[1;30;43m
RED=\033[1;30;41m
NC=\033[0m

# NIXOS --------------------------------------------------------------------------

## update-nixos: apply NixOS configuration
update-nixos: nixos-hardware-config
	@echo -e "${BLUE} I ${NC} Applying NixOS configuration..."
	@if type nh >/dev/null 2>&1; then \
		nh os switch --hostname "${NIX_HOST}" --ask .; \
	else \
		sudo nixos-rebuild switch --flake '.#${NIX_HOST}'; \
	fi
	@$(MAKE) check-nixos-health --no-print-directory

## nixos-hardware-config: generate hardware-configuration
nixos-hardware-config:
	@rm ${NIXOS_HARDWARE_CONFIGURATION_FILE}
	@nixos-generate-config --show-hardware-config > ${NIXOS_HARDWARE_CONFIGURATION_FILE}

## clean-nixos: clean up nixos garbage
clean-nixos:
	@echo -e "${YELLOW} W ${NC} Cleaning up NixOS garbage..."
	@sudo nix-collect-garbage -d
	@sudo nixos-rebuild boot --flake '.#${NIX_HOST}'

## check-nixos-health: check NixOS configuration
check-nixos-health:
	@nix-shell -p nix-health --run nix-health

## find-nix-package: find a Nix package
find-nix-package:
	@if [ -z ${PACKAGE} ]; then \
		echo 'Missing `PACKAGE` argument, usage: `make find-nix-package PACKAGE=<package>`' >/dev/stderr && exit 1; \
	fi
	@nix search nixpkgs ${PACKAGE}

## find-nix-option: find Nix option documentation
find-nix-option:
	@if [ -z ${OPTION} ]; then \
		echo -e "${RED} E ${NC}Missing `OPTION` argument, usage: `make find-nix-option OPTION=<option>`" >/dev/stderr && exit 1; \
	fi
	@nix-shell -p manix --run "manix '${OPTION}'"

## update-flake: update Nix flake lock file
update-flake:
	@echo -e "${BLUE} I ${NC} Updating Nix flake lock file..."
	@nix flake update
	@$(MAKE) update-nixos update-home --no-print-directory

# HOME-MANAGER --------------------------------------------------------------------------

## update-home: apply home-manager configuration
update-home: add-pre-commit-hook
	@echo -e "${BLUE} I ${NC} Applying home-manager configuration..."
	@if type nh >/dev/null 2>&1; then \
		nh home switch --backup-extension bak --configuration "${NIX_PROFILE}" .; \
	else \
		home-manager switch -b bak --flake '.#${NIX_PROFILE}'; \
	fi
	@$(MAKE) create-symlinks --no-print-directory

## show-home-news: show home-manager news entries
show-home-news:
	@home-manager news --flake '.#${NIX_PROFILE}'

## clean-home: clean up home-manager garbage
clean-home:
	@echo -e "${YELLOW} W ${NC} Cleaning up home-manager garbage..."
	@nix-collect-garbage -d

# STOW --------------------------------------------------------------------------

## create-symlinks: add symlinks for files that need to be writeable
create-symlinks:
	@cd stow \
	&& for folder in $$(find . -type d -maxdepth 1 2>/dev/null); do \
		if [[ "$${folder}" != '.' ]] && [[ "$${folder}" != './.git' ]]; then \
			app=$$(echo "$${folder}" | sed 's~./~~') \
			&& echo -e "${BLUE} I ${NC} Add symlinks for $${app}" \
			&& stow -t "$${HOME}" "$${app}"; \
		fi; \
	done

## remove-symlinks: remove-symlinks
remove-symlinks:
	@if [ -z ${FOLDER} ]; then \
		echo -e "${RED} E ${NC}Missing `FOLDER` argument, usage: `make remove-symlinks FOLDER=<folder>`" >/dev/stderr && exit 1; \
	fi
	@cd stow \
		&& stow --delete -t $${HOME} ${FOLDER}

# --------------------------------------------------------------------------

## reload-pyprland: reload pyprland configuration
reload-pyprland:
	@echo -e "${BLUE} I ${NC} Reloading pyprland configuration..."
	@pypr reload

## install-cheatsheets: install navi cheatsheets if not present
install-cheatsheets:
	@cheats=('github.com/l-lin/cheats') \
		&& for c in $${cheats[@]}; do \
			host=$$(echo $${c} | cut --delimiter '/' --fields 1) \
			&& owner=$$(echo $${c} | cut --delimiter '/' --fields 2) \
			&& repo=$$(echo $${c} | cut --delimiter '/' --fields 3) \
			&& $(MAKE) install-cheatsheet HOST=$${host} OWNER=$${owner} REPO=$${repo} --no-print-directory; \
		done

install-cheatsheet:
	@if [ -z ${HOST} ] || [ -z ${OWNER} ] || [ -z ${REPO} ]; then \
		echo -e "${RED} E ${NC} Missing argument, usage: `make install-cheatsheet HOST=<host> OWNER=<owner> REPO=<repo>`" >/dev/stderr && exit 1; \
	fi
	@cheatsheet_name="${OWNER}__${REPO}" \
		&& folder_name="$$(echo $$(navi info cheats-path)/$${cheatsheet_name})" \
		&& if [ -d $${folder_name} ]; then \
			echo -e "${BLUE} I ${NC} Cheatsheet '$${cheatsheet_name}' already exists, skipping..."; \
		else \
			echo -e "${BLUE} I ${NC} Installing cheatsheet '$${cheatsheet_name}'."; \
			git clone "git@${HOST}:${OWNER}/${REPO}" "$${folder_name}/$${cheatsheet_name}"; \
		fi

add-pre-commit-hook:
	@cp "${PRE_COMMIT_FILE}" .git/hooks/pre-commit

## change-theme: change theme
change-theme:
	@if [ -z ${TO} ]; then \
		echo -e "${RED} E ${NC} Missing argument, usage: `make change-theme TO=<theme>`" >/dev/stderr && exit 1; \
	fi
	@if [[ ! -d "${THEMES_FOLDER}/${TO}" ]]; then \
		supported_themes=$$(find ${THEMES_FOLDER} -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '\n' ' ') \
		&& echo -e "${RED} E ${NC} Unsupported theme '${TO}', expecting one of '$${supported_themes% }'!" >/dev/stderr && exit 1; \
	fi
	@echo -e "${BLUE} I ${NC} Changing theme to '${TO}'..."
	@sed -i 's~theme = "\(.*\)"~theme = "${TO}"~' flake.nix
	@$(MAKE) update-home --no-print-directory
	@tmux source "${XDG_CONFIG_HOME}/tmux/tmux.conf"

.PHONY: help
all: help
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo
