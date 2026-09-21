# Testing this guide on a new machine

Thanks for trying it. The goal is to find out whether the install and the fixes work
on a system that has never had BYOND or these fonts set up. Please go through the
steps below and send back the report at the end, including anything that failed
or looked odd.

## Before you start

- Don't copy any fonts or Wine prefixes from someone else's setup. A clean machine is
  the point of the test.
- Close games and other heavy programs during the install.

## 1. Install

Follow [README.md](README.md) → *Install*. Note:

- Did `./install.sh` finish without errors? Copy its terminal output.
- Did the Lutris installer finish? If it showed an error, take a screenshot of it and
  save the error details ("Copy Details to Clipboard" in the Lutris error window, pasted
  into a text file).
- Which install folder you picked, and roughly how long the install took.

## 2. Check the install

```bash
./scripts/check-setup.sh ~/Games/<your install folder>
```

Copy the full output.

## 3. In-game checks (Scorcher)

Log in, join Scorcher, and wait through the "Forbidden" loading screen (see README).
Then take screenshots of:

| # | What | When | What it should look like |
|---|---|---|---|
| 1 | Bottom-left **stat box** | once in-game | Two lines: numbers on top, `ST DX HT PR IN AT` below |
| 2 | **Skills** tab in the chat panel | right after joining | Dots `●○○○○`, not boxes |
| 3 | **Skills** tab in the chat panel | after ~30 minutes of play | Same as above |
| 4 | **Skills** window during character creation | when you see it | Dots, not boxes |
| 5 | Top-left **currency counter** | once in-game | A rune symbol before the number (a box `□` is a known issue) |
| 6 | Anything else that looks broken | whenever | Screenshot + a short description |

If you **can't join** at first, see README → *Troubleshooting → Can't join the game*
before reporting it, and mention how many retries it took.

## 4. Report template

Copy this, fill it in, and attach the screenshots and logs:

```text
Distro + version:
Desktop (KDE/GNOME/…, X11 or Wayland):
GPU + driver:
Lutris version, native or Flatpak:
Other Wine/BYOND setups on this machine before (yes/no, which):
Custom fonts installed system-wide (e.g. ~/.local/share/fonts, /usr/local/share/fonts)? :

install.sh finished OK:            yes / no (output attached)
Lutris installer finished OK:      yes / no (error attached)
check-setup.sh output:             (attached)

Could join Scorcher:               yes / after N retries / no
Stat box shows numbers:            yes / no   (screenshot 1)
Skills dots right after joining:   dots / boxes (screenshot 2)
Skills dots after ~30 min:         dots / boxes (screenshot 3)
Character creation skills window:  dots / boxes (screenshot 4)
Currency counter symbol:           symbol / box (screenshot 5)
Other problems:
```
