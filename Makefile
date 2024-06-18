default: help

PROJECTNAME=$(shell basename "$(PWD)")
NIXOS_HARDWARE_CONFIGURATION_FILE=./nixos/hardware-configuration.nix
NIX_PROFILE=l-lin
NIX_HOST=nixos

BLUE=\033[1;30;44m
YELLOW=\033[1;30;43m
NC=\033[0m

## home: apply home-manager configuration
home:
	@echo -e "${BLUE} I ${NC} Applying home-manager configuration..."
	@if type nh >/dev/null 2>&1; then \
		nh home switch --backup-extension bak --configuration "${NIX_PROFILE}" .; \
	else \
		home-manager switch -b bak --flake '.#${NIX_PROFILE}'; \
	fi
	@$(MAKE) hyprland --no-print-directory
	@$(MAKE) create-symlinks --no-print-directory

## home-news: show home-manager news entries
home-news:
	@home-manager news --flake '.#${NIX_PROFILE}'

## nixos: apply NixOS configuration
.PHONY: nixos
nixos: nixos-hardware-config
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

## clean-home: clean up home-manager garbage
clean-home:
	@echo -e "${YELLOW} W ${NC} Cleaning up home-manager garbage..."
	@nix-collect-garbage -d

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
	@nix search nixpkgs ${package}

## find-nix-option: find Nix option documentation
find-nix-option:
	@if [ -z ${OPTION} ]; then \
		echo 'Missing `OPTION` argument, usage: `make find-nix-option OPTION=<option>`' >/dev/stderr && exit 1; \
	fi
	@nix-shell -p manix --run "manix '${OPTION}'"

# --------------------------------------------------------------------------

## stow: add symlinks for files that need to be writeable
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
		echo 'Missing `FOLDER` argument, usage: `make remove-symlinks FOLDER=<folder>`' >/dev/stderr && exit 1; \
	fi
	@cd stow \
		&& stow --delete -t $${HOME} ${FOLDER}

# --------------------------------------------------------------------------

## hyprland: reload hyprland configuration
hyprland:
	@echo -e "${BLUE} I ${NC} Reloading Hyprland configuration..."
	@hyprctl reload

## install-cheatsheets: install navi cheatsheets if not present
install-cheatsheets:
	@cheats=('github.com/l-lin/cheats') \
		&& for c in $${cheats[@]}; do \
			host=$$(echo $${c} | cut --delimiter '/' --fields 1) \
			&& owner=$$(echo $${c} | cut --delimiter '/' --fields 2) \
			&& repo=$$(echo $${c} | cut --delimiter '/' --fields 3) \
			&& $(MAKE) install-cheatsheet HOST=$${host} OWNER=$${owner} REPO=$${repo} --no-print-directory; \
		done

## install-cheatsheet: install navi cheatsheet if not present
install-cheatsheet:
	@if [ -z ${HOST} ] || [ -z ${OWNER} ] || [ -z ${REPO} ]; then \
		echo 'Missing argument, usage: `make install-cheatsheet HOST=<host> OWNER=<owner> REPO=<repo>`' >/dev/stderr && exit 1; \
	fi
	@cheatsheet_name="${OWNER}__${REPO}" \
		&& folder_name="$$(echo $$(navi info cheats-path)/$${cheatsheet_name})" \
		&& if [ -d $${folder_name} ]; then \
			echo -e "${BLUE} I ${NC} Cheatsheet '$${cheatsheet_name}' already exists, skipping..."; \
		else \
			echo -e "${BLUE} I ${NC} Installing cheatsheet '$${cheatsheet_name}'."; \
			git clone "git@${HOST}:${OWNER}/${REPO}" "$${folder_name}/$${cheatsheet_name}"; \
		fi

.PHONY: help
all: help
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo
