.PHONY: build install-claude install-codex

build:
	bash build.sh

install-claude:
	bash scripts/install-claude.sh

install-codex:
	bash scripts/install-codex.sh
