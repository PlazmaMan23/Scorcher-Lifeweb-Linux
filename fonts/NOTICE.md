# Fonts

These font files are **not** part of this project's own work. They come from the
Scorcher game's resource pack and belong to their respective authors and
licensors. They're bundled only so the game's HUD renders correctly under Wine.
If you're a rights holder and want a font removed, open an issue.

Only one file is modified:

| File | Family | Change |
|---|---|---|
| `12420.ttf` | Retron2000 | 1. Added no-op `fpgm` + `prep` tables (`scripts/patch-font-hinting.py`) so FreeType doesn't auto-hint it wider. 2. Added the rune ᛞ (U+16DE) copied from `Pixel.ttf` (`scripts/copy-glyph.py`), which Wine otherwise draws as a box |

Unmodified: `1.otf` `3.otf` `6.otf` `8.otf` `10.otf` `12.otf` `19151.ttf`
`19187.ttf` `baron.ttf` `brandon.otf` `ERIS.ttf` `erisblack.ttf` `frank.ttf`
`neom.otf` `Pixel.ttf` `SCOVRB.ttf` `TALES.ttf` `TLHeader.otf` `vrn.ttf`

Microsoft fonts (Segoe UI Symbol, MS Sans Serif, Small Fonts) are intentionally
**not** included.
