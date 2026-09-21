#!/usr/bin/env python3
"""Add no-op hinting tables to a TrueType font so FreeType won't auto-hint it.

Why: under Wine, fonts without `fpgm`/`prep` tables get FreeType's auto-hinter,
which rounds some glyph advances up by a pixel (e.g. Retron2000 "S" 6px -> 7px at
9ppem). Windows doesn't do that, so BYOND maptext laid out under Wine comes out
wider and wraps (Scorcher's stat box lost its numbers line). A one-instruction
`fpgm` and `prep` make FreeType use the TrueType path, which keeps advances as
designed. Glyph shapes and names are untouched.

Usage: patch-font-hinting.py INPUT.ttf OUTPUT.ttf
Requires: fontTools (Arch: python-fonttools, Debian/Ubuntu: python3-fonttools)
"""
import sys

from fontTools.ttLib import TTFont, newTable
from fontTools.ttLib.tables import ttProgram


def noop_program():
    program = ttProgram.Program()
    program.fromAssembly(["SVTCA[0]"])
    return program


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, dst = sys.argv[1], sys.argv[2]
    # Keep the original 'modified' timestamp so the output is reproducible.
    font = TTFont(src, recalcTimestamp=False)
    if "glyf" not in font:
        sys.exit(f"{src}: not a TrueType-outline font (CFF fonts aren't auto-hinted this way)")
    added = []
    for tag in ("fpgm", "prep"):
        if tag not in font:
            table = newTable(tag)
            table.program = noop_program()
            font[tag] = table
            added.append(tag)
    font.save(dst)
    print(f"{src} -> {dst}: added {', '.join(added) if added else 'nothing (already hinted)'}")


if __name__ == "__main__":
    main()
