#!/usr/bin/env bash
set -euo pipefail

DESTINATION="/c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/SmartLFG"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Deploy only what the addon needs at runtime: the .toc, src/, and media/icon.
# Docs, dev assets (screenshots/logo), and tooling are stripped.
EXCLUDES=(
    '.git'
    '.github'
    '.idea'
    'docs'
    'dist'
    'CLAUDE.md'
    'media/logo.png'
    'media/role-dungeon-finder.png'
    'media/tooltip-group-finder.png'
    'media/tooltip-only.png'
    '.editorconfig'
    '.gitignore'
    '.luacheckrc'
    'package.sh'
    'deploy.sh'
    'deploy.ps1'
    'pkgmeta.yaml'
    'CHANGELOG.md'
    'LICENSE.md'
    'README.md'
)

echo "Deploying SmartLFG to $DESTINATION ..."

# Stage into a temp dir first so a failure never leaves the live addon wiped.
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

if command -v rsync >/dev/null 2>&1; then
    EXARGS=()
    for ex in "${EXCLUDES[@]}"; do EXARGS+=("--exclude=$ex"); done
    rsync -a "${EXARGS[@]}" "$SOURCE/" "$STAGING/"
else
    echo "(rsync not found — using tar fallback)"
    EXARGS=()
    for ex in "${EXCLUDES[@]}"; do EXARGS+=("--exclude=$ex"); done
    tar -C "$SOURCE" "${EXARGS[@]}" -cf - . | tar -C "$STAGING" -xf -
fi

if [[ -d "$DESTINATION" ]]; then
    echo "Removing existing $DESTINATION ..."
    rm -rf "$DESTINATION"
fi
mkdir -p "$DESTINATION"
cp -a "$STAGING/." "$DESTINATION/"

echo ""
echo "Done. SmartLFG deployed to:"
echo "  $DESTINATION"
