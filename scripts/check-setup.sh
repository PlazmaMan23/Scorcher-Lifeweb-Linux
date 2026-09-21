#!/usr/bin/env bash
# Read-only health check of a BYOND Wine prefix against this repo's fixes.
# Usage: scripts/check-setup.sh /path/to/prefix
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
prefix="${1:-}"
[[ -n "$prefix" && -d "$prefix/drive_c" ]] || { echo "usage: $0 /path/to/wine-prefix" >&2; exit 1; }

ok()   { printf '  [ok]   %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; }

echo "Prefix: $prefix"

core="$prefix/drive_c/Program Files (x86)/BYOND/bin/byondcore.dll"
if [[ -f "$core" ]]; then
    ver="$(strings -el "$core" 2>/dev/null | grep -A1 -x 'FileVersion' | tail -1)"
    ok "BYOND installed (${ver:-version unknown})"
else
    bad "BYOND not found at: $core"
fi

if compgen -G "$prefix/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application/*/msedgewebview2.exe" >/dev/null; then
    ok "WebView2 runtime installed"
else
    bad "WebView2 runtime missing (BYOND's pager/chat windows will be blank)"
fi

grep -q 'msedgewebview2.exe' "$prefix/user.reg" 2>/dev/null && ok "WebView2 Windows-7 app default set" \
    || warn "No AppDefaults entry for msedgewebview2.exe (win7)"

fonts="$prefix/drive_c/windows/Fonts"
missing=0; different=0
for font in "$repo"/fonts/*.ttf "$repo"/fonts/*.otf; do
    name="$(basename "$font")"
    existing="$(find "$fonts" -maxdepth 1 -iname "$name" -print -quit 2>/dev/null)"
    if [[ -z "$existing" ]]; then missing=$((missing + 1))
    elif ! cmp -s "$font" "$existing"; then different=$((different + 1)); fi
done
if (( missing == 0 && different == 0 )); then ok "All bundled fonts installed and up to date"
else warn "Fonts: $missing missing, $different different -> run scripts/install-fonts.sh \"$prefix\""; fi

retron="$(find "$fonts" -maxdepth 1 -iname 12420.ttf -print -quit 2>/dev/null)"
if [[ -n "$retron" ]] && python3 -c "import sys; from fontTools.ttLib import TTFont; f=TTFont(sys.argv[1]); sys.exit(0 if 'fpgm' in f and 'prep' in f else 1)" "$retron" 2>/dev/null; then
    ok "Retron2000 (12420.ttf) has the hinting patch"
elif [[ -n "$retron" ]] && ! python3 -c "import fontTools" 2>/dev/null; then
    cmp -s "$retron" "$repo/fonts/12420.ttf" && ok "Retron2000 matches the patched copy" || warn "Can't verify Retron2000 patch (fontTools not installed)"
else
    bad "Retron2000 missing or unpatched: stat numbers may disappear"
fi

if grep -qE '^"\*?(wininet|urlmon|mshtml)"="native' "$prefix/user.reg" 2>/dev/null; then
    warn "Native IE DLL overrides found (winetricks ie8?). They don't help BYOND; remove them."
else
    ok "No IE8 DLL overrides"
fi
