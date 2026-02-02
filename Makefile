# Makefile for homebrew-tap

.PHONY: all build test lint audit install clean help ci ci-lint ci-test validate hooks
.DEFAULT_GOAL := help

# Variables
FORMULAS := $(wildcard Formula/*.rb)
CASKS := $(wildcard Casks/*.rb)
TAP_NAME := radiolabme/tap

## Build & Validation
all: lint audit test ## Run all checks

build: ## No-op for tap repo (formulas are declarative)
	@echo "Nothing to build - formulas are validated via lint/audit"

lint: ## Run linters (rubocop, shellcheck)
	@echo "==> Running rubocop..."
	@rubocop --config .rubocop.yml Formula/ Casks/ || true
	@echo "==> Running shellcheck..."
	@shellcheck -e SC2086 scripts/**/*.sh || true

audit: ## Run brew audit on all formulas
	@brew tap $(TAP_NAME) . 2>/dev/null || true
	@for formula in $(FORMULAS); do \
		name=$$(basename $$formula .rb); \
		echo "==> Auditing $$name..."; \
		brew audit --strict $(TAP_NAME)/$$name; \
	done

test: ## Run brew test on all formulas
	@brew tap $(TAP_NAME) . 2>/dev/null || true
	@for formula in $(FORMULAS); do \
		name=$$(basename $$formula .rb); \
		echo "==> Testing $$name..."; \
		brew install $(TAP_NAME)/$$name && brew test $(TAP_NAME)/$$name && brew uninstall $$name || true; \
	done

## Development
install: hooks ## Install git hooks (alias for hooks)

validate: ## Run formula validation script
	@./scripts/hooks/validate-formula.sh

hooks: ## Install git hooks (pre-push runs CI before push)
	@mkdir -p .git/hooks
	@echo '#!/bin/sh' > .git/hooks/pre-push
	@echo 'make ci' >> .git/hooks/pre-push
	@chmod +x .git/hooks/pre-push
	@echo '#!/bin/sh' > .git/hooks/commit-msg
	@echo '# Validate conventional commit format' >> .git/hooks/commit-msg
	@echo 'msg=$$(cat "$$1")' >> .git/hooks/commit-msg
	@echo 'pattern="^(feat|fix|refactor|test|build|chore|docs|perf|ci)(\\(.+\\))?: .{1,50}"' >> .git/hooks/commit-msg
	@echo 'if ! echo "$$msg" | head -1 | grep -qE "$$pattern"; then' >> .git/hooks/commit-msg
	@echo '  echo "Error: Invalid commit message format"' >> .git/hooks/commit-msg
	@echo '  echo "Expected: type(scope)?: description (50 chars max)"' >> .git/hooks/commit-msg
	@echo '  echo "Types: feat, fix, refactor, test, build, chore, docs, perf, ci"' >> .git/hooks/commit-msg
	@echo '  echo ""' >> .git/hooks/commit-msg
	@echo '  echo "Your message: $$msg"' >> .git/hooks/commit-msg
	@echo '  exit 1' >> .git/hooks/commit-msg
	@echo 'fi' >> .git/hooks/commit-msg
	@chmod +x .git/hooks/commit-msg
	@echo "Installed pre-push and commit-msg hooks"

## CI - run GitHub Actions locally via act (install: brew install act)
# Detect git worktree and get parent .git path for container mount
ACT_WORKTREE_OPTS := $(shell \
	if [ -f .git ]; then \
		gitdir=$$(sed -n 's/^gitdir: //p' .git); \
		parent_git=$$(echo "$$gitdir" | sed 's|/worktrees/.*||'); \
		echo "--container-options \"-v $$parent_git:$$parent_git:ro\""; \
	fi)

ci: ## Run full CI workflow locally
	@command -v act >/dev/null 2>&1 || { echo "Install act: brew install act"; exit 1; }
	act push -W .github/workflows/ci.yml $(ACT_WORKTREE_OPTS)

ci-lint: ## Run lint job only
	@command -v act >/dev/null 2>&1 || { echo "Install act: brew install act"; exit 1; }
	act push -j lint -W .github/workflows/ci.yml $(ACT_WORKTREE_OPTS)

ci-test: ## Run test-formulas job only
	@command -v act >/dev/null 2>&1 || { echo "Install act: brew install act"; exit 1; }
	act push -j test-formulas -W .github/workflows/ci.yml $(ACT_WORKTREE_OPTS)

## Cleanup
clean: ## Clean up local state
	@brew untap $(TAP_NAME) 2>/dev/null || true
	@echo "✓ Cleaned up"

## Help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
