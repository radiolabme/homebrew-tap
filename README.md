# Homebrew Tap for radiolabme

Homebrew tap for [radiolabme](https://github.com/radiolabme) projects.

## Installation

```bash
brew tap radiolabme/tap
```

## Usage

```bash
# Install a formula
brew install radiolabme/tap/<formula-name>

# Search available formulas
brew search radiolabme/tap

# Update formulas
brew update && brew upgrade
```

## Available Formulas

| Formula | Description |
|---------|-------------|
| *(formulas appear here as projects are added)* | |

## Adding Your Project

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed setup instructions.

**Quick links:**
- [Goreleaser setup](examples/goreleaser/) - For Go projects with binary releases
- [Sync setup](examples/sync/) - For other projects or manual control

## How It Works

This tap accepts formulas via two methods:

1. **Push (Goreleaser)** - Source repos push formulas directly on release
2. **Pull (Sync)** - Tap pulls formulas from repos with `Formula/` directories

Both methods are fully supported. Choose based on your project type.

## Manual Sync

Trigger a sync manually:
- **GitHub UI**: [Run sync workflow](https://github.com/radiolabme/homebrew-tap/actions/workflows/sync.yml)
- **CLI**: `gh workflow run sync.yml -R radiolabme/homebrew-tap`

## License

MIT
