#!/usr/bin/env bash
# package.sh — builds a WoW-ready release zip for SmartLFG
# Usage:  ./package.sh
# Output: dist/<version>.zip
set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve version from the .toc file
# ---------------------------------------------------------------------------
TOC="SmartLFG.toc"

if [[ ! -f "$TOC" ]]; then
    echo "ERROR: $TOC not found. Run this script from the project root." >&2
    exit 1
fi

VERSION=$(grep -E "^## Version:" "$TOC" | awk '{print $NF}')

if [[ -z "$VERSION" ]]; then
    echo "ERROR: Could not read ## Version: from $TOC." >&2
    exit 1
fi

echo "SmartLFG — building ${VERSION} …"

# ---------------------------------------------------------------------------
# Staging
# ---------------------------------------------------------------------------
DIST="dist"
STAGING="$DIST/SmartLFG"

rm -rf "$DIST"
mkdir -p "$STAGING"

# Files/dirs to exclude from the release.
# This is the single source of truth — release.yml delegates here via ./package.sh.
# ⚠ Keep in sync with the ignore list in pkgmeta.yaml (used by the CurseForge packager).
EXCLUDES=(
    '.git'
    '.github'
    '.idea'
    'docs'
    'dist'
    '.editorconfig'
    '.gitignore'
    '.luacheckrc'
    'package.sh'
    'pkgmeta.yaml'
    '*.zip'
    '*.tar.gz'
)

# Build rsync exclude args
RSYNC_EXCLUDES=()
for ex in "${EXCLUDES[@]}"; do
    RSYNC_EXCLUDES+=("--exclude=$ex")
done

rsync -a "${RSYNC_EXCLUDES[@]}" . "$STAGING/"

# ---------------------------------------------------------------------------
# Zip (top-level folder inside the archive must be "SmartLFG")
# ---------------------------------------------------------------------------
ZIPFILE="${VERSION}.zip"

cd "$DIST"
zip -r "$ZIPFILE" SmartLFG/
cd ..

echo ""
echo "  Output : dist/${ZIPFILE}"
echo "  Install : unzip into World of Warcraft/_retail_/Interface/AddOns/"
echo ""
echo "Done."
