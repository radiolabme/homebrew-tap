# Contributing to radiolabme/homebrew-tap

This document explains how to make your radiolabme project installable via Homebrew.

## Overview

There are two ways to publish formulas to this tap:

| Method | Best For | How It Works |
|--------|----------|--------------|
| **Goreleaser (Push)** | Go projects with binary releases | Goreleaser pushes formula directly to tap on release |
| **Sync (Pull)** | Other projects, or manual control | Tap pulls formula from your repo's `Formula/` directory |

---

## Semantic Versioning & Tagging

All releases must use [semantic versioning](https://semver.org/) with a `v` prefix.

### Version Format

```
vMAJOR.MINOR.PATCH
```

| Version | When to Use | Example |
|---------|-------------|---------|
| `v0.x.x` | Pre-1.0 development (API may change) | `v0.1.0`, `v0.2.3` |
| `v1.0.0` | First stable release (public API commitment) | `v1.0.0` |
| `vX.Y.Z+1` | **Patch**: Bug fixes, no new features | `v1.0.0` → `v1.0.1` |
| `vX.Y+1.0` | **Minor**: New features, backward compatible | `v1.0.1` → `v1.1.0` |
| `vX+1.0.0` | **Major**: Breaking changes | `v1.1.0` → `v2.0.0` |

### Creating a Release

```bash
# Ensure you're on main with clean state
git checkout main
git pull origin main

# Tag the release
git tag v1.0.0

# Push the tag (triggers release workflow)
git push origin v1.0.0
```

### Creating a Release with Annotation

```bash
# Annotated tag (recommended - includes message)
git tag -a v1.0.0 -m "First stable release"
git push origin v1.0.0
```

### Listing Tags

```bash
git tag --list 'v*' --sort=-version:refname
```

### Deleting a Tag (if needed)

```bash
# Delete locally
git tag -d v1.0.0

# Delete remote
git push origin --delete v1.0.0
```

> ⚠️ **Warning**: Never delete/recreate tags after release. This breaks checksums and user installs. Instead, create a new patch version.

---

## Method 1: Goreleaser (Recommended for Go Projects)

Goreleaser automatically creates and pushes a Homebrew formula when you release.

### Setup

1. **Add `HOMEBREW_TAP_TOKEN` secret** to your repo (already configured org-wide)

2. **Configure `.goreleaser.yaml`**:

```yaml
# See examples/goreleaser/.goreleaser.yaml for full example
brews:
  - name: your-tool
    repository:
      owner: radiolabme
      name: homebrew-tap
      token: "{{ .Env.HOMEBREW_TAP_TOKEN }}"
    homepage: "https://github.com/radiolabme/your-repo"
    description: "Your tool description"
    license: "MIT"
    install: |
      bin.install "your-tool"
    test: |
      system "#{bin}/your-tool", "--version"
```

3. **Release**: When you create a GitHub release, goreleaser builds binaries and pushes the formula.

### Example Files

See [examples/goreleaser/](examples/goreleaser/) for complete boilerplate.

---

## Method 2: Sync (For Non-Go Projects)

The tap automatically syncs formulas from your repo's `Formula/` directory.

### Setup

1. **Create `Formula/your-tool.rb`** in your repo:

```ruby
# See examples/sync/Formula/example.rb for template
class YourTool < Formula
  desc "Your tool description"
  homepage "https://github.com/radiolabme/your-repo"
  url "https://github.com/radiolabme/your-repo/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "SHA256_OF_TARBALL"
  license "MIT"

  def install
    # Build and install commands
  end

  test do
    system "#{bin}/your-tool", "--version"
  end
end
```

2. **Trigger sync** (choose one):
   - **Wait** for daily sync (6 AM UTC)
   - **Manual**: Go to [Actions](https://github.com/radiolabme/homebrew-tap/actions/workflows/sync.yml) → Run workflow
   - **Automatic**: Add webhook workflow (see below)

### Automatic Sync on Release

Add this workflow to trigger sync immediately when you release:

```yaml
# .github/workflows/notify-tap.yml
# See examples/sync/.github/workflows/notify-tap.yml

name: Notify Homebrew Tap

on:
  release:
    types: [published]
  push:
    branches: [main]
    paths:
      - 'Formula/**'

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger tap sync
        env:
          GH_TOKEN: ${{ secrets.HOMEBREW_TAP_TOKEN }}
        run: |
          gh api repos/radiolabme/homebrew-tap/dispatches \
            -f event_type=formula-update \
            -f client_payload='{"repo":"${{ github.repository }}"}'
```

### Example Files

See [examples/sync/](examples/sync/) for complete boilerplate.

---

## Updating Your Formula

### Goreleaser Method
Just create a new release. Goreleaser handles everything.

### Sync Method
1. Update `Formula/your-tool.rb` in your repo:
   - Change `url` to new release tag
   - Update `sha256` (run: `curl -sL <url> | shasum -a 256`)
2. Commit and push, or create a release
3. Sync triggers automatically (or manually)

---

## Getting the SHA256

For tarball URLs:
```bash
curl -sL https://github.com/radiolabme/your-repo/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
```

For direct binary URLs:
```bash
curl -sL https://github.com/radiolabme/your-repo/releases/download/v1.0.0/your-tool-darwin-arm64.tar.gz | shasum -a 256
```

---

## Testing Locally

Before pushing, test your formula locally:

```bash
# Tap the repo (if not already)
brew tap radiolabme/tap

# Install from local formula file
brew install --build-from-source ./Formula/your-tool.rb

# Or test the formula
brew test your-tool

# Audit for issues
brew audit --strict your-tool
```

---

## Troubleshooting

### Formula not appearing after sync
- Check [sync workflow runs](https://github.com/radiolabme/homebrew-tap/actions/workflows/sync.yml) for errors
- Verify your `Formula/` directory is at repo root (not nested)
- Ensure formula filename ends in `.rb`

### Goreleaser not pushing
- Check release workflow logs for brew step errors
- Verify `HOMEBREW_TAP_TOKEN` secret is set
- Ensure token has write access to `homebrew-tap` repo

### SHA256 mismatch
- GitHub tarballs can change if you force-push tags
- Always use release tarballs, not branch archives
- Recalculate SHA256 after any tag changes

---

## Pre-commit Hooks (For Tap Contributors)

If editing the tap directly:

```bash
# After cloning
brew install pre-commit
pre-commit install
```

This runs shellcheck, rubocop, and formatting checks on commit.

---

## Pre-push Validation (For Source Repos)

Add formula validation to your source repo's pre-push hook. This catches errors before you push.

### Setup

Add to your `.pre-commit-config.yaml`:

```yaml
repos:
  # ... your other hooks ...

  - repo: https://github.com/radiolabme/homebrew-tap
    rev: main  # or pin to a specific tag
    hooks:
      - id: validate-formula
        stages: [pre-push]
```

Then install the pre-push hook:

```bash
pre-commit install --hook-type pre-push
```

### What It Validates

- **Formula/*.rb files**:
  - Ruby syntax
  - Required fields: `class`, `desc`, `homepage`, `url`, `install`
  - Recommended fields: `sha256`, `license`, `test`

- **.goreleaser.yaml**:
  - YAML syntax
  - Goreleaser config (if `goreleaser` CLI is installed)
  - Token references for homebrew-tap
