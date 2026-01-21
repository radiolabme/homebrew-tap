#!/usr/bin/env bash
set -euo pipefail

# Sync formulas from radiolabme repos to this tap
# This script discovers repos with Formula/ or Casks/ directories
# and copies their contents here.

ORG="${GITHUB_ORG:-radiolabme}"
TAP_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FORMULA_DIR="$TAP_ROOT/Formula"
CASKS_DIR="$TAP_ROOT/Casks"

log() { echo "[sync] $*" >&2; }

# Ensure directories exist
mkdir -p "$FORMULA_DIR" "$CASKS_DIR"

# Get list of repos in the org
log "Fetching repos from $ORG..."
REPOS=$(gh repo list "$ORG" --json name,isArchived --jq '.[] | select(.isArchived == false) | .name' --limit 200)

if [[ -z "$REPOS" ]]; then
  log "No repos found or gh auth issue"
  exit 1
fi

FORMULAS_FOUND=0
CASKS_FOUND=0

for repo in $REPOS; do
  # Skip this tap repo itself
  [[ "$repo" == "homebrew-tap" ]] && continue

  log "Checking $ORG/$repo..."

  # Check for Formula directory in repo
  FORMULA_FILES=$(gh api "repos/$ORG/$repo/contents/Formula" --jq '.[].name' 2>/dev/null || true)

  if [[ -n "$FORMULA_FILES" ]]; then
    log "  Found formulas in $repo"
    for formula in $FORMULA_FILES; do
      if [[ "$formula" == *.rb ]]; then
        log "    Syncing $formula"
        gh api "repos/$ORG/$repo/contents/Formula/$formula" --jq '.content' | base64 -d > "$FORMULA_DIR/$formula"
        ((FORMULAS_FOUND++)) || true
      fi
    done
  fi

  # Check for Casks directory in repo
  CASK_FILES=$(gh api "repos/$ORG/$repo/contents/Casks" --jq '.[].name' 2>/dev/null || true)

  if [[ -n "$CASK_FILES" ]]; then
    log "  Found casks in $repo"
    for cask in $CASK_FILES; do
      if [[ "$cask" == *.rb ]]; then
        log "    Syncing $cask"
        gh api "repos/$ORG/$repo/contents/Casks/$cask" --jq '.content' | base64 -d > "$CASKS_DIR/$cask"
        ((CASKS_FOUND++)) || true
      fi
    done
  fi

  # Also check for homebrew/ directory (alternative convention)
  HOMEBREW_FORMULAS=$(gh api "repos/$ORG/$repo/contents/homebrew/Formula" --jq '.[].name' 2>/dev/null || true)

  if [[ -n "$HOMEBREW_FORMULAS" ]]; then
    log "  Found formulas in $repo/homebrew/Formula"
    for formula in $HOMEBREW_FORMULAS; do
      if [[ "$formula" == *.rb ]]; then
        log "    Syncing $formula"
        gh api "repos/$ORG/$repo/contents/homebrew/Formula/$formula" --jq '.content' | base64 -d > "$FORMULA_DIR/$formula"
        ((FORMULAS_FOUND++)) || true
      fi
    done
  fi
done

log "Sync complete: $FORMULAS_FOUND formulas, $CASKS_FOUND casks"

# Clean up .gitkeep if we have actual formulas
if [[ $FORMULAS_FOUND -gt 0 ]]; then
  rm -f "$FORMULA_DIR/.gitkeep"
fi
if [[ $CASKS_FOUND -gt 0 ]]; then
  rm -f "$CASKS_DIR/.gitkeep"
fi
