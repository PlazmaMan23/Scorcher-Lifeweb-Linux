#!/usr/bin/env bash
# Installs BYOND through Lutris with the Linux fixes from this repo:
#   1. downloads the pinned Wine build into Lutris' runner folder (checksum-verified)
#   2. fills in the Lutris installer template with this repo's path
#   3. hands the installer to Lutris (you click through the Lutris window)
#
# Usage: ./install.sh [scorcher|lifeweb]
#   scorcher (default)  BYOND 516.1683
#   lifeweb             BYOND 516.1673
# Each one installs into its own Wine prefix, so both can be installed side by side.
set -euo pipefail

case "${1:-scorcher}" in
    scorcher) template="byond.yml.in";         game_label="Scorcher (BYOND 516.1683)" ;;
    lifeweb)  template="byond-lifeweb.yml.in"; game_label="LifeWeb (BYOND 516.1673)" ;;
    -h|--help) echo "usage: $0 [scorcher|lifeweb]"; exit 0 ;;
    *) echo "unknown game '${1}' (expected: scorcher, lifeweb)" >&2; exit 1 ;;
esac

ARCHIVE="wine-11.17-staging-amd64-wow64"
RUNNER_URL="https://github.com/Kron4ek/Wine-Builds/releases/download/11.17/${ARCHIVE}.tar.xz"
RUNNER_SHA256="278d80f3073f1a81386baafb41b83638d89eedaffb640f31599855145ed4fd7b"
# Lutris requires runner folder names to end in an architecture (-x86_64); without
# it, Lutris appends one itself and then can't find (or download) the runner.
RUNNER="${ARCHIVE}-x86_64"

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/byond-lutris-guide"

die() { echo "error: $*" >&2; exit 1; }

# --- Find Lutris (native or Flatpak) -----------------------------------------
if command -v lutris >/dev/null 2>&1; then
    lutris_cmd=(lutris)
    runners_dir="${XDG_DATA_HOME:-$HOME/.local/share}/lutris/runners/wine"
elif command -v flatpak >/dev/null 2>&1 && flatpak info net.lutris.Lutris >/dev/null 2>&1; then
    lutris_cmd=(flatpak run net.lutris.Lutris)
    runners_dir="$HOME/.var/app/net.lutris.Lutris/data/lutris/runners/wine"
else
    die "Lutris not found. Install it from your distro's packages or Flathub first."
fi

for tool in curl tar sha256sum; do
    command -v "$tool" >/dev/null 2>&1 || die "'$tool' is required but not installed."
done
[[ "$repo" == *" "* ]] && die "Please move this folder to a path without spaces (Lutris quoting): $repo"

# --- 1. Pinned Wine runner ----------------------------------------------------
if [[ ! -e "$runners_dir/$RUNNER" && -x "$runners_dir/$ARCHIVE/bin/wine" ]]; then
    # Folder from an older version of this script that lacked the -x86_64 suffix.
    mv "$runners_dir/$ARCHIVE" "$runners_dir/$RUNNER"
fi

if [[ -x "$runners_dir/$RUNNER/bin/wine" ]]; then
    echo "Wine runner already installed: $runners_dir/$RUNNER"
else
    mkdir -p "$cache" "$runners_dir"
    tarball="$cache/$ARCHIVE.tar.xz"
    if [[ ! -f "$tarball" ]] || ! echo "$RUNNER_SHA256  $tarball" | sha256sum -c --status; then
        echo "Downloading $RUNNER (~100 MB)..."
        curl -L --fail --progress-bar -o "$tarball.part" "$RUNNER_URL"
        mv "$tarball.part" "$tarball"
    fi
    echo "$RUNNER_SHA256  $tarball" | sha256sum -c --status || die "Checksum mismatch for $tarball (delete it and retry)."
    echo "Extracting to $runners_dir/$RUNNER ..."
    tmp="$(mktemp -d "$runners_dir/.extract.XXXXXX")"
    tar -xJf "$tarball" -C "$tmp"
    mv "$tmp/$ARCHIVE" "$runners_dir/$RUNNER"
    rmdir "$tmp"
    [[ -x "$runners_dir/$RUNNER/bin/wine" ]] || die "Runner extraction failed."
fi

# --- 2. Render the Lutris installer --------------------------------------------
mkdir -p "$cache"
installer="$cache/${template%.yml.in}-linux-fixes.yml"
sed -e "s|@REPO@|$repo|g" -e "s|@RUNNER@|$RUNNER|g" "$repo/lutris/$template" > "$installer"
echo "Lutris installer written to: $installer"

# --- 3. Run it ----------------------------------------------------------------
echo "Installing: $game_label"
echo "Opening Lutris. Pick an install folder of its own (e.g. ~/Games/byond or ~/Games/byond-lifeweb)"
echo "and follow the prompts. Don't reuse another game's folder."
echo "Tip: close games/heavy apps during install; unpacking WebView2 needs RAM and ~2 GB disk."
"${lutris_cmd[@]}" -i "$installer"
