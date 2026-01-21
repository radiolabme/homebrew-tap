# Goreleaser Example

This example shows how to configure a Go project to automatically publish to the Homebrew tap using Goreleaser.

## Files

- `.goreleaser.yaml` - Goreleaser configuration with Homebrew formula generation
- `.github/workflows/release.yml` - GitHub Actions workflow to run goreleaser on release

## Setup

1. Copy these files to your Go project
2. Ensure `HOMEBREW_TAP_TOKEN` secret is available (org-wide or per-repo)
3. Create a GitHub release → goreleaser builds and pushes formula

## How It Works

1. You push a tag: `git tag v1.0.0 && git push --tags`
2. GitHub Actions triggers on the tag
3. Goreleaser:
   - Builds binaries for all platforms
   - Creates GitHub release with artifacts
   - Generates Homebrew formula
   - Pushes formula to `radiolabme/homebrew-tap`
4. Users can immediately install: `brew install radiolabme/tap/your-tool`
