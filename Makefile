.PHONY: all client host brew test test-docker check-endpoints clean help

all:
	@./install.sh

client:
	@./install.sh --client

host:
	@./install.sh --host

brew:
	@brew bundle --file=Brewfile

test:
	@echo "==> Running BATS test suite..."
	@bats tests/

test-docker:
	@echo "==> Building Docker test image and running BATS test suite..."
	@docker build -q -t dotfiles-test -f tests/Dockerfile .
	@docker run --rm dotfiles-test

check-endpoints:
	@echo "==> Testing shell syntax and local overrides..."
	@zsh -ic "echo '✔︎ Zsh interactive loaded successfully'"
	@echo "==> Verifying Ghostty configuration symlink..."
	@ls -l ~/.config/ghostty/config
	@echo "==> Verifying LM Studio endpoint connectivity..."
	@zsh -ic 'target=$${LMSTUDIO_HOST:-127.0.0.1}; \
		echo "    Target host: $$target"; \
		if curl -s -m 3 "http://$$target:1234/v1/models" >/dev/null; then \
			echo "✔︎ http://$$target:1234 reachable"; \
		else \
			echo "⚠ http://$$target:1234 unreachable (check Tailscale/server)"; \
		fi'

help:
	@echo "Dotfiles Management:"
	@echo "  make          - Run smart installer with hardware probe"
	@echo "  make client   - Install client profile (Satellite/Laptop, remote LM Studio via MagicDNS)"
	@echo "  make host     - Install host profile (Workstation with >= 64 GB RAM, local inference daemon)"
	@echo "  make brew     - Install/update Homebrew packages from Brewfile"
	@echo "  make test     - Run BATS test suite locally (guardrails, idempotency, configs, symlinks)"
	@echo "  make test-docker - Run BATS test suite in isolated Docker container (OrbStack)"
	@echo "  make check-endpoints - Verify live shell startup and LM Studio connectivity"
	@echo "  make help     - Show this help message"
