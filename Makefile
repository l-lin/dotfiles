default: help

PROJECTNAME=$(shell basename "$(PWD)")


## install: install all packages
install:
	@for f in installs/*.sh; do \
		./$$f; \
	done

## bootstrap: setup & add all symlinks
bootstrap: setup create-symlinks

# ---------------------------------------------------------------------------

setup:
	@echo "[-] Creating folders..."
	@mkdir -p "${HOME}/apps"
	@mkdir -p "${HOME}/bin"
	@mkdir -p "${HOME}/perso"
	@mkdir -p "${HOME}/work"
	@mkdir -p "${HOME}/.config/openbox/polybar/gruvbox"
	@mkdir -p "${HOME}/.config/pet"
	@mkdir -p "${HOME}/.m2"
	@mkdir -p "${HOME}/.undodir"
	@mkdir -p "${HOME}/.zsh/completion"
	@echo "[-] Removing overrided files"
	@rm -f "${HOME}/.config/openbox/polybar/gruvbox/config.ini"
	@rm -f "${HOME}/.config/openbox/rofi/bin/launcher"
	@rm -f "${HOME}/.config/openbox/rofi/bin/runner"

create-symlinks:
	@for folder in $$(find . -type d -maxdepth 1 2>/dev/null); do \
		if [[ "$${folder}" != '.' ]] && [[ "$${folder}" != './.git' ]] && [[ "$${folder}" != './installs' ]] && [[ "$${folder}" != './vim' ]]; then \
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
