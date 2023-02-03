default: help

PROJECTNAME=$(shell basename "$(PWD)")

## setup: init folders
setup:
	@echo "[-] Creating folders..."
	@mkdir -p "${HOME}/apps"
	@mkdir -p "${HOME}/bin"
	@mkdir -p "${HOME}/work"
	@mkdir -p "${HOME}/perso"
	@mkdir -p "${HOME}/.undodir"

## install-all: install all packages
install-all:
	@for f in installs/*.sh; do \
	  ./$f \
	done

## bootstrap: add all symlinks
bootstrap:
	@for app in \
		asdf \
		bat \
		bin \
		fontconfig \
		dip \
		git \
		intellij \
		navi \
		nodejs \
		nvim \
		openbox \
		pet \
		polybar \
		psql \
		redshift \
		tmux \
		warp \
		zsh \
	; do \
		echo "[-] add config for $${app}" \
		&& stow -t "$${HOME}" "$${app}"; \
	done

# ---------------------------------------------------------------------------

.PHONY: help
all: help
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo
