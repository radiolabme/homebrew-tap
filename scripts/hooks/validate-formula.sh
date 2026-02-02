#!/usr/bin/env bash
# Validate Homebrew formulas before push
# Drop this in your repo and reference from .pre-commit-config.yaml

set -euo pipefail

ERRORS=0

# Check for Formula directory
if [[ -d "Formula" ]]; then
  for formula in Formula/*.rb; do
    [[ -f "$formula" ]] || continue
    [[ "$formula" == *".gitkeep"* ]] && continue

    echo "Validating $formula..."

    # Ruby syntax check
    if ! ruby -c "$formula" > /dev/null 2>&1; then
      echo "  ✗ Ruby syntax error in $formula"
      ruby -c "$formula"
      ((ERRORS++))
      continue
    fi
    echo "  ✓ Ruby syntax OK"

    # Check required fields
    if ! grep -q 'class .* < Formula' "$formula"; then
      echo "  ✗ Missing Formula class definition"
      ((ERRORS++))
    fi

    # Accept both DSL styles: desc "..." and desc("...")
    if ! grep -qE 'desc[[:space:]]+"' "$formula" && ! grep -qE 'desc\(' "$formula"; then
      echo "  ✗ Missing 'desc' field"
      ((ERRORS++))
    fi

    if ! grep -qE 'homepage[[:space:]]+"' "$formula" && ! grep -qE 'homepage\(' "$formula"; then
      echo "  ✗ Missing 'homepage' field"
      ((ERRORS++))
    fi

    if ! grep -qE 'url[[:space:]]+"' "$formula" && ! grep -qE 'url\(' "$formula" && ! grep -qE 'head[[:space:]]+"' "$formula" && ! grep -qE 'head\(' "$formula"; then
      echo "  ✗ Missing 'url' or 'head' field"
      ((ERRORS++))
    fi

    if ! grep -qE 'sha256[[:space:]]+"' "$formula" && ! grep -qE 'sha256\(' "$formula" && ! grep -qE 'head[[:space:]]+"' "$formula" && ! grep -qE 'head\(' "$formula"; then
      echo "  ⚠ Missing 'sha256' (required unless head-only)"
    fi

    if ! grep -qE 'license[[:space:]]+"' "$formula" && ! grep -qE 'license\(' "$formula"; then
      echo "  ⚠ Missing 'license' field (recommended)"
    fi

    if ! grep -q 'def install' "$formula"; then
      echo "  ✗ Missing 'install' method"
      ((ERRORS++))
    fi

    if ! grep -q 'test do' "$formula"; then
      echo "  ⚠ Missing 'test' block (recommended)"
    fi
  done
fi

# Check goreleaser config
if [[ -f ".goreleaser.yaml" ]]; then
  GORELEASER_CONFIG=".goreleaser.yaml"
elif [[ -f ".goreleaser.yml" ]]; then
  GORELEASER_CONFIG=".goreleaser.yml"
else
  GORELEASER_CONFIG=""
fi

if [[ -n "$GORELEASER_CONFIG" ]]; then
  echo "Validating $GORELEASER_CONFIG..."

  # YAML syntax check
  if command -v python3 &> /dev/null; then
    if ! python3 -c "import yaml; yaml.safe_load(open('$GORELEASER_CONFIG'))" 2>/dev/null; then
      echo "  ✗ YAML syntax error"
      ((ERRORS++))
    else
      echo "  ✓ YAML syntax OK"
    fi
  fi

  # Check for brews section if this should push to tap
  if grep -q 'homebrew-tap' "$GORELEASER_CONFIG"; then
    if ! grep -q 'HOMEBREW_TAP_TOKEN' "$GORELEASER_CONFIG"; then
      echo "  ⚠ homebrew-tap referenced but HOMEBREW_TAP_TOKEN not found"
    fi
  fi

  # Full goreleaser check if available
  if command -v goreleaser &> /dev/null; then
    if ! goreleaser check --quiet 2>/dev/null; then
      echo "  ✗ Goreleaser config validation failed"
      goreleaser check 2>&1 | head -10
      ((ERRORS++))
    else
      echo "  ✓ Goreleaser config OK"
    fi
  fi
fi

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo "✗ Validation failed with $ERRORS error(s)"
  exit 1
fi

echo ""
echo "✓ All validations passed"
