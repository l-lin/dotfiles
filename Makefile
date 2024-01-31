default: help

PROJECTNAME=$(shell basename "$(PWD)")


## install: install all packages
install:
	@for f in installs/*.sh; do \
		./$$f; \
	done

## bootstrap: setup & add all symlinks
bootstrap: setup create-symlinks

## unbootstrap: remote folder symlinks
unbootstrap:
	@stow --delete -t $${HOME} ${folder}

# ---------------------------------------------------------------------------

setup:
	@echo "[-] Creating folders..."
	@mkdir -p "${HOME}/apps"
	@mkdir -p "${HOME}/bin"
	@mkdir -p "${HOME}/perso"
	@mkdir -p "${HOME}/work"
	@mkdir -p "${HOME}/.config/pet"
	@mkdir -p "${HOME}/.config/nvim/plugin"
	@mkdir -p "${HOME}/.config/zsh/completions"
	@mkdir -p "${HOME}/.config/zsh/conf.d"
	@mkdir -p "${HOME}/.config/zsh/functions"
	@mkdir -p "${HOME}/.config/zsh/plugins"
	@mkdir -p "${HOME}/.config/zsh/zprofile.d"
	@mkdir -p "${HOME}/.m2"
	@mkdir -p "${HOME}/.undodir"
	@mkdir -p "${HOME}/.local/share/navi/cheats"
	@rm -rf "${HOME}/.config/openbox/rc.xml"
	@rm -rf "${HOME}/.config/openbox/scripts/ob-furminal"

create-symlinks:
	@for folder in $$(find . -type d -maxdepth 1 2>/dev/null); do \
		if [[ "$${folder}" != '.' ]] && [[ "$${folder}" != './.git' ]] && [[ "$${folder}" != './installs' ]] && [[ "$${folder}" != './dip' ]]; then \
			app=$$(echo "$${folder}" | sed 's~./~~') \
			&& echo "[-] Add symlinks for $${app}" \
			&& stow -t "$${HOME}" "$${app}"; \
		fi; \
	done

.PHONY: help
all: help
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo
