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
	home-manager switch -b backup --flake '.#${NIX_PROFILE}' --show-trace
	@$(MAKE) hyprland --no-print-directory
	@$(MAKE) lazy-nvim-lock --no-print-directory

## home-news: show home-manager news entries
home-news:
	home-manager news --flake '.#${NIX_PROFILE}'

## nixos: apply NixOS configuration
.PHONY: nixos
nixos: nixos-hardware-config
	@echo "${BLUE} I ${NC} Applying NixOS configuration..."
	sudo nixos-rebuild switch --flake '.#${NIX_HOST}'

## nixos-hardware-config: generate hardware-configuration
nixos-hardware-config:
	@rm ${NIXOS_HARDWARE_CONFIGURATION_FILE}
	nixos-generate-config --show-hardware-config > ${NIXOS_HARDWARE_CONFIGURATION_FILE}

## clean-home: clean up home-manager garbage
clean-home:
	@echo "${YELLOW} W ${NC} Cleaning up home-manager garbage..."
	nix-collect-garbage -d

## clean-nixos: clean up nixos garbage
clean-nixos:
	@echo "${YELLOW} W ${NC} Cleaning up NixOS garbage..."
	sudo nix-collect-garbage -d
	sudo nixos-rebuild boot --flake '.#${NIX_HOST}'

## find-nix-package: find a nix package
find-nix-package:
	@nix search nixpkgs ${package}

# --------------------------------------------------------------------------

## hyprland: reload hyprland configuration
hyprland:
	@echo "${BLUE} I ${NC} Reloading Hyprland configuration..."
	@hyprctl reload

## lazy-nvim-lock: add lazy-lock.json symlink to XDG folder
lazy-nvim-lock:
	@echo "${BLUE} I ${NC} Recreating neovim lazy-lock.json symlink..."
	@rm -rf "$${HOME}/.config/nvim/lazy-lock.json"
	@ln -s ${PWD}/home-manager/modules/tui/nvim/lazy-lock.json "$${HOME}/.config/nvim/lazy-lock.json"

.PHONY: help
all: help
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo
