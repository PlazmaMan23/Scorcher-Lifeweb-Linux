#!/usr/bin/env bash
# Install this repo's fonts into a Wine prefix.
#
# By default only the *patched* fonts are installed (currently Retron2000,
# 12420.ttf), and any other bundled font previously installed by this script is
# moved out of the prefix again.
#
# Why: the game ships all of these fonts in its own resource pack, so installing
# them into Windows' font folder adds nothing - but it does break things. Several
# of them (Project Sans, Neometric Alt, ErisPro) contain no ● / ○, and draw a
# labelled box for missing characters. When the embedded browser resolves such a
# font by name, the skills-tab dots become boxes. Wine 11.18 started exposing
# installed fonts to WebView2 where 11.17 didn't, which broke the dots for users
# who had them installed.
#
# Usage: scripts/install-fonts.sh /path/to/prefix [--all]
#   --all   install every bundled font (the old behaviour; not recommended)
# Close BYOND first: running Wine processes keep old fonts loaded.
set -euo pipefail

# Fonts we modify and therefore must install; everything else is left to the game.
PATCHED_FONTS=(12420.ttf)

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
prefix=""
install_all=0
for arg in "$@"; do
    case "$arg" in
        --all) install_all=1 ;;
        *) prefix="$arg" ;;
    esac
done

if [[ -z "$prefix" || ! -d "$prefix/drive_c/windows" ]]; then
    echo "usage: $0 /path/to/wine-prefix [--all]   (must contain drive_c/windows)" >&2
    exit 1
fi

dest="$prefix/drive_c/windows/Fonts"
mkdir -p "$dest"
backup=""
installed=0
unchanged=0
removed=0

make_backup_dir() {
    [[ -n "$backup" ]] && return
    backup="$prefix/fonts-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup"
}

wanted() {  # is this bundled font one we install?
    local name="$1"
    (( install_all )) && return 0
    local p
    for p in "${PATCHED_FONTS[@]}"; do [[ "$name" == "$p" ]] && return 0; done
    return 1
}

for font in "$repo"/fonts/*.ttf "$repo"/fonts/*.otf; do
    name="$(basename "$font")"
    # Wine's Fonts folder is case-insensitive in practice; match any existing case.
    existing="$(find "$dest" -maxdepth 1 -iname "$name" -print -quit)"

    if ! wanted "$name"; then
        if [[ -n "$existing" ]]; then
            make_backup_dir
            mv "$existing" "$backup/"
            removed=$((removed + 1))
        fi
        continue
    fi

    if [[ -n "$existing" ]] && cmp -s "$font" "$existing"; then
        unchanged=$((unchanged + 1))
        continue
    fi
    if [[ -n "$existing" ]]; then
        make_backup_dir
        mv "$existing" "$backup/"
    fi
    cp "$font" "$dest/$name"
    installed=$((installed + 1))
done

echo "Fonts: $installed installed/updated, $unchanged already up to date -> $dest"
(( removed )) && echo "Removed $removed font(s) the game provides itself (they can turn the skills dots into boxes)."
[[ -n "$backup" ]] && echo "Replaced/removed files were moved to: $backup"
exit 0
