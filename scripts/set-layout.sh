#!/usr/bin/env bash
# Switch keyboard layout so BYOND's chat/HTML windows follow it.
#
# Why this is needed: those windows are WebView2 (Chromium). The usual layout
# switch (Alt+Shift and friends) only changes the XKB *group*. Wine translates
# that correctly for its own windows but never tells Windows programs the layout
# changed, so Chromium keeps using the key table it already built - you end up
# able to type only one layout in the chat and in any window the game opens.
# Replacing the *keymap* does reach it, and takes effect immediately, with no
# need to reopen anything. That is what this script does.
#
# Usage:
#   ./set-layout.sh                 show the current layout list and the method used
#   ./set-layout.sh us              put 'us' first in the existing list (the rest stay)
#   ./set-layout.sh us ru ua        set the list outright, first one active
#
# Bind it to a key with your WM/DE's shortcut config and use it instead of the
# group switch while playing. Safe to re-run.
set -euo pipefail

usage() { sed -n '3,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
[[ "${1:-}" == -h || "${1:-}" == --help ]] && { usage; exit 0; }

have() { command -v "$1" >/dev/null 2>&1; }

# --- Pick a method -------------------------------------------------------------
# Each backend can report the current comma-separated layout list and replace it.
method=""
if [[ -n "${SWAYSOCK:-}" ]] && have swaymsg; then
    method=sway
elif [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && have hyprctl; then
    method=hyprland
elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && have riverctl && pgrep -x river >/dev/null 2>&1; then
    method=river
elif [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] && have kreadconfig6 && have kwriteconfig6; then
    method=kde
elif [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]] && have gsettings; then
    method=gnome
elif [[ -z "${WAYLAND_DISPLAY:-}" && -n "${DISPLAY:-}" ]] && have setxkbmap; then
    method=x11
fi

if [[ -z "$method" ]]; then
    cat >&2 <<'MSG'
No way found to change the keymap of a running session.

Most Wayland compositors without an IPC command (labwc, Wayfire, plain weston)
can only take the layout at startup, from the environment:

    XKB_DEFAULT_LAYOUT=us,ru
    XKB_DEFAULT_OPTIONS=grp:alt_shift_toggle

Set those before the compositor starts and put the layout you need to type in
the game first. Until it is restarted, the only workarounds are typing in
another program and pasting with Ctrl+V, or using the game's own input instead
of the windows it opens.
MSG
    exit 1
fi

# --- Read the current list -----------------------------------------------------
current() {
    case "$method" in
        # sway reports layout *names* ("English (US)"), not codes, and river has no
        # query command at all - so with those, pass the whole list explicitly.
        sway|river) echo "" ;;
        hyprland) hyprctl -j getoption input:kb_layout \
                    | sed -n 's/.*"str": *"\([^"]*\)".*/\1/p' ;;
        kde)      kreadconfig6 --file kxkbrc --group Layout --key LayoutList ;;
        gnome)    gsettings get org.gnome.desktop.input-sources sources \
                    | grep -o "'xkb', *'[^']*'" | sed "s/.*'\([^']*\)'$/\1/" | paste -sd, - ;;
        x11)      setxkbmap -query | awk '/^layout:/ {print $2}' ;;
    esac
}

cur="$(current || true)"

if [[ $# -eq 0 ]]; then
    echo "Method:  $method"
    echo "Layouts: ${cur:-(cannot be queried with this method)}"
    [[ -n "$cur" ]] && echo "First one (${cur%%,*}) is what the game's WebView2 windows use."
    exit 0
fi

# --- Work out the new list -----------------------------------------------------
if [[ $# -gt 1 ]]; then
    IFS=','; new="$*"; unset IFS            # explicit list, used as given
else
    want="$1"
    if [[ -z "$cur" ]]; then
        echo "Can't read the current list with this method; pass the whole list," >&2
        echo "e.g. $(basename "$0") $want <others>" >&2
        exit 1
    fi
    IFS=',' read -r -a list <<< "$cur"
    idx=-1
    for i in "${!list[@]}"; do
        [[ "${list[i]}" == "$want" ]] && { idx=$i; break; }
    done
    if (( idx < 0 )); then
        echo "'$want' is not in the current list ($cur)." >&2
        echo "Either add it there first, or pass the whole list:" >&2
        echo "  $(basename "$0") $want ${list[*]}" >&2
        exit 1
    fi
    # Rotate, so the other layouts stay available in the same relative order.
    rotated=()
    for ((k = 0; k < ${#list[@]}; k++)); do
        rotated+=("${list[$(( (idx + k) % ${#list[@]} ))]}")
    done
    IFS=','; new="${rotated[*]}"; unset IFS
fi

if [[ "$new" == "$cur" ]]; then
    echo "Already $new - nothing to do."
    exit 0
fi

# --- Apply ---------------------------------------------------------------------
case "$method" in
    sway)
        swaymsg input type:keyboard xkb_layout "$new" >/dev/null ;;
    hyprland)
        hyprctl keyword input:kb_layout "$new" >/dev/null ;;
    river)
        riverctl keyboard-layout "$new" ;;
    x11)
        setxkbmap -layout "$new" ;;
    gnome)
        sources=""
        IFS=',' read -r -a list <<< "$new"
        for l in "${list[@]}"; do sources+="${sources:+, }('xkb', '$l')"; done
        gsettings set org.gnome.desktop.input-sources sources "[$sources]" ;;
    kde)
        # Keep VariantList/DisplayNames paired with LayoutList, then make KWin
        # re-read the file - the same thing System Settings does.
        IFS=',' read -r -a old_l <<< "$cur"
        IFS=',' read -r -a old_v <<< "$(kreadconfig6 --file kxkbrc --group Layout --key VariantList),,,,,,,,"
        IFS=',' read -r -a old_n <<< "$(kreadconfig6 --file kxkbrc --group Layout --key DisplayNames),,,,,,,,"
        IFS=',' read -r -a new_l <<< "$new"
        new_v=(); new_n=()
        for l in "${new_l[@]}"; do
            v=""; n=""
            for i in "${!old_l[@]}"; do
                [[ "${old_l[i]}" == "$l" ]] && { v="${old_v[i]:-}"; n="${old_n[i]:-}"; break; }
            done
            new_v+=("$v"); new_n+=("$n")
        done
        join() { local IFS=','; echo "$*"; }
        kwriteconfig6 --file kxkbrc --group Layout --key LayoutList   "$(join "${new_l[@]}")"
        kwriteconfig6 --file kxkbrc --group Layout --key VariantList  "$(join "${new_v[@]}")"
        kwriteconfig6 --file kxkbrc --group Layout --key DisplayNames "$(join "${new_n[@]}")"
        qdbus="$(command -v qdbus6 || command -v qdbus-qt6 || command -v qdbus)"
        "$qdbus" org.kde.KWin /KWin reconfigure ;;
esac

echo "Layouts now: $new  (via $method)"
echo "${new%%,*} is active; the game's WebView2 windows should follow immediately."
