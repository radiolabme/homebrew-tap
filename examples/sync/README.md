# Sync Example

This example shows how to configure a project to use the tap's sync mechanism (pull-based).

Use this method when:
- Your project is not written in Go
- You're not using Goreleaser
- You want manual control over the formula

## Files

- `Formula/example.rb` - Example Homebrew formula template
- `.github/workflows/notify-tap.yml` - Workflow to trigger immediate sync on release

## Setup

1. Create `Formula/your-tool.rb` in your repo (copy and modify the template)
2. Optionally add the notify workflow for immediate sync
3. On release, the tap syncs your formula automatically

## How It Works

1. You maintain `Formula/your-tool.rb` in your repo
2. When you release (or push formula changes):
   - Notify workflow triggers `repository_dispatch` on the tap
   - Tap's sync workflow pulls your formula
3. Alternatively, daily sync at 6 AM UTC catches any changes
4. Users can install: `brew install radiolabme/tap/your-tool`

## Updating

1. Update `url` to point to new release tag
2. Recalculate and update `sha256`:
   ```bash
   curl -sL https://github.com/radiolabme/your-repo/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
   ```
3. Commit and push (or create release)
