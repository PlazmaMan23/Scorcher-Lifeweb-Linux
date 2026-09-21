#!/usr/bin/env python3
"""Copy one character's glyph from a donor font into another TrueType font.

Why: Scorcher draws the "dangs" currency symbol (the rune ᛞ, U+16DE) in
Retron2000, which has no such character. On Windows the missing character is
filled in from another font; under Wine it comes out as a box. The game ships a
font that does have it (Fifaks, Pixel.ttf), so we copy the glyph into our
patched Retron2000 and the symbol renders from the font itself.

The glyph is scaled so both fonts' capital-H heights match, and placed on the
baseline with the destination font's left side bearing and advance width.

Usage: copy-glyph.py DONOR.ttf DEST.ttf U+16DE OUT.ttf
Requires: fontTools
"""
import sys

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont


def cap_bounds(font):
    """Bounding box of capital H, used to match size and position across fonts."""
    pen = BoundsPen(font.getGlyphSet())
    font.getGlyphSet()[font.getBestCmap()[ord("H")]].draw(pen)
    return pen.bounds  # x_min, y_min, x_max, y_max


def main():
    if len(sys.argv) != 5:
        sys.exit(__doc__)
    donor_path, dest_path, codepoint_arg, out_path = sys.argv[1:]
    codepoint = int(codepoint_arg.lower().replace("u+", ""), 16)

    donor, dest = TTFont(donor_path), TTFont(dest_path, recalcTimestamp=False)
    donor_cmap, dest_cmap = donor.getBestCmap(), dest.getBestCmap()
    if codepoint not in donor_cmap:
        sys.exit(f"{donor_path} has no U+{codepoint:04X}")
    if codepoint in dest_cmap:
        sys.exit(f"{dest_path} already has U+{codepoint:04X}")

    donor_x0, donor_y0, _, donor_y1 = cap_bounds(donor)
    dest_x0, dest_y0, _, dest_y1 = cap_bounds(dest)
    scale = (dest_y1 - dest_y0) / (donor_y1 - donor_y0)

    # Scale to the same cap height, then align with the destination's capital H:
    # same baseline, same left side bearing.
    pen = TTGlyphPen(None)
    transform = (scale, 0, 0, scale, dest_x0 - donor_x0 * scale, dest_y0 - donor_y0 * scale)
    donor.getGlyphSet()[donor_cmap[codepoint]].draw(TransformPen(pen, transform))
    glyph = pen.glyph()
    glyph.recalcBounds(dest["glyf"])

    name = f"uni{codepoint:04X}"
    while name in dest.getGlyphOrder():
        name += "_"
    dest["glyf"][name] = glyph  # also appends to the glyph order
    # Match the destination's own spacing (Retron2000 is monospaced).
    advance = dest["hmtx"][dest_cmap[ord("H")]][0]
    dest["hmtx"][name] = (advance, glyph.xMin)
    added = 0
    for table in dest["cmap"].tables:
        if table.isUnicode():
            table.cmap[codepoint] = name
            added += 1
    if not added:
        sys.exit("no Unicode cmap subtable to add the character to")
    dest["maxp"].recalc(dest)
    dest.save(out_path)
    print(f"{dest_path} + U+{codepoint:04X} from {donor_path} -> {out_path} "
          f"(scaled x{scale:.1f}, added to {added} cmap subtable(s))")


if __name__ == "__main__":
    main()
