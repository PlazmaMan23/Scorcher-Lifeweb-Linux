# BYOND on Linux (Lutris) — with fixes for Scorcher's UI

A Lutris-based install of **BYOND 516.1683** that plays Space Station 13–style
games (tested on **Scorcher**) under Wine. It includes the workarounds found while
getting the HUD to render correctly on Linux.

What you get:

- BYOND 516.1683 in its own Wine prefix, installed through Lutris
- A pinned Wine build (**wine-staging 11.17, WoW64**) so everyone runs the same Wine
- WebView2 (BYOND's pager and chat UI), Visual C++ 2022 runtime, DirectX bits, core fonts
- Scorcher's HUD fonts, including a **patched Retron2000** that fixes the missing
  stat numbers (`ST DX HT PR IN AT` box)

---

## Requirements

- A 64-bit Linux distro with a working Vulkan driver (DXVK is used)
- **Lutris** (distro package or Flatpak `net.lutris.Lutris`)
- `curl`, `tar`, `sha256sum` (present on most systems)
- About 3 GB of free disk space (plus ~750 MB for a game's resources on first join)
- Optional: `python3` with fontTools, only for `scripts/check-setup.sh` and
  `scripts/patch-font-hinting.py`

Keep this folder somewhere **without spaces in the path** and don't delete it until
the install finishes, because Lutris copies the fonts from it.

## Install

```bash
git clone https://github.com/PlazmaMan23/Scorcher-Lifeweb-Linux.git ~/Scorcher-Lifeweb-Linux
cd ~/Scorcher-Lifeweb-Linux
./install.sh
```

`install.sh`:

1. downloads the pinned Wine build into Lutris' runner folder and verifies its checksum
2. writes a Lutris installer pointing at this folder
3. opens Lutris with that installer

In the Lutris window, pick an install folder (for example `~/Games/byond`) and
follow the prompts. The install takes several minutes. A WebView2 installer
window appears and closes by itself when it's done. The BYOND installer runs silently,
so Lutris can look idle for a while. The installer is based on the published
Lutris script `byond-v5161680-egl`, with the fixes from this repo added on top.

**Close games and other heavy programs while it installs.** The WebView2 installer
unpacks a ~700 MB archive and needs free RAM plus ~2 GB of disk. If it fails with
*"Command exited with code 512"*, see *Troubleshooting* below.

When it's done you'll have a **BYOND** entry in Lutris.

## First launch

1. Start **BYOND** from Lutris and log in to your BYOND account in the pager.
2. Join the server you want to play, from the pager's game list or a `byond://` link.
3. **Wait on the "Your Game Is Starting" window**, even if it shows a white page
   saying **"Forbidden"**. That page is harmless. Behind it, the game is downloading
   its resource pack (hundreds of MB). Closing the window at this point is what
   makes it look like "it can't connect". To confirm it's downloading, watch
   `drive_c/users/<you>/Documents/BYOND/cache/` inside the prefix grow.
4. Once in-game, the bottom-left stat box should show **two lines**: numbers on
   top, `ST DX HT PR IN AT` below.

## Checking an install

```bash
./scripts/check-setup.sh ~/Games/byond
```

Read-only. It reports the BYOND version, WebView2, the fonts and the Retron2000 patch,
and warns about known-bad tweaks.

## Already have a BYOND prefix?

You can apply just the font fix to an existing prefix. Close BYOND first:

```bash
./scripts/install-fonts.sh ~/Games/your-byond-prefix
```

Existing fonts with the same file name are moved into
`<prefix>/fonts-backup-<timestamp>/` before being replaced.

---

## Known issues

| Symptom | Status / workaround |
|---|---|
| "Forbidden" page when joining | Not an error. Wait for the resource download (see *First launch*). |
| Right-hand chat panel is blank after alt-tabbing back | Click on the chat window and it redraws. A WebView2-under-Wine redraw quirk; harmless. |
| No icon for the **dangs** symbol on Scorcher: a small box `□` next to the counter | The symbol isn't in the font the counter uses, and Wine doesn't substitute another font for it like Windows does. Cosmetic, not fixed yet. |
| Other HUD text slightly too wide / wrapping | Other unhinted game fonts may have the same issue as Retron2000 (see below). Not patched yet. |

## Things that do **not** help (don't bother)

- **`winetricks ie8`**: replaces Wine's networking DLLs with 2009 IE8 ones and can
  break logins. `check-setup.sh` warns if present.
- **Changing DPI** in Lutris: BYOND's in-game text (maptext) ignores it. It only
  resizes the WebView2 chat panel.

---

## How the stat-box fix works

Scorcher draws its HUD text (maptext) with **Retron2000**, a monospaced pixel
font. The font ships without TrueType hinting tables (`fpgm`/`prep`). With no
hinting, FreeType (which Wine uses) turns on its **auto-hinter**. At small sizes
this rounds some letters up by a pixel. For example, at 9 px "S" becomes 7 px wide
instead of 6, while digits stay at 6. Windows doesn't auto-hint, so on Windows
`ST DX HT PR IN AT` is 87 px. Under Wine it's 99 px, which no longer fits the
stat box: `AT` wraps to a new line and the numbers line gets pushed out.

`scripts/patch-font-hinting.py` adds a one-instruction `fpgm` and `prep` table.
FreeType then uses the regular TrueType path and keeps the designed widths. Letter
shapes are unchanged. The bundled `fonts/12420.ttf` was produced with:

```bash
./scripts/patch-font-hinting.py original/12420.ttf fonts/12420.ttf
```

The same approach may help other game fonts that lack hinting (Project Sans
`SCOVRB.ttf`, IntellectCYR `19187.ttf`, TL header `TLHeader.otf`,
Konung `TALES.ttf`, AlundraText `19151.ttf`). Those are shipped **unpatched** for now
because they haven't been tested in-game.

## Uninstall

Remove the game from Lutris (optionally deleting its files). The Wine build lives
in `~/.local/share/lutris/runners/wine/wine-11.17-staging-amd64-wow64-x86_64`
(Flatpak: `~/.var/app/net.lutris.Lutris/data/lutris/runners/wine/`), and downloads
are cached in `~/.cache/byond-lutris-guide/`.

## Troubleshooting

**Can't join the game / stuck while connecting.** Most of these are fixed simply by
**re-joining the server**, or by **closing and relaunching BYOND, several times if
needed**, before anything else. Make sure BYOND is fully closed between attempts
(the pager too). If the "Your Game Is Starting" window shows "Forbidden", that's the
resource download, so just wait (see *First launch*).

**Lutris: "Command exited with code 512" during install.** Some installer step
failed. The usual culprit is WebView2. Check
`<install folder>/drive_c/Program Files/msedge_installer.log`. If it says
*"Unable to uncompress archive"* / *"installer archive is corrupted"*:

1. Delete the half-finished install folder (Lutris may fail to trash it itself).
2. Close other heavy programs and run `./install.sh` again. Lutris downloads a fresh
   copy of the WebView2 installer.

**Lutris: "Failed to retrieve wine (...) information".** Lutris can't find the
Wine build. Re-run `./install.sh`, which installs it into Lutris' runner folder
before opening the installer.

## Debugging tips

- Wine font selection: launch with `WINEDEBUG=+font` and grep the output for
  `font_SelectFont` / `select_font Chosen`.
- Networking: `WINEDEBUG=+winsock`. Expect a lot of output.
- BYOND is a single-instance app: if a pager is already running, a new launch
  hands off to it. Close BYOND fully before running a traced session.

## Testing on a new machine

Trying this guide on a fresh system? Please follow [TESTING.md](TESTING.md). It lists
what to check in-game and has a report template to send back.

## Repository layout

```
install.sh                    entry point
TESTING.md                    checklist + report template for testers
lutris/byond.yml.in           Lutris installer template (filled in by install.sh)
fonts/                        bundled game fonts (see fonts/NOTICE.md)
scripts/install-fonts.sh      copy fonts into a prefix (with backups)
scripts/check-setup.sh        read-only health check of a prefix
scripts/patch-font-hinting.py add no-op hinting tables to a TrueType font
```
