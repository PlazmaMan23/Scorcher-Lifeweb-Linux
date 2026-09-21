#!/usr/bin/env bash
# Copy the bundled Scorcher fonts (incl. the patched Retron2000) into a Wine prefix.
# Safe to re-run. Files that already exist with different contents are backed up
# to <prefix>/fonts-backup-<timestamp>/ before being replaced.
#
# Usage: scripts/install-fonts.sh /path/to/prefix
# Close BYOND first: running Wine processes keep old fonts loaded.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
prefix="${1:-}"

if [[ -z "$prefix" || ! -d "$prefix/drive_c/windows" ]]; then
    echo "usage: $0 /path/to/wine-prefix   (must contain drive_c/windows)" >&2
    exit 1
fi

dest="$prefix/drive_c/windows/Fonts"
mkdir -p "$dest"
backup=""
installed=0
unchanged=0

for font in "$repo"/fonts/*.ttf "$repo"/fonts/*.otf; do
    name="$(basename "$font")"
    target="$dest/$name"
    # Wine's Fonts folder is case-insensitive in practice; match any existing case.
    existing="$(find "$dest" -maxdepth 1 -iname "$name" -print -quit)"
    if [[ -n "$existing" ]] && cmp -s "$font" "$existing"; then
        unchanged=$((unchanged + 1))
        continue
    fi
    if [[ -n "$existing" ]]; then
        if [[ -z "$backup" ]]; then
            backup="$prefix/fonts-backup-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$backup"
        fi
        mv "$existing" "$backup/"
    fi
    cp "$font" "$target"
    installed=$((installed + 1))
done

echo "Fonts: $installed installed/updated, $unchanged already up to date -> $dest"
[[ -n "$backup" ]] && echo "Replaced files were backed up to: $backup"
exit 0
