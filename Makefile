default: help

PROJECTNAME=$(shell basename "$(PWD)")

## setup: init folders
setup:
	@echo "[-] Creating folders..."
	@mkdir -p "${HOME}/apps"
	@mkdir -p "${HOME}/bin"
	@mkdir -p "${HOME}/work"
	@mkdir -p "${HOME}/perso"
	@mkdir -p "${HOME}/.zsh/completion"
	@mkdir -p "${HOME}/.undodir"

## install-all: install all packages
install-all:
	@for f in installs/*.sh; do \
	  ./$f \
	done

## bootstrap: add all symlinks
bootstrap:
	@for folder in $$(find . -type d -maxdepth 1 2>/dev/null); do \
		if [[ "$${folder}" != '.' ]] && [[ "$${folder}" != './.git' ]] && [[ "$${folder}" != './installs' ]] && [[ "$${folder}" != './vim' ]]; then \
			app=$$(echo "$${folder}" | sed 's~./~~') \
			&& echo "[-] Add symlinks for $${app}" \
			&& stow -t "$${HOME}" "$${app}"; \
		fi; \
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
