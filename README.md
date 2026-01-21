# Homebrew Tap for radiolabme

This is an auto-syncing Homebrew tap that automatically discovers and publishes formulas from [radiolabme](https://github.com/radiolabme) repositories.

## Installation

```bash
brew tap radiolabme/tap
```

## Usage

Once tapped, install any formula:

```bash
brew install radiolabme/tap/<formula-name>
```

Or search available formulas:

```bash
brew search radiolabme/tap
```

## How Auto-Sync Works

This tap automatically discovers formulas from any radiolabme repository that contains:

- `Formula/*.rb` - Homebrew formulas
- `Casks/*.rb` - Homebrew casks (GUI apps)
- `homebrew/Formula/*.rb` - Alternative formula location

### Sync Triggers

1. **Daily schedule** - Runs at 6 AM UTC
2. **Manual** - Trigger via GitHub Actions UI
3. **Webhook** - Source repos can trigger via `repository_dispatch`

### Adding a Formula to Your Repo

To make your package available via this tap, add a `Formula/` directory to your repo with a Ruby formula file:

```ruby
# Formula/your-tool.rb
class YourTool < Formula
  desc "Description of your tool"
  homepage "https://github.com/radiolabme/your-repo"
  url "https://github.com/radiolabme/your-repo/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "abc123..."
  license "MIT"

  depends_on "go" => :build  # or whatever dependencies

  def install
    system "go", "build", "-o", bin/"your-tool"
  end

  test do
    system "#{bin}/your-tool", "--version"
  end
end
```

The tap will automatically pick up your formula within 24 hours (or immediately if you trigger a manual sync).

### Triggering Immediate Sync

From your source repo, add this GitHub Action to trigger sync on release:

```yaml
# .github/workflows/notify-tap.yml
name: Notify Tap

on:
  release:
    types: [published]
  push:
    paths:
      - 'Formula/**'
      - 'Casks/**'

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger tap sync
        run: |
          curl -X POST \
            -H "Authorization: token ${{ secrets.TAP_TRIGGER_TOKEN }}" \
            -H "Accept: application/vnd.github.v3+json" \
            https://api.github.com/repos/radiolabme/homebrew-tap/dispatches \
            -d '{"event_type":"formula-update","client_payload":{"repo":"${{ github.repository }}"}}'
```

## Setup (For Maintainers)

### Required Secrets

1. **FORMULA_SYNC_TOKEN** - Personal access token with `repo` scope to read formulas from org repos

### Creating the Token

1. Go to GitHub Settings → Developer Settings → Personal Access Tokens → Fine-grained tokens
2. Create token with:
   - Resource owner: `radiolabme`
   - Repository access: All repositories (or selected)
   - Permissions: Contents (read)
3. Add as repository secret `FORMULA_SYNC_TOKEN`

## Contributing

Formulas should be maintained in their source repositories, not directly in this tap. To update a formula:

1. Update the formula in the source repo
2. Wait for auto-sync (or trigger manually)

## License

MIT
